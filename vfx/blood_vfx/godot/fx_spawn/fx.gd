extends Node
## Fx: one-line spawning for SovDigital effects packs (Godot 4.3 or newer). Licence: MIT-0 (see LICENSE_MIT0.txt).
##
## Setup (once): Project > Project Settings > Globals > Autoload: add this file as "Fx".
## The pack folder can sit anywhere under res://. On first use Fx finds every effects/<name>/<name>.json with its
## godot/<name>_spriteframes.tres (or call Fx.scan("res://path/to/pack") yourself, e.g. in a loading screen).
##
##   Fx.spawn("frost", "impact", hit_position)                  # one-shot: plays once, then frees itself
##   Fx.spawn("frost", "cast", hand_position, 0.0, self)        # optional rotation (radians) and parent node
##   var bolt := Fx.spawn_flight("frost", muzzle_position, aim_direction)   # looping projectile sprite, you move and free it
##   Fx.chain("frost", ["area", "linger", "expiry"], ground_position, 3.0)   # form, linger 3 s, expire, free
##   Fx.clips("frost")                                          # clip names of an effect
##
## Every call returns the AnimatedSprite2D, so you can change scale, modulate, speed_scale or z_index.
## Flights: the sprite row nearest to the direction is chosen (S, SE, E, NE, N, NW, W, SW). If an effect does not have that
## exact row, the nearest row is used and the sprite is turned by the small difference.

const HEADINGS := {"E": 0.0, "SE": 45.0, "S": 90.0, "SW": 135.0, "W": 180.0, "NW": 225.0, "N": 270.0, "NE": 315.0}
const LAYER_Z := {"ground": -1, "behind": -1, "front": 1, "overhead": 2}

var _effects := {}   # name -> {"frames": SpriteFrames path, "meta": Dictionary}
var _cache := {}     # name -> SpriteFrames
var _scanned := false


func scan(root: String = "res://") -> int:
	_scanned = true
	var found := 0
	var stack: Array[String] = [root]
	while stack.size() > 0:
		var d: String = stack.pop_back()
		var da := DirAccess.open(d)
		if da == null:
			continue
		for sub in da.get_directories():
			if sub.begins_with(".") or sub == "frames" or sub == "_sizes":
				continue
			stack.append(d.path_join(sub))
		var name := d.get_file()
		var json_path := d.path_join(name + ".json")
		var tres_path := d.path_join("godot").path_join(name + "_spriteframes.tres")
		if FileAccess.file_exists(json_path) and ResourceLoader.exists(tres_path):
			var meta = JSON.parse_string(FileAccess.get_file_as_string(json_path))
			if typeof(meta) != TYPE_DICTIONARY:
				meta = {}
			var key := name
			if d.contains("/ColourVariations/") or (_effects.has(key) and _effects[key]["frames"] != tres_path):
				key = d.get_base_dir().get_file() + "/" + name   # colour folders: "<colour>/<effect>"
			_effects[key] = {"frames": tres_path, "meta": meta}
			found += 1
	return found


func has_effect(effect: String) -> bool:
	_ensure()
	return _effects.has(effect)


func effect_names() -> Array:
	_ensure()
	var names := _effects.keys()
	names.sort()
	return names


func clips(effect: String) -> PackedStringArray:
	var sf := _frames_of(effect)
	return sf.get_animation_names() if sf else PackedStringArray()


func spawn(effect: String, clip: String, at: Vector2, rotation_rad: float = 0.0, parent: Node = null) -> AnimatedSprite2D:
	var s := _make(effect, clip, parent)
	if s == null:
		return null
	s.global_position = at
	s.rotation = rotation_rad
	if not s.sprite_frames.get_animation_loop(clip):
		s.animation_finished.connect(s.queue_free)
	return s


func spawn_flight(effect: String, at: Vector2, direction: Vector2, parent: Node = null) -> AnimatedSprite2D:
	var sf := _frames_of(effect)
	if sf == null:
		return null
	var deg := fposmod(rad_to_deg(direction.angle()), 360.0)
	var best := ""
	var best_d := 999.0
	for h in HEADINGS:
		if not sf.has_animation("flight_" + h):
			continue
		var dd: float = abs(angle_difference(deg_to_rad(deg), deg_to_rad(HEADINGS[h])))
		if dd < best_d:
			best_d = dd
			best = h
	if best == "":
		push_warning("Fx: %s has no flight_<heading> animations" % effect)
		return null
	var s := _make(effect, "flight_" + best, parent, "flight")
	s.global_position = at
	s.rotation = angle_difference(deg_to_rad(HEADINGS[best]), deg_to_rad(deg))
	return s


func chain(effect: String, clip_names: Array, at: Vector2, hold_loop_seconds: float = 2.0, parent: Node = null) -> AnimatedSprite2D:
	var s := _make(effect, clip_names[0], parent)
	if s == null:
		return null
	s.global_position = at
	_run_chain(s, clip_names, hold_loop_seconds)
	return s


func _run_chain(s: AnimatedSprite2D, clip_names: Array, hold: float) -> void:
	for i in clip_names.size():
		if not is_instance_valid(s):
			return
		var c: String = clip_names[i]
		if i > 0:
			s.play(c)
		if s.sprite_frames.get_animation_loop(c):
			await get_tree().create_timer(hold).timeout
		else:
			await s.animation_finished
	if is_instance_valid(s):
		s.queue_free()


func _ensure() -> void:
	if not _scanned:
		scan("res://")


func _frames_of(effect: String) -> SpriteFrames:
	_ensure()
	if _cache.has(effect):
		return _cache[effect]
	if not _effects.has(effect):
		push_warning("Fx: effect '%s' not found (scan a folder with Fx.scan)" % effect)
		return null
	var sf: SpriteFrames = load(_effects[effect]["frames"])
	_cache[effect] = sf
	return sf


func _make(effect: String, clip: String, parent: Node, meta_clip: String = "") -> AnimatedSprite2D:
	var sf := _frames_of(effect)
	if sf == null:
		return null
	if not sf.has_animation(clip):
		push_warning("Fx: %s has no clip '%s' (clips: %s)" % [effect, clip, ", ".join(sf.get_animation_names())])
		return null
	var s := AnimatedSprite2D.new()
	s.sprite_frames = sf
	var info: Dictionary = _effects[effect]["meta"].get("clips", {}).get(meta_clip if meta_clip != "" else clip, {})
	if info.has("pivot") and info.has("frame_size"):
		var fs: Array = info["frame_size"]
		var pv: Array = info["pivot"]
		s.offset = Vector2(fs[0] * 0.5 - pv[0], fs[1] * 0.5 - pv[1])
	if info.get("additive", false):
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		s.material = m
	s.z_index = LAYER_Z.get(info.get("layer", "front"), 0)
	var p: Node = parent if parent != null else get_tree().current_scene
	if p == null:
		p = get_tree().root
	p.add_child(s)
	s.play(clip)
	return s
