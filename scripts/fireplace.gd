extends Area2D
class_name Fireplace

# Параметры огня
@export var warming_bonus: float = 50.0  # Дополнительное тепло от огня
@export var heating_radius: float = 120.0  # Радиус обогрева

signal fire_heating(bodies: Array)

func _ready() -> void:
	add_to_group("heat_sources")
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	print("🔥 Костер активирован!")

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Area2D" or area.owner.name == "CharacterBody2D":
		print("🔥 Охотник согревается у костра!")

func _on_area_exited(area: Area2D) -> void:
	if area.name == "Area2D" or area.owner.name == "CharacterBody2D":
		print("❄️ Охотник отошел от костра")

func _process(delta: float) -> void:
	# Обогреваем всех, кто в зоне - проверяем через родителя
	var areas = get_overlapping_areas()
	for area in areas:
		# Проверяем, это ли площадь персонажа
		if area.owner and area.owner.name == "CharacterBody2D":
			if area.owner.has_method("add_warmth"):
				area.owner.add_warmth(warming_bonus * delta)
