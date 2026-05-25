extends Node

## Глобальное состояние: данные пролога и стартовые навыки героя.
## Autoload: /root/GameState

var hero_name: String = "Кыым (Искра)"
var prologue_choices: Array = []
var prologue_skills: Array = []
var prologue_completed: bool = false


func reset_prologue() -> void:
	prologue_choices.clear()
	prologue_skills.clear()
	prologue_completed = false


func record_prologue_choice(stage_id: String, choice_index: int, choice_label: String, skill_name: String) -> void:
	var entry := {
		"stage_id": stage_id,
		"choice_index": choice_index,
		"choice_label": choice_label,
		"skill": skill_name,
	}
	prologue_choices.append(entry)
	if skill_name != "" and not prologue_skills.has(skill_name):
		prologue_skills.append(skill_name)


func complete_prologue() -> void:
	prologue_completed = true
