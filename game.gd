extends Node2D

@onready var inventory = $Inventory_game

var inventory_open := false

func _ready() -> void:
	CombatState.inventory_closed.connect(_close_inventory)

func _input(event):
	if event is InputEventKey and event.keycode == KEY_I and event.pressed and not event.echo:
		if inventory_open:
			_close_inventory()
		else:
			_open_inventory()

func _open_inventory():
	inventory_open = true
	CombatState.is_busy = true
	CombatState.pop_in(inventory)

func _close_inventory():
	inventory_open = false
	CombatState.is_busy = false
	CombatState.pop_out(inventory)
	
