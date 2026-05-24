extends Area2D

func _ready() -> void:
	# Добавляем в группу укрытий
	add_to_group("shelters")
	
	# Подключаемся к сигналам Area2D
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	# Если это охотник, входим в укрытие
	if body.is_in_group("player") or body.name == "CharacterBody2D":
		if body.has_method("enter_shelter"):
			body.enter_shelter()

func _on_body_exited(body: Node) -> void:
	# Если это охотник, выходим из укрытия
	if body.is_in_group("player") or body.name == "CharacterBody2D":
		if body.has_method("exit_shelter"):
			body.exit_shelter()
