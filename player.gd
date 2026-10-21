extends CharacterBody2D

const SPEED := 200.0
const ACCEL := 1000.0
const FRICTION := 1200.0

var is_walking = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var SFXplayer = $SFXplayer

var footsteps = preload("res://sfx/footstep.ogg")
var def_dir = "default"

func _ready():
	animated_sprite.frame_changed.connect(_on_animation_frame_changed)

func _physics_process(delta: float) -> void:
	if CombatState.is_busy:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		move_and_slide()
		is_walking = false
		play_idle_animation()
		return

	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * SPEED, ACCEL * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	move_and_slide()
	update_animation(direction)

func update_animation(input_dir):
	if input_dir != Vector2.ZERO:
		if not is_walking:
			SFXplayer.stream = footsteps
			SFXplayer.pitch_scale = randf_range(0.9, 1.1)
			SFXplayer.play()
		is_walking = true
		if input_dir.y < 0:      
			play_animation("walking_dorsi")
		elif input_dir.y > 0:    
			play_animation("walking_ventri")
		elif input_dir.x < 0:    
			play_animation("walking_left")
		elif input_dir.x > 0:    
			play_animation("walking_right")
	else:
		is_walking = false
		play_idle_animation()

func play_animation(anim_name):
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func play_idle_animation():
	var idle_anim = def_dir
	
	if animated_sprite.animation != idle_anim:
		animated_sprite.play(idle_anim)

func _on_animation_frame_changed():
	if is_walking == true and animated_sprite.frame % 2 == 0: 
		SFXplayer.stream = footsteps
		SFXplayer.pitch_scale = randf_range(0.9, 1.1)
		SFXplayer.play()
