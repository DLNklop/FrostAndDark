extends Control
@export var menu_music_path: String = "res://audio/menu_music.mp3"
@export var game_scene_path: String = "res://tscn/scene_1.tscn"
@export var background_path: String = "res://sprite_objects/menu_bg.png"

var menu_music: AudioStreamPlayer
var main_menu: VBoxContainer
var settings_bg: ColorRect


func _ready() -> void:
	_make_menu()
	_start_menu_music()

func _start_menu_music() -> void:
	menu_music = AudioStreamPlayer.new()
	menu_music.stream = load(menu_music_path)
	menu_music.bus = "Music"
	menu_music.volume_db = -8
	menu_music.autoplay = false
	add_child(menu_music)
	menu_music.play()

func _make_menu() -> void:
	var bg = TextureRect.new()
	bg.texture = load(background_path)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg)

	var dark = ColorRect.new()
	dark.color = Color(0, 0, 0, 0.25)
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dark)

	main_menu = VBoxContainer.new()
	main_menu.anchor_left = 1.0
	main_menu.anchor_top = 0.5
	main_menu.anchor_right = 1.0
	main_menu.anchor_bottom = 0.5
	main_menu.offset_left = -420
	main_menu.offset_top = -120
	main_menu.offset_right = -420
	main_menu.offset_bottom = 120
	main_menu.add_theme_constant_override("separation", 12)
	add_child(main_menu)

	var title = Label.new()
	title.text = "FROST AND DARK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color.WHITE)
	main_menu.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "survive the cold"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	main_menu.add_child(subtitle)

	main_menu.add_child(_space(12))

	main_menu.add_child(_button("Играть", _on_play_pressed))
	main_menu.add_child(_button("Настройки", _on_settings_pressed))
	main_menu.add_child(_button("Выйти", _on_exit_pressed))


func _button(text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 42)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.pressed.connect(callback)

	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.12, 0.18, 0.45)
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_left = 12
	normal.corner_radius_bottom_right = 12

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.20, 0.32, 0.50, 0.75)
	hover.corner_radius_top_left = 12
	hover.corner_radius_top_right = 12
	hover.corner_radius_bottom_left = 12
	hover.corner_radius_bottom_right = 12

	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color(0.04, 0.08, 0.13, 0.9)
	pressed.corner_radius_top_left = 12
	pressed.corner_radius_top_right = 12
	pressed.corner_radius_bottom_left = 12
	pressed.corner_radius_bottom_right = 12

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)

	return button


func _create_slider(text: String, value: int, callback: Callable) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(420, 58)
	box.add_theme_constant_override("separation", 5)

	var label = Label.new()
	label.text = text + ": " + str(value) + "%"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(label)

	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.value = value
	slider.step = 1
	slider.custom_minimum_size = Vector2(420, 22)

	slider.value_changed.connect(func(new_value):
		label.text = text + ": " + str(int(new_value)) + "%"
		callback.call(int(new_value))
	)

	box.add_child(slider)

	return box


func _show_settings_menu() -> void:
	main_menu.visible = false

	settings_bg = ColorRect.new()
	settings_bg.name = "SettingsMenu"
	settings_bg.color = Color(0, 0, 0, 0.55)
	settings_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(settings_bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_bg.add_child(center)

	var panel_holder = Control.new()
	panel_holder.custom_minimum_size = Vector2(560, 470)
	center.add_child(panel_holder)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_holder.add_child(panel)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.12, 0.92)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.45, 0.7)
	panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 55)
	margin.add_theme_constant_override("margin_right", 55)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "НАСТРОЙКИ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	vbox.add_child(_space(8))

	vbox.add_child(_create_slider("Общий звук", 80, _on_master_volume_changed))
	vbox.add_child(_create_slider("Музыка", 70, _on_music_volume_changed))
	vbox.add_child(_create_slider("Эффекты", 80, _on_sfx_volume_changed))

	vbox.add_child(_space(6))

	var back_button = _button("Назад", _on_back_pressed)
	back_button.custom_minimum_size = Vector2(420, 46)
	back_button.add_theme_font_size_override("font_size", 20)
	vbox.add_child(back_button)

	# Кнопка крестика
	var close_button = Button.new()
	close_button.text = "✕"
	close_button.anchor_left = 1.0
	close_button.anchor_top = 0.0
	close_button.anchor_right = 1.0
	close_button.anchor_bottom = 0.0
	close_button.offset_left = -52
	close_button.offset_top = 12
	close_button.offset_right = -12
	close_button.offset_bottom = 52
	close_button.add_theme_font_size_override("font_size", 20)
	close_button.add_theme_color_override("font_color", Color.WHITE)
	close_button.pressed.connect(_on_back_pressed)

	var close_normal = StyleBoxFlat.new()
	close_normal.bg_color = Color(0.12, 0.16, 0.23, 0.8)
	close_normal.corner_radius_top_left = 10
	close_normal.corner_radius_top_right = 10
	close_normal.corner_radius_bottom_left = 10
	close_normal.corner_radius_bottom_right = 10

	var close_hover = StyleBoxFlat.new()
	close_hover.bg_color = Color(0.45, 0.18, 0.22, 0.95)
	close_hover.corner_radius_top_left = 10
	close_hover.corner_radius_top_right = 10
	close_hover.corner_radius_bottom_left = 10
	close_hover.corner_radius_bottom_right = 10

	var close_pressed = StyleBoxFlat.new()
	close_pressed.bg_color = Color(0.30, 0.10, 0.13, 1.0)
	close_pressed.corner_radius_top_left = 10
	close_pressed.corner_radius_top_right = 10
	close_pressed.corner_radius_bottom_left = 10
	close_pressed.corner_radius_bottom_right = 10

	close_button.add_theme_stylebox_override("normal", close_normal)
	close_button.add_theme_stylebox_override("hover", close_hover)
	close_button.add_theme_stylebox_override("pressed", close_pressed)

	panel_holder.add_child(close_button)


func _set_bus_volume(bus_name: String, value: int) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		return

	if value <= 0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value / 100.0))


func _on_master_volume_changed(value: int) -> void:
	_set_bus_volume("Master", value)


func _on_music_volume_changed(value: int) -> void:
	_set_bus_volume("Music", value)


func _on_sfx_volume_changed(value: int) -> void:
	_set_bus_volume("SFX", value)


func _space(size: int) -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(1, size)
	return c


func _on_play_pressed() -> void:
	Inventory.clear_inventory()

	if menu_music:
		menu_music.stop()

	get_tree().change_scene_to_file(game_scene_path)


func _on_settings_pressed() -> void:
	_show_settings_menu()


func _on_back_pressed() -> void:
	if settings_bg:
		settings_bg.queue_free()

	main_menu.visible = true


func _on_exit_pressed() -> void:
	get_tree().quit()
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			if settings_bg and is_instance_valid(settings_bg):
				_on_back_pressed()
