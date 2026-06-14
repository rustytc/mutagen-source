shader_type canvas_item;

uniform float amount = 40.0;

void fragment() {
	vec2 uv = UV * 0.05;
	float a = fract(sin(dot(UV, vec2(12.9898, 78.233) * TIME)) * 438.5453) * 8.0;
	COLOR.a *= clamp(pow(a, amount), 0, 1);
}