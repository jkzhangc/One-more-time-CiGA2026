shader_type canvas_item;

uniform int dir = 0;
uniform float rotation_angle = 0.0;

void fragment() {
	if (dir == 1 && UV.y > 0.5) discard;
	if (dir == 2 && UV.y < 0.5) discard;
	if (dir == 3 && UV.x > 0.5) discard;
	if (dir == 4 && UV.x < 0.5) discard;

	vec2 uv = UV - 0.5;
	float c = cos(rotation_angle);
	float s = sin(rotation_angle);
	mat2 rot = mat2(vec2(c, s), vec2(-s, c));
	uv = rot * uv + 0.5;

	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0);
	} else {
		COLOR = texture(TEXTURE, uv);
	}
}
