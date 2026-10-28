Fx spawn helper for Godot 4.3 or newer (tested with Godot 4.6.2)

1. Copy the whole pack folder into your project (any place under res://).
2. Project > Project Settings > Globals > Autoload: add godot/fx_spawn/fx.gd with the name Fx.
3. Spawn effects in one line:
     Fx.spawn("frost", "impact", hit_position)                 # plays once, then frees itself
     var bolt = Fx.spawn_flight("frost", muzzle, aim_direction)  # looping projectile; move it and free it yourself
     Fx.chain("frost", ["area", "linger", "expiry"], spot, 3.0)  # forms, lingers 3 s, expires, frees itself
4. To see everything: open godot/fx_spawn/fx_gallery.tscn and press F6 (Left/Right: next effect, click: fire a flight).

Fx reads each effect's JSON (frame size, pivot, loop, layer) and its Godot SpriteFrames. Every call returns the
AnimatedSprite2D, so scale, modulate, speed_scale and z_index stay yours to change.
Flights pick the sprite row nearest to the direction; the small remaining angle is applied as rotation.
Colour variations: Fx also finds ColourVariations/<colour>/<effect>/; the name is then "<colour>/<effect>".
