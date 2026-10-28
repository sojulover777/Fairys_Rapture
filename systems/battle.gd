extends Node2D

@onready var coolassbg = $Witchcraft_choice/CoolAssBG
@onready var persize_damage = $Witchcraft_choice/CoolAssBG/liltextbox/persize_damage
@onready var choice = $Control/player/choice
@onready var timer = $timer
@onready var timer_label = $timer/timer_label
@onready var info_text = $CanvasGroup/info_all/info_bg/info
@onready var info = $CanvasGroup/info_all/info_bg
@onready var SFXplayer = $SFXplayer
@onready var inventory = $inventory_control
@onready var player = $Control
@onready var cancel = $Witchcraft_choice/CoolAssBG/cancel_button
@onready var witchcraft_choice = $Witchcraft_choice
@onready var info_all = $CanvasGroup/info_all
@onready var ready_btn = $Witchcraft_choice/CoolAssBG/ready_btn
@onready var litteral_inventory = $inventory_control/Inventory
@onready var status_sprite = $Control/player/HpBar/status_sprite
@onready var status_sprite_inventory = $inventory_control/Inventory/status_sprite_inventory
@onready var lin_lin = $Control/player/AnimatedSprite2D
@onready var enemy_sprite: CanvasItem = $Control/player/pedobear

const HOLD_DURATION = 4.0
const TICK_INTERVAL = 1.0
const BASE_PITCH = 1.0
const MAX_PITCH = 2.0

var hold_time = 0.0
var last_tick_time = 0.0

var is_dead = false
var first_death = true 
var is_busy = false 
var player_damaged = false
var player_attack = false

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

var blood_particles = preload("res://systems/blood_impact.tscn")

var strong_against = { 1: [2, 4], 2: [3, 5], 3: [4, 1], 4: [5, 2], 5: [1, 3] }
var weak_against = { 1: [5, 3], 2: [4, 1], 3: [5, 3], 4: [3, 1], 5: [4, 2] }


func _ready():
	print("\n=== [БОЙ НАЧАЛСЯ] ===")
	
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
	
	lin_lin.animation_finished.connect(_on_lin_lin_animation_finished)

	CombatState.load_support("вадим")
	CombatState.turn_number = 0
	CombatState.choise_visibility = false
	
	timer.visible = false
	inventory.visible = false
	info.visible = false
	is_dead = false
	is_busy = false

	player_status = CombatState.player_element
	if player_status == 0: player_status = 1
	player_element_name = ""

	status_sprite.play(status_sprite_name)
	status_sprite_inventory.play(status_sprite_name)
	lin_lin.play("idle")

	if CombatState.current_enemy.is_empty():
		print("[DEBUG] Враг пустой! Выход на карту.")
		get_tree().change_scene_to_file.call_deferred("res://game.tscn")
		return
	
	_enemy_ai()
	_update_label()
	_update_choice_visibility()
	print("=== [ХОД ИГРОКА] ===")


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
	choice.visible = not CombatState.choise_visibility

func _update_label():
	_player_damage_math()
	var cost = CombatState.get_spell_cost(current_spell_name)
	persize_damage.text = "урон = " + str(player_damage) + "\nмана = " + str(cost + current_mods_cost)

	if current_spell_name != "" and CombatState.mana_player < cost + current_mods_cost:
		persize_damage.modulate = Color(1.0, 0.4, 0.4)
	else:
		persize_damage.modulate = Color(1.0, 1.0, 1.0)

func _player_damage_math():
	player_damage = spell_damage
	var enemy_element = CombatState.enemy_element

	if enemy_element in strong_against.get(current_element_number, []):
		player_damage = round(player_damage * 1.2)
	elif enemy_element in weak_against.get(current_element_number, []):
		player_damage = round(player_damage * 0.6)

	random_player_damage = round(randi_range(round(player_damage) - 10, round(player_damage) + 10) * CombatState.stress_damage_mod)


# --- СИГНАЛЫ ---

func _spell_changed(spell_data):
	current_spell_name = spell_data.get("type")
	current_spell_number = spell_data.get("number")
	spell_damage = spell_data.get("damage")
	print("[DEBUG] Выбрано заклинание: ", current_spell_name, " (Урон: ", spell_damage, ")")
	_update_label()

func _element_changed(element_data):
	CombatState.player_element = element_data.get("number")
	current_element_name = element_data.get("type")
	current_element_number = element_data.get("number")
	print("[DEBUG] Выбран элемент: ", current_element_name, " (Номер: ", current_element_number, ")")
	_update_label()

func _mods_changed(mods_data):
	current_mods_name = mods_data.get("type")
	current_mods_number = mods_data.get("number")
	current_mods_cost = mods_data.get("cost")
	print("[DEBUG] Выбран модификатор: ", current_mods_name)
	_update_label()


func _enemy_ai():
	var enemy_elements = CombatState.current_enemy.get("element", [1])
	
	if not (enemy_elements is Array):
		enemy_elements = [enemy_elements]
		
	var good_elements = []
	
	for el in enemy_elements:
		var is_weak = player_status in weak_against.get(el, [])
		if not is_weak:
			good_elements.append(el)
	
	if not good_elements.is_empty():
		CombatState.enemy_element = good_elements.pick_random()
	else:
		CombatState.enemy_element = enemy_elements.pick_random()
	print("[AI] Враг выбрал стихию: ", CombatState.enemy_element)


# --- АНИМАЦИИ ---

func _player_animation():
	if player_damaged:
		print("[ANIM] Лин Лин получает урон -> анимация 'damage'") 
		lin_lin.play("damage")
		
		await get_tree().create_timer(0.5).timeout 
		_spawn_blood(lin_lin.global_position, -1.0)
		flash_sprite(lin_lin, Color.RED)
		SFXplayer.stream = normal
		SFXplayer.play()
		await get_tree().create_timer(0.5).timeout 
		_on_lin_lin_animation_finished()
		
	elif player_attack:
		print("[ANIM] Лин Лин атакует -> анимация 'attack'") 
		lin_lin.play("attack")
		flash_sprite(lin_lin, Color.DEEP_PINK)
		await get_tree().create_timer(1.25).timeout 
		_on_lin_lin_animation_finished()

func _on_lin_lin_animation_finished():
	player_damaged = false
	player_attack = false
	if lin_lin.animation == "attack" or lin_lin.animation == "damage":
		print("[ANIM] Анимация ", lin_lin.animation, " завершилась. Возврат в 'idle'.")
		lin_lin.play("idle")

func _enemy_animation():
	flash_sprite(enemy_sprite, Color.RED)
	_spawn_blood(enemy_sprite.global_position, 1.0) #задатки на полноценную анимацию противника

# --- ДЕЙСТВИЯ ИГРОКА ---

func _on_ready_btn_pressed() -> void:
	await get_tree().create_timer(0.1).timeout
	if is_busy: return

	if current_spell_name == "" or current_element_name == "":
		SFXplayer.stream = no
		SFXplayer.play()
		print("[DEBUG] Не выбрано заклинание или элемент!")
		return

	var spell_cost = CombatState.get_spell_cost(current_spell_name)
	if CombatState.mana_player < spell_cost:
		SFXplayer.stream = no
		SFXplayer.play()
		CombatState.pop_in(info_all)
		await get_tree().create_timer(0.1).timeout
		info.visible = true
		await get_tree().create_timer(1.0).timeout
		CombatState.pop_out(info_all)
		info.visible = false
		print("[DEBUG] Не хватает маны! Нужно: ", spell_cost, ", есть: ", CombatState.mana_player)
		return

	CombatState.mana_player -= spell_cost + current_mods_cost
	CombatState.mana_player = clamp(CombatState.mana_player, 0, CombatState.mana_player_max)
	print("[DEBUG] Игрок кастует. Осталось маны: ", CombatState.mana_player)

	player_status = current_element_number
	player_element_name = current_element_name
	
	match player_status:
		0: status_sprite_name = "neutral"
		1: status_sprite_name = "fire"
		2: status_sprite_name = "blood"
		3: status_sprite_name = "water"
		4: status_sprite_name = "metal"
		5: status_sprite_name = "bile"
			
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

	player_attack = true
	_player_animation()

	CombatState.turn_number += 1
	_player_damage_math()
	CombatState.stress_status_changer()

	if current_mods_number == 2:
		CombatState.hp_player += round(round(random_player_damage) * 15 / 100)
		CombatState.hp_player = clamp(CombatState.hp_player, 0, CombatState.hp_player_max)
		print("[DEBUG] Сработал модификатор лечения!")

	var local_crit_chance = randi_range(1, 100)
	CombatState.pop_in(info_all)
	await get_tree().create_timer(0.1).timeout
	info.visible = true

	if local_crit_chance <= CombatState.crit_chance_player:
		random_player_damage = round(random_player_damage * randf_range(1.3, 1.7))
		info_text.text = "ты опиздюлила (и кританула) врага на " + str(random_player_damage)
		print("[DEBUG] КРИТ! Урон: ", random_player_damage)
	else:
		info_text.text = "ты опиздюлила врага на " + str(random_player_damage)
		print("[DEBUG] Урон: ", random_player_damage)

	CombatState.current_enemy["hp"] -= random_player_damage
	CombatState.current_enemy["hp"] = clamp(CombatState.current_enemy["hp"], 0, CombatState.current_enemy["max_hp"])
	print("[DEBUG] HP врага после магии: ", CombatState.current_enemy["hp"])
	
	

	player_damage = 0
	random_player_damage = 0
	_update_label()

	await get_tree().create_timer(2.0).timeout

	if CombatState.current_enemy["hp"] <= 0:
		_enemy_die()
		return

	_support_turn()


func _normal_attack(normal_damage) -> void:
	await get_tree().create_timer(0.1).timeout
	if is_busy: return

	is_busy = true
	CombatState.choise_visibility = true

	var random_normal_damage = randi_range(normal_damage - 10, normal_damage + 10)
	var enemy_defense = CombatState.current_enemy.get("defense", 1.0)
	random_normal_damage = round(random_normal_damage * enemy_defense * CombatState.stress_damage_mod)

	var local_crit_chance = randi_range(1, 100)
	CombatState.pop_in(info_all)
	await get_tree().create_timer(0.1).timeout
	info.visible = true

	if local_crit_chance <= CombatState.crit_chance_player:
		random_normal_damage = round(random_normal_damage * randf_range(1.3, 1.7))
		info_text.text = "ты скучно опиздюлила (и кританула) врага на " + str(random_normal_damage)
		print("[DEBUG] Обычная атака (КРИТ). Урон: ", random_normal_damage)
	else:
		info_text.text = "ты скучно опиздюлила врага на " + str(random_normal_damage)
		print("[DEBUG] Обычная атака. Урон: ", random_normal_damage)

	CombatState.current_enemy["hp"] -= round(random_normal_damage)
	CombatState.current_enemy["hp"] = clamp(CombatState.current_enemy["hp"], 0, CombatState.current_enemy["max_hp"])
	print("[DEBUG] HP врага после меча: ", CombatState.current_enemy["hp"])
	
	
	
	_enemy_animation()
	
	CombatState.turn_number += 1

	if CombatState.current_enemy["hp"] <= 0:
		_enemy_die()
		return

	var enemy_element = CombatState.enemy_element
	if enemy_element == 1: SFXplayer.stream = fire
	elif enemy_element == 2: SFXplayer.stream = blood
	elif enemy_element == 3: SFXplayer.stream = water
	elif enemy_element == 4: SFXplayer.stream = metal
	else: SFXplayer.stream = bile

	SFXplayer.pitch_scale = randf_range(0.9, 1.1)
	SFXplayer.play()
	await get_tree().create_timer(1.0).timeout
	_support_turn()


func _defense_player(armor) -> void:
	await get_tree().create_timer(0.1).timeout
	if is_busy: return

	is_busy = true
	CombatState.choise_visibility = true

	SFXplayer.stream = aegis
	SFXplayer.play()

	CombatState.pop_in(info_all)
	await get_tree().create_timer(0.1).timeout
	info.visible = true

	current_player_defense = clamp(armor, 0.1, 1.0)
	CombatState.turn_number += 1
	info_text.text = "ты юзанул защиту"
	print("[DEBUG] Игрок использует защиту. Множитель: ", current_player_defense)

	CombatState.mana_player += round(randf_range(8, 12)) 
	CombatState.mana_player = clamp(CombatState.mana_player, 0, CombatState.mana_player_max)
	print("[DEBUG] Восстановление маны за защиту. Мана: ", CombatState.mana_player)

	await get_tree().create_timer(1.5).timeout
	_support_turn()


# --- ХОДЫ ИИ ---

func _support_turn():
	print("\n--- [ХОД ВАДИМА] ---")
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
		print("[DEBUG] Вадим ничего не сделал (шанс ", support_chance, ")")
		await get_tree().create_timer(1.0).timeout
		_enemy_turn()

	elif support_chance >= 5 and support_chance <= 9: 
		CombatState.current_enemy["hp"] -= support_damage
		CombatState.current_enemy["hp"] = clamp(CombatState.current_enemy["hp"], 0, CombatState.current_enemy["max_hp"])
		info_text.text = str(CombatState.current_support["name"]) + " атаковал на " + str(support_damage)
		print("[DEBUG] Вадим атаковал на ", support_damage, ". HP врага: ", CombatState.current_enemy["hp"])
		
		
		_enemy_animation()
		
		await get_tree().create_timer(1.0).timeout

		if CombatState.current_enemy["hp"] <= 0:
			_enemy_die()
			return
		_enemy_turn()

	elif support_chance == 10: 
		var spell_chance = [1, 2].pick_random()
		if spell_chance == 1:
			print("[DEBUG] Вадим использует стан!")
			var ability = CombatState.current_support.get("abilities")[1]
			ability.call() 
			SFXplayer.stream = CombatState.current_support.get("sfx")[1]
			SFXplayer.play()
			info_text.text = CombatState.support_abilitie_description
			await get_tree().create_timer(1.0).timeout
			_enemy_turn()
		elif spell_chance == 2:
			print("[DEBUG] Вадим бьет себя!")
			var ability = CombatState.current_support.get("abilities")[0]
			ability.call() 
			SFXplayer.stream = CombatState.current_support.get("sfx")[0]
			SFXplayer.play()
			info_text.text = CombatState.support_abilitie_description
			
			flash_sprite(lin_lin, Color.RED)
			
			await get_tree().create_timer(1.0).timeout
			_enemy_turn()

	if CombatState.current_enemy["hp"] <= 0:
		_enemy_die()
		return


func _enemy_turn():
	print("\n--- [ХОД ВРАГА] ---")
	if CombatState.enemy_skip_turn:
		print("[DEBUG] Враг пропускает ход (стан)!")
		CombatState.enemy_skip_turn = false
		await get_tree().create_timer(1.0).timeout
		inventory.visible = false
		is_busy = false
		CombatState.pop_out(info_all)
		await get_tree().create_timer(0.1).timeout
		info.visible = false
		CombatState.choise_visibility = false
		_update_choice_visibility()
		CombatState.mana_player += 5 
		return

	if CombatState.debuff_turns <= 0 and randi_range(1, 100) <= 10: 
		var abilities = CombatState.current_enemy.get("abilities", [])
		if not abilities.is_empty():
			var chosen_ability = abilities.pick_random()
			print("[DEBUG] Враг использует дебафф: ", chosen_ability)
			CombatState.call(chosen_ability)
			
		CombatState.turn_number += 1
		SFXplayer.stream = no
		SFXplayer.play()
		info.visible = true
		info_text.text = CombatState.debuff_description
		await get_tree().create_timer(1.5).timeout

		CombatState.choise_visibility = false
		is_busy = false
		CombatState.pop_out(info_all)
		await get_tree().create_timer(0.1).timeout
		info.visible = false
		_update_choice_visibility()
		return

	_enemy_ai()

	var enemy_damage = round(randi_range(
		CombatState.current_enemy["attack"] - 10,
		CombatState.current_enemy["attack"] + 10
	) * current_player_defense)
	
	if player_status in strong_against.get(CombatState.enemy_element, []):
		enemy_damage = round(enemy_damage * 1.5) 
		print("[DEBUG] Враг бьет СИЛЬНО (стихия).")
	elif player_status in weak_against.get(CombatState.enemy_element, []):
		enemy_damage = round(enemy_damage * 0.5) 
		print("[DEBUG] Враг бьет СЛАБО (стихия).")

	var local_enemy_crit_chance = randi_range(1, 100)
	if local_enemy_crit_chance <= CombatState.crit_chance_enemy:
		enemy_damage = round(enemy_damage * randf_range(1.3, 1.7))
		info_text.text = "враг опиздюлил (и кританул) тебя на " + str(enemy_damage)
		print("[DEBUG] Враг КРИТАНУЛ! Урон: ", enemy_damage)
	else:
		info_text.text = "враг опиздюлил тебя на " + str(enemy_damage)
		print("[DEBUG] Враг атакует. Урон: ", enemy_damage)

	CombatState.hp_player -= enemy_damage
	CombatState.hp_player = clamp(CombatState.hp_player, 0, CombatState.hp_player_max)
	print("[DEBUG] HP игрока после атаки: ", CombatState.hp_player)
	
	player_damaged = true
	_player_animation()
	
	await get_tree().create_timer(1.5).timeout
	
	CombatState.stress_status_changer()
	
	current_player_defense = 1 
	CombatState.turn_number += 1

	CombatState.choise_visibility = false
	is_busy = false
	CombatState.pop_out(info_all)
	await get_tree().create_timer(0.1).timeout
	info.visible = false
	_update_choice_visibility()

	CombatState.tick_debuff()

	if CombatState.hp_player <= 0:
		_player_death()
	else:
		print("=== [ХОД ИГРОКА] ===")


# --- КОНЕЦ БОЯ ---

func _enemy_die():
	print("\n=== [ПОБЕДА] ===")
	CombatState.pop_out(player)
	await get_tree().create_timer(0.1).timeout
	player.visible = false

	info.visible = true
	CombatState.choise_visibility = false
	_update_choice_visibility()
	is_busy = false

	SFXplayer.stream = win
	SFXplayer.play()
	info_text.text = "ты победил"
	CombatState.current_enemy["is_alive"] = false

	CombatState.mana_player = CombatState.mana_player_max

	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://game.tscn")


func _player_death():
	if first_death:
		print("\n=== [СМЕРТЬ ОТМЕНЕНА] Второй шанс! ===")
		CombatState.hp_player = 1
		first_death = false
		info_text.text = "Ты на грани! Но что-то удерживает тебя от смерти..."
		await get_tree().create_timer(2.0).timeout
		CombatState.choise_visibility = false
		is_busy = false
		CombatState.pop_out(info_all)
		await get_tree().create_timer(0.1).timeout
		info.visible = false
		_update_choice_visibility()
		print("=== [ХОД ИГРОКА] (Второй шанс) ===")
		return
		
	print("\n=== [ПОРАЖЕНИЕ] ===")
	CombatState.pop_out(player)
	await get_tree().create_timer(0.1).timeout
	player.visible = false

	info.visible = true
	CombatState.choise_visibility = false
	_update_choice_visibility()
	is_busy = false

	SFXplayer.stream = death
	SFXplayer.play()
	info_text.text = "ты проиграл"
	await get_tree().create_timer(1.5).timeout
	
	CombatState.hp_player = CombatState.hp_player_max * 0.5
	CombatState.mana_player = CombatState.mana_player_max * 0.5
	get_tree().change_scene_to_file("res://systems/death_screen.tscn")


# --- ИНТЕРФЕЙС И МЕНЮ ---

func _on_cancel_button_pressed() -> void:
	SFXplayer.stream = button_pressed
	SFXplayer.play()
	CombatState.bounce_press(cancel)
	CombatState.pop_out(witchcraft_choice)
	await get_tree().create_timer(0.15).timeout
	CombatState.choise_visibility = false
	coolassbg.visible = false
	_update_choice_visibility()
	print("[DEBUG] Меню магии закрыто (отмена).")


func _on_witchcraft_pressed():
	SFXplayer.stream = button_pressed
	SFXplayer.play()
	CombatState.pop_in(witchcraft_choice)
	info.visible = false
	coolassbg.visible = true
	print("[DEBUG] Открыто меню магии.")


func _on_krutilka_pressed():
	SFXplayer.stream = krutilkas_button
	SFXplayer.pitch_scale = randf_range(0.9, 1.1)
	SFXplayer.play()


func _exit_battle() -> void:
	print("[DEBUG] Выход из боя через R.")
	CombatState.choise_visibility = false
	get_tree().change_scene_to_file("res://game.tscn")


func _on_item_used() -> void:
	SFXplayer.stream = button_pressed
	SFXplayer.play()
	CombatState.turn_number += 1
	print("[DEBUG] Использован предмет. Переход хода к Вадиму.")

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
	SFXplayer.play()
	
	if is_busy: return
		
	CombatState.pop_out(player)
	player.visible = false
	info.visible = false
	is_busy = true
	CombatState.choise_visibility = true
	CombatState.pop_in(litteral_inventory)
	CombatState.pop_in(inventory)
	await get_tree().create_timer(0.1).timeout
	inventory.visible = true
	print("[DEBUG] Открыт инвентарь.")


func _on_inventory_closed() -> void:
	SFXplayer.stream = button_pressed
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
	print("[DEBUG] Инвентарь закрыт.")


# --- ВСПЫШКА (Работает с твоим готовым материалом) ---
func flash_sprite(target_sprite: CanvasItem, color: Color):
	if not target_sprite:
		print("[SHADER] ОШИБКА: Спрайт не найден!")
		return
		
	if not target_sprite.material:
		print("[SHADER] ОШИБКА: У узла '", target_sprite.name, "' нет материала! Назначь ShaderMaterial в инспекторе.")
		return
		
	var mat = target_sprite.material as ShaderMaterial
	if not mat:
		print("[SHADER] ОШИБКА: Материал узла '", target_sprite.name, "' не является ShaderMaterial!")
		return
	
	mat.set_shader_parameter("flash_color", color)
	mat.set_shader_parameter("flash_amount", 1.0)
	
	var tween = create_tween()
	tween.tween_property(mat, "shader_parameter/flash_amount", 0.0, 0.3)

func _spawn_blood(pos: Vector2, direction_x: float):
	
	var blood_fx = blood_particles.instantiate()
	
	get_tree().current_scene.add_child(blood_fx)

	blood_fx.global_position = pos
	
	if direction_x < 0:
		blood_fx.scale.x = -1
