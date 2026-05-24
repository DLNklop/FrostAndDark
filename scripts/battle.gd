extends Node2D
class_name BattleScene

# === Боевая статистика ===
@export var player_max_health: float = 100.0
@export var enemy_max_health: float = 50.0

var player_health: float = 100.0
var enemy_health: float = 50.0
var player_ammo: int = 10
var player_damage: float = 15.0
var enemy_damage: float = 10.0

# === Состояние боя ===
enum Turn { PLAYER, ENEMY }
var current_turn: Turn = Turn.PLAYER
var battle_active: bool = false

# === Позиции для возврата ===
var previous_scene_position: Vector2
var previous_scene: String = ""

# === UI элементы ===
@onready var player_health_label: Label = $UI/PlayerHealthLabel if has_node("UI/PlayerHealthLabel") else null
@onready var enemy_health_label: Label = $UI/EnemyHealthLabel if has_node("UI/EnemyHealthLabel") else null
@onready var ammo_label: Label = $UI/AmmoLabel if has_node("UI/AmmoLabel") else null
@onready var turn_label: Label = $UI/TurnLabel if has_node("UI/TurnLabel") else null
@onready var message_label: Label = $UI/MessageLabel if has_node("UI/MessageLabel") else null

# === Кнопки действий ===
@onready var shoot_button: Button = $UI/ShootButton if has_node("UI/ShootButton") else null
@onready var melee_button: Button = $UI/MeleeButton if has_node("UI/MeleeButton") else null
@onready var skill_button: Button = $UI/SkillButton if has_node("UI/SkillButton") else null
@onready var item_button: Button = $UI/ItemButton if has_node("UI/ItemButton") else null
@onready var run_button: Button = $UI/RunButton if has_node("UI/RunButton") else null

# === Спрайты ===
@onready var player_sprite: Sprite2D = $player if has_node("player") else null
@onready var enemy_sprite: Sprite2D = $enemy if has_node("enemy") else null

# === Анимации ===
@onready var player_animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var enemy_animation_player: AnimationPlayer = $EnemyAnimationPlayer if has_node("EnemyAnimationPlayer") else null


func _ready() -> void:
	_setup_battle()


func _setup_battle() -> void:
	battle_active = true
	current_turn = Turn.PLAYER
	
	# Инициализация здоровья
	player_health = player_max_health
	enemy_health = enemy_max_health
	
	# Получаем патроны из инвентаря
	if Inventory.has_item("ammo"):
		var items = Inventory.get_items()
		player_ammo = items["ammo"]["amount"]
	else:
		player_ammo = 5  # Стартовые патроны
	
	_update_ui()
	_show_message("Твой ход!")
	_set_buttons_enabled(true)


func _update_ui() -> void:
	if player_health_label:
		player_health_label.text = "HP: %d/%d" % [player_health, player_max_health]
	
	if enemy_health_label:
		enemy_health_label.text = "Враг: %d/%d" % [enemy_health, enemy_max_health]
	
	if ammo_label:
		ammo_label.text = "Патроны: %d" % [player_ammo]
	
	if turn_label:
		turn_label.text = "Ход: ИГРОК" if current_turn == Turn.PLAYER else "Ход: ВРАГ"


func _set_buttons_enabled(enabled: bool) -> void:
	if shoot_button:
		shoot_button.disabled = !enabled
	if melee_button:
		melee_button.disabled = !enabled
	if skill_button:
		skill_button.disabled = !enabled
	if item_button:
		item_button.disabled = !enabled
	if run_button:
		run_button.disabled = !enabled


func _show_message(text: String) -> void:
	if message_label:
		message_label.text = text


# === ДЕЙСТВИЯ ИГРОКА ===

func _on_shoot_button_pressed() -> void:
	if current_turn != Turn.PLAYER or not battle_active:
		return
	
	if player_ammo <= 0:
		_show_message("Нет патронов!")
		return
	
	player_ammo -= 1
	Inventory.remove_item("ammo", 1)
	
	# Урон с небольшим разбросом
	var damage = player_damage + randf_range(-3, 3)
	enemy_health -= damage
	enemy_health = max(0, enemy_health)
	
	_show_message("Выстрел! Враг получил %d урона." % int(damage))
	_play_shoot_animation()
	_update_ui()
	
	if enemy_health <= 0:
		await get_tree().create_timer(1.0).timeout
		_win_battle()
	else:
		current_turn = Turn.ENEMY
		_update_ui()
		_set_buttons_enabled(false)
		await get_tree().create_timer(0.5).timeout
		_enemy_turn()


func _on_melee_button_pressed() -> void:
	if current_turn != Turn.PLAYER or not battle_active:
		return
	
	var damage = player_damage * 0.7 + randf_range(-2, 2)  # Меньше урона в ближнем бою
	enemy_health -= damage
	enemy_health = max(0, enemy_health)
	
	_show_message("Удар вблизи! Враг получил %d урона." % int(damage))
	_play_melee_animation()
	_update_ui()
	
	if enemy_health <= 0:
		await get_tree().create_timer(1.0).timeout
		_win_battle()
	else:
		current_turn = Turn.ENEMY
		_update_ui()
		_set_buttons_enabled(false)
		await get_tree().create_timer(0.5).timeout
		_enemy_turn()


func _on_skill_button_pressed() -> void:
	if current_turn != Turn.PLAYER or not battle_active:
		return
	
	# Простой навык - мощный выстрел
	if player_ammo < 2:
		_show_message("Нужно 2 патрона для навыка!")
		return
	
	player_ammo -= 2
	Inventory.remove_item("ammo", 2)
	
	var damage = player_damage * 2.0
	enemy_health -= damage
	enemy_health = max(0, enemy_health)
	
	_show_message("Специальный выстрел! Враг получил %d урона." % int(damage))
	_play_shoot_animation()
	_update_ui()
	
	if enemy_health <= 0:
		await get_tree().create_timer(1.0).timeout
		_win_battle()
	else:
		current_turn = Turn.ENEMY
		_update_ui()
		_set_buttons_enabled(false)
		await get_tree().create_timer(0.5).timeout
		_enemy_turn()


func _on_item_button_pressed() -> void:
	if current_turn != Turn.PLAYER or not battle_active:
		return
	
	# Проверка наличия аптечки
	if Inventory.has_item("medkit"):
		var heal_amount = 30.0
		player_health = min(player_health + heal_amount, player_max_health)
		Inventory.remove_item("medkit", 1)
		_show_message("Аптечка использована! +30 HP")
		_update_ui()
		
		# После использования предмета ход переходит к врагу
		current_turn = Turn.ENEMY
		_set_buttons_enabled(false)
		await get_tree().create_timer(0.5).timeout
		_enemy_turn()
	else:
		_show_message("Нет аптечки в инвентаре!")


func use_medkit_outside_battle() -> void:
	# Использование аптечки вне боя
	if Inventory.has_item("medkit"):
		var heal_amount = 30.0
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("add_health"):
			player.add_health(heal_amount)
		
		Inventory.remove_item("medkit", 1)
		print("🏥 Аптечка использована! +30 HP")
	else:
		print("❌ Нет аптечки в инвентаре!")


func _on_run_button_pressed() -> void:
	if current_turn != Turn.PLAYER or not battle_active:
		return
	
	# 50% шанс убежать
	if randf() > 0.5:
		_show_message("Удалось сбежать!")
		await get_tree().create_timer(0.5).timeout
		_end_battle(false)
	else:
		_show_message("Не удалось сбежать!")
		current_turn = Turn.ENEMY
		_set_buttons_enabled(false)
		await get_tree().create_timer(0.5).timeout
		_enemy_turn()


# === ХОД ВРАГА ===

func _enemy_turn() -> void:
	if not battle_active:
		return
	
	_show_message("Ход врага...")
	await get_tree().create_timer(0.5).timeout
	
	# Простая атака врага
	var damage = enemy_damage + randf_range(-2, 3)
	player_health -= damage
	player_health = max(0, player_health)
	
	_show_message("Враг атакует! Вы получили %d урона." % int(damage))
	_play_enemy_attack_animation()
	_update_ui()
	
	if player_health <= 0:
		await get_tree().create_timer(1.0).timeout
		_lose_battle()
	else:
		current_turn = Turn.PLAYER
		_update_ui()
		_set_buttons_enabled(true)
		_show_message("Твой ход!")


# === АНИМАЦИИ ===

func _play_shoot_animation() -> void:
	if player_animation_player and player_animation_player.has_animation("shoot"):
		player_animation_player.play("shoot")
	elif player_sprite:
		# Простая анимация тряски
		var tween = create_tween()
		tween.tween_property(player_sprite, "position:x", player_sprite.position.x + 5, 0.05)
		tween.tween_property(player_sprite, "position:x", player_sprite.position.x - 5, 0.05)
		tween.tween_property(player_sprite, "position:x", player_sprite.position.x, 0.05)


func _play_melee_animation() -> void:
	if player_sprite:
		var tween = create_tween()
		tween.tween_property(player_sprite, "position:y", player_sprite.position.y - 10, 0.1)
		tween.tween_property(player_sprite, "position:y", player_sprite.position.y, 0.1)


func _play_enemy_attack_animation() -> void:
	if enemy_sprite:
		var tween = create_tween()
		tween.tween_property(enemy_sprite, "position:y", enemy_sprite.position.y + 10, 0.1)
		tween.tween_property(enemy_sprite, "position:y", enemy_sprite.position.y, 0.1)


# === РЕЗУЛЬТАТЫ БОЯ ===

func _win_battle() -> void:
	battle_active = false
	_show_message("Победа! Враг повержен.")
	await get_tree().create_timer(1.5).timeout
	_end_battle(true)


func _lose_battle() -> void:
	battle_active = false
	_show_message("Поражение... Вы погибли.")
	await get_tree().create_timer(2.0).timeout
	# Перезапуск сцены при проигрыше
	get_tree().reload_current_scene()


func _end_battle(won: bool) -> void:
	# Возвращаемся в предыдущую сцену на ту же позицию
	BattleSystem.end_battle(won, previous_scene_position)


# === Сигналы кнопок (подключаются в battle.tscn или кодом) ===
func connect_buttons() -> void:
	if shoot_button:
		shoot_button.pressed.connect(_on_shoot_button_pressed)
	if melee_button:
		melee_button.pressed.connect(_on_melee_button_pressed)
	if skill_button:
		skill_button.pressed.connect(_on_skill_button_pressed)
	if item_button:
		item_button.pressed.connect(_on_item_button_pressed)
	if run_button:
		run_button.pressed.connect(_on_run_button_pressed)
