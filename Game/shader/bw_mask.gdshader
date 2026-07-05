shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform bool is_active = false;
uniform vec2 mouse_pos = vec2(-10000.0, -10000.0);
uniform float mouse_radius = 40.0;
uniform vec2 fixed_pos_1 = vec2(-10000.0, -10000.0);
uniform vec2 fixed_pos_2 = vec2(-10000.0, -10000.0);
uniform vec2 fixed_pos_3 = vec2(-10000.0, -10000.0);
uniform float fixed_radius = 75.0;
uniform float fixed_scale_1 = 1.0;
uniform float fixed_scale_2 = 1.0;
uniform float fixed_scale_3 = 1.0;
uniform vec4 border_color : source_color = vec4(0.2, 0.6, 1.0, 1.0);
uniform float border_width = 3.0;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	COLOR = screen_color;
	if (is_active) {
		bool make_gray = false;
		float max_border_alpha = 0.0;

		float dist_to_mouse = distance(local_pos, mouse_pos);
		if (dist_to_mouse < mouse_radius) {
			make_gray = true;
		}

		float dist_to_fix1 = distance(local_pos, fixed_pos_1);
		float dist_to_fix2 = distance(local_pos, fixed_pos_2);
		float dist_to_fix3 = distance(local_pos, fixed_pos_3);
		float eff_r1 = fixed_radius * fixed_scale_1;
		float eff_r2 = fixed_radius * fixed_scale_2;
		float eff_r3 = fixed_radius * fixed_scale_3;
		if (dist_to_fix1 < eff_r1 || dist_to_fix2 < eff_r2 || dist_to_fix3 < eff_r3) {
			make_gray = true;
		}

		float fix1_border_diff = abs(dist_to_fix1 - eff_r1);
		float fix2_border_diff = abs(dist_to_fix2 - eff_r2);
		float fix3_border_diff = abs(dist_to_fix3 - eff_r3);
		float lo = border_width / 2.0 - 0.5;
		float hi = border_width / 2.0 + 0.5;
		max_border_alpha = max(max_border_alpha, smoothstep(hi, lo, fix1_border_diff) * step(0.001, fixed_scale_1));
		max_border_alpha = max(max_border_alpha, smoothstep(hi, lo, fix2_border_diff) * step(0.001, fixed_scale_2));
		max_border_alpha = max(max_border_alpha, smoothstep(hi, lo, fix3_border_diff) * step(0.001, fixed_scale_3));

		if (make_gray) {
			float gray = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));
			COLOR = vec4(gray, gray, gray, 1.0);
		}
		if (max_border_alpha > 0.0) {
			COLOR = mix(COLOR, border_color, max_border_alpha);
		}
	}
}
