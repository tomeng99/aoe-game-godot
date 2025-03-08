shader_type canvas_item;

uniform vec2 offset = vec2(0.5, 0.5);

void fragment() {
    vec2 shifted_uv = UV - offset * TEXTURE_PIXEL_SIZE * 16.0;
    COLOR = texture(TEXTURE, shifted_uv);
    
    COLOR.rgb = vec3(0.0, 0.0, 0.0);
    COLOR.a *= 0.25;
}
