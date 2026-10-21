extends Node

func _ready():
	# 1. Загружаем сцены (лучше явно указать тип PackedScene для безопасности)
	var menu_scene = load("res://inventory.tscn") as PackedScene
	var battle_scene = load("res://battle.tscn") as PackedScene
	
	if not menu_scene or not battle_scene:
		print("ОШИБКА: Не удалось загрузить сцены для прогрева!")
		get_tree().change_scene_to_file("res://game.tscn")
		return
	
	# 2. Создаем экземпляры
	var temp_menu = menu_scene.instantiate()
	var temp_battle = battle_scene.instantiate()
	
	# 3. ВАЖНО: Скрываем их, чтобы игрок не видел мигания
	temp_menu.visible = false 
	temp_battle.visible = false
	
	# 4. Добавляем в дерево сцены, чтобы они "ожили" и скомпилировали шейдеры
	add_child(temp_menu)
	add_child(temp_battle)
	
	# 5. Ждем несколько кадров (3-5 обычно достаточно, 16 — это перебор, но не страшно)
	for i in range(5):
		await get_tree().process_frame
	
	# 6. Удаляем ОБА экземпляра из памяти
	temp_menu.queue_free()
	temp_battle.queue_free()
	
	# 7. Переходим на главную игровую сцену (именно .tscn!)
	get_tree().change_scene_to_file("res://game.tscn")
