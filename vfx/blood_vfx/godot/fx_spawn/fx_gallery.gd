extends Node2D
## Gallery: every effect of the packs in this project, every clip played in turn. Open fx_gallery.tscn and press F6.
## Left / Right (or A / D): previous / next effect. Space: replay. Click: fire the flight toward the mouse.
## Works without the autoload: it makes its own Fx helper.

const FxScript := preload("fx.gd")

var fx: Node
var names: Array = []
var index := 0
var label := Label.new()
var _live: Array = []


func _ready() -> void:
	if has_node("/root/Fx"):
		fx = get_node("/root/Fx")
	else:
		fx = FxScript.new()
		fx.name = "FxLocal"
		add_child(fx)
	names = fx.effect_names()
	label.position = Vector2(16, 12)
	add_child(label)
	_show()


func _unhandled_input(event: InputEvent) -> void:
	if names.is_empty():
		return
	if event.is_action_pressed("ui_right") or (event is InputEventKey and event.pressed and event.keycode == KEY_D):
		index = (index + 1) % names.size()
		_show()
	elif event.is_action_pressed("ui_left") or (event is InputEventKey and event.pressed and event.keycode == KEY_A):
		index = (index - 1 + names.size()) % names.size()
		_show()
	elif event.is_action_pressed("ui_accept"):
		_show()
	elif event is InputEventMouseButton and event.pressed:
		var from := get_viewport_rect().size * Vector2(0.5, 0.85)
		var dir: Vector2 = (get_global_mouse_position() - from).normalized()
		var bolt: AnimatedSprite2D = fx.spawn_flight(names[index], from, dir, self)
		if bolt:
			var tw := create_tween()
			tw.tween_property(bolt, "global_position", from + dir * 600.0, 0.8)
			tw.tween_callback(bolt.queue_free)


func _show() -> void:
	for n in _live:
		if is_instance_valid(n):
			n.queue_free()
	_live.clear()
	if names.is_empty():
		label.text = "No effects found. Put an effects pack folder in this project."
		return
	var effect: String = names[index]
	var clip_names: PackedStringArray = fx.clips(effect)
	label.text = "%s  (%d / %d)   clips: %s\nLeft/Right: effect   Space: replay   Click: flight toward the mouse" % [effect, index + 1, names.size(), ", ".join(clip_names)]
	var size := get_viewport_rect().size
	var cols := 5
	var i := 0
	for c in clip_names:
		if c.begins_with("flight_") and c != "flight_E":
			continue
		var pos := Vector2(size.x * (0.12 + 0.19 * (i % cols)), size.y * (0.3 + 0.32 * floori(i / float(cols))))
		var s: AnimatedSprite2D = fx.spawn(effect, c, pos, 0.0, self)
		if s:
			s.scale = Vector2(0.6, 0.6)
			if not s.sprite_frames.get_animation_loop(c):
				# keep one-shots repeating in the gallery
				if s.animation_finished.is_connected(s.queue_free):
					s.animation_finished.disconnect(s.queue_free)
				s.animation_finished.connect(s.play.bind(c))
			_live.append(s)
			var l := Label.new()
			l.text = c
			l.position = pos + Vector2(-40, 100)
			add_child(l)
			_live.append(l)
		i += 1
