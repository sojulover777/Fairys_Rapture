extends Control

var display_hp = 0
var display_mana = 0


func _ready() -> void:
	display_hp = CombatState.hp_player
	display_mana = CombatState.mana_player


func _process(delta: float) -> void:
	if display_hp != CombatState.hp_player:
		display_hp = move_toward(display_hp, CombatState.hp_player, 100 * delta)
	
	if display_mana != CombatState.mana_player:
		display_mana = move_toward(display_mana, CombatState.mana_player, 100 * delta)
	
	$Hp.value = display_hp
	$Hp.max_value = CombatState.hp_player_max
	$Mana.value = display_mana
	$Mana.max_value = CombatState.mana_player_max
	
	$hp_text.text = str(int(CombatState.hp_player))
	$hp_max_text.text = str(int(CombatState.hp_player_max))
	$mp_text.text = str(int(CombatState.mana_player))
	$mp_max_text.text = str(int(CombatState.mana_player_max))
