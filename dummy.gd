extends Area2D

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	animated_sprite.play("default")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		CombatState.load_enemy("педобир")
		get_tree().change_scene_to_file("res://battle.tscn")
	else:
		print("some kind of a bug?")
