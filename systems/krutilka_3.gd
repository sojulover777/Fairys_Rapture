extends Control

@onready var guide = $Sprite2D/guide
@onready var mod_name = $Sprite2D/mod_name
@onready var mod_description = $Sprite2D/mod_name/mod_description
@onready var mods_pictures = $Sprite2D/AnimatedSprite2D
@onready var right_btn = $Sprite2D/right_button
@onready var left_btn = $Sprite2D/left_button

var mods = [
{"type":"Отсутствует","cost":0, "number":0},
{"type":"Вампиризм","cost":5,"number":2},
{"type":"Святость","cost":5,"number":3},
{"type":"Перегрузка","cost":50,"number":4}
]

var counter3 = 0

func _ready() -> void:
	mods_pictures.visible = false
	mod_description.text = ""
	
func _sprite_and_text():
	var mods_data = mods[counter3]
	var mod = mods_data.get("type")
	CombatState.mods_changed.emit(mods_data)
	mod_name.text = mods_data.get("type")
	mods_pictures.visible = true
	mods_pictures.play(mods_data.get("type"))
	
	match mod:
		"Отсутствует":
			mod_description.text = ""
		"Умножение":
			mod_description.text = "Наносит атаку 3 раза подряд."
		"Вампиризм":
			mod_description.text = "Восстанавливает 15% ХП от нанесенного урона."
		"Святость":
			mod_description.text = "Наносит дополнительный урон по феям ценой 10 ХП, но есть нюанс..."
		"Перегрузка":
			mod_description.text = "Умножает урон в 5 раз!"


func _on_left_button_pressed() -> void:
	CombatState.bounce_press(left_btn)
	CombatState.krutilkas_button.emit()
	counter3 += 1
	if counter3 > (mods.size() - 1):
		counter3 = 0	
	_sprite_and_text()
	
func _on_right_button_pressed() -> void:
	CombatState.bounce_press(right_btn)
	CombatState.krutilkas_button.emit()
	counter3 -= 1
	if counter3 < 0:
		counter3 = (mods.size() - 1)
	_sprite_and_text()
