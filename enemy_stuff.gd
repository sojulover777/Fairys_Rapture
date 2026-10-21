class_name EnemyAbilities
extends Control

func horror() -> void:
	CombatState.turn_local = CombatState.turn_number + 2
	CombatState.is_ticking = true
	
	CombatState.mana_debuff_percent = 0.5
	CombatState.mana_debuff_turns = 2
	CombatState.recalc_mana_max()
	print("УЖАС! Мана сожжена на 2 хода.")


	
