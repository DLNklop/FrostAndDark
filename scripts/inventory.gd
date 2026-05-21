extends Node

signal inventory_changed

var items: Dictionary = {}


func add_item(item_id: String, item_name: String, amount: int = 1) -> void:
	if items.has(item_id):
		items[item_id]["amount"] += amount
	else:
		items[item_id] = {
			"name": item_name,
			"amount": amount
		}

	inventory_changed.emit()


func remove_item(item_id: String, amount: int = 1) -> void:
	if not items.has(item_id):
		return

	items[item_id]["amount"] -= amount

	if items[item_id]["amount"] <= 0:
		items.erase(item_id)

	inventory_changed.emit()


func has_item(item_id: String) -> bool:
	return items.has(item_id)


func get_items() -> Dictionary:
	return items


func clear_inventory() -> void:
	items.clear()
	inventory_changed.emit()
