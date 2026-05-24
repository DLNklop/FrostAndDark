extends CharacterBody2D

enum State {
	WANDER,
	CHASE,
	RETURN_HOME,
	BATTLE_STUB
}

# === ДВИЖЕНИЕ ===
@export var walk_speed: float = 22.0
@export var chase_speed: float = 55.0

@export var view_radius: float = 120.0
@export var lose_radius: float = 210.0
@export var battle_radius: float = 24.0
@export var wander_radius: float = 70.0

var current_direction: String = "south"
var is_moving: bool = false

# === ЗВУКИ ===
@onready var footstep_audio: AudioStreamPlayer2D = $FootstepAudio

# === СЛЕДЫ НА СНЕГУ ===
@export var footprint_scene: PackedScene

@export var footprint_distance: float = 16.0

@export var footprint_side_offset_vertical: float = 3.5
@export var footprint_side_offset_horizontal: float = 2.0

@export var footprint_random_offset: float = 0.8

@export var footprint_origin_offset_south: Vector2 = Vector2(0, 0)
@export var footprint_origin_offset_north: Vector2 = Vector2(0, 4)
@export var footprint_origin_offset_side: Vector2 = Vector2(0, -1)

@export var snow_tilemap_path: NodePath
@export var footprints_parent_path: NodePath

@onready var snow_tilemap: TileMapLayer = get_node_or_null(snow_tilemap_path) as TileMapLayer
@onready var footprints_parent: Node2D = get_node_or_null(footprints_parent_path) as Node2D

var last_footprint_position: Vector2
var is_left_footprint: bool = true

# === AI ===
var player: Node2D
var state: State = State.WANDER

var home_position: Vector2
var wander_target: Vector2

var wait_timer: float = 0.0
var lose_timer: float = 0.0

var battle_started: bool = false


func _ready() -> void:
	home_position = global_position
	last_footprint_position = _get_footprint_base_position()
	
	player = get_tree().get_first_node_in_group("player") as Node2D
	
	if player == null:
		push_warning("Enemy1AI: игрок не найден. Добавь игрока в группу player.")
		return
	
	_pick_new_wander_target()


func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	var was_moving := is_moving
	is_moving = false
	
	if battle_started:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_footsteps_sound()
		return
	
	if _can_see_player():
		state = State.CHASE
		lose_timer = 0.0
	elif state == State.CHASE:
		lose_timer += delta
		
		if global_position.distance_to(player.global_position) > lose_radius or lose_timer >= 1.2:
			state = State.RETURN_HOME
	
	match state:
		State.WANDER:
			_wander(delta)
		
		State.CHASE:
			_chase_player()
		
		State.RETURN_HOME:
			_return_home()
		
		State.BATTLE_STUB:
			velocity = Vector2.ZERO
			move_and_slide()
	
	_update_footsteps_sound()
	_update_footprints()


func _wander(delta: float) -> void:
	if global_position.distance_to(wander_target) <= 6.0:
		velocity = Vector2.ZERO
		is_moving = false
		move_and_slide()
		
		wait_timer -= delta
		
		if wait_timer <= 0.0:
			_pick_new_wander_target()
		
		return
	
	_move_to(wander_target, walk_speed)


func _chase_player() -> void:
	var distance_to_player := global_position.distance_to(player.global_position)
	
	if distance_to_player <= battle_radius:
		_start_battle_stub()
		return
	
	_move_to(player.global_position, chase_speed)


func _return_home() -> void:
	if global_position.distance_to(home_position) <= 6.0:
		state = State.WANDER
		_pick_new_wander_target()
		return
	
	_move_to(home_position, walk_speed)


func _move_to(target: Vector2, speed: float) -> void:
	var difference := target - global_position
	
	if abs(difference.x) < 2.0 and abs(difference.y) < 2.0:
		velocity = Vector2.ZERO
		is_moving = false
		move_and_slide()
		return
	
	var direction := Vector2.ZERO
	
	# Только 4 стороны, без диагонали
	if abs(difference.x) > abs(difference.y):
		direction.x = sign(difference.x)
		
		if direction.x > 0:
			current_direction = "east"
		else:
			current_direction = "west"
	else:
		direction.y = sign(difference.y)
		
		if direction.y > 0:
			current_direction = "south"
		else:
			current_direction = "north"
	
	velocity = direction * speed
	is_moving = true
	move_and_slide()


func _pick_new_wander_target() -> void:
	var angle := randf() * TAU
	var distance := randf_range(20.0, wander_radius)
	
	wander_target = home_position + Vector2(cos(angle), sin(angle)) * distance
	wait_timer = randf_range(0.4, 1.2)


func _can_see_player() -> bool:
	var distance_to_player := global_position.distance_to(player.global_position)
	
	if state == State.CHASE:
		return distance_to_player <= lose_radius
	
	return distance_to_player <= view_radius


func _start_battle_stub() -> void:
	battle_started = true
	state = State.BATTLE_STUB
	velocity = Vector2.ZERO
	is_moving = false
	
	print("НАЧАЛАСЬ БОЁВКА С ENEMY1")


# === ЗВУК ШАГОВ ===
func _update_footsteps_sound() -> void:
	if footstep_audio == null:
		return
	
	if is_moving:
		if not footstep_audio.playing:
			footstep_audio.play()
	else:
		if footstep_audio.playing:
			footstep_audio.stop()


# === СЛЕДЫ НА СНЕГУ ===
func _update_footprints() -> void:
	if not is_moving:
		return
	
	if footprint_scene == null:
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
