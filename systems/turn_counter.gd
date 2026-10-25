extends Control

func _process(_delta: float) -> void:
	$Sprite2D/Counter.text = str(CombatState.turn_number)
