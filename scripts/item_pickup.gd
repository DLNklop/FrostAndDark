extends Area2D

@export var item_id: String = "dry_branch"
@export var item_name: String = "Сухая ветка"
@export var amount: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Inventory.add_item(item_id, item_name, amount)
		queue_free()
