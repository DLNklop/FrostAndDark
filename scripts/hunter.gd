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
@export var speed: float = 140.0
var is_in_shelter: bool = true  # Начинаем в укрытии

# === АНИМАЦИИ ===
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var current_direction: String = "south"  # По умолчанию смотрим на юг
var is_moving: bool = false

# === ЗВУКИ ===
@onready var snow_footsteps: AudioStreamPlayer2D = $SnowFootsteps

# === СЛЕДЫ НА СНЕГУ ===
@export var footprint_scene: PackedScene

# Расстояние между следами
@export var footprint_distance: float = 16.0

# Насколько левый/правый след смещается в сторону
@export var footprint_side_offset_vertical: float = 3.5
@export var footprint_side_offset_horizontal: float = 2.0

# Небольшая рандомность, чтобы следы не были идеально ровными
@export var footprint_random_offset: float = 0.8

# Если true, в укрытии следов не будет
@export var footprints_only_outside: bool = false

# Если позиция игрока не у ног, можно сдвинуть след вниз
@export var footprint_origin_offset_south: Vector2 = Vector2(0, 0)
@export var footprint_origin_offset_north: Vector2 = Vector2(0, 4)
@export var footprint_origin_offset_side: Vector2 = Vector2(0, -1)

# Слой снега
@export var snow_tilemap_path: NodePath

# Узел Footprints, куда будут добавляться следы
@export var footprints_parent_path: NodePath

@onready var snow_tilemap: TileMapLayer = get_node_or_null(snow_tilemap_path) as TileMapLayer
@onready var footprints_parent: Node2D = get_node_or_null(footprints_parent_path) as Node2D

var last_footprint_position: Vector2
var is_left_footprint: bool = true

# === СИСТЕМА ХОЛОДА ===
@export var freezing_rate: float = 2.0  # Как быстро остывает на улице
@export var warming_rate: float = 15.0   # Как быстро греется в укрытии
@export var shelter_bonus: float = 50.0  # Бонус тепла в укрытии

# === ИНИЦИАЛИЗАЦИЯ ===
var init_frames: int = 0  # Счетчик для инициализации

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
	last_footprint_position = _get_footprint_base_position()
	
	print("🐺 Охотник готов! Скорость: ", speed)
	print("🐺 Охотник готов к выживанию!")
	print("📍 Начальная позиция: ", position)
	print("🌡️ Начальные параметры - HP: %.0f, Тепло: %.0f" % [health, warmth])
	print("🏠 В укрытии: ", is_in_shelter)
	
	# Проверяем укрытия сразу
	await get_tree().process_frame  # Ждем кадра, чтобы все инициализировалось
	
	var shelters = get_tree().get_nodes_in_group("shelters")
	print("📍 Найдено укрытий: ", shelters.size())
	for shelter in shelters:
		if shelter is Area2D:
			var distance = global_position.distance_to(shelter.global_position)
			print("  - Укрытие на расстоянии: ", distance)
	
	_update_ui()
	_update_animation()  # Устанавливаем начальную анимацию

func _physics_process(delta: float) -> void:
	# 1. ОБРАБОТКА ВВОДА (WASD или стрелки)
	# Только 4 направления без диагоналей
	var input_horizontal = Input.get_axis("ui_left", "ui_right")
	var input_vertical = Input.get_axis("ui_up", "ui_down")
	
	var was_moving = is_moving
	is_moving = false
	
	# Приоритет: горизонтальное движение важнее вертикального
	# Это предотвращает диагональное движение
	if abs(input_horizontal) > 0:
		velocity.x = input_horizontal * speed
		velocity.y = 0
		is_moving = true
		
		# Определяем направление
		if input_horizontal > 0:
			current_direction = "east"
		else:
			current_direction = "west"
			
	elif abs(input_vertical) > 0:
		velocity.x = 0
		velocity.y = input_vertical * speed
		is_moving = true
		
		# Определяем направление
		if input_vertical > 0:
			current_direction = "south"
		else:
			current_direction = "north"
	else:
		velocity.x = 0
		velocity.y = 0
	
	# 2. ДВИЖЕНИЕ
	move_and_slide()
	
	# 3. ОБНОВЛЕНИЕ АНИМАЦИИ
	if is_moving or was_moving:
		_update_animation()

	_update_footsteps_sound()
	_update_footprints()
	
	
	
	# ОТЛАДКА: только если движемся
	if abs(input_horizontal) > 0 or abs(input_vertical) > 0:
		print("Позиция: ", position, " Ввод: ", Vector2(input_horizontal, input_vertical))
	
	# 4. ПРОВЕРКА УКРЫТИЯ (после первых 10 кадров)
	init_frames += 1
	if init_frames > 10:
		_check_shelter_status()
	
	# 5. СИСТЕМА ХОЛОДА
	_process_cold(delta)
	
	# 6. ПРОВЕРКА СОСТОЯНИЯ
	_check_survival_status()

func _update_animation() -> void:
	if animated_sprite == null:
		return
	
	var animation_name: String
	if is_moving:
		animation_name = "walk_" + current_direction
	else:
		animation_name = "idle_" + current_direction
	
	# Проверяем существует ли анимация
	if animated_sprite.sprite_frames.has_animation(animation_name):
		if animated_sprite.animation != animation_name:
			animated_sprite.play(animation_name)
			# print("🎬 Анимация: ", animation_name)
	else:
		print("⚠️ Анимация не найдена: ", animation_name)

func _update_footsteps_sound() -> void:
	if snow_footsteps == null:
		return
	
	if is_moving:
		if not snow_footsteps.playing:
			snow_footsteps.play()
	else:
		if snow_footsteps.playing:
			snow_footsteps.stop()

func _process_cold(delta: float) -> void:
	if init_frames % 30 == 0:  # Выводим каждую секунду
		print("[%.0f] 🌡️ is_in_shelter=%s HP=%.1f Warmth=%.1f" % [init_frames, is_in_shelter, health, warmth])
	
	if is_in_shelter:
		# Греемся в укрытии
		warmth = min(warmth + warming_rate * delta, max_warmth)
		# Восстанавливаем здоровье в укрытии
		health = min(health + 20.0 * delta, max_health)  # +20 HP/сек в укрытии
	else:
		# Замерзаем на улице
		warmth -= freezing_rate * delta
		
		# Система урона от холода
		if warmth <= 0:
			# Максимальный холод (100%) - сильный урон
			warmth = 0
			health -= 5.0 * delta  # -5 HP в секунду при 100% холоде
			emit_signal("player_frozen")
		else:
			# Нормальный урон от холода на улице
			health -= 0.5 * delta  # -0.5 HP в секунду
	
	emit_signal("warmth_changed", warmth)
	emit_signal("health_changed", health)

func _check_survival_status() -> void:
	# Смерть от холода или потери здоровья
	if health <= 0:
		health = 0
		emit_signal("player_died")
		print("❌ Охотник погиб от холода...")
		get_tree().reload_current_scene()

func _check_shelter_status() -> void:
	# Проверяем расстояние до укрытий
	var shelters = get_tree().get_nodes_in_group("shelters")
	var shelter_radius = 150.0  # Радиус укрытия (увеличили с 100)
	var in_shelter_now = false
	
	if shelters.size() == 0:
		print("⚠️ ВНИМАНИЕ: Нет укрытий в группе 'shelters'!")
	
	for shelter in shelters:
		if shelter is Area2D:
			var distance = global_position.distance_to(shelter.global_position)
			if distance < shelter_radius:
				in_shelter_now = true
				# print("✓ Персонаж в укрытии на расстоянии %.1f" % distance)
				break
			# else:
				# print("✗ Укрытие на расстоянии %.1f (нужно < %.1f)" % [distance, shelter_radius])
	
	# Если состояние изменилось
	if in_shelter_now != is_in_shelter:
		if in_shelter_now:
			enter_shelter()
		else:
			exit_shelter()

func _update_ui() -> void:
	# Вывод статистики в консоль (для отладки)
	if Input.is_action_just_pressed("ui_accept"):  # Нажми ПРОБЕЛ для проверки
		print("=== 🌡️ СОСТОЯНИЕ ОХОТНИКА ===")
		print("❤️  Здоровье: %.1f / %.1f" % [health, max_health])
		print("🔥 Тепло: %.1f / %.1f" % [warmth, max_warmth])
		print("🧠 Рассудок: %.1f / %.1f" % [sanity, max_sanity])
		print(" Инвентарь: %d / %d" % [inventory.size(), max_inventory_slots])
		print("🏠 В укрытии: ", "ДА" if is_in_shelter else "НЕТ")
		print("🎬 Анимация: ", current_direction, " (движение: ", is_moving, ")" if is_moving else " (покой)")
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
	print("   Статус укрытия: ", is_in_shelter)

func exit_shelter() -> void:
	is_in_shelter = false
	print("❄️ Вышел на улицу. Берегись холода!")
	print("   Статус укрытия: ", is_in_shelter)

# === МЕТОДЫ ДЛЯ УПРАВЛЕНИЯ ТЕПЛОМ ===
func add_warmth(amount: float) -> void:
	warmth = min(warmth + amount, max_warmth)

# === ВХОД В ЗОНУ УКРЫТИЯ (вызывать из Area2D) ===
func _on_shelter_area_entered(area: Area2D) -> void:
	if area.is_in_group("shelters"):
		enter_shelter()

func _on_shelter_area_exited(area: Area2D) -> void:
	if area.is_in_group("shelters"):
		exit_shelter()

# === СИСТЕМА СЛЕДОВ НА СНЕГУ ===
func _update_footprints() -> void:
	if not is_moving:
		return
	
	if footprint_scene == null:
		return
	
	if footprints_only_outside and is_in_shelter:
		return
	
	var base_position: Vector2 = _get_footprint_base_position()
	
	if base_position.distance_to(last_footprint_position) < footprint_distance:
		return
	
	if not _is_position_on_snow(base_position):
		return
	
	_spawn_footprint(base_position)
	last_footprint_position = base_position


func _spawn_footprint(spawn_position: Vector2) -> void:
	var footprint = footprint_scene.instantiate() as Node2D
	
	if footprint == null:
		return
	
	var parent_for_footprints: Node = get_parent()
	
	if footprints_parent != null:
		parent_for_footprints = footprints_parent
	
	parent_for_footprints.add_child(footprint)
	footprint.global_position = spawn_position + _get_footprint_offset()
	
	if footprint.has_method("setup"):
		footprint.setup(current_direction, is_left_footprint)
	
	is_left_footprint = not is_left_footprint


func _get_footprint_base_position() -> Vector2:
	match current_direction:
		"south":
			return global_position + footprint_origin_offset_south
		"north":
			return global_position + footprint_origin_offset_north
		"east", "west":
			return global_position + footprint_origin_offset_side
	
	return global_position


func _get_footprint_offset() -> Vector2:
	var side: float
	
	if is_left_footprint:
		side = -1.0
	else:
		side = 1.0
	
	var offset := Vector2.ZERO
	
	match current_direction:
		"north", "south":
			# Когда идём вверх/вниз, следы дальше друг от друга по X
			offset.x = side * footprint_side_offset_vertical
		
		"east", "west":
			# Когда идём влево/вправо, оставляем ближе по Y
			offset.y = side * footprint_side_offset_horizontal
	
	offset.x += randf_range(-footprint_random_offset, footprint_random_offset)
	offset.y += randf_range(-footprint_random_offset, footprint_random_offset)
	
	return offset


func _is_position_on_snow(world_position: Vector2) -> bool:
	if snow_tilemap == null:
		return false
	
	var local_position: Vector2 = snow_tilemap.to_local(world_position)
	var cell_position: Vector2i = snow_tilemap.local_to_map(local_position)
	
	return snow_tilemap.get_cell_source_id(cell_position) != -1
