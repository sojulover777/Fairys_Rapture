extends Area2D

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	animated_sprite.play("default")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		CombatState.load_enemy("Педотрамп")
		get_tree().change_scene_to_file.call_deferred("res://systems/battle.tscn")
	else:
		print("some kind of a bug?")
