shader_type canvas_item;

uniform float beat_speed : hint_range(0.5, 5.0) = 2.0;
uniform vec4 flesh_color : source_color = vec4(0.8, 0.1, 0.1, 1.0);

void light() {
    float t = mod(TIME * beat_speed, 1.0);
    float beat = exp(-10.0 * t) + exp(-10.0 * mod(t + 0.15, 1.0));
    
    // ИСПРАВЛЕНО: Присваиваем цвет напрямую в LIGHT, а не в LIGHT_COLOR
    LIGHT.rgb = flesh_color.rgb * (0.3 + beat * 1.5);
}