extends Node2D

@onready var impact_sprite = $ImpactSprite
@onready var particles = $Blood

func _ready() -> void:

	impact_sprite.play("default") 
	
	# 2. Включаем партиклы
	particles.emitting = true
	
	# 3. Ждем, пока закончится анимация импакта
	await impact_sprite.animation_finished
	
	# 4. Даем партиклам догореть (ждем время их жизни + запас)
	await get_tree().create_timer(particles.lifetime + 0.2).timeout
	
	# 5. Удаляем эффект из памяти
	queue_free()
