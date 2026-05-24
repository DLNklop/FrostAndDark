extends Control

## Менеджер интерактивного пролога JRPG «Frost & Dark: Ыччаттар».

# --- Пути к ресурсам ---
const MUSIC_PATH := "res://audio/menu_music.mp3"
const AMBIENT_PATH := "res://audio/blizzard.mp3"
const GAME_SCENE_PATH := "res://tscn/scene_1.tscn"

# --- Тайминги ---
const FADE_DURATION := 0.5
const TYPEWRITER_CHAR_DELAY := 0.02
const FINALE_WAIT_SEC := 3.0
const TEXT_SHAKE_AMOUNT := 2.0
const BG_PULSE_MIN := 0.92
const BG_PULSE_MAX := 1.0
const BG_PULSE_DURATION := 2.5

# --- Цветовая схема ---
const COLOR_BG := Color("#0a0e17")
const COLOR_ACCENT := Color("#2a9d8f")
const COLOR_ACCENT_BRIGHT := Color("#38b6ff")
const COLOR_TEXT := Color("#b8c9d9")

# --- Узлы UI ---
@onready var _background: TextureRect = $Control/Background
@onready var _main_box: Panel = $Control/MainBox
@onready var _text_label: RichTextLabel = $Control/MainBox/RichTextLabel
@onready var _choices_box: VBoxContainer = $Control/ChoicesBox
@onready var _choice_buttons: Array[Button] = [
	$Control/ChoicesBox/Button,
	$Control/ChoicesBox/Button2,
	$Control/ChoicesBox/Button3,
]

# --- Данные сцен (удобно редактировать в одном месте) ---
var scenes: Array[Dictionary] = [
	{
		"age": 12,
		"title": "Первый белый мрак",
		"text": "Внезапная метель застала вдали от стойбища. Ветер рвёт парку, глаза слепит наст. Нужно пережить ночь.",
		"choices": [
			"Вырыть яму в сугробе, накрыться шкурой, ждать",
			"Идти по ветру, искать естественный навес",
			"Развести костёр на открытом месте, греться движением",
		],
	},
	{
		"age": 18,
		"title": "Первая кровь",
		"text": "Ты загнал крупного зверя в ледяную расщелину. Он ранен, но не сдаётся. Дыхание сбивается, копыта скребут лёд.",
		"choices": [
			"Добить точно. Мясо и шкура нужны роду",
			"Отступить, дать уйти. Зверь сильнее в своей стихии",
			"Шепнуть благодарность, оставить подношение",
		],
	},
	{
		"age": 25,
		"title": "Замерзающий дух",
		"text": "В сугробе ты находишь детёныша ледяного волка. Он дрожит, глаза стекленеют. Метель усиливается, а запасы тепла на исходе.",
		"choices": [
			"Согреть дыханием и шкурой, даже если сам замёрзнешь",
			"Быстрый удар. Без мучений, но с добычей",
			"Оставить укрытие и еду, уйти искать помощь",
		],
	},
]

const FINALE_TEXT := (
	"Метель усиливается. Холод пробивает до костей. "
	+ "Ты — последний охотник своего рода. Бог охоты Байанай наблюдает за тобой..."
)

# --- Состояние ---
var current_index: int = 0
var choices: Array = []  # позже передадим в GameState
var _busy: bool = false
var _is_typing: bool = false
var _typewriter_timer: Timer
var _typewriter_target: String = ""
var _typewriter_pos: int = 0
var _fade_rect: ColorRect
var _audio_music: AudioStreamPlayer
var _audio_ambient: AudioStreamPlayer
var _audio_click: AudioStreamPlayer
var _main_box_base_pos: Vector2
var _bg_pulse_tween: Tween
var _fade_tween: Tween


func _ready() -> void:
	_setup_visual_style()
	_setup_fade_overlay()
	_setup_typewriter()
	_setup_audio()
	_setup_buttons()
	_setup_background_pulse()
	_main_box_base_pos = _main_box.position
	_begin_prologue()


func _setup_visual_style() -> void:
	# Панель текста — тёмно-синий фон, голубая рамка
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(COLOR_BG.r, COLOR_BG.g, COLOR_BG.b, 0.85)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = COLOR_ACCENT
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	_main_box.add_theme_stylebox_override("panel", panel_style)

	_text_label.bbcode_enabled = true
	_text_label.add_theme_color_override("default_color", COLOR_TEXT)
	_text_label.add_theme_font_size_override("normal_font_size", 17)


func _setup_fade_overlay() -> void:
	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeOverlay"
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.color = Color.BLACK
	_fade_rect.color.a = 1.0
	add_child(_fade_rect)
	move_child(_fade_rect, get_child_count() - 1)


func _setup_typewriter() -> void:
	_typewriter_timer = Timer.new()
	_typewriter_timer.name = "TypewriterTimer"
	_typewriter_timer.one_shot = false
	_typewriter_timer.wait_time = TYPEWRITER_CHAR_DELAY
	_typewriter_timer.timeout.connect(_on_typewriter_tick)
	add_child(_typewriter_timer)


func _setup_audio() -> void:
	_audio_music = _create_audio_player("Music", -10.0)
	_audio_ambient = _create_audio_player("Ambient", -15.0)
	_audio_click = _create_audio_player("SFX", -6.0)
	_audio_click.stream = _make_click_stream()

	var music := _load_stream(MUSIC_PATH)
	if music:
		if music is AudioStreamMP3:
			music.loop = true
		_audio_music.stream = music
		_audio_music.finished.connect(_on_music_finished)
		_audio_music.play()

	var ambient := _load_stream(AMBIENT_PATH)
	if ambient:
		if ambient is AudioStreamMP3:
			ambient.loop = true
		_audio_ambient.stream = ambient
		_audio_ambient.play()


func _create_audio_player(player_name: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.volume_db = volume_db
	player.bus = "Master"
	add_child(player)
	return player


func _load_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("PrologueManager: файл не найден — %s" % path)
		return null
	var resource := load(path)
	if resource == null or not resource is AudioStream:
		push_error("PrologueManager: не удалось загрузить аудио — %s" % path)
		return null
	return resource as AudioStream


func _on_music_finished() -> void:
	if _audio_music and _audio_music.stream:
		_audio_music.play()


func _begin_prologue() -> void:
	_busy = true
	await _fade_in()
	_busy = false
	load_scene(0)


func _setup_buttons() -> void:
	for i in _choice_buttons.size():
		var btn := _choice_buttons[i]
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", COLOR_TEXT)
		btn.add_theme_color_override("font_hover_color", COLOR_ACCENT_BRIGHT)
		btn.add_theme_color_override("font_pressed_color", COLOR_ACCENT)

		var normal := _make_button_stylebox(false)
		var hover := _make_button_stylebox(true)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", hover)
		btn.add_theme_stylebox_override("focus", hover)

		btn.mouse_entered.connect(_on_button_hover.bind(btn, true))
		btn.mouse_exited.connect(_on_button_hover.bind(btn, false))
		btn.pressed.connect(_on_choice_pressed.bind(i))


func _make_button_stylebox(bright: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.15 if not bright else 0.35)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = COLOR_ACCENT_BRIGHT if bright else COLOR_ACCENT
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _on_button_hover(btn: Button, hovered: bool) -> void:
	btn.modulate = Color(1.15, 1.15, 1.2, 1.0) if hovered else Color.WHITE


func _setup_background_pulse() -> void:
	if _background == null:
		return
	_background.modulate = Color(BG_PULSE_MAX, BG_PULSE_MAX, BG_PULSE_MAX, 1.0)
	_bg_pulse_tween = create_tween()
	_bg_pulse_tween.set_loops()
	_bg_pulse_tween.tween_property(_background, "modulate", Color(BG_PULSE_MIN, BG_PULSE_MIN, BG_PULSE_MIN, 1.0), BG_PULSE_DURATION)
	_bg_pulse_tween.tween_property(_background, "modulate", Color(BG_PULSE_MAX, BG_PULSE_MAX, BG_PULSE_MAX, 1.0), BG_PULSE_DURATION)


func _make_click_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var duration := 0.07
	var sample_count := int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in sample_count:
		var t := float(i) / float(stream.mix_rate)
		var envelope := 1.0 - (t / duration)
		var sample := sin(TAU * 920.0 * t) * envelope * 0.45
		data[i] = int(clamp((sample + 1.0) * 127.5, 0.0, 255.0))
	stream.data = data
	return stream


func _play_click() -> void:
	if _audio_click and _audio_click.stream:
		_audio_click.play()


func _set_buttons_enabled(enabled: bool) -> void:
	for btn in _choice_buttons:
		btn.disabled = not enabled
	_choices_box.modulate.a = 1.0 if enabled else 0.45


func load_scene(index: int) -> void:
	if index < 0 or index >= scenes.size():
		push_error("PrologueManager: неверный индекс сцены — %d" % index)
		return

	current_index = index
	var scene_data: Dictionary = scenes[index]
	var header := "[color=#38b6ff]%d лет — «%s»[/color]\n\n" % [scene_data.age, scene_data.title]
	var body: String = scene_data.text
	_start_typewriter(header + body)

	var scene_choices: Array = scene_data.choices
	for i in _choice_buttons.size():
		if i < scene_choices.size():
			_choice_buttons[i].text = scene_choices[i]
			_choice_buttons[i].visible = true
		else:
			_choice_buttons[i].visible = false

	_set_buttons_enabled(false)


func _start_typewriter(full_text: String) -> void:
	_typewriter_timer.stop()
	_is_typing = true
	_typewriter_target = full_text
	_typewriter_pos = 0
	_text_label.text = ""
	_typewriter_timer.start()


func _on_typewriter_tick() -> void:
	if _typewriter_pos >= _typewriter_target.length():
		_typewriter_timer.stop()
		_on_typewriter_finished()
		return

	# BBCode-теги выводим целиком, чтобы не ломать разметку
	if _typewriter_target[_typewriter_pos] == "[":
		var close := _typewriter_target.find("]", _typewriter_pos)
		if close != -1:
			_typewriter_pos = close + 1
		else:
			_typewriter_pos += 1
	else:
		_typewriter_pos += 1

	_text_label.text = _typewriter_target.substr(0, _typewriter_pos)

	# Лёгкое дрожание панели на каждой букве (едва заметно)
	if _typewriter_pos % 3 == 0:
		_shake_text_panel()


func _on_typewriter_finished() -> void:
	_is_typing = false
	_main_box.position = _main_box_base_pos
	if _choices_box.visible:
		_set_buttons_enabled(true)


func _shake_text_panel() -> void:
	var offset := Vector2(
		randf_range(-TEXT_SHAKE_AMOUNT, TEXT_SHAKE_AMOUNT),
		randf_range(-TEXT_SHAKE_AMOUNT, TEXT_SHAKE_AMOUNT)
	)
	_main_box.position = _main_box_base_pos + offset


func _on_choice_pressed(option_index: int) -> void:
	if _busy or _is_typing:
		return

	_busy = true
	_play_click()
	_set_buttons_enabled(false)

	var scene_data: Dictionary = scenes[current_index]
	var choice_text: String = scene_data.choices[option_index]
	choices.append({
		"scene_index": current_index,
		"age": scene_data.age,
		"title": scene_data.title,
		"choice_index": option_index,
		"choice_text": choice_text,
	})

	if current_index >= scenes.size() - 1:
		await _fade_out()
		_choices_box.visible = false
		await _fade_in()
		_start_typewriter(FINALE_TEXT)
		await _wait_typewriter_done()
		await get_tree().create_timer(FINALE_WAIT_SEC).timeout
		finish_prologue()
	else:
		current_index += 1
		await _fade_out()
		load_scene(current_index)
		await _fade_in()
		_busy = false


func _wait_typewriter_done() -> void:
	while _is_typing:
		await get_tree().process_frame


func _fade_in() -> void:
	await _run_fade(1.0, 0.0)


func _fade_out() -> void:
	await _run_fade(0.0, 1.0)


func _run_fade(from_alpha: float, to_alpha: float) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_rect.color.a = from_alpha
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fade_rect, "color:a", to_alpha, FADE_DURATION)
	await _fade_tween.finished


func finish_prologue() -> void:
	_busy = true
	if _audio_music:
		_audio_music.stop()
	if _audio_ambient:
		_audio_ambient.stop()

	if not ResourceLoader.exists(GAME_SCENE_PATH):
		push_error("PrologueManager: сцена игры не найдена — %s" % GAME_SCENE_PATH)
		_busy = false
		return

	var err := get_tree().change_scene_to_file(GAME_SCENE_PATH)
	if err != OK:
		push_error("PrologueManager: ошибка загрузки сцены (%d) — %s" % [err, GAME_SCENE_PATH])
		_busy = false
