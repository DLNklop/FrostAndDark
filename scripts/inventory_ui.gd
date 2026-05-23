extends CanvasLayer

var overlay: ColorRect
var panel: PanelContainer
var items_grid: GridContainer
var items_count_label: Label

var is_open := false


func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS

	_make_inventory_ui()

	overlay.visible = false

	Inventory.inventory_changed.connect(_update_inventory)
	_update_inventory()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			_toggle_inventory()
			get_viewport().set_input_as_handled()

		elif event.keycode == KEY_ESCAPE and is_open:
			_close_inventory()
			get_viewport().set_input_as_handled()

func _make_inventory_ui() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.45)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(390, 300)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var header = HBoxContainer.new()
	root.add_child(header)

	var title_box = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	header.add_child(title_box)

	var title = Label.new()
	title.text = "ИНВЕНТАРЬ"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color.WHITE)
	title_box.add_child(title)

	var hint = Label.new()
	hint.text = "I / Esc — закрыть"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.72, 0.84, 1.0))
	title_box.add_child(hint)

	var close_button = Button.new()
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.add_theme_font_size_override("font_size", 14)
	close_button.add_theme_color_override("font_color", Color.WHITE)
	close_button.add_theme_stylebox_override("normal", _small_button_style(Color(0.12, 0.16, 0.24, 0.85)))
	close_button.add_theme_stylebox_override("hover", _small_button_style(Color(0.35, 0.18, 0.22, 0.95)))
	close_button.add_theme_stylebox_override("pressed", _small_button_style(Color(0.25, 0.10, 0.14, 1.0)))
	close_button.pressed.connect(_close_inventory)
	header.add_child(close_button)

	root.add_child(_line())

	items_count_label = Label.new()
	items_count_label.text = "Слотов: 0 | Предметов: 0"
	items_count_label.add_theme_font_size_override("font_size", 12)
	items_count_label.add_theme_color_override("font_color", Color(0.80, 0.88, 1.0))
	root.add_child(items_count_label)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(350, 165)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	items_grid = GridContainer.new()
	items_grid.columns = 1
	items_grid.add_theme_constant_override("h_separation", 8)
	items_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(items_grid)


func _toggle_inventory() -> void:
	if is_open:
		_close_inventory()
	else:
		_open_inventory()


func _open_inventory() -> void:
	is_open = true
	Inventory.inventory_ui_open = true
	overlay.visible = true
	_update_inventory()


func _close_inventory() -> void:
	is_open = false
	Inventory.inventory_ui_open = false
	overlay.visible = false


func _update_inventory() -> void:
	if items_grid == null:
		return

	for child in items_grid.get_children():
		child.queue_free()

	var items = Inventory.get_items()
	var total_stacks := items.size()
	var total_amount := 0

	for item_id in items.keys():
		total_amount += int(items[item_id]["amount"])

	items_count_label.text = "Слотов: %d | Предметов: %d" % [total_stacks, total_amount]

	if items.size() == 0:
		var empty_card = PanelContainer.new()
		empty_card.custom_minimum_size = Vector2(340, 90)
		empty_card.add_theme_stylebox_override("panel", _item_card_style())

		var empty_margin = MarginContainer.new()
		empty_margin.add_theme_constant_override("margin_left", 14)
		empty_margin.add_theme_constant_override("margin_right", 14)
		empty_margin.add_theme_constant_override("margin_top", 14)
		empty_margin.add_theme_constant_override("margin_bottom", 14)
		empty_card.add_child(empty_margin)

		var empty_box = VBoxContainer.new()
		empty_box.alignment = BoxContainer.ALIGNMENT_CENTER
		empty_box.add_theme_constant_override("separation", 4)
		empty_margin.add_child(empty_box)

		var empty_title = Label.new()
		empty_title.text = "Инвентарь пуст"
		empty_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_title.add_theme_font_size_override("font_size", 16)
		empty_title.add_theme_color_override("font_color", Color.WHITE)
		empty_box.add_child(empty_title)

		var empty_hint = Label.new()
		empty_hint.text = "Подбирай предметы на карте"
		empty_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_hint.add_theme_font_size_override("font_size", 11)
		empty_hint.add_theme_color_override("font_color", Color(0.68, 0.80, 0.95))
		empty_box.add_child(empty_hint)

		items_grid.add_child(empty_card)
		return

	for item_id in items.keys():
		var item = items[item_id]
		items_grid.add_child(_create_item_card(item_id, item))


func _create_item_card(item_id: String, item: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(340, 64)
	card.add_theme_stylebox_override("panel", _item_card_style())

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	margin.add_child(row)

	var icon_bg = PanelContainer.new()
	icon_bg.custom_minimum_size = Vector2(42, 42)
	icon_bg.add_theme_stylebox_override("panel", _icon_style())
	row.add_child(icon_bg)

	var icon_label = Label.new()
	icon_label.text = _get_item_icon(item_id)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 20)
	icon_label.add_theme_color_override("font_color", Color.WHITE)
	icon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_bg.add_child(icon_label)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 1)
	row.add_child(info)

	var name_label = Label.new()
	name_label.text = str(item["name"])
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	info.add_child(name_label)

	var type_label = Label.new()
	type_label.text = _get_item_type_text(item_id)
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.add_theme_color_override("font_color", Color(0.70, 0.82, 0.98))
	info.add_child(type_label)

	var amount_bg = PanelContainer.new()
	amount_bg.custom_minimum_size = Vector2(34, 24)
	amount_bg.add_theme_stylebox_override("panel", _amount_badge_style())
	row.add_child(amount_bg)

	var amount_label = Label.new()
	amount_label.text = "x" + str(item["amount"])
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount_label.add_theme_font_size_override("font_size", 12)
	amount_label.add_theme_color_override("font_color", Color.WHITE)
	amount_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	amount_bg.add_child(amount_label)

	return card


func _get_item_icon(item_id: String) -> String:
	match item_id:
		"dry_branch":
			return "🪵"
		_:
			return "•"


func _get_item_type_text(item_id: String) -> String:
	match item_id:
		"dry_branch":
			return "Материал для костра"
		_:
			return "Предмет"


func _line() -> ColorRect:
	var line = ColorRect.new()
	line.color = Color(0.35, 0.48, 0.68, 0.45)
	line.custom_minimum_size = Vector2(0, 1)
	return line


func _panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.09, 0.14, 0.96)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.32, 0.46, 0.70, 0.85)
	style.shadow_color = Color(0, 0, 0, 0.30)
	style.shadow_size = 6
	return style


func _item_card_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.13, 0.20, 0.88)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.24, 0.36, 0.55, 0.75)
	return style


func _icon_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.20, 0.30, 0.95)
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 9
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.38, 0.55, 0.82, 0.55)
	return style


func _amount_badge_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.32, 0.48, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _small_button_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style
