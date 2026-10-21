extends Control

# Используем @onready для кэширования узлов (работает быстрее)
@onready var hp_bar = $Hp
@onready var hp_delay_bar = $Hp_delay_bar# Новая полоска задержки ХП
@onready var mana_bar = $Mana
@onready var mana_delay_bar = $Mana_delay_bar # Новая полоска задержки Маны (если нужна)

@onready var hp_text = $hp_text
@onready var hp_max_text = $hp_max_text
@onready var mp_text = $mp_text
@onready var mp_max_text = $mp_max_text

var display_hp = 0.0
var display_hp_delay = 0.0
var display_mana = 0.0
var display_mana_delay = 0.0

func _ready() -> void:
	# Инициализируем все значения при старте
	display_hp = CombatState.hp_player
	display_hp_delay = CombatState.hp_player
	
	display_mana = CombatState.mana_player
	display_mana_delay = CombatState.mana_player

func _process(delta: float) -> void:
	_update_hp_logic(delta)
	_update_mana_logic(delta)

func _update_hp_logic(delta: float) -> void:
	# 1. Основная полоска ХП (быстро реагирует)
	if display_hp != CombatState.hp_player:
		display_hp = move_toward(display_hp, CombatState.hp_player, 150 * delta)
	
	# 2. Логика отстающей полоски ХП
	if CombatState.hp_player > display_hp_delay:
		# Если игрока вылечили, отстающая полоска МГНОВЕННО прыгает вверх
		display_hp_delay = CombatState.hp_player
	elif display_hp_delay > display_hp:
		# Если игрок получил урон, полоска плавно и медленно ползет вниз
		display_hp_delay = move_toward(display_hp_delay, display_hp, 40 * delta)
	
	# 3. Применяем значения к узлам
	hp_bar.max_value = CombatState.hp_player_max
	hp_bar.value = display_hp
	
	hp_delay_bar.max_value = CombatState.hp_player_max
	hp_delay_bar.value = display_hp_delay
	
	# 4. Обновляем текст (ВАЖНО: используем display_hp, чтобы цифры плавно уменьшались)
	hp_text.text = str(int(display_hp))
	hp_max_text.text = str(int(CombatState.hp_player_max))

func _update_mana_logic(delta: float) -> void:
	# 1. Основная полоска Маны
	if display_mana != CombatState.mana_player:
		display_mana = move_toward(display_mana, CombatState.mana_player, 150 * delta)
	
	# 2. Логика отстающей полоски Маны
	if CombatState.mana_player > display_mana_delay:
		display_mana_delay = CombatState.mana_player
	elif display_mana_delay > display_mana:
		display_mana_delay = move_toward(display_mana_delay, display_mana, 40 * delta)
	
	# 3. Применяем значения
	mana_bar.max_value = CombatState.mana_player_max
	mana_bar.value = display_mana
	
	mana_delay_bar.max_value = CombatState.mana_player_max
	mana_delay_bar.value = display_mana_delay
	
	# 4. Текст маны
	mp_text.text = str(int(display_mana))
	mp_max_text.text = str(int(CombatState.mana_player_max))
