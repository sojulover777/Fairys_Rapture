extends Control

@onready var hp_bar = $Hp
@onready var hp_delay_bar = $Hp_delay_bar
@onready var mana_bar = $Mana
@onready var mana_delay_bar = $Mana_delay_bar 

@onready var hp_text = $hp_text
@onready var hp_max_text = $hp_max_text
@onready var mp_text = $mp_text
@onready var mp_max_text = $mp_max_text
@onready var stress_status = $Poebalo

var display_hp = 0.0
var display_hp_delay = 0.0
var display_mana = 0.0
var display_mana_delay = 0.0

func _ready() -> void:
	display_hp = CombatState.hp_player
	display_hp_delay = CombatState.hp_player
	
	display_mana = CombatState.mana_player
	display_mana_delay = CombatState.mana_player

func _process(delta: float) -> void:
	_update_hp_logic(delta)
	_update_mana_logic(delta)
	stress_status.play(CombatState.stress)
	

func _update_hp_logic(delta: float) -> void:
	if display_hp != CombatState.hp_player:
		display_hp = move_toward(display_hp, CombatState.hp_player, 150 * delta)
	
	if CombatState.hp_player > display_hp_delay:
		display_hp_delay = CombatState.hp_player
	elif display_hp_delay > display_hp:
		display_hp_delay = move_toward(display_hp_delay, display_hp, 40 * delta)
	
	hp_bar.max_value = CombatState.hp_player_max
	hp_bar.value = display_hp
	
	hp_delay_bar.max_value = CombatState.hp_player_max
	hp_delay_bar.value = display_hp_delay
	
	hp_text.text = str(int(display_hp))
	hp_max_text.text = str(int(CombatState.hp_player_max))

func _update_mana_logic(delta: float) -> void:
	if display_mana != CombatState.mana_player:
		display_mana = move_toward(display_mana, CombatState.mana_player, 150 * delta)
	
	if CombatState.mana_player > display_mana_delay:
		display_mana_delay = CombatState.mana_player
	elif display_mana_delay > display_mana:
		display_mana_delay = move_toward(display_mana_delay, display_mana, 40 * delta)
	
	mana_bar.max_value = CombatState.mana_player_max
	mana_bar.value = display_mana
	
	mana_delay_bar.max_value = CombatState.mana_player_max
	mana_delay_bar.value = display_mana_delay
	
	mp_text.text = str(int(display_mana))
	mp_max_text.text = str(int(CombatState.mana_player_max))
