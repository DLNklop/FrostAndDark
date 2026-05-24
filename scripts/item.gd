extends Node2D

@export var item_id: String = "ammo"
@export var item_name: String = "Патроны"
@export var amount: int = 1
@export var pickup_sound: AudioStream

var picked_up: bool = false


func _ready() -> void:
	add_to_group("pickup_items")


func _on_area_2d_area_entered(area: Area2D) -> void:
	if picked_up:
		return
	
	if area.has_node("../../"):  # Проверяем, что это игрок
		var parent = area.get_parent().get_parent()
		if parent is CharacterBody2D and parent.is_in_group("player"):
			pickup_item(parent)


func pickup_item(player: Node2D) -> void:
	picked_up = true
	
	# Добавляем предмет в инвентарь
	Inventory.add_item(item_id, item_name, amount)
	
	print("📦 Подобран предмет: ", item_name, " x", amount)
	
	# Воспроизводим звук если есть
	if pickup_sound:
		var audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = pickup_sound
		add_child(audio_player)
		audio_player.play()
		await audio_player.finished
		audio_player.queue_free()
	
	# Удаляем предмет через небольшую задержку
	await get_tree().create_timer(0.3).timeout
	queue_free()
