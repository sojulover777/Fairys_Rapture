extends  Node2D

@warning_ignore("unused_signal")
signal spell_changed(spell_data)
@warning_ignore("unused_signal")
signal element_changed(element_data)
@warning_ignore("unused_signal")
signal mods_changed(mods_data)
@warning_ignore("unused_signal")
signal normal_attack(normal_damage)
@warning_ignore("unused_signal")
signal defense(_defense_player)
@warning_ignore("unused_signal")
signal contact_dummy(pedobear)
@warning_ignore("unused_signal")
signal witchcraft()
@warning_ignore("unused_signal")
signal krutilkas_button()
@warning_ignore("unused_signal")
signal item_used()
@warning_ignore("unused_signal")
signal item_pressed()
@warning_ignore("unused_signal")
signal inventory_closed()

var SFXplayer: AudioStreamPlayer
var oh_shit = preload("res://sfx/shit_happend.mp3")

var turn_number = 0
var level_player = 1
var hp_player = 100
var armor_player = 0.6
var mana_player = 80
var hp_player_max = 100
var mana_player_max = 100
var normal_damage = 20
var player_crit = 1.25
var crit_chance_player = 15
var enemy_crit = 1.15
var crit_chance_enemy = 10
var player_element = 0
var enemy_element = 0
var hp_player_max_base = 100
var hp_debuff_turns = 0
var hp_debuff_percent = 0.0
var mana_player_max_base = 100
var debuff_turns = 0
var mana_debuff_percent = 0.0
var current_debuff = ""
var stress = "stress_0"
var stress_damage_mod = 1.0

var choise_visibility = false
var enemy_skip_turn = false
var is_busy = false

var support_abilitie_description = ""
var debuff_description = ""

var items_database = {
	"bandage": {
		"name": "Бинт",
		"description": "Восстанавливает 50 HP",
		"icon": "res://bandage.png",
		"effect": "heal",
		"value": 50
	},
	"gum": {
		"name": "Жвачка",
		"description": "Восстанавливает 50 EP",
		"icon": "res://chewing_gum.png",
		"effect": "mana_restore",
		"value": 50
	},
}

var inventory = {}

var enemy_database = {
	"Педотрамп": {
		"hp": 160,
		"max_hp": 160,
		"attack": 10,
		"defense": 0.8,
		"element": [3,4],
		"abilities": ["horror", "bleeding"],
		"sprite": "res://sprites/enemies/pedotrump.png"}
}

var current_enemy = {}

func _ready() -> void:	
	SFXplayer = AudioStreamPlayer.new()
	add_child(SFXplayer)
	
	var img = load("res://sprites/gui/cursor.png").get_image()
	
	var new_size = img.get_size() / 4
	img.resize(new_size.x, new_size.y, Image.INTERPOLATE_LANCZOS)
	
	var tex = ImageTexture.create_from_image(img)
	
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, Vector2.ZERO)

func load_enemy(enemy_name: String):
	if enemy_database.has(enemy_name):
		current_enemy = enemy_database[enemy_name].duplicate()
		current_enemy["name"] = enemy_name
		current_enemy["is_alive"] = true
	else:
		print("такого врага не существует")

var supports_database = {
	"вадим": {
		"attack_modificator": 0.4,
		"element": [2,4],
		"abilities": [Callable(_vadim_stun),Callable(_vadim_pizduly)],
		"support_stuff":Callable(_vadim_stuff),
		"sfx": [preload("res://sfx/sliva.ogg"),preload("res://sfx/zhuk.ogg")]
}}

var current_support = {}

func load_support(support_name: String):
	if supports_database.has(support_name):
		current_support = supports_database[support_name].duplicate()
		current_support["name"] = support_name
	else:
		print("такого саппорта не существует")

var spell_stats = {
	"Надрез":  {"damage": 25, "cost": 15},
	"Догма":   {"damage": 35, "cost": 25},
	"Клевета": {"damage": 40, "cost": 35},
	"Вердикт": {"damage": 65, "cost": 50}
}

func _level_up_all_spells(damage_percent: float = 0.3, cost_percent: float = 0.3):
	for spell_name in spell_stats:
		var spell = spell_stats[spell_name]
		spell["damage"] = round(spell["damage"] * (1 + damage_percent))
		spell["cost"] = round(spell["cost"] * (1 + cost_percent))

func get_spell_damage(spell_name: String) -> int:
	return spell_stats.get(spell_name, {}).get("damage", 0)

func get_spell_cost(spell_name: String) -> int:
	return spell_stats.get(spell_name, {}).get("cost", 0)

func _level_up() -> void:
	level_player += 1
	hp_player_max += 15
	mana_player_max_base += 10
	normal_damage += 3
	_level_up_all_spells()

func _vadim_stuff():
	mana_player += 1

func _vadim_stun():
	enemy_skip_turn = true
	support_abilitie_description = "вадим склеил сливу, враг пропускает ход"
	pass
	
func _vadim_pizduly():
	hp_player -=10
	support_abilitie_description = "вадим споткнулся о жука и опиздюлился, ты получаешь 10 урона"
	pass

func recalc_mana_max() -> void:
	if debuff_turns > 0:
		mana_player_max = mana_player_max_base * ( 1.0 - mana_debuff_percent)
	else:
		mana_player_max = mana_player_max_base
	mana_player = clamp(mana_player, 0, mana_player_max)

func tick_debuff() -> void:
	if debuff_turns > 0:
		debuff_turns -= 1
		match current_debuff:
			"horror":
				recalc_mana_max()
			"bleeding":
				bleeding_stuff()
		if debuff_turns == 0:
			mana_debuff_percent = 0.0
			recalc_mana_max()
			current_debuff = ""

func horror() -> void:
	current_debuff = "horror"
	mana_debuff_percent = 0.4
	debuff_turns = 2
	recalc_mana_max()
	debuff_description = "Наложен ужас!"

func bleeding() -> void:
	current_debuff = "bleeding"
	debuff_description = "Наложено кровотечение!"
	debuff_turns = 2
	
func bleeding_stuff():
	hp_player -= randi_range(10,15)

func stress_status_changer() -> void:
	var new_stress = ""
	var new_mod = 1.0
	var new_pitch = 1.0

	if hp_player <= 25:
		new_stress = "stress_4"
		new_mod = 1.4
		new_pitch = 1.0
	elif hp_player <= 60:
		new_stress = "stress_3"
		new_mod = 1.2
		new_pitch = 1.1
	elif hp_player < 99:
		new_stress = "stress_2"
		new_mod = 1
		new_pitch = 1.2
	else:
		new_stress = "stress_0"
		new_mod = 0.85
		new_pitch = 1.3
		
	if stress != new_stress:
		stress = new_stress
		stress_damage_mod = new_mod
		
		SFXplayer.stream = oh_shit
		SFXplayer.volume_linear = 0.8
		SFXplayer.pitch_scale = new_pitch
		SFXplayer.play()

func bounce_press(button: Control):
	button.pivot_offset = button.size / 2
	var tween = button.create_tween()
	tween.tween_property(button, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.05)

func pop_in(node: Control, duration: float = 0.3):
	node.modulate.a = 0.0
	node.scale = Vector2(0.8, 0.8)
	node.visible = true
	node.pivot_offset = node.size / 2
	
	var tween = node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "modulate:a", 1.0, duration)
	tween.tween_property(node, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
func pop_out(node: Control, duration: float = 0.2) -> void:
	node.pivot_offset = node.size / 2
	node.visible = true
	
	var tween = node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "modulate:a", 0.0, duration)
	tween.tween_property(node, "scale", Vector2(0.8, 0.8), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	await tween.finished
	node.visible = false
	node.scale = Vector2.ONE
	node.modulate.a = 1.0
