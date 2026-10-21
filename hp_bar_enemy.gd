extends Control

@onready var hp_bar = $Hp
@onready var hp_delay_bar = $Hp_delay_bar
@onready var hp_text = $hp_text
@onready var hp_max_text = $l/hp_max_text
@onready var enemy_name = $Label

var display_hp: float = 0.0
var display_delay_hp: float = 0.0
var current_max_hp: float = 100.0

# Скорости анимации (подберите под свой вкус)
var hp_speed = 200.0
var delay_speed = 80.0

func _ready() -> void:
	# Если данных о враге нет (например, мы зашли в бой напрямую из редактора)
	if CombatState.current_enemy.is_empty():
		return
	enemy_name.text = CombatState.current_enemy.get("name", "null")

	current_max_hp = CombatState.current_enemy.get("max_hp", 100)
	display_hp = CombatState.current_enemy.get("hp", 0)
	display_delay_hp = display_hp
	
	hp_bar.max_value = current_max_hp
	hp_delay_bar.max_value = current_max_hp
	
	hp_bar.value = display_hp
	hp_delay_bar.value = display_delay_hp
	
	_update_text(display_hp, current_max_hp)

func _process(delta: float) -> void:
	if CombatState.current_enemy.is_empty():
		return
		
	var real_hp = float(CombatState.current_enemy.get("hp", 0))
	var real_max = float(CombatState.current_enemy.get("max_hp", 100))
	
	# Если врага поменяли прямо в бою (например, вторая фаза)
	if real_max != current_max_hp:
		current_max_hp = real_max
		hp_bar.max_value = current_max_hp
		hp_delay_bar.max_value = current_max_hp
		display_hp = real_hp
		display_delay_hp = real_hp
		_update_text(real_hp, real_max)
		return

	# 1. Основная полоска (падает/растет быстро)
	if display_hp != real_hp:
		display_hp = move_toward(display_hp, real_hp, hp_speed * delta)
		hp_bar.value = display_hp
		_update_text(display_hp, real_max)

	# 2. Полоска задержки (ползет медленно)
	# Если реальное HP стало больше (например, врага вылечили), 
	# то полоска задержки тоже должна быстро подняться
	if real_hp > display_delay_hp:
		display_delay_hp = real_hp
		hp_delay_bar.value = display_delay_hp
		
	# Если ХП меньше, начинаем отставать
	elif display_delay_hp > display_hp:
		display_delay_hp = move_toward(display_delay_hp, display_hp, delay_speed * delta)
		hp_delay_bar.value = display_delay_hp
	else:
		display_delay_hp = display_hp
		hp_delay_bar.value = display_delay_hp

func _update_text(hp: float, max_hp: float):
	hp_text.text = str(int(hp))
	hp_max_text.text = str(int(max_hp))
	
	# Меняем цвет текста при низком ХП
	if hp / max_hp <= 0.2:
		hp_text.modulate = Color(1.0, 0.3, 0.3) # Болезненный красный
		hp_max_text.modulate = Color(1.0, 0.3, 0.3)
	else:
		hp_text.modulate = Color(1.0, 1.0, 1.0) # Обычный
		hp_max_text.modulate = Color(1.0, 1.0, 1.0)
