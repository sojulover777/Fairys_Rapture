extends Control

func _process(delta: float) -> void:
	$Sprite2D/Counter.text = str(CombatState.turn_number)
