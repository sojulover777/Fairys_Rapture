extends Node2D

@onready var all_name = $Witchcraft_choice/CoolAssBG/liltextbox/result_label
@onready var coolassbg = $Witchcraft_choice/CoolAssBG
@onready var persize_damage = $Witchcraft_choice/CoolAssBG/liltextbox/persize_damage
@onready var choice = $Control/player/choice
@onready var timer = $timer
@onready var timer_label = $timer/timer_label
@onready var enemy_hp_lvl = $Control/player/enemy_hp
@onready var info_text = $info_all/info_bg/info
@onready var info = $info_all/info_bg
@onready var SFXplayer = $SFXplayer
@onready var inventory = $inventory_control
@onready var player = $Control
@onready var level_up = $level_up
@onready var cancel = $Witchcraft_choice/CoolAssBG/cancel_button
@onready var witchcraft_choice = $Witchcraft_choice
@onready var info_all = $info_all
@onready var ready_btn = $Witchcraft_choice/CoolAssBG/ready_btn
@onready var litteral_inventory = $inventory_control/Inventory
@onready var inventory_cancel = $inventory_control/Inventory/inventory_cancel_button
@onready var status_sprite = $Control/player/HpBar/status_sprite
@onready var status_sprite_inventory = $inventory_control/Inventory/status_sprite_inventory
@onready var enemy_abilities = $EnemyAbilitiesNode

const HOLD_DURATION = 4.0
const TICK_INTERVAL = 1.0
const BASE_PITCH = 1.0
const MAX_PITCH = 2.0

var hold_time = 0.0
var last_tick_time = 0.0

var is_dead = false
var is_busy = false

var current_spell_name = ""
var current_element_name = ""
var current_mods_name = ""
var status_sprite_name = "neutral"
var current_spell_number = 0
var current_element_number = 0
var current_mods_number = 0
var current_mods_cost = 0
var current_player_defense = 1
var spell_damage = 0
var player_damage = 0
var random_player_damage = 0

# Элемент, которым игрок "стал" после последнего каста. Живёт до следующего каста. Именно он сравнивается с элементом врага.
var player_status = 1
var player_element_name = ""

var major = preload("res://sfx/attack_major.ogg")
var bile = preload("res://sfx/sword_bile.ogg")
var blood = preload("res://sfx/sword_blood.ogg")
var fire = preload("res://sfx/sword_fire.ogg")
var metal = preload("res://sfx/sword_metal.ogg")
var water = preload("res://sfx/sword_water.ogg")
var normal = preload("res://sfx/sword_normal.ogg")
var death = preload("res://sfx/DEATH.ogg")
var win = preload("res://sfx/win.ogg")
var button_pressed = preload("res://sfx/button_pressed.ogg")
var aegis = preload("res://sfx/aegis.ogg")
var krutilkas_button = preload("res://sfx/krutilkas_button.ogg")
var count_down = preload("res://sfx/count_down.ogg")
var final_chord = preload("res://sfx/final_chord.ogg")
var no = preload("res://sfx/no.ogg")

var strong_against = {
	1: [2, 4],
	2: [3, 5],
	3: [4, 1],
	4: [5, 2],
	5: [1, 3]
}

var weak_against = {
	1: [5, 3],
	2: [4, 1],
	3: [5, 3],
	4: [3, 1],
	5: [4, 2]
}


func _ready():
	CombatState.spell_changed.connect(_spell_changed)
	CombatState.element_changed.connect(_element_changed)
	CombatState.mods_changed.connect(_mods_changed)
	CombatState.normal_attack.connect(_normal_attack)
	CombatState.defense.connect(_defense_player)
	CombatState.witchcraft.connect(_on_witchcraft_pressed)
	CombatState.krutilkas_button.connect(_on_krutilka_pressed)
	CombatState.item_used.connect(_on_item_used)
	CombatState.item_pressed.connect(_on_item_pressed)
	CombatState.inventory_closed.connect(_on_inventory_closed)

	CombatState.load_support("вадим")

	CombatState.turn_number = 0
	CombatState.choise_visibility = false
	timer.visible = false
	inventory.visible = false
	info.visible = false
	is_dead = false
	is_busy = false

	player_status = CombatState.player_element
	if player_status == 0:
		player_status = 1
	player_element_name = ""

	status_sprite.play(status_sprite_name)
	status_sprite_inventory.play(status_sprite_name)

	$player_status.text = player_element_name

	if CombatState.current_enemy.is_empty():
		get_tree().change_scene_to_file("res://game.tscn")
		return

	_update_enemy_hp_display()
	_update_label()
	_update_choice_visibility()


func _process(delta: float) -> void:
	CombatState.hp_player = clamp(CombatState.hp_player, 0, CombatState.hp_player_max)
	CombatState.mana_player = clamp(CombatState.mana_player, 0, CombatState.mana_player_max)

	_update_choice_visibility()

	if Input.is_key_pressed(KEY_R):
		timer.visible = true
		timer_label.visible = true
		hold_time += delta
		timer_label.text = str(int(HOLD_DURATION - hold_time))

		if hold_time - last_tick_time >= TICK_INTERVAL:
			last_tick_time = hold_time
			var progress = hold_time / HOLD_DURATION
			SFXplayer.stream = count_down
			SFXplayer.pitch_scale = lerp(BASE_PITCH, MAX_PITCH, progress)
			SFXplayer.play()

		if hold_time >= HOLD_DURATION:
			if not is_busy:
				_exit_battle()
			else:
				hold_time = 0.0
				last_tick_time = 0.0
				timer.visible = false
	else:
		timer.visible = false
		if hold_time > 0:
			hold_time = 0.0
			last_tick_time = 0.0
			SFXplayer.pitch_scale = BASE_PITCH


func _update_choice_visibility():
	if CombatState.choise_visibility:
		choice.visible = false
	else:
		choice.visible = true


func _update_enemy_hp_display():
	var hp = CombatState.current_enemy["hp"]
	var max_hp = CombatState.current_enemy["max_hp"]
	enemy_hp_lvl.text = str(hp) + "/" + str(max_hp)


func _update_label():
	all_name.text = current_element_name + "+" + current_mods_name
	_player_damage_math()
	var cost = CombatState.get_spell_cost(current_spell_name)
	persize_damage.text = "урон = " + str(player_damage) + " | мана: " + str(cost + current_mods_cost)

	if current_spell_name != "" and CombatState.mana_player < cost + current_mods_cost:
		persize_damage.modulate = Color(1.0, 0.4, 0.4)
	else:
		persize_damage.modulate = Color(1.0, 1.0, 1.0)


func _player_damage_math():
	player_damage = spell_damage

	var enemy_element = CombatState.current_enemy.get("element", 0)

	if enemy_element in strong_against.get(current_element_number, []):
		player_damage = round(player_damage * 1.2)
	elif enemy_element in weak_against.get(current_element_number, []):
		player_damage = round(player_damage * 0.6)

	random_player_damage = randi_range(round(player_damage) - 10, round(player_damage) + 10)


func _spell_changed(spell_data):
	current_spell_name = spell_data.get("type")
	current_spell_number = spell_data.get("number")
	spell_damage = spell_data.get("damage")
	_update_label()


func _element_changed(element_data):
	CombatState.player_element = element_data.get("number")
	current_element_name = element_data.get("type")
	current_element_number = element_data.get("number")
	_update_label()


func _mods_changed(mods_data):
	current_mods_name = mods_data.get("type")
	current_mods_number = mods_data.get("number")
	current_mods_cost = mods_data.get("cost")
	_update_label()


func _on_ready_btn_pressed() -> void:
	await get_tree().create_timer(0.1).timeout
	if is_busy:
		return

	if current_spell_name == "" or current_element_name == "":
		SFXplayer.stream = no
		SFXplayer.pitch_scale = randf_range(0.9, 1.1)
		SFXplayer.play()
		return

	var spell_cost = CombatState.get_spell_cost(current_spell_name)
	if CombatState.mana_player < spell_cost:
		SFXplayer.stream = no
		SFXplayer.pitch_scale = randf_range(0.9, 1.1)
		SFXplayer.play()
		CombatState.pop_in(info_all)
		await get_tree().create_timer(0.1).timeout
		info.visible = true
		info_text.text = "не хватает маны (нужно " + str(spell_cost) + ")"
		await get_tree().create_timer(1.0).timeout
		CombatState.pop_out(info_all)
		info.visible = false
		return

	CombatState.mana_player -= spell_cost + current_mods_cost
	CombatState.mana_player = clamp(CombatState.mana_player, 0, CombatState.mana_player_max)

	player_status = current_element_number
	player_element_name = current_element_name
	
	match player_status:
		0:
			status_sprite_name = "neutral"
		1:
			status_sprite_name = "fire"
		2:
			status_sprite_name = "blood"
		3:
			status_sprite_name = "water"
		4:
			status_sprite_name = "metal"
		5:
			status_sprite_name = "bile"
			
	status_sprite.play(status_sprite_name)
	status_sprite_inventory.play(status_sprite_name)

	CombatState.bounce_press(ready_btn)
	CombatState.pop_out(witchcraft_choice)
	await get_tree().create_timer(0.1).timeout
	is_busy = true
	CombatState.choise_visibility = true
	coolassbg.visible = false

	SFXplayer.stream = major
	SFXplayer.pitch_scale = randf_range(0.9, 1.1)
	SFXplayer.play()

	CombatState.turn_number += 1
	_player_damage_math()

	if current_mods_number == 2:
		CombatState.hp_player += round(round(random_player_damage) * 15 / 100)
		CombatState.hp_player = clamp(CombatState.hp_player, 0, CombatState.hp_player_max)

	var local_crit_chance = randi_range(1, 100)

	CombatState.pop_in(info_all)
	await get_tree().create_timer(0.1).timeout
	info.visible = true

	if local_crit_chance <= CombatState.crit_chance_player:
		random_player_damage = round(random_player_damage * randf_range(1.3, 1.7))
		info_text.text = "ты опиздюлила (и кританула) врага на " + str(random_player_damage)
	else:
		info_text.text = "ты опиздюлила врага на " + str(random_player_damage)

	CombatState.current_enemy["hp"] -= random_player_damage
	CombatState.current_enemy["hp"] = clamp(
		CombatState.current_enemy["hp"],
		0,
		CombatState.current_enemy["max_hp"]
	)

	player_damage = 0
	random_player_damage = 0

	_update_enemy_hp_display()
	$player_status.text = player_element_name
	_update_label()

	await get_tree().create_timer(2.0).timeout

	if CombatState.current_enemy["hp"] <= 0:
		_enemy_die()
		return

	_support_turn()


func _normal_attack(normal_damage) -> void:
	await get_tree().create_timer(0.1).timeout
	if is_busy:
		return

	is_busy = true
	CombatState.choise_visibility = true

	var random_normal_damage = randi_range(normal_damage - 10, normal_damage + 10)

	# Броня врага
	var enemy_defense = CombatState.current_enemy.get("defense", 1.0)
	random_normal_damage = round(random_normal_damage * enemy_defense)

	# --- КРИТ ИГРОКА ---
	var local_crit_chance = randi_range(1, 100)

	CombatState.pop_in(info_all)
	await get_tree().create_timer(0.1).timeout
	info.visible = true

	if local_crit_chance <= CombatState.crit_chance_player:
		random_normal_damage = round(random_normal_damage * randf_range(1.3, 1.7))
		info_text.text = "ты скучно опиздюлила (и кританула) врага на " + str(random_normal_damage)
	else:
		info_text.text = "ты скучно опиздюлила врага на " + str(random_normal_damage)

	CombatState.current_enemy["hp"] -= random_normal_damage
	CombatState.current_enemy["hp"] = clamp(
		CombatState.current_enemy["hp"],
		0,
		CombatState.current_enemy["max_hp"]
	)


	CombatState.turn_number += 1
	_update_enemy_hp_display()

	if CombatState.current_enemy["hp"] <= 0:
		_enemy_die()
		return

	var enemy_element = CombatState.current_enemy["element"]

	if enemy_element == 1:
		SFXplayer.stream = fire
	elif enemy_element == 2:
		SFXplayer.stream = blood
	elif enemy_element == 3:
		SFXplayer.stream = water
	elif enemy_element == 4:
		SFXplayer.stream = metal
	else:
		SFXplayer.stream = bile

	SFXplayer.pitch_scale = randf_range(0.9, 1.1)
	SFXplayer.play()
	await get_tree().create_timer(1.0).timeout

	_support_turn()


func _defense_player(armor) -> void:
	await get_tree().create_timer(0.1).timeout
	if is_busy:
		return

	is_busy = true
	CombatState.choise_visibility = true

	SFXplayer.stream = aegis
	SFXplayer.pitch_scale = randf_range(0.9, 1.1)
	SFXplayer.play()

	CombatState.pop_in(info_all)
	await get_tree().create_timer(0.1).timeout
	info.visible = true

	current_player_defense = clamp(armor, 0.1, 1.0)
	CombatState.turn_number += 1
	info_text.text = "ты юзанул защиту"

	CombatState.mana_player += round(randf_range(5, 10))
	CombatState.mana_player = clamp(CombatState.mana_player, 0, CombatState.mana_player_max)

	await get_tree().create_timer(1.5).timeout

	_support_turn()


func _support_turn():
	is_busy = false

	var support = CombatState.current_support
	support["support_stuff"].call()

	if CombatState.current_support.is_empty():
		_enemy_turn()
		return

	var support_chance = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].pick_random()
	var support_damage = round(randi_range(
		CombatState.normal_damage * CombatState.current_support["attack_modificator"] - 10,
		CombatState.normal_damage * CombatState.current_support["attack_modificator"] + 10
	))

	if support_chance <= 4:
		info_text.text = str(CombatState.current_support["name"]) + " подумал-подумал и нихуя не сделал"
		await get_tree().create_timer(1.0).timeout
		_enemy_turn()

	elif support_chance >= 5 and support_chance <= 8:
		CombatState.current_enemy["hp"] -= support_damage
		CombatState.current_enemy["hp"] = clamp(
			CombatState.current_enemy["hp"],
			0,
			CombatState.current_enemy["max_hp"]
		)
		info_text.text = str(CombatState.current_support["name"]) + " атаковал на " + str(support_damage)
		_update_enemy_hp_display()
		await get_tree().create_timer(1.0).timeout

		if CombatState.current_enemy["hp"] <= 0:
			_enemy_die()
			return

		_enemy_turn()

	elif support_chance >= 9:
		var spell_chance = [1, 2].pick_random()

		if spell_chance == 1:
			var abilities = CombatState.current_support.get("abilities")
			var ability = abilities[1]
			ability.call()
			var sfx_support = CombatState.current_support.get("sfx")
			var current_sfx_support = sfx_support[1]
			SFXplayer.stream = current_sfx_support
			SFXplayer.play()
			info_text.text = CombatState.support_abilitie_description
			await get_tree().create_timer(1.0).timeout
			_enemy_turn()
		elif spell_chance == 2:
			var abilities = CombatState.current_support.get("abilities")
			var ability = abilities[0]
			ability.call()
			var sfx_support = CombatState.current_support.get("sfx")
			var current_sfx_support = sfx_support[0]
			SFXplayer.stream = current_sfx_support
			SFXplayer.play()
			info_text.text = CombatState.support_abilitie_description
			await get_tree().create_timer(1.0).timeout
			_enemy_turn()

	if CombatState.current_enemy["hp"] <= 0:
		_enemy_die()
		return


func _enemy_turn():
	
	if CombatState.enemy_skip_turn:
		CombatState.enemy_skip_turn = false
		await get_tree().create_timer(1.0).timeout
		inventory.visible = false
		is_busy = false
		CombatState.pop_out(info_all)
		await get_tree().create_timer(0.1).timeout
		info.visible = false
		CombatState.choise_visibility = false
		_update_choice_visibility()
		CombatState.mana_player += 3
		CombatState.mana_player = clamp(CombatState.mana_player, 0, CombatState.mana_player_max)
		return

	if CombatState.mana_debuff_turns > 0 and randi_range(1, 100) <= 100: #не работает проверка, почини
		var abilities = CombatState.current_enemy.get("abilities", [])
	
		if not abilities.is_empty():
			var chosen_ability = abilities.pick_random()
			CombatState.call(chosen_ability)
			
		CombatState.turn_number += 1
		SFXplayer.stream = no
		SFXplayer.pitch_scale = randf_range(0.9, 1.1)
		SFXplayer.play()
		info.visible = true
		info_text.text = "наложили ужас"
		await get_tree().create_timer(1.5).timeout

		CombatState.choise_visibility = false
		is_busy = false
		CombatState.pop_out(info_all)
		await get_tree().create_timer(0.1).timeout
		info.visible = false
		_update_choice_visibility()
		return

	var enemy_damage = round(randi_range(
		CombatState.current_enemy["attack"] - 10,
		CombatState.current_enemy["attack"] + 10
	) * current_player_defense)

	var enemy_element = CombatState.current_enemy.get("element", 0)

	if player_status in strong_against.get(enemy_element, []):
		enemy_damage = round(enemy_damage * 1.5)
	elif player_status in weak_against.get(enemy_element, []):
		enemy_damage = round(enemy_damage * 0.5)

	var local_enemy_crit_chance = randi_range(1, 100)

	if local_enemy_crit_chance <= CombatState.crit_chance_enemy:
		enemy_damage = round(enemy_damage * randf_range(1.3, 1.7))
		info_text.text = "враг опиздюлил (и кританул) тебя на " + str(enemy_damage)
	else:
		info_text.text = "враг опиздюлил тебя на " + str(enemy_damage)

	CombatState.hp_player -= enemy_damage
	CombatState.hp_player = clamp(CombatState.hp_player, 0, CombatState.hp_player_max)

	current_player_defense = 1
	CombatState.turn_number += 1

	SFXplayer.stream = normal
	SFXplayer.pitch_scale = randf_range(0.9, 1.1)
	SFXplayer.play()
	await get_tree().create_timer(1.5).timeout

	CombatState.choise_visibility = false
	is_busy = false

	CombatState.pop_out(info_all)
	await get_tree().create_timer(0.1).timeout
	info.visible = false
	_update_choice_visibility()

	CombatState.tick_mana_debuff()

	if CombatState.hp_player <= 0:
		_player_death()


func _enemy_die():
	CombatState.pop_out(player)
	await get_tree().create_timer(0.1).timeout
	player.visible = false

	info.visible = true
	CombatState.choise_visibility = false
	_update_choice_visibility()
	is_busy = false

	SFXplayer.stream = win
	SFXplayer.pitch_scale = randf_range(0.9, 1.1)
	SFXplayer.play()
	info_text.text = "ты победил"
	CombatState.current_enemy["is_alive"] = false

	CombatState.mana_player = CombatState.mana_player_max

	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://game.tscn")


func _player_death():
	CombatState.pop_out(player)
	await get_tree().create_timer(0.1).timeout
	player.visible = false

	info.visible = true
	CombatState.choise_visibility = false
	_update_choice_visibility()
	is_busy = false

	SFXplayer.stream = death
	SFXplayer.pitch_scale = randf_range(0.9, 1.1)
	SFXplayer.play()
	info_text.text = "ты проиграл"
	await get_tree().create_timer(1.5).timeout
	CombatState.hp_player = CombatState.hp_player_max * 0.5
	CombatState.mana_player = CombatState.mana_player_max * 0.5
	get_tree().change_scene_to_file("res://death_screen.tscn")


func _on_cancel_button_pressed() -> void:
	SFXplayer.stream = button_pressed
	SFXplayer.pitch_scale = randf_range(0.9, 1.1)
	SFXplayer.play()
	CombatState.bounce_press(cancel)
	CombatState.pop_out(witchcraft_choice)
	await get_tree().create_timer(0.15).timeout
	CombatState.choise_visibility = false
	coolassbg.visible = false
	_update_choice_visibility()


func _on_witchcraft_pressed():
	SFXplayer.stream = button_pressed
	SFXplayer.pitch_scale = randf_range(0.9, 1.1)
	SFXplayer.play()
	CombatState.pop_in(witchcraft_choice)
	await get_tree().create_timer(0.1).timeout
	info.visible = false
	coolassbg.visible = true


func _on_krutilka_pressed():
	SFXplayer.stream = krutilkas_button
	SFXplayer.pitch_scale = randf_range(0.9, 1.1)
	SFXplayer.play()


func _exit_battle() -> void:
	CombatState.choise_visibility = false
	get_tree().change_scene_to_file("res://game.tscn")


func _on_item_used() -> void:
	SFXplayer.stream = button_pressed
	SFXplayer.pitch_scale = randf_range(0.9, 1.1)
	SFXplayer.play()
	CombatState.turn_number += 1

	CombatState.pop_in(info_all)
	CombatState.pop_out(litteral_inventory)
	CombatState.pop_out(inventory)
	await get_tree().create_timer(0.1).timeout
	info.visible = true
	player.visible = true
	is_busy = false
	inventory.visible = false
	_support_turn()


func _on_item_pressed() -> void:
	await get_tree().create_timer(0.1).timeout
	SFXplayer.stream = button_pressed
	SFXplayer.pitch_scale = randf_range(0.9, 1.1)
	SFXplayer.play()
	if is_busy:
		return
	CombatState.pop_out(player)
	player.visible = false
	info.visible = false
	is_busy = true
	CombatState.choise_visibility = true
	CombatState.pop_in(litteral_inventory)
	CombatState.pop_in(inventory)
	await get_tree().create_timer(0.1).timeout
	inventory.visible = true


func _on_inventory_closed() -> void:
	SFXplayer.stream = button_pressed
	SFXplayer.pitch_scale = randf_range(0.9, 1.1)
	SFXplayer.play()
	CombatState.pop_out(litteral_inventory)
	CombatState.pop_out(inventory)
	is_busy = false
	info.visible = false
	await get_tree().create_timer(0.1).timeout
	CombatState.pop_in(player)
	player.visible = true
	inventory.visible = false
	CombatState.choise_visibility = false
