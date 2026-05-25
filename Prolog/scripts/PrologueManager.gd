extends Control

## Пролог JRPG: лор → герой → 3 выбора → катастрофа → игра.

const MUSIC_PATH := "res://audio/menu_music.mp3"
const AMBIENT_PATH := "res://audio/blizzard.mp3"
const GAME_SCENE_PATH := "res://tscn/scene_1.tscn"
const DEFAULT_BG := "res://Prolog/sprite_objects/фон.png"

const FADE_STAGE := 0.5
const FADE_FINISH := 2.0
const TYPEWRITER_DEFAULT := 0.02
const COLOR_BG := Color("#0a0e17")
const COLOR_ACCENT := Color("#2a9d8f")
const COLOR_ACCENT_BRIGHT := Color("#38b6ff")
const COLOR_TEXT := Color("#b8c9d9")
const TEXT_FONT_SIZE := 17
const PANEL_WIDTH := 600  # viewport 640 — поля по 20px с каждой стороны
const TEXT_INNER_MARGIN := 16
const PANEL_HEIGHT_NARRATIVE := 200
const PANEL_HEIGHT_SHAKE := 220
const PANEL_HEIGHT_CHOICE := 108
const TEXT_INNER_WIDTH := PANEL_WIDTH - TEXT_INNER_MARGIN * 2
const SHAKE_OFFSET_MAX := 1.2

@onready var _background: TextureRect = $Background
@onready var _center_column: VBoxContainer = $ContentRoot/CenterColumn
@onready var _main_box: Panel = $ContentRoot/CenterColumn/MainBox
@onready var _text_label: RichTextLabel = $ContentRoot/CenterColumn/MainBox/TextCenter/RichTextLabel
@onready var _choices_box: VBoxContainer = $ContentRoot/CenterColumn/ChoicesBox
@onready var _choice_buttons: Array[Button] = [
	$ContentRoot/CenterColumn/ChoicesBox/ChoiceButton1,
	$ContentRoot/CenterColumn/ChoicesBox/ChoiceButton2,
	$ContentRoot/CenterColumn/ChoicesBox/ChoiceButton3,
]
@onready var _shake_root: TextureRect = $Background

var stages: Array[Dictionary] = [
	{
		"stage_id": "lore_intro_part1",
		"type": "narrative",
		"text": (
			"В мире, где зима длится девять месяцев в году, люди научились жить рядом с духами.\n\n"
			+ "Девять богов Айыы незримо охраняют людские роды: Юрюнг Айыы Тойон с девятого неба "
			+ "наблюдает за мирозданием, Улуу Суорун Тойон дарует огонь кузнецам, Дьөһөгэй Тойон "
			+ "благословляет табуны лошадей..."
		),
		"background": DEFAULT_BG,
		"next_stage": "lore_intro_part2",
	},
	{
		"stage_id": "lore_intro_part2",
		"type": "narrative",
		"text": (
			"Но самый близкий к людям — Байанай, бог охоты. Он ходит среди смертных в облике "
			+ "старика или животного, испытывая их щедрость и уважение к природе.\n\n"
			+ "Те, кто почитает заветы предков, получают его благословение. Те, кто забыл обычаи — "
			+ "остаются один на один с безжалостной тайгой."
		),
		"background": DEFAULT_BG,
		"next_stage": "hero_intro",
	},
	{
		"stage_id": "hero_intro",
		"type": "narrative",
		"text": (
			"Ты — Кыым (Искра). Тебе 29 лет. Ты охотник из небольшого стойбища у подножия "
			+ "Чочур-Мурана. Твой род живёт здесь семь поколений.\n\n"
			+ "Ты знаешь каждый след в тайге, умеешь читать погоду по облакам, различаешь голоса "
			+ "духов в шуме ветра."
		),
		"background": DEFAULT_BG,
		"next_stage": "hero_intro_part2",
	},
	{
		"stage_id": "hero_intro_part2",
		"type": "narrative",
		"text": (
			"Твой отец учил: «Байанай видит каждого. Он может прийти в облике волка, чтобы испытать "
			+ "тебя. Может шепнуть во сне, где искать добычу. Никогда не забывай поблагодарить лес "
			+ "за то, что он даёт тебе»."
		),
		"background": DEFAULT_BG,
		"next_stage": "trial_12",
	},
	{
		"stage_id": "trial_12",
		"type": "choice",
		"text": (
			"Вспомни свою юность. Тебе 12 лет. Первая серьёзная метель застала тебя вдали от "
			+ "стойбища. Ветер ревёт, снег слепит глаза. Ты видишь три пути..."
		),
		"background": DEFAULT_BG,
		"next_stage": "trial_18",
		"options": [
			{
				"label": "Вырыть яму в сугробе, накрыться шкурой и ждать",
				"skill": "Терпение охотника",
				"skill_desc": "укрытия эффективнее",
			},
			{
				"label": "Идти по ветру, искать естественное укрытие",
				"skill": "Чтение наста",
				"skill_desc": "быстрее находишь укрытия",
			},
			{
				"label": "Развести костёр на открытом месте",
				"skill": "Огонь в крови",
				"skill_desc": "медленнее замерзаешь",
			},
		],
	},
	{
		"stage_id": "trial_18",
		"type": "choice",
		"text": (
			"Тебе 18. Первая самостоятельная охота на крупного зверя. Ты загнал сохатого в "
			+ "ледяную расщелину. Он ранен, тяжело дышит, но не сдаётся..."
		),
		"background": DEFAULT_BG,
		"next_stage": "trial_25",
		"options": [
			{
				"label": "Добить быстро и точно. Мясо нужно роду",
				"skill": "Без пощады",
				"skill_desc": "больше урона по раненым врагам",
			},
			{
				"label": "Шепнуть благодарность и дать уйти, если сможет",
				"skill": "Завет Байаная",
				"skill_desc": "питомцы приручаются быстрее",
			},
			{
				"label": "Отступить, дать зверю умереть самому",
				"skill": "Тень тайги",
				"skill_desc": "шанс избежать случайных встреч",
			},
		],
	},
	{
		"stage_id": "trial_25",
		"type": "choice",
		"text": (
			"Тебе 25. В сугробе ты находишь детёныша ледяного волка. Он дрожит, глаза стекленеют. "
			+ "Метель усиливается. Твои запасы тепла на исходе..."
		),
		"background": DEFAULT_BG,
		"next_stage": "bull_awakening_part1",
		"options": [
			{
				"label": "Согреть своим дыханием и шкурой, даже если сам замёрзнешь",
				"skill": "Верность до конца",
				"skill_desc": "питомцы получают защиту",
			},
			{
				"label": "Быстрый удар ножом — без мучений",
				"skill": "Холодная рука",
				"skill_desc": "игнорируешь страх",
			},
			{
				"label": "Оставить укрытие и еду, уйти искать помощь",
				"skill": "Тактик метели",
				"skill_desc": "быстрее перемещаешься",
			},
		],
	},
	{
		"stage_id": "bull_awakening_part1",
		"type": "narrative",
		"text": (
			"29 лет. Поздняя осень.\n\n"
			+ "Старейшина стойбища будит тебя ночью: «Кыым, проснись! Смотри!»\n\n"
			+ "Ты выходишь из чума. На горизонте, там, где должна быть священная гора, пульсирует "
			+ "странное зеленоватое сияние."
		),
		"background": DEFAULT_BG,
		"next_stage": "bull_awakening_part1b",
		"typewriter_speed": 0.035,
		"screen_shake": true,
		"ambient_boost_db": 4.0,
	},
	{
		"stage_id": "bull_awakening_part1b",
		"type": "narrative",
		"text": (
			"Земля дрожит. Из трещин в вечной мерзлоте поднимается пар, "
			+ "но пахнет не теплом — пахнет древним льдом и пустотой."
		),
		"background": DEFAULT_BG,
		"next_stage": "bull_awakening_part2",
		"typewriter_speed": 0.035,
		"screen_shake": true,
		"ambient_boost_db": 4.0,
	},
	{
		"stage_id": "bull_awakening_part2",
		"type": "narrative",
		"text": (
			"«Бык Тымныы пробудился», — шепчет старейшина. — «Дух вечной зимы, что спал под горой "
			+ "сотни лет. Мы нарушили заветы... забыли подношения...»\n\n"
			+ "Ты чувствуешь, как меняется воздух. Ветер становится острее. Снег падает гуще."
		),
		"background": DEFAULT_BG,
		"next_stage": "bull_awakening_part2b",
		"typewriter_speed": 0.035,
		"screen_shake": true,
		"ambient_boost_db": 4.0,
	},
	{
		"stage_id": "bull_awakening_part2b",
		"type": "narrative",
		"text": "Ты бежишь к своему стойбищу, но когда доходишь — уже слишком поздно.",
		"background": DEFAULT_BG,
		"next_stage": "bull_awakening_part3",
		"typewriter_speed": 0.035,
		"screen_shake": true,
		"ambient_boost_db": 4.0,
	},
	{
		"stage_id": "bull_awakening_part3",
		"type": "narrative",
		"text": (
			"Метель накрыла всё. Чумы разрушены. Люди... их нет. Только ледяные статуи там, где "
			+ "они пытались спастись.\n\n"
			+ "Ты падаешь на колени в снег. Холод проникает в кости. Ты чувствуешь, как сознание "
			+ "покидает тебя...\n\n"
			+ "И в этот момент, сквозь белую пелену, появляется ОН."
		),
		"background": DEFAULT_BG,
		"next_stage": "bull_awakening_part4",
		"typewriter_speed": 0.035,
		"screen_shake": true,
		"ambient_boost_db": 4.0,
	},
	{
		"stage_id": "bull_awakening_part4",
		"type": "narrative",
		"text": (
			"Старик в потрёпанной парке, с луком за плечами. Его глаза светятся, как у волка.\n\n"
			+ "«Встань, Кыым. Ты — последний из своего рода. Но я видел твои выборы. Видел, как ты "
			+ "спасал зверей, уважал лес, помнил заветы предков."
		),
		"background": DEFAULT_BG,
		"next_stage": "bull_awakening_part5",
		"typewriter_speed": 0.035,
		"screen_shake": true,
		"ambient_boost_db": 4.0,
	},
	{
		"stage_id": "bull_awakening_part5",
		"type": "narrative",
		"text": (
			"Я — Байанай. И я предлагаю тебе сделку.\n\n"
			+ "Я покажу путь к источнику этой зимы. Я дам силу бороться. Но взамен ты должен будешь "
			+ "спасать тех, кого ещё можно спасти. Неси мои заветы. Не забывай: холод — это не враг. "
			+ "Это испытание."
		),
		"background": DEFAULT_BG,
		"next_stage": "bull_awakening_part6",
		"typewriter_speed": 0.035,
		"screen_shake": true,
		"ambient_boost_db": 4.0,
	},
	{
		"stage_id": "bull_awakening_part6",
		"type": "narrative",
		"text": "«Выбери свой путь, охотник.»",
		"background": DEFAULT_BG,
		"next_stage": "",
		"typewriter_speed": 0.035,
		"screen_shake": true,
		"ambient_boost_db": 4.0,
	},
]

var _stage_by_id: Dictionary = {}
var _current_stage_id: String = ""
var _busy: bool = false
var _is_typing: bool = false
var _typewriter_timer: Timer
var _typewriter_target: String = ""
var _typewriter_pos: int = 0
var _typewriter_delay: float = TYPEWRITER_DEFAULT
var _fade_rect: ColorRect
var _audio_music: AudioStreamPlayer
var _audio_ambient: AudioStreamPlayer
var _audio_click: AudioStreamPlayer
var _ambient_base_db: float = -15.0
var _bg_pulse_tween: Tween
var _fade_tween: Tween
var _shake_tween: Tween
var _main_box_base_pos: Vector2
var _shake_base_pos: Vector2 = Vector2.ZERO


func _game_state() -> Node:
	return get_node_or_null("/root/GameState")


func _ready() -> void:
	_index_stages()
	_setup_layout()
	_setup_visual_style()
	_setup_fade_overlay()
	_setup_typewriter()
	_setup_audio()
	_setup_buttons()
	_setup_background_pulse()
	_hide_interaction_ui()
	_main_box_base_pos = _main_box.position
	_shake_base_pos = _background.position
	var gs := _game_state()
	if gs:
		gs.reset_prologue()
	_begin_prologue()


func _index_stages() -> void:
	_stage_by_id.clear()
	for stage in stages:
		_stage_by_id[stage.stage_id] = stage


func _setup_layout() -> void:
	_center_column.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	_center_column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_main_box.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT_NARRATIVE)
	_main_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_main_box.clip_contents = true
	_choices_box.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	_choices_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_panel_height(PANEL_HEIGHT_NARRATIVE)


func _setup_visual_style() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(COLOR_BG.r, COLOR_BG.g, COLOR_BG.b, 0.88)
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

	_text_label.bbcode_enabled = false
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.scroll_active = false
	_text_label.fit_content = true
	_text_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_text_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_text_label.custom_minimum_size = Vector2(TEXT_INNER_WIDTH, 0)
	_text_label.add_theme_color_override("default_color", COLOR_TEXT)
	_text_label.add_theme_font_size_override("normal_font_size", TEXT_FONT_SIZE)
	_text_label.visible = true


func _apply_panel_height(height: int) -> void:
	_main_box.custom_minimum_size = Vector2(PANEL_WIDTH, height)


func _setup_fade_overlay() -> void:
	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeOverlay"
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.color = Color.BLACK
	add_child(_fade_rect)
	move_child(_fade_rect, get_child_count() - 1)


func _setup_typewriter() -> void:
	_typewriter_timer = Timer.new()
	_typewriter_timer.one_shot = false
	_typewriter_timer.wait_time = TYPEWRITER_DEFAULT
	_typewriter_timer.timeout.connect(_on_typewriter_tick)
	add_child(_typewriter_timer)


func _setup_audio() -> void:
	_audio_music = _create_audio_player("Music", -10.0)
	_audio_ambient = _create_audio_player("Ambient", _ambient_base_db)
	_audio_click = _create_audio_player("SFX", -6.0)
	_audio_click.stream = _make_click_stream()

	var music := _load_stream(MUSIC_PATH)
	if music:
		if music is AudioStreamMP3:
			music.loop = true
		_audio_music.stream = music
		_audio_music.finished.connect(func() -> void: _audio_music.play())
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
		push_error("PrologueManager: не удалось загрузить — %s" % path)
		return null
	return resource as AudioStream


func _setup_buttons() -> void:
	for i in _choice_buttons.size():
		var btn := _choice_buttons[i]
		btn.visible = false
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_choice_pressed.bind(i))
		_style_action_button(btn)
		btn.mouse_entered.connect(_on_button_hover.bind(btn, true))
		btn.mouse_exited.connect(_on_button_hover.bind(btn, false))


func _style_action_button(btn: Button) -> void:
	btn.add_theme_font_size_override("font_size", 15)
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_color_override("font_hover_color", COLOR_ACCENT_BRIGHT)
	var normal := _make_button_stylebox(false)
	var hover := _make_button_stylebox(true)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", hover)


func _make_button_stylebox(bright: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.2 if not bright else 0.4)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = COLOR_ACCENT_BRIGHT if bright else COLOR_ACCENT
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _on_button_hover(btn: Button, hovered: bool) -> void:
	btn.modulate = Color(1.12, 1.12, 1.18, 1.0) if hovered else Color.WHITE


func _setup_background_pulse() -> void:
	_bg_pulse_tween = create_tween().set_loops()
	_bg_pulse_tween.tween_property(_background, "modulate", Color(0.92, 0.92, 0.92, 1.0), 2.5)
	_bg_pulse_tween.tween_property(_background, "modulate", Color(1.0, 1.0, 1.0, 1.0), 2.5)


func _make_click_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
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


func _hide_interaction_ui() -> void:
	_choices_box.visible = false
	for btn in _choice_buttons:
		btn.visible = false
		btn.disabled = true


func _input(event: InputEvent) -> void:
	if _busy:
		return

	var is_advance := false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			is_advance = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_advance = true

	if not is_advance:
		return

	if _is_typing:
		_skip_typewriter()
		get_viewport().set_input_as_handled()
		return

	var stage: Dictionary = _stage_by_id.get(_current_stage_id, {})
	if stage.get("type", "") != "narrative":
		return

	get_viewport().set_input_as_handled()
	_play_click()
	var next_id: String = stage.get("next_stage", "")
	if next_id == "":
		_finish_prologue()
	else:
		_advance_to_stage(next_id)


func _skip_typewriter() -> void:
	if not _is_typing:
		return
	_typewriter_timer.stop()
	_text_label.text = _typewriter_target
	_typewriter_pos = _typewriter_target.length()
	_on_typewriter_finished()


func _begin_prologue() -> void:
	_busy = true
	await _run_fade(1.0, 0.0, FADE_STAGE)
	_busy = false
	load_stage("lore_intro_part1")


func load_stage(stage_id: String) -> void:
	if not _stage_by_id.has(stage_id):
		push_error("PrologueManager: неизвестный этап — %s" % stage_id)
		return

	_current_stage_id = stage_id
	var stage: Dictionary = _stage_by_id[stage_id]
	_hide_interaction_ui()
	_apply_background(stage.get("background", DEFAULT_BG))

	_typewriter_delay = stage.get("typewriter_speed", TYPEWRITER_DEFAULT)
	_typewriter_timer.wait_time = _typewriter_delay

	if stage.get("screen_shake", false):
		_start_screen_shake()
	else:
		_stop_screen_shake()

	if stage.has("ambient_boost_db") and _audio_ambient:
		_audio_ambient.volume_db = _ambient_base_db + float(stage.ambient_boost_db)
	elif _audio_ambient:
		_audio_ambient.volume_db = _ambient_base_db

	var is_choice: bool = String(stage.get("type", "")) == "choice"
	var use_shake: bool = bool(stage.get("screen_shake", false))
	var panel_h: int = PANEL_HEIGHT_CHOICE
	if not is_choice:
		panel_h = PANEL_HEIGHT_SHAKE if use_shake else PANEL_HEIGHT_NARRATIVE
	_apply_panel_height(panel_h)

	var body: String = stage.get("text", "")
	_start_typewriter(body)

	if stage.get("type", "") == "choice":
		var options: Array = stage.get("options", [])
		for i in _choice_buttons.size():
			if i < options.size():
				var opt: Dictionary = options[i]
				var skill_name: String = opt.get("skill", "")
				if skill_name != "":
					_choice_buttons[i].text = "%s\n→ %s: %s" % [
						opt.label,
						skill_name,
						opt.get("skill_desc", ""),
					]
				else:
					_choice_buttons[i].text = opt.label
				_choice_buttons[i].disabled = true
			else:
				_choice_buttons[i].visible = false


func _apply_background(path: String) -> void:
	var bg_path: String = path if ResourceLoader.exists(path) else DEFAULT_BG
	if not ResourceLoader.exists(bg_path):
		push_warning("PrologueManager: фон не найден — %s" % bg_path)
		return
	var tex := load(bg_path) as Texture2D
	if tex:
		_background.texture = tex


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

	if _typewriter_target[_typewriter_pos] == "[":
		var close := _typewriter_target.find("]", _typewriter_pos)
		_typewriter_pos = close + 1 if close != -1 else _typewriter_pos + 1
	else:
		_typewriter_pos += 1

	_text_label.text = _typewriter_target.substr(0, _typewriter_pos)


func _on_typewriter_finished() -> void:
	_is_typing = false
	_main_box.position = _main_box_base_pos
	_text_label.text = _typewriter_target

	var stage: Dictionary = _stage_by_id[_current_stage_id]
	if stage.get("type", "") == "choice":
		_choices_box.visible = true
		var options: Array = stage.get("options", [])
		for i in _choice_buttons.size():
			if i < options.size():
				_choice_buttons[i].visible = true
				_choice_buttons[i].disabled = false


func _on_choice_pressed(option_index: int) -> void:
	if _busy or _is_typing:
		return

	var stage: Dictionary = _stage_by_id[_current_stage_id]
	var options: Array = stage.get("options", [])
	if option_index < 0 or option_index >= options.size():
		return

	_busy = true
	_play_click()
	_hide_interaction_ui()

	var opt: Dictionary = options[option_index]
	var gs := _game_state()
	if gs:
		gs.record_prologue_choice(
			stage.stage_id,
			option_index,
			opt.label,
			opt.get("skill", "")
		)

	var next_id: String = stage.get("next_stage", "")
	if next_id == "":
		_finish_prologue()
	else:
		await _run_fade(0.0, 1.0, FADE_STAGE)
		load_stage(next_id)
		await _run_fade(1.0, 0.0, FADE_STAGE)
		_busy = false


func _advance_to_stage(next_id: String) -> void:
	_busy = true
	_hide_interaction_ui()
	await _run_fade(0.0, 1.0, FADE_STAGE)
	load_stage(next_id)
	await _run_fade(1.0, 0.0, FADE_STAGE)
	_busy = false


func _start_screen_shake() -> void:
	_stop_screen_shake()
	_shake_tween = create_tween().set_loops()
	_shake_tween.tween_method(_set_shake_intensity, 0.0, 1.0, 0.2)
	_shake_tween.tween_method(_set_shake_intensity, 1.0, 0.0, 0.2)


func _set_shake_intensity(intensity: float) -> void:
	if _shake_root == null:
		return
	var amp := SHAKE_OFFSET_MAX * intensity
	_shake_root.position = _shake_base_pos + Vector2(
		randf_range(-amp, amp),
		randf_range(-amp, amp)
	)


func _stop_screen_shake() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	if _shake_root:
		_shake_root.position = _shake_base_pos


func _run_fade(from_alpha: float, to_alpha: float, duration: float) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_rect.color.a = from_alpha
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fade_rect, "color:a", to_alpha, duration)
	await _fade_tween.finished


func _finish_prologue() -> void:
	_busy = true
	_hide_interaction_ui()
	_stop_screen_shake()
	var gs := _game_state()
	if gs:
		gs.complete_prologue()

	if _audio_music:
		_audio_music.stop()

	await _run_fade(_fade_rect.color.a, 1.0, FADE_FINISH)

	if not ResourceLoader.exists(GAME_SCENE_PATH):
		push_error("PrologueManager: сцена не найдена — %s" % GAME_SCENE_PATH)
		_busy = false
		return

	var err := get_tree().change_scene_to_file(GAME_SCENE_PATH)
	if err != OK:
		push_error("PrologueManager: ошибка смены сцены (%d)" % err)
