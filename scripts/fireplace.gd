extends StaticBody2D
class_name Fireplace

# Обогрев
@export var warming_bonus: float = 50.0
@export var heating_radius: float = 120.0

# Свет костра
@export var base_light_energy: float = 0.5
@export var light_energy_flicker: float = 0.5

@export var base_light_scale: float = 1.15
@export var light_scale_flicker: float = 0.18

@export var flicker_speed: float = 8.0
@export var light_jitter: float = 2.0

@export var fire_color: Color = Color(0.894, 0.627, 0.165, 1.0)

signal fire_heating(bodies: Array)

var _noise := FastNoiseLite.new()
var _time: float = 0.0
var _light_start_pos: Vector2 = Vector2.ZERO

@onready var fire_light: PointLight2D = get_node_or_null("FireLight")
@onready var heat_area: Area2D = get_node_or_null("HeatArea")


func _ready() -> void:
	add_to_group("heat_sources")

	_setup_heat_area()
	_setup_light()

	if heat_area:
		heat_area.area_entered.connect(_on_area_entered)
		heat_area.area_exited.connect(_on_area_exited)

	


func _setup_heat_area() -> void:
	if heat_area == null:
		heat_area = Area2D.new()
		heat_area.name = "HeatArea"
		add_child(heat_area)

	var collision_shape: CollisionShape2D = heat_area.get_node_or_null("CollisionShape2D")

	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		heat_area.add_child(collision_shape)

	var circle := CircleShape2D.new()
	circle.radius = heating_radius
	collision_shape.shape = circle

	heat_area.monitoring = true
	heat_area.monitorable = true


func _setup_light() -> void:
	if fire_light == null:
		fire_light = PointLight2D.new()
		fire_light.name = "FireLight"
		add_child(fire_light)

	fire_light.color = fire_color
	fire_light.energy = base_light_energy
	fire_light.texture_scale = base_light_scale
	fire_light.position = Vector2.ZERO
	
	fire_light.blend_mode = Light2D.BLEND_MODE_ADD
	fire_light.shadow_enabled = true
	fire_light.shadow_color = Color(0, 0, 0, 0.3)
	fire_light.shadow_filter = Light2D.SHADOW_FILTER_NONE
	fire_light.shadow_filter_smooth = 0.0
	fire_light.shadow_item_cull_mask = 1
	
	
	_light_start_pos = fire_light.position

	_noise.seed = randi()
	_noise.frequency = 1.0

	if fire_light.texture == null:
		fire_light.texture = _create_fire_light_texture()


func _create_fire_light_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.75, 0.35, 1.0))
	gradient.set_color(1, Color(1.0, 0.2, 0.05, 0.0))

	var texture := GradientTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient

	return texture


func _process(delta: float) -> void:
	_update_fire_light(delta)
	_heat_nearby_player(delta)


func _update_fire_light(delta: float) -> void:
	if fire_light == null:
		return

	_time += delta

	var n1 := (_noise.get_noise_1d(_time * flicker_speed) + 1.0) * 0.5
	var n2 := (_noise.get_noise_1d(_time * flicker_speed + 50.0) + 1.0) * 0.5
	var n3 := (_noise.get_noise_1d(_time * flicker_speed + 100.0) + 1.0) * 0.5

	var target_energy := base_light_energy + (n1 - 0.5) * 2.0 * light_energy_flicker
	var target_scale := base_light_scale + (n2 - 0.5) * 2.0 * light_scale_flicker

	fire_light.energy = lerp(fire_light.energy, target_energy, 10.0 * delta)
	fire_light.texture_scale = lerp(fire_light.texture_scale, target_scale, 8.0 * delta)

	var jitter_offset := Vector2(
		(n2 - 0.5) * light_jitter,
		(n3 - 0.5) * light_jitter
	)

	fire_light.position = _light_start_pos + jitter_offset


func _heat_nearby_player(delta: float) -> void:
	if heat_area == null:
		return

	var areas := heat_area.get_overlapping_areas()

	for area in areas:
		var owner_node := area.owner

		if owner_node and owner_node.has_method("add_warmth"):
			owner_node.add_warmth(warming_bonus * delta)


func _on_area_entered(area: Area2D) -> void:
	var owner_node := area.owner

	


func _on_area_exited(area: Area2D) -> void:
	var owner_node := area.owner

	
