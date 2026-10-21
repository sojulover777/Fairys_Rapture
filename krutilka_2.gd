extends Control

var elements = [
	{"type":"Огонь","number":1},
	{"type":"Кровь","number":2},
	{"type":"Вода","number":3},
	{"type":"Металл","number":4},
	{"type":"Желчь","number":5}
]

@onready var right_btn = $Sprite2D/right_button
@onready var left_btn = $Sprite2D/left_button

var counter2 = 0

func _ready() -> void:
	$Sprite2D/AnimatedSprite2D.visible = false
	$Sprite2D/element_name/element_description.text = ""

func _sprite_and_text() -> void:  
	var element_data = elements[counter2]
	var element = element_data.get("type")
	CombatState.element_changed.emit(element_data)
	$Sprite2D/element_name.text = element_data.get("type")
	$Sprite2D/AnimatedSprite2D.visible = true
	$Sprite2D/AnimatedSprite2D.play(element_data.get("type"))
	
	match element:
		"Кровь":
			$Sprite2D/element_name/element_description.text = "Пластична и податлива,центр жизни всего сущего."
		"Огонь":
			$Sprite2D/element_name/element_description.text = "Страсть, уничтожающая саму себя,но дающая свет во тьме."
		"Вода":
			$Sprite2D/element_name/element_description.text = "Двуликая стихия,что создаёт и разрушает."
		"Желчь":
			$Sprite2D/element_name/element_description.text = "Горькое подобие стихии,не обладающее формой."
		"Металл":
			$Sprite2D/element_name/element_description.text = "Холодный и упрямый,металл не знает пощады."

func _on_left_button_pressed() -> void:
	CombatState.bounce_press(left_btn)
	CombatState.krutilkas_button.emit()
	counter2 -= 1
	if counter2 < 0:
		counter2 = (elements.size() - 1)
	_sprite_and_text()

func _on_right_button_pressed() -> void:
	CombatState.bounce_press(right_btn)
	CombatState.krutilkas_button.emit()
	counter2 += 1
	if counter2 > (elements.size() - 1):
		counter2 = 0
	_sprite_and_text()
