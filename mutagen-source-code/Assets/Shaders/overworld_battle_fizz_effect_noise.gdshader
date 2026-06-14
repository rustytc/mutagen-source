shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 10.0) = 1.0; // Fizz strength
uniform float darkness : hint_range(0.0, 1.0) = 0.0;   // 0 = no darkening, 1 = full black
uniform float color_bleed_strength : hint_range(0.0, 5.0) = 1.0; // Color bleed offset amount

float get_noise(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;

    // Time-based noise
    float noise = get_noise(uv + vec2(TIME * 20.0, sin(TIME * 5.0)));

    // Color channel offsets for chromatic aberration
    vec2 offset = vec2(0.002 * color_bleed_strength); // base offset scale
    vec4 red   = texture(SCREEN_TEXTURE, uv + offset);
    vec4 green = texture(SCREEN_TEXTURE, uv);
    vec4 blue  = texture(SCREEN_TEXTURE, uv - offset);
    vec3 color_bleed = vec3(red.r, green.g, blue.b);

    // Fizz effect
    vec3 fizz = vec3(noise * intensity, 0.0, 0.0);
    vec3 color = clamp(color_bleed + fizz, 0.0, 1.0);

    // Darkness overlay
    color = mix(color, vec3(0.0), darkness);

    COLOR = vec4(color, 1.0);
}
