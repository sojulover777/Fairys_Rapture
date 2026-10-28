Free Blood Splash  -  version 1.0.5

2 HD effects for top-down games, as PNG sheets, single frames and Godot 4 SpriteFrames.

- blood splash medium: effect (6 frames)
- blood droplets: effect (18 frames)

Each effect folder has horizontal PNG strips, single frames, a JSON with frame size, frame count, FPS and pivot, and a Godot 4 SpriteFrames file (godot/).

SMOOTH CLIPS
  Every idle, walk, run, attack and hurt animation (and every effect) also comes as <animation>_smooth: the same animation with twice the frames, played at twice the fps (same frame size, feet pivot and row order). Sheets, single frames, 128 px copies, colour variations and recolour masks included; Godot 4 SpriteFrames in godot/<name>_smooth_spriteframes.tres (animations <animation>_smooth_<direction>); the JSON lists them. Effects: <clip>_smooth sheets next to the originals, listed in each effect JSON.

ADDED IN 1.0.5
The pierce spurt from Blood & Gore Effects. This added effect comes without a _smooth copy: its frames are the full animation.
- blood pierce spurt (from Blood & Gore Effects): an arrow or bullet hit, pointing right (rotate it in the engine); colour variations azure, black, violet (ColourVariations/<colour>/blood-pierce-spurt/)

GODOT SPAWN HELPER
godot/fx_spawn/ holds Fx, a small autoload that spawns any effect in one line (Fx.spawn("frost", "impact", position)) and frees one-shots by itself; fx_gallery.tscn shows every effect in the project. See godot/fx_spawn/README_GODOT.txt (scripts MIT-0).

MORE IN THIS STYLE
  Blood & Gore Effects: https://sovdigital.itch.io/blood-and-gore-effects
  Effects Complete Edition: https://sovdigital.itch.io/effects-complete-edition
  Complete Edition (every pack, boss and effect in one download): https://sovdigital.itch.io/complete-edition
  Everything by Sova Digital: https://sovdigital.itch.io/

Anything added to this pack later is free if you already own it.
