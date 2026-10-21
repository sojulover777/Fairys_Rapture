extends Control

var counter1 = 0
@onready var right_btn = $right_button1
@onready var left_btn = $left_button1

var active_tweens = {}

func get_attacks() -> Array:
	return [
		{"type": "Догма", "damage": CombatState.get_spell_damage("Догма"),
		 "cost": 20, "number": 1},
		{"type": "Клевета", "damage": CombatState.get_spell_damage("Клевета"),
		 "cost": 30, "number": 2},
		{"type": "Надрез", "damage": CombatState.get_spell_damage("Надрез"),
		 "cost": 15, "number": 3},
		{"type": "Вердикт", "damage": CombatState.get_spell_damage("Вердикт"),
		 "cost": 35, "number": 4}
	]

func _ready() -> void:
	$Sprite2D/AnimatedSprite2D.visible = false
	$Sprite2D/spell_name/spell_descritpion.text = ""

func _sprite_and_text():
	var attacks = get_attacks()
	var spell_data = attacks[counter1]
	var spell = spell_data["type"]
	
	CombatState.spell_changed.emit(spell_data)
	$Sprite2D/spell_name.text = spell
	$Sprite2D/AnimatedSprite2D.visible = true
	$Sprite2D/AnimatedSprite2D.play(spell)
	
	match spell:
		"Догма":
			$Sprite2D/spell_name/spell_descritpion.text = "Пластична и податлива,\nцентр жизни всего сущего."
		"Клевета":
			$Sprite2D/spell_name/spell_descritpion.text = "Страсть, уничтожающая саму себя,\nно дающая свет во тьме."
		"Надрез":
			$Sprite2D/spell_name/spell_descritpion.text = "Двуликая стихия,\nчто создаёт и разрушает."
		"Вердикт":
			$Sprite2D/spell_name/spell_descritpion.text = "Горькое подобие стихии,\nне обладающее формой."

func _on_left_button_1_pressed() -> void:
	CombatState.bounce_press(left_btn)
	CombatState.krutilkas_button.emit()
	var attacks = get_attacks()
	counter1 += 1
	if counter1 > (attacks.size() - 1):
		counter1 = 0
	_sprite_and_text()

func _on_right_button_1_pressed() -> void:
	CombatState.bounce_press(right_btn)
	CombatState.krutilkas_button.emit()
	var attacks = get_attacks()
	counter1 -= 1
	if counter1 < 0:
		counter1 = (attacks.size() - 1)
	_sprite_and_text()
