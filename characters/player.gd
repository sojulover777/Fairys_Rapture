extends CharacterBody2D

@export var walk_speed = 200.0
@export var run_speed = 400.0
@export var accel = 1500.0    
@export var friction = 2500.0

var is_walking = false
var last_direction = "ventri" 

@onready var animated_sprite = $AnimatedSprite2D
@onready var SFXplayer = $SFXplayer

var footsteps = preload("res://sfx/footstep.ogg")

func _ready():
	animated_sprite.frame_changed.connect(_on_animation_frame_changed)

func _physics_process(delta: float) -> void:
	
	if CombatState.is_busy:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		is_walking = false
		play_idle_animation()
		return

	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	var current_target_speed = walk_speed
	if Input.is_physical_key_pressed(KEY_Z):
		current_target_speed = run_speed

	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * current_target_speed, accel * delta)

		if direction.y < 0: last_direction = "dorsi"
		elif direction.y > 0: last_direction = "ventri"
		elif direction.x < 0: last_direction = "left"
		elif direction.x > 0: last_direction = "right"
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	update_animation(direction)

func update_animation(input_dir):
	
	if input_dir != Vector2.ZERO:
		is_walking = true
		
		if Input.is_physical_key_pressed(KEY_Z):
			animated_sprite.speed_scale = 2.0
		else:
			animated_sprite.speed_scale = 1.0
			
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
	var idle_anim = "idle_" + last_direction
	
	if not animated_sprite.sprite_frames.has_animation(idle_anim):
		idle_anim = "default"
		
	if animated_sprite.animation != idle_anim:
		animated_sprite.play(idle_anim)

func _on_animation_frame_changed():
	if is_walking and animated_sprite.frame % 2 == 0:
		SFXplayer.stream = footsteps
		SFXplayer.pitch_scale = randf_range(0.9, 1.1)
		SFXplayer.play()
