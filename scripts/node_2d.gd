extends CharacterBody2D
class_name Hunter

# === СТАТИСТИКА ПЕРСОНАЖА ===
@export var max_health: float = 100.0
@export var max_warmth: float = 100.0
@export var max_sanity: float = 100.0

var health: float = 100.0
var warmth: float = 100.0
var sanity: float = 100.0

# === ДВИЖЕНИЕ ===
@export var speed: float = 200.0
var is_in_shelter: bool = false

# === СИСТЕМА ХОЛОДА ===
@export var freezing_rate: float = 8.0  # Как быстро остывает на улице
@export var warming_rate: float = 25.0   # Как быстро греется в укрытии
@export var shelter_bonus: float = 50.0  # Бонус тепла в укрытии

# === ИНВЕНТАРЬ (базовый) ===
var inventory: Array = []
var max_inventory_slots: int = 8

# === СИГНАЛЫ ===
signal warmth_changed(new_warmth: float)
signal health_changed(new_health: float)
signal sanity_changed(new_sanity: float)
signal player_frozen
signal player_died

func _ready() -> void:
	print("🐺 Охотник готов! Скорость: ", speed)
	print("🐺 Охотник готов к выживанию!")
	print("📍 Начальная позиция: ", position)
	_update_ui()

func _physics_process(delta: float) -> void:
	# 1. ОБРАБОТКА ВВОДА (WASD или стрелки)
	# Только 4 направления без диагоналей
	var input_horizontal = Input.get_axis("ui_left", "ui_right")
	var input_vertical = Input.get_axis("ui_up", "ui_down")
	
	# Приоритет: горизонтальное движение важнее вертикального
	# Это предотвращает диагональное движение
	if abs(input_horizontal) > 0:
		velocity.x = input_horizontal * speed
		velocity.y = 0
	elif abs(input_vertical) > 0:
		velocity.x = 0
		velocity.y = input_vertical * speed
	else:
		velocity.x = 0
		velocity.y = 0
	
	# 2. ДВИЖЕНИЕ
	move_and_slide()
	
	# ОТЛАДКА: только если движемся
	if abs(input_horizontal) > 0 or abs(input_vertical) > 0:
		print("Позиция: ", position, " Ввод: ", Vector2(input_horizontal, input_vertical))
	
	# 3. СИСТЕМА ХОЛОДА
	_process_cold(delta)
	
	# 4. ПРОВЕРКА СОСТОЯНИЯ
	_check_survival_status()

func _process_cold(delta: float) -> void:
	if is_in_shelter:
		# Греемся в укрытии
		warmth = min(warmth + warming_rate * delta, max_warmth)
	else:
		# Замерзаем на улице
		warmth -= freezing_rate * delta
		
		# Если совсем холодно - теряем здоровье
		if warmth <= 0:
			warmth = 0
			health -= 5.0 * delta  # Урон от замерзания
			emit_signal("player_frozen")
	
	emit_signal("warmth_changed", warmth)

func _check_survival_status() -> void:
	# Смерть от холода или потери здоровья
	if health <= 0:
		health = 0
		emit_signal("player_died")
		print("❌ Охотник погиб от холода...")
		get_tree().reload_current_scene()

func _update_ui() -> void:
	# Вывод статистики в консоль (для отладки)
	if Input.is_action_just_pressed("ui_accept"):  # Нажми ПРОБЕЛ для проверки
		print("=== 🌡️ СОСТОЯНИЕ ОХОТНИКА ===")
		print("❤️  Здоровье: %.1f / %.1f" % [health, max_health])
		print("🔥 Тепло: %.1f / %.1f" % [warmth, max_warmth])
		print("🧠 Рассудок: %.1f / %.1f" % [sanity, max_sanity])
		print(" Инвентарь: %d / %d" % [inventory.size(), max_inventory_slots])
		print("🏠 В укрытии: ", "ДА" if is_in_shelter else "НЕТ")
		print("===========================")

# === ФУНКЦИИ ДЛЯ ИНВЕНТАРЯ ===
func add_item(item_name: String) -> bool:
	if inventory.size() < max_inventory_slots:
		inventory.append(item_name)
		print("📦 Подобрал: ", item_name)
		return true
	else:
		print("⚠️ Инвентарь полон!")
		return false

func remove_item(index: int) -> void:
	if index >= 0 and index < inventory.size():
		var removed = inventory.pop_at(index)
		print("🗑️ Выбросил: ", removed)

# === ФУНКЦИИ ДЛЯ УКРЫТИЙ ===
func enter_shelter() -> void:
	is_in_shelter = true
	print("🏠 Вошел в укрытие. Стало теплее!")

func exit_shelter() -> void:
	is_in_shelter = false
	print("❄️ Вышел на улицу. Берегись холода!")

# === ВХОД В ЗОНУ УКРЫТИЯ (вызывать из Area2D) ===
func _on_shelter_area_entered(area: Area2D) -> void:
	if area.is_in_group("shelters"):
		enter_shelter()

func _on_shelter_area_exited(area: Area2D) -> void:
	if area.is_in_group("shelters"):
		exit_shelter()
