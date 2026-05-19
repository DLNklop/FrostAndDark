extends CanvasLayer

@export var main_menu_scene_path: String = "res://tscn/main_menu.tscn"

var overlay: ColorRect

var pause_center: CenterContainer
var pause_panel: PanelContainer

var settings_center: CenterContainer
var settings_panel: PanelContainer

var pause_menu_open := false


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	_make_overlay()
	_make_pause_menu()
	_make_settings_menu()

	overlay.visible = false
	pause_center.visible = false
	settings_center.visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			if settings_center.visible:
				_show_pause_menu()
			elif pause_menu_open:
				_resume_game()
			else:
				_pause_game()


func _make_overlay() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)


func _make_pause_menu() -> void:
	pause_center = CenterContainer.new()
	pause_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(pause_center)

	pause_panel = PanelContainer.new()
	pause_panel.custom_minimum_size = Vector2(420, 360)
	pause_panel.add_theme_stylebox_override("panel", _panel_style())
	pause_center.add_child(pause_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 35)
	margin.add_theme_constant_override("margin_right", 35)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	pause_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "ПАУЗА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	vbox.add_child(_space(10))

	vbox.add_child(_button("Продолжить", _resume_game))
	vbox.add_child(_button("Настройки", _show_settings_menu))
	vbox.add_child(_button("В главное меню", _go_to_main_menu))
	vbox.add_child(_button("Выйти", _quit_game))


func _make_settings_menu() -> void:
	settings_center = CenterContainer.new()
	settings_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(settings_center)

	settings_panel = PanelContainer.new()
	settings_panel.custom_minimum_size = Vector2(470, 390)
	settings_panel.add_theme_stylebox_override("panel", _panel_style())
	settings_center.add_child(settings_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 35)
	margin.add_theme_constant_override("margin_right", 35)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	settings_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "НАСТРОЙКИ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	vbox.add_child(_space(8))

	vbox.add_child(_create_slider("Общий звук", 80, _on_master_volume_changed))
	vbox.add_child(_create_slider("Музыка", 70, _on_music_volume_changed))
	vbox.add_child(_create_slider("Эффекты", 80, _on_sfx_volume_changed))

	vbox.add_child(_space(6))

	vbox.add_child(_button("Назад", _show_pause_menu))


func _button(text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(350, 42)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.pressed.connect(callback)

	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.12, 0.18, 0.60)
	_set_round(normal, 12)

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.20, 0.32, 0.50, 0.82)
	_set_round(hover, 12)

	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color(0.04, 0.08, 0.13, 0.95)
	_set_round(pressed, 12)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)

	return button


func _create_slider(text: String, value: int, callback: Callable) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(390, 52)
	box.add_theme_constant_override("separation", 4)

	var label = Label.new()
	label.text = text + ": " + str(value) + "%"
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(label)

	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.value = value
	slider.step = 1
	slider.custom_minimum_size = Vector2(390, 20)

	slider.value_changed.connect(func(new_value):
		label.text = text + ": " + str(int(new_value)) + "%"
		callback.call(int(new_value))
	)

	box.add_child(slider)

	return box


func _panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.12, 0.94)
	_set_round(style, 18)

	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.45, 0.7)

	return style


func _set_round(style: StyleBoxFlat, radius: int) -> void:
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius


func _pause_game() -> void:
	pause_menu_open = true
	get_tree().paused = true

	overlay.visible = true
	pause_center.visible = true
	settings_center.visible = false


func _resume_game() -> void:
	pause_menu_open = false
	get_tree().paused = false

	overlay.visible = false
	pause_center.visible = false
	settings_center.visible = false


func _show_settings_menu() -> void:
	pause_center.visible = false
	settings_center.visible = true


func _show_pause_menu() -> void:
	settings_center.visible = false
	pause_center.visible = true


func _go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_scene_path)


func _quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()


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
