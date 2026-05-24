extends Node

## Глобальная система боя для управления переходами между сценами

var in_battle: bool = false
var player_position_before_battle: Vector2 = Vector2.ZERO
var current_enemy: Node2D = null

signal battle_started
signal battle_ended(won: bool)


func start_battle(enemy: Node2D, player_pos: Vector2) -> void:
	if in_battle:
		return
	
	in_battle = true
	current_enemy = enemy
	player_position_before_battle = player_pos
	
	print("🔫 Начало боя с врагом!")
	battle_started.emit()
	
	# Переходим к сцене боя
	var battle_scene = load("res://tscn/battle.tscn") as PackedScene
	if battle_scene:
		var battle_instance = battle_scene.instantiate() as BattleScene
		if battle_instance:
			battle_instance.previous_scene_position = player_pos
			battle_instance.connect_buttons()
			
			# Получаем текущую сцену и добавляем бой поверх
			var current = get_tree().current_scene
			if current:
				current.add_child(battle_instance)


func end_battle(won: bool, return_position: Vector2) -> void:
	if not in_battle:
		return
	
	in_battle = false
	battle_ended.emit(won)
	
	# Находим и удаляем сцену боя
	var current = get_tree().current_scene
	if current:
		for child in current.get_children():
			if child is BattleScene:
				child.queue_free()
				break
	
	# Восстанавливаем позицию игрока
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_global_position"):
		player.set_global_position(return_position)
	
	# Удаляем врага если победили
	if won and current_enemy:
		current_enemy.queue_free()
	
	current_enemy = null
	print("⚔️ Бой завершен. Победа: ", won)
