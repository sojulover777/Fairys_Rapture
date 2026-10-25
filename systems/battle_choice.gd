extends Control

@onready var attack = $Sprite2D/Attack
@onready var witchcraft = $Sprite2D/Witchcraft
@onready var items = $Sprite2D/Items
@onready var defense = $Sprite2D/Defense

func _on_attack_pressed() -> void:
	CombatState.bounce_press(attack)
	var normal_damage = CombatState.normal_damage
	CombatState.normal_attack.emit(normal_damage)


func _on_witchcraft_pressed() -> void:
	CombatState.bounce_press(witchcraft)
	await get_tree().create_timer(0.1).timeout
	CombatState.witchcraft.emit()
	CombatState.choise_visibility = true


func _on_defense_pressed() -> void:
	CombatState.bounce_press(defense)
	var armor = CombatState.armor_player
	CombatState.defense.emit(armor)


func _on_items_pressed() -> void:
	CombatState.bounce_press(items)
	CombatState.item_pressed.emit()
