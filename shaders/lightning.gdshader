shader_type canvas_item;

uniform float distortion_strength : hint_range(0.0, 0.1) = 0.02;
uniform float speed = 2.0;

void light() {
    // Используем стандартную UV вместо несуществующей LIGHT_UV
    vec2 uv = UV;
    
    // Создаем эффект "дыхания" или ряби
    uv.x += sin(uv.y * 20.0 + TIME * speed) * distortion_strength;
    uv.y += cos(uv.x * 20.0 + TIME * speed) * distortion_strength;
    
    // LIGHT_COLOR уже содержит текстуру света, умноженную на его цвет.
    // Мы можем использовать его напрямую и добавлять свои эффекты.
    vec3 final_color = LIGHT_COLOR.rgb;
    
    // Пример: слегка подкрашиваем свет в багровый оттенок для вашего вайба
    final_color = mix(final_color, vec3(1.0, 0.2, 0.2), 0.2);
    
    // Записываем результат в выходную переменную LIGHT
    LIGHT = vec4(final_color, 1.0) * LIGHT_ENERGY;
}