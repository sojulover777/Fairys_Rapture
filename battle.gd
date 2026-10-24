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
@onready var level_up = $level_up
@onready var cancel = $Witchcraft_choice/CoolAssBG/cancel_button
@onready var witchcraft_choice = $Witchcraft_choice
@onready var info_all = $CanvasGroup/info_all
@onready var ready_btn = $Witchcraft_choice/CoolAssBG/ready_btn
@onready var litteral_inventory = $inventory_control/Inventory
@onready var status_sprite = $Control/player/HpBar/status_sprite
@onready var status_sprite_inventory = $inventory_control/Inventory/status_sprite_inventory
@onready var enemy_abilities = $EnemyAbilitiesNode
@onready var lin_lin = $Control/player/AnimatedSprite2D

const HOLD_DURATION = 4.0
const TICK_INTERVAL = 1.0
const BASE_PITCH = 1.0
const MAX_PITCH = 2.0

var hold_time = 0.0
var last_tick_time = 0.0

var is_dead = false
var is_busy = false # Блокировщик действий: true, когда враг бьет или проигрывается анимация

# Переменные текущей выбранной магии
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

# Элемент, которым игрок "стал" после последнего каста (влияет на получаемый урон)
var player_status = 1
var player_element_name = ""

# Загрузка звуков
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

# Таблицы стихий: кто кого бьет сильнее (1.2x) или слабее (0.6x)
var strong_against = {
	1: [2, 4], 2: [3, 5], 3: [4, 1], 4: [5, 2], 5: [1, 3]
}
var weak_against = {
	1: [5, 3], 2: [4, 1], 3: [5, 3], 4: [3, 1], 5: [4, 2]
}


## Инициализация боя: подключение сигналов, сброс UI, проверка врага.
func _ready():
	# Подключаем все сигналы из глобального CombatState
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
	
	# Сброс видимости интерфейса
	timer.visible = false
	inventory.visible = false
	info.visible = false
	is_dead = false
	is_busy = false

	player_status = CombatState.player_element
	if player_status == 0:
		player_status = 1
	player_element_name = ""

	# Включаем анимации статусов (нейтральный элемент)
	status_sprite.play(status_sprite_name)
	status_sprite_inventory.play(status_sprite_name)
	
	lin_lin.play("idle")

	# Если врага нет (например, запустили сцену напрямую из редактора) — выходим на карту
	if CombatState.current_enemy.is_empty():
		get_tree().change_scene_to_file("res://game.tscn")
		return

	_update_label()
	_update_choice_visibility()


## Каждый кадр проверяет лимиты ХП/маны и обрабатывает зажатие клавиши R (побег).
func _process(delta: float) -> void:
	CombatState.hp_player = clamp(CombatState.hp_player, 0, CombatState.hp_player_max)
	CombatState.mana_player = clamp(CombatState.mana_player, 0, CombatState.mana_player_max)

	_update_choice_visibility()

	# Механика выхода из боя зажатием R (4 секунды)
	if Input.is_key_pressed(KEY_R):
		timer.visible = true
		timer_label.visible = true
		hold_time += delta
		timer_label.text = str(int(HOLD_DURATION - hold_time))

		if hold_time - last_tick_time >= TICK_INTERVAL:
			last_tick_time = hold_time
			var progress = hold_time / HOLD_DURATION
			SFXplayer.stream = count_down
			SFXplayer.pitch_scale = lerp(BASE_PITCH, MAX_PITCH, progress) # Звук ускоряется
			SFXplayer.play()

		if hold_time >= HOLD_DURATION:
			if not is_busy: # Если игрок не занят (не бьет/не бьют его)
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


## Скрывает/показывает кнопки действий (ATTACK, WITCHCRAFT и т.д.) в зависимости от хода.
func _update_choice_visibility():
	if CombatState.choise_visibility:
		choice.visible = false
	else:
		choice.visible = true

## Обновляет текст в меню магии (название, урон, стоимость).
func _update_label():
	_player_damage_math()
	var cost = CombatState.get_spell_cost(current_spell_name)
	persize_damage.text = "урон = " + str(player_damage) + " | мана: " + str(cost + current_mods_cost)

	# Красит текст в красный, если не хватает маны
	if current_spell_name != "" and CombatState.mana_player < cost + current_mods_cost:
		persize_damage.modulate = Color(1.0, 0.4, 0.4)
	else:
		persize_damage.modulate = Color(1.0, 1.0, 1.0)

## Считает предварительный урон с учетом стихий.
func _player_damage_math():
	player_damage = spell_damage
	var enemy_element = CombatState.current_enemy.get("element", 0)

	# Проверка таблиц сильных/слабых стихий
	if enemy_element in strong_against.get(current_element_number, []):
		player_damage = round(player_damage * 1.2)
	elif enemy_element in weak_against.get(current_element_number, []):
		player_damage = round(player_damage * 0.6)

	# Добавляем случайный разброс урона (+-10)
	random_player_damage = round(randi_range(round(player_damage) - 10, round(player_damage) + 10) * CombatState.stress_damage_mod)


# --- СИГНАЛЫ ИЗ МЕНЮ МАГИИ ---

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


# --- ДЕЙСТВИЯ ИГРОКА ---

## Вызывается при нажатии кнопки "Готово" в меню магии.
func _on_ready_btn_pressed() -> void:
	await get_tree().create_timer(0.1).timeout
	if is_busy:
		return

	# Проверки на выбранные элементы и ману
	if current_spell_name == "" or current_element_name == "":
		SFXplayer.stream = no
		SFXplayer.play()
		return

	var spell_cost = CombatState.get_spell_cost(current_spell_name)
	if CombatState.mana_player < spell_cost:
		SFXplayer.stream = no
		SFXplayer.play()
		CombatState.pop_in(info_all)
		await get_tree().create_timer(0.1).timeout
		info.visible = true
		info_text.text = "не хватает маны (нужно " + str(spell_cost) + ")"
		await get_tree().create_timer(1.0).timeout
		CombatState.pop_out(info_all)
		info.visible = false
		return

	# Списываем ману
	CombatState.mana_player -= spell_cost + current_mods_cost
	CombatState.mana_player = clamp(CombatState.mana_player, 0, CombatState.mana_player_max)

	# Игрок меняет свой элемент на тот, которым кастовал
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

	CombatState.turn_number += 1
	_player_damage_math()
	CombatState.stress_status_changer()

	# Модификатор лечения (восстанавливает 15% от урона)
	if current_mods_number == 2:
		CombatState.hp_player += round(round(random_player_damage) * 15 / 100)
		CombatState.hp_player = clamp(CombatState.hp_player, 0, CombatState.hp_player_max)

	# Проверка на критический удар
	var local_crit_chance = randi_range(1, 100)
	CombatState.pop_in(info_all)
	await get_tree().create_timer(0.1).timeout
	info.visible = true

	if local_crit_chance <= CombatState.crit_chance_player:
		random_player_damage = round(random_player_damage * randf_range(1.3, 1.7))
		info_text.text = "ты опиздюлила (и кританула) врага на " + str(random_player_damage)
	else:
		info_text.text = "ты опиздюлила врага на " + str(random_player_damage)

	# Наносим урон врагу
	CombatState.current_enemy["hp"] -= random_player_damage
	CombatState.current_enemy["hp"] = clamp(CombatState.current_enemy["hp"], 0, CombatState.current_enemy["max_hp"])

	player_damage = 0
	random_player_damage = 0

	_update_label()

	await get_tree().create_timer(2.0).timeout

	if CombatState.current_enemy["hp"] <= 0:
		_enemy_die()
		return

	_support_turn()


## Обычная атака (мечом).
func _normal_attack(normal_damage) -> void:
	await get_tree().create_timer(0.1).timeout
	if is_busy:
		return

	is_busy = true
	CombatState.choise_visibility = true

	var random_normal_damage = randi_range(normal_damage - 10, normal_damage + 10)
	var enemy_defense = CombatState.current_enemy.get("defense", 1.0)
	random_normal_damage = round(random_normal_damage * enemy_defense * CombatState.stress_damage_mod) # Учитываем защиту врага

	var local_crit_chance = randi_range(1, 100)
	CombatState.pop_in(info_all)
	await get_tree().create_timer(0.1).timeout
	info.visible = true

	if local_crit_chance <= CombatState.crit_chance_player:
		random_normal_damage = round(random_normal_damage * randf_range(1.3, 1.7))
		info_text.text = "ты скучно опиздюлила (и кританула) врага на " + str(random_normal_damage)
	else:
		info_text.text = "ты скучно опиздюлила врага на " + str(random_normal_damage)

	CombatState.current_enemy["hp"] -= round(random_normal_damage)
	CombatState.current_enemy["hp"] = clamp(CombatState.current_enemy["hp"], 0, CombatState.current_enemy["max_hp"])

	CombatState.turn_number += 1

	if CombatState.current_enemy["hp"] <= 0:
		_enemy_die()
		return

	# Звук удара зависит от элемента врага
	var enemy_element = CombatState.current_enemy["element"]
	if enemy_element == 1: SFXplayer.stream = fire
	elif enemy_element == 2: SFXplayer.stream = blood
	elif enemy_element == 3: SFXplayer.stream = water
	elif enemy_element == 4: SFXplayer.stream = metal
	else: SFXplayer.stream = bile

	SFXplayer.pitch_scale = randf_range(0.9, 1.1)
	SFXplayer.play()
	await get_tree().create_timer(1.0).timeout

	_support_turn()


## Защита (Aegis). Повышает защиту на один ход и дает ману.
func _defense_player(armor) -> void:
	await get_tree().create_timer(0.1).timeout
	if is_busy:
		return

	is_busy = true
	CombatState.choise_visibility = true

	SFXplayer.stream = aegis
	SFXplayer.play()

	CombatState.pop_in(info_all)
	await get_tree().create_timer(0.1).timeout
	info.visible = true

	current_player_defense = clamp(armor, 0.1, 1.0) # Чем ниже, тем меньше урона получим
	CombatState.turn_number += 1
	info_text.text = "ты юзанул защиту"

	# Восстановление маны за защиту
	CombatState.mana_player += round(randf_range(5, 10))
	CombatState.mana_player = clamp(CombatState.mana_player, 0, CombatState.mana_player_max)

	await get_tree().create_timer(1.5).timeout
	_support_turn()


# --- ХОДЫ ИИ ---

## Ход саппорта (Вадима). Случайно выбирает: ничего не делать, атаковать или юзнуть скилл.
func _support_turn():
	is_busy = false
	var support = CombatState.current_support
	support["support_stuff"].call() # Восстанавливает игроку 5 HP

	if CombatState.current_support.is_empty():
		_enemy_turn()
		return

	var support_chance = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].pick_random()
	var support_damage = round(randi_range(
		CombatState.normal_damage * CombatState.current_support["attack_modificator"] - 10,
		CombatState.normal_damage * CombatState.current_support["attack_modificator"] + 10
	))

	if support_chance <= 4: # 40% шанс, что Вадим ничего не сделает
		info_text.text = str(CombatState.current_support["name"]) + " подумал-подумал и нихуя не сделал"
		await get_tree().create_timer(1.0).timeout
		_enemy_turn()

	elif support_chance >= 5 and support_chance <= 8: # 40% шанс обычной атаки
		CombatState.current_enemy["hp"] -= support_damage
		CombatState.current_enemy["hp"] = clamp(CombatState.current_enemy["hp"], 0, CombatState.current_enemy["max_hp"])
		info_text.text = str(CombatState.current_support["name"]) + " атаковал на " + str(support_damage)
		await get_tree().create_timer(1.0).timeout

		if CombatState.current_enemy["hp"] <= 0:
			_enemy_die()
			return
		_enemy_turn()

	elif support_chance >= 10: # 20% шанс юзнуть скилл (стан или самопоранение)
		var spell_chance = [1, 2].pick_random()
		if spell_chance == 1:
			var ability = CombatState.current_support.get("abilities")[1]
			ability.call() # Стан
			SFXplayer.stream = CombatState.current_support.get("sfx")[1]
			SFXplayer.play()
			info_text.text = CombatState.support_abilitie_description
			await get_tree().create_timer(1.0).timeout
			_enemy_turn()
		elif spell_chance == 2:
			var ability = CombatState.current_support.get("abilities")[0]
			ability.call() # Вадим бьет себя
			SFXplayer.stream = CombatState.current_support.get("sfx")[0]
			SFXplayer.play()
			info_text.text = CombatState.support_abilitie_description
			await get_tree().create_timer(1.0).timeout
			_enemy_turn()

	if CombatState.current_enemy["hp"] <= 0:
		_enemy_die()
		return


## Ход врага: проверяет стан, использует дебафф или бьет игрока.
func _enemy_turn():
	# Пропуск хода из-за стана Вадима
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
		CombatState.mana_player += 3 # Небольшой бонус маны за пропуск хода
		return

	# Проверка на использование дебаффа (Сейчас шанс 100%, так как randi_range(1, 100) <= 100 всегда true)
	if CombatState.debuff_turns <= 0 and randi_range(1, 100) <= 10: 
		var abilities = CombatState.current_enemy.get("abilities", [])
		if not abilities.is_empty():
			var chosen_ability = abilities.pick_random()
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

	# Расчет урона врага
	var enemy_damage = round(randi_range(
		CombatState.current_enemy["attack"] - 10,
		CombatState.current_enemy["attack"] + 10
	) * current_player_defense) # Учитываем защиту игрока

	var enemy_element = CombatState.current_enemy.get("element", 0)

	# Проверка стихий (стихия игрока против стихии врага)
	if player_status in strong_against.get(enemy_element, []):
		enemy_damage = round(enemy_damage * 1.5 * CombatState.stress_damage_mod) # Враг бьет сильнее
	elif player_status in weak_against.get(enemy_element, []):
		enemy_damage = round(enemy_damage * 0.5 * CombatState.stress_damage_mod) # Враг бьет слабее

	# Крит врага
	var local_enemy_crit_chance = randi_range(1, 100)
	if local_enemy_crit_chance <= CombatState.crit_chance_enemy:
		enemy_damage = round(enemy_damage * randf_range(1.3, 1.7))
		info_text.text = "враг опиздюлил (и кританул) тебя на " + str(enemy_damage)
	else:
		info_text.text = "враг опиздюлил тебя на " + str(enemy_damage)

	# Наносим урон игроку
	CombatState.hp_player -= enemy_damage
	CombatState.hp_player = clamp(CombatState.hp_player, 0, CombatState.hp_player_max)
	CombatState.stress_status_changer()
	
	current_player_defense = 1 # Сбрасываем защиту после удара
	CombatState.turn_number += 1

	SFXplayer.stream = normal
	SFXplayer.play()
	await get_tree().create_timer(1.5).timeout

	CombatState.choise_visibility = false
	is_busy = false
	CombatState.pop_out(info_all)
	await get_tree().create_timer(0.1).timeout
	info.visible = false
	_update_choice_visibility()

	CombatState.tick_debuff() # Тикаем дебаффs

	if CombatState.hp_player <= 0:
		_player_death()


# --- КОНЕЦ БОЯ ---

## Смерть врага: проигрываем анимацию, забираем лут, переходим на карту.
func _enemy_die():
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

	CombatState.mana_player = CombatState.mana_player_max # Восстанавливаем ману после боя

	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://game.tscn")


## Смерть игрока: экран смерти, отнимаем половину ресурсов.
func _player_death():
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
	get_tree().change_scene_to_file("res://death_screen.tscn")


# --- ИНТЕРФЕЙС И МЕНЮ ---

## Отмена выбора в меню магии.
func _on_cancel_button_pressed() -> void:
	SFXplayer.stream = button_pressed
	SFXplayer.play()
	CombatState.bounce_press(cancel)
	CombatState.pop_out(witchcraft_choice)
	await get_tree().create_timer(0.15).timeout
	CombatState.choise_visibility = false
	coolassbg.visible = false
	_update_choice_visibility()


## Открытие меню магии (WITCHCRAFT).
func _on_witchcraft_pressed():
	SFXplayer.stream = button_pressed
	SFXplayer.play()
	CombatState.pop_in(witchcraft_choice)
	info.visible = false
	coolassbg.visible = true


## Просто звук для крутилки выбора элементов.
func _on_krutilka_pressed():
	SFXplayer.stream = krutilkas_button
	SFXplayer.pitch_scale = randf_range(0.9, 1.1)
	SFXplayer.play()


## Принудительный выход из боя (через зажатие R).
func _exit_battle() -> void:
	CombatState.choise_visibility = false
	get_tree().change_scene_to_file("res://game.tscn")


## Использование предмета из инвентаря.
func _on_item_used() -> void:
	SFXplayer.stream = button_pressed
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
	_support_turn() # После предмета ход переходит саппорту


## Открытие инвентаря.
func _on_item_pressed() -> void:
	await get_tree().create_timer(0.1).timeout
	SFXplayer.stream = button_pressed
	SFXplayer.play()
	
	if is_busy:
		return
		
	CombatState.pop_out(player)
	player.visible = false
	info.visible = false
	is_busy = true # Блокируем кнопки, пока инвентарь открыт
	CombatState.choise_visibility = true
	CombatState.pop_in(litteral_inventory)
	CombatState.pop_in(inventory)
	await get_tree().create_timer(0.1).timeout
	inventory.visible = true


## Закрытие инвентаря без использования предмета.
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
	
