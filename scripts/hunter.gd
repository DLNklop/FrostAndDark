extends CharacterBody2D
class_name Hunter

# === СТАТИСТИКА ПЕРСОНАЖА ===
@export var max_health: float = 100.0
@export var max_warmth: float = 100.0
@export var max_sanity: float = 100.0

var health: float = 100.0
var warmth: float = 100.0
var sanity: float = 100.0


# === ТЕНЬ ОТ ИГРОКА ===
@onready var occluder_south: LightOccluder2D = get_node_or_null("OccluderSouth") as LightOccluder2D
@onready var occluder_north: LightOccluder2D = get_node_or_null("OccluderNorth") as LightOccluder2D
@onready var occluder_east: LightOccluder2D = get_node_or_null("OccluderEast") as LightOccluder2D
@onready var occluder_west: LightOccluder2D = get_node_or_null("OccluderWest") as LightOccluder2D

@export var active_shadow_mask: int = 1


# === ДВИЖЕНИЕ ===
@export var speed: float = 140.0
var is_in_shelter: bool = true


# === АНИМАЦИИ ===
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var current_direction: String = "south"
var is_moving: bool = false


# === ЗВУКИ ===
@onready var snow_footsteps: AudioStreamPlayer2D = $SnowFootsteps


# === СЛЕДЫ НА СНЕГУ ===
@export var footprint_scene: PackedScene

@export var footprint_distance: float = 16.0

@export var footprint_side_offset_vertical: float = 3.5
@export var footprint_side_offset_horizontal: float = 2.0

@export var footprint_random_offset: float = 0.8

@export var footprints_only_outside: bool = false

@export var footprint_origin_offset_south: Vector2 = Vector2(0, 0)
@export var footprint_origin_offset_north: Vector2 = Vector2(0, 4)
@export var footprint_origin_offset_side: Vector2 = Vector2(0, -1)

@export var snow_tilemap_path: NodePath
@export var footprints_parent_path: NodePath

@onready var snow_tilemap: TileMapLayer = get_node_or_null(snow_tilemap_path) as TileMapLayer
@onready var footprints_parent: Node2D = get_node_or_null(footprints_parent_path) as Node2D

var last_footprint_position: Vector2
var is_left_footprint: bool = true


# === СИСТЕМА ХОЛОДА ===
@export var freezing_rate: float = 2.0
@export var warming_rate: float = 15.0
@export var shelter_bonus: float = 50.0


# === ИНИЦИАЛИЗАЦИЯ ===
var init_frames: int = 0


# === ИНВЕНТАРЬ ===
var inventory: Array = []
var max_inventory_slots: int = 8

# === ЛЕЧЕНИЕ ===
func add_health(amount: float) -> void:
	health = min(health + amount, max_health)
	emit_signal("health_changed", health)


# === ИСПОЛЬЗОВАНИЕ АПТЕЧКИ ===
func use_medkit() -> void:
	if Inventory.has_item("medkit"):
		add_health(30.0)
		Inventory.remove_item("medkit", 1)
		print("🏥 Аптечка использована! +30 HP")
	else:
		print("❌ Нет аптечки в инвентаре!")


# === СИГНАЛЫ ===
signal warmth_changed(new_warmth: float)
signal health_changed(new_health: float)
signal sanity_changed(new_sanity: float)
signal player_frozen
signal player_died


func _ready() -> void:
	last_footprint_position = _get_footprint_base_position()
	
	
	await get_tree().process_frame
	
	var shelters = get_tree().get_nodes_in_group("shelters")
	print("📍 Найдено укрытий: ", shelters.size())
	
	for shelter in shelters:
		if shelter is Area2D:
			var distance = global_position.distance_to(shelter.global_position)
			print("  - Укрытие на расстоянии: ", distance)
	
	_update_animation()
	_update_shadow_occluder()


func _physics_process(delta: float) -> void:
	# 1. ОБРАБОТКА ВВОДА
	var input_horizontal = Input.get_axis("ui_left", "ui_right")
	var input_vertical = Input.get_axis("ui_up", "ui_down")
	
	var was_moving = is_moving
	is_moving = false
	
	# Только 4 направления без диагоналей
	if abs(input_horizontal) > 0:
		velocity.x = input_horizontal * speed
		velocity.y = 0
		is_moving = true
		
		if input_horizontal > 0:
			current_direction = "east"
		else:
			current_direction = "west"
			
	elif abs(input_vertical) > 0:
		velocity.x = 0
		velocity.y = input_vertical * speed
		is_moving = true
		
		if input_vertical > 0:
			current_direction = "south"
		else:
			current_direction = "north"
	else:
		velocity.x = 0
		velocity.y = 0
	
	# Важно: обновляем тень сразу после смены current_direction
	_update_shadow_occluder()
	
	# 2. ДВИЖЕНИЕ
	move_and_slide()
	
	# 3. АНИМАЦИЯ
	if is_moving or was_moving:
		_update_animation()
	
	_update_footsteps_sound()
	_update_footprints()
	
	# 4. ИСПОЛЬЗОВАНИЕ АПТЕЧКИ (клавиша H)
	if Input.is_action_just_pressed("use_medkit"):
		use_medkit()
	
	# ОТЛАДКА
	if abs(input_horizontal) > 0 or abs(input_vertical) > 0:
		print("Позиция: ", position, " Направление: ", current_direction)
	
	# 4. ПРОВЕРКА УКРЫТИЯ
	init_frames += 1
	if init_frames > 10:
		_check_shelter_status()
	
	# 5. ХОЛОД
	_process_cold(delta)
	
	# 6. СОСТОЯНИЕ
	_check_survival_status()


func _update_animation() -> void:
	if animated_sprite == null:
		return
	
	var animation_name: String
	
	if is_moving:
		animation_name = "walk_" + current_direction
	else:
		animation_name = "idle_" + current_direction
	
	if animated_sprite.sprite_frames.has_animation(animation_name):
		if animated_sprite.animation != animation_name:
			animated_sprite.play(animation_name)
	else:
		print("Анимация не найдена: ", animation_name)


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
	if is_in_shelter:
		warmth = min(warmth + warming_rate * delta, max_warmth)
		health = min(health + 20.0 * delta, max_health)
	else:
		warmth -= freezing_rate * delta
		
		if warmth <= 0:
			warmth = 0
			health -= 5.0 * delta
			emit_signal("player_frozen")
		else:
			health -= 0.5 * delta
	
	emit_signal("warmth_changed", warmth)
	emit_signal("health_changed", health)


func _check_survival_status() -> void:
	if health <= 0:
		health = 0
		emit_signal("player_died")
		get_tree().reload_current_scene()


func _check_shelter_status() -> void:
	var shelters = get_tree().get_nodes_in_group("shelters")
	var shelter_radius = 150.0
	var in_shelter_now = false
	
	for shelter in shelters:
		if shelter is Area2D:
			var distance = global_position.distance_to(shelter.global_position)
			if distance < shelter_radius:
				in_shelter_now = true
				break
	
	if in_shelter_now != is_in_shelter:
		if in_shelter_now:
			enter_shelter()
		else:
			exit_shelter()


# === ИНВЕНТАРЬ ===
func add_item(item_name: String) -> bool:
	if inventory.size() < max_inventory_slots:
		inventory.append(item_name)
		return true
	
	return false


func remove_item(index: int) -> void:
	if index >= 0 and index < inventory.size():
		inventory.pop_at(index)


# === УКРЫТИЯ ===
func enter_shelter() -> void:
	is_in_shelter = true


func exit_shelter() -> void:
	is_in_shelter = false


func add_warmth(amount: float) -> void:
	warmth = min(warmth + amount, max_warmth)


func _on_shelter_area_entered(area: Area2D) -> void:
	if area.is_in_group("shelters"):
		enter_shelter()


func _on_shelter_area_exited(area: Area2D) -> void:
	if area.is_in_group("shelters"):
		exit_shelter()


# === СЛЕДЫ НА СНЕГУ ===
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
			offset.x = side * footprint_side_offset_vertical
		
		"east", "west":
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


# === СИСТЕМА ТЕНИ ОТ ИГРОКА ===
func _update_shadow_occluder() -> void:
	_disable_all_shadow_occluders()
	
	match current_direction:
		"south":
			_enable_shadow_occluder(occluder_south)
		"north":
			_enable_shadow_occluder(occluder_north)
		"east":
			_enable_shadow_occluder(occluder_east)
		"west":
			_enable_shadow_occluder(occluder_west)
	
	print("Активная тень: ", current_direction)


func _disable_all_shadow_occluders() -> void:
	_disable_shadow_occluder(occluder_south)
	_disable_shadow_occluder(occluder_north)
	_disable_shadow_occluder(occluder_east)
	_disable_shadow_occluder(occluder_west)


func _enable_shadow_occluder(occluder: LightOccluder2D) -> void:
	if occluder == null:
		return
	
	occluder.occluder_light_mask = active_shadow_mask
	occluder.visible = true


func _disable_shadow_occluder(occluder: LightOccluder2D) -> void:
	if occluder == null:
		return
	
	occluder.occluder_light_mask = 0
	occluder.visible = false
