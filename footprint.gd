extends Node2D

@export var lifetime: float = 3.0
@export var fade_time: float = 2.0
@export var start_alpha: float = 0.35
@export var footprint_color: Color = Color(0.015, 0.018, 0.02, 1.0)

func _ready() -> void:
	z_index = 0
	modulate.a = start_alpha
	
	queue_redraw()
	
	var wait_time = max(lifetime - fade_time, 0.0)
	await get_tree().create_timer(wait_time).timeout
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	await tween.finished
	
	queue_free()


func _draw() -> void:
	# След высотой 7 пикселей
	draw_rect(Rect2(-1, -3, 2, 1), footprint_color, true)
	draw_rect(Rect2(-2, -2, 4, 5), footprint_color, true)
	draw_rect(Rect2(-1, 3, 2, 1), footprint_color, true)


func setup(direction: String, is_left_step: bool) -> void:
	match direction:
		"south":
			rotation_degrees = 0
		"north":
			rotation_degrees = 180
		"east":
			rotation_degrees = 90
		"west":
			rotation_degrees = -90
	
	if is_left_step:
		scale.x = -1
	else:
		scale.x = 1
