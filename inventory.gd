extends Control

@onready var vbox = $item_bg/VBoxContainer
@onready var picture = $item_bg/item_pictures
@onready var description = $item_bg/descritpion
@onready var cancel = $Cancel_inventory
@onready var use = $Use_inventory
@onready var stats_text = $Stats_bg/Stats_text

var item_buttons = []
var selected_id = ""

func _ready() -> void:
	_update_items()


func _add_item(item_id: String, count: int):
	if CombatState.inventory.has(item_id):
		CombatState.inventory[item_id] += count
	else:
		CombatState.inventory[item_id] = count


func _use_item(item_id: String, count: int = 1):
	if not CombatState.inventory.has(item_id):
		return
	
	var item = CombatState.items_database[item_id]
	
	match item["effect"]:
		"heal":
			CombatState.hp_player += 25
			CombatState.hp_player = clamp(CombatState.hp_player, 0, CombatState.hp_player_max)
		"mana_restore":
			CombatState.mana_player += 25
			CombatState.mana_player = clamp(CombatState.mana_player, 0, CombatState.mana_player_max)
	
	CombatState.stress_status_changer()
	CombatState.inventory[item_id] -= count
	if CombatState.inventory[item_id] <= 0:
		CombatState.inventory.erase(item_id)
	
	selected_id = ""
	picture.play("none")
	
	_update_items()


func _update_items():
	for child in vbox.get_children():
		vbox.remove_child(child)
		child.queue_free()
	
	item_buttons.clear()
	
	stats_text.text = "Множитель крит урона: " + str(CombatState.player_crit) + "\nФизический урон: " + str(CombatState.normal_damage) + "\nУровень: " + str(CombatState.level_player) + "\nМножитель брони: " + str(CombatState.armor_player)


	for item_id in CombatState.inventory:
		var item_name = CombatState.items_database[item_id]["name"]
		var count = CombatState.inventory[item_id]
		
		var button = Button.new()
		_style_button(button)
		button.text = item_name + " — " + str(count) + " шт"
		button.pressed.connect(_on_item_clicked.bind(item_id))
		vbox.add_child(button)
		item_buttons.append(button)


func _on_item_clicked(item_id: String):
	selected_id = item_id
	picture.play(selected_id)
	_update_selection()
	
	match selected_id:
		"bandage":
			description.text = "Восстанавливает 25 ХП"
		"gum":
			description.text = "Восстанавливает 25 МП"

func _update_selection():
	for i in range(item_buttons.size()):
		var item_id = CombatState.inventory.keys()[i]
		if item_id == selected_id:
			item_buttons[i].modulate = Color.WHITE
		else:
			item_buttons[i].modulate = Color(0.5, 0.5, 0.5)

func _style_button(button: Button):
	var font = preload("res://ClickClack.ttf")
	
	var empty = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.447, 0.282, 0.125, 0.0)
	button.add_theme_stylebox_override("hover", hover)
	
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_outline_color", Color.BLACK)
	button.add_theme_constant_override("outline_size", 15)
	
	button.add_theme_color_override("font_color",  Color("9f7a65"))
	button.add_theme_color_override("font_hover_color", Color("e5d3c6ff"))
	button.add_theme_color_override("font_pressed_color", Color("9c8975ff"))
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("61503eff"))

func _on_button_pressed() -> void:
	_add_item("bandage", 1)
	_add_item("gum", 1)
	_update_items()

func _on_cancel_inventory_pressed() -> void:
	CombatState.bounce_press(cancel)
	await get_tree().create_timer(0.1).timeout
	CombatState.inventory_closed.emit()

func _on_use_inventory_pressed() -> void:
	CombatState.bounce_press(use)
	picture.play("none")
	description.text = ""
	await get_tree().create_timer(0.1).timeout
	_use_item(selected_id, 1)
	_update_items()
	CombatState.item_used.emit()
