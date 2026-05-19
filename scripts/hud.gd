extends CanvasLayer
class_name HUD

# UI элементы
var hp_label: Label
var cold_label: Label
var hp_bar: ProgressBar
var hunter: Hunter

func _ready() -> void:
	# Находим охотника
	hunter = get_tree().root.get_child(0).find_child("CharacterBody2D")
	print("🎮 HUD инициализирован. Охотник найден: ", hunter != null)
	
	# Создаем UI элементы программно
	_setup_ui()
	
	# Подключаемся к сигналам охотника
	if hunter:
		hunter.health_changed.connect(_on_health_changed)
		hunter.warmth_changed.connect(_on_warmth_changed)
		
		# Инициализируем значения
		_on_health_changed(hunter.health)
		_on_warmth_changed(hunter.warmth)
	else:
		print("❌ Охотник не найден!")

func _setup_ui() -> void:
	# Контейнер для UI (нижний правый угол)
	var ui_container = Control.new()
	ui_container.name = "UIContainer"
	ui_container.anchor_left = 1.0
	ui_container.anchor_top = 1.0
	ui_container.anchor_right = 1.0
	ui_container.anchor_bottom = 1.0
	ui_container.offset_left = -150
	ui_container.offset_top = -100
	ui_container.offset_right = 0
	ui_container.offset_bottom = 0
	add_child(ui_container)
	
	# === Холод ===
	cold_label = Label.new()
	cold_label.name = "ColdLabel"
	cold_label.text = "Холод: 100"
	cold_label.add_theme_font_size_override("font_size", 14)
	cold_label.add_theme_color_override("font_color", Color.CYAN)
	ui_container.add_child(cold_label)
	
	# === HP Label ===
	hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.text = "HP: 100/100"
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.add_theme_color_override("font_color", Color.RED)
	hp_label.position.y = 20
	ui_container.add_child(hp_label)
	
	# === HP Bar ===
	hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.min_value = 0
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.custom_minimum_size = Vector2(140, 20)
	hp_bar.position.y = 40
	
	# Стиль для полоски
	var theme = Theme.new()
	var style_filled = StyleBoxFlat.new()
	style_filled.bg_color = Color.RED
	style_filled.corner_radius_top_left = 2
	style_filled.corner_radius_top_right = 2
	style_filled.corner_radius_bottom_left = 2
	style_filled.corner_radius_bottom_right = 2
	
	var style_background = StyleBoxFlat.new()
	style_background.bg_color = Color.DARK_RED
	style_background.corner_radius_top_left = 2
	style_background.corner_radius_top_right = 2
	style_background.corner_radius_bottom_left = 2
	style_background.corner_radius_bottom_right = 2
	
	theme.set_stylebox("fill", "ProgressBar", style_filled)
	theme.set_stylebox("background", "ProgressBar", style_background)
	
	hp_bar.theme = theme
	ui_container.add_child(hp_bar)

func _on_health_changed(new_health: float) -> void:
	if hp_label and hp_bar and hunter:
		hp_label.text = "HP: %.0f/%.0f" % [new_health, hunter.max_health]
		hp_bar.value = new_health
		
		# Меняем цвет в зависимости от здоровья
		var color = Color.RED
		if new_health > 50:
			color = Color.GREEN
		elif new_health > 25:
			color = Color.YELLOW
		
		var style_filled = StyleBoxFlat.new()
		style_filled.bg_color = color
		style_filled.corner_radius_top_left = 2
		style_filled.corner_radius_top_right = 2
		style_filled.corner_radius_bottom_left = 2
		style_filled.corner_radius_bottom_right = 2
		
		hp_bar.theme.set_stylebox("fill", "ProgressBar", style_filled)

func _on_warmth_changed(new_warmth: float) -> void:
	if cold_label and hunter:
		# Показываем ХОЛОД (противоположно теплу)
		var coldness_percent = (1.0 - (new_warmth / hunter.max_warmth)) * 100.0
		cold_label.text = "Холод: %.0f%%" % coldness_percent
		
		# Меняем цвет индикатора холода в зависимости от значения
		var color = Color.CYAN
		if coldness_percent > 70:
			color = Color.BLUE
		elif coldness_percent > 90:
			color = Color.RED
		
		cold_label.add_theme_color_override("font_color", color)
