extends CanvasLayer
class_name HUD

var hp_label: Label
var cold_label: Label
var hp_bar: ProgressBar
var hunter: Hunter


func _ready() -> void:
	hunter = get_tree().root.get_child(0).find_child("CharacterBody2D")

	_setup_ui()

	if hunter:
		hunter.health_changed.connect(_on_health_changed)
		hunter.warmth_changed.connect(_on_warmth_changed)

		_on_health_changed(hunter.health)
		_on_warmth_changed(hunter.warmth)
	else:
		print("Охотник не найден!")


func _setup_ui() -> void:
	var ui_container = VBoxContainer.new()
	ui_container.name = "UIContainer"

	ui_container.anchor_left = 1.0
	ui_container.anchor_top = 1.0
	ui_container.anchor_right = 1.0
	ui_container.anchor_bottom = 1.0

	ui_container.offset_left = -160
	ui_container.offset_top = -70
	ui_container.offset_right = -15
	ui_container.offset_bottom = -15

	ui_container.alignment = BoxContainer.ALIGNMENT_END

	add_child(ui_container)

	cold_label = Label.new()
	cold_label.text = "❄ Холод: 0%"
	cold_label.add_theme_font_size_override("font_size", 14)
	cold_label.add_theme_color_override("font_color", Color.CYAN)
	ui_container.add_child(cold_label)

	hp_label = Label.new()
	hp_label.text = "❤ HP: 100"
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.add_theme_color_override("font_color", Color.RED)
	ui_container.add_child(hp_label)

	# Полоску скрываем
	hp_bar = ProgressBar.new()
	hp_bar.visible = false


func _on_health_changed(new_health: float) -> void:
	if hp_label and hunter:
		hp_label.text = "❤ HP: %.0f" % new_health

		if new_health > 50:
			hp_label.add_theme_color_override("font_color", Color.GREEN)
		elif new_health > 25:
			hp_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			hp_label.add_theme_color_override("font_color", Color.RED)


func _on_warmth_changed(new_warmth: float) -> void:
	if cold_label and hunter:
		var coldness_percent = (1.0 - (new_warmth / hunter.max_warmth)) * 100.0

		cold_label.text = "❄ Холод: %.0f%%" % coldness_percent

		if coldness_percent > 90:
			cold_label.add_theme_color_override("font_color", Color.RED)
		elif coldness_percent > 70:
			cold_label.add_theme_color_override("font_color", Color.BLUE)
		else:
			cold_label.add_theme_color_override("font_color", Color.CYAN)
