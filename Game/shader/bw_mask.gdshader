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

// 外观参数
uniform vec4 border_color : source_color = vec4(0.78, 0.37, 0.3, 0.95);
uniform float border_width = 3.0;
uniform vec4 glow_color : source_color = vec4(0.5, 0.8, 1.0, 1.0);
uniform float glow_width = 14.0;
uniform float glow_intensity = 0.45;
uniform float desaturate_factor = 0.65;
uniform vec4 inner_tint : source_color = vec4(0.55, 0.78, 1.0, 1.0);
uniform float tint_strength = 0.28;
uniform vec4 ripple_color : source_color = vec4(0.7, 0.9, 1.0, 1.0);
uniform float ripple_speed = 60.0;
uniform float ripple_width_px = 2.5;
uniform float ripple_alpha = 0.22;
uniform float ripple_interval = 3.2;
uniform vec4 center_color : source_color = vec4(0.85, 0.95, 1.0, 1.0);
uniform float center_glow_intensity = 0.12;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

// 计算单个遮罩对当前像素的贡献
// 返回 vec4(in_mask, border_a, glow_a, ripple_a)
vec4 mask_contrib(vec2 center, float eff_r) {
	if (eff_r < 0.5) {
		return vec4(0.0);
	}
	float dist = distance(local_pos, center);

	// 是否在遮罩内
	float in_m = step(dist, eff_r);

	// 边框
	float bdiff = abs(dist - eff_r);
	float bw_lo = border_width * 0.5 - 0.5;
	float bw_hi = border_width * 0.5 + 0.5;
	float border = smoothstep(bw_hi, bw_lo, bdiff);

	// 柔光：外发光 + 内发光
	float outer_glow = 1.0 - smoothstep(0.0, glow_width, dist - eff_r);
	outer_glow *= step(0.0, dist - eff_r);
	float inner_w = glow_width * 0.6;
	float inner_glow = 1.0 - smoothstep(0.0, inner_w, eff_r - dist);
	inner_glow *= step(0.0, eff_r - dist);
	float glow = max(outer_glow, inner_glow * 0.7) * glow_intensity;

	// 波纹：从中心向外扩散的脉冲环，两环错相保证连续性
	float ripple_wavelength = ripple_speed * ripple_interval;
	float ring = 0.0;
	float rw = ripple_width_px;
	for (int i = 0; i < 2; i++) {
		float phase_offset = float(i) * ripple_interval * 0.5;
		float r = mod(TIME * ripple_speed + phase_offset * ripple_speed, ripple_wavelength);
		float pulse = smoothstep(r - rw, r, dist) * smoothstep(r + rw, r, dist);
		pulse *= step(dist, eff_r - 1.0);
		pulse *= smoothstep(0.0, rw * 2.0, dist);
		pulse *= 1.0 - clamp(r / (eff_r + 1.0), 0.0, 1.0);
		ring = max(ring, pulse);
	}
	ring *= ripple_alpha;

	return vec4(in_m, border, glow, ring);
}

// 中心柔光
float center_glow_f(vec2 center, float eff_r) {
	if (eff_r < 0.5) {
		return 0.0;
	}
	float dist = distance(local_pos, center);
	float inside = step(dist, eff_r);
	return (1.0 - smoothstep(0.0, eff_r * 0.5, dist)) * center_glow_intensity * inside;
}

void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	vec3 color = screen_color.rgb;

	if (is_active) {
		vec4 mc_mouse = mask_contrib(mouse_pos, mouse_radius);
		float eff1 = fixed_radius * fixed_scale_1;
		float eff2 = fixed_radius * fixed_scale_2;
		float eff3 = fixed_radius * fixed_scale_3;
		vec4 mc1 = mask_contrib(fixed_pos_1, eff1);
		vec4 mc2 = mask_contrib(fixed_pos_2, eff2);
		vec4 mc3 = mask_contrib(fixed_pos_3, eff3);

		float in_mask = max(max(mc_mouse.x, mc1.x), max(mc2.x, mc3.x));
		float border_a = max(max(mc_mouse.y, mc1.y), max(mc2.y, mc3.y));
		float glow_a = max(max(mc_mouse.z, mc1.z), max(mc2.z, mc3.z));
		float ripple_a = max(max(mc_mouse.w, mc1.w), max(mc2.w, mc3.w));
		float cg = max(
			max(center_glow_f(mouse_pos, mouse_radius), center_glow_f(fixed_pos_1, eff1)),
			max(center_glow_f(fixed_pos_2, eff2), center_glow_f(fixed_pos_3, eff3))
		);

		// 1. 降饱和 + 蓝色色调
		if (in_mask > 0.0) {
			float gray = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));
			vec3 desat = mix(screen_color.rgb, vec3(gray), desaturate_factor);
			vec3 tinted = mix(desat, inner_tint.rgb, tint_strength);
			color = mix(color, tinted, in_mask);
		}

		// 2. 中心高亮
		if (cg > 0.0) {
			color = mix(color, center_color.rgb, cg * center_color.a);
		}

		// 3. 内外柔光
		if (glow_a > 0.0) {
			color = mix(color, glow_color.rgb, glow_a * glow_color.a);
		}

		// 4. 波纹
		if (ripple_a > 0.0) {
			color = mix(color, ripple_color.rgb, ripple_a * ripple_color.a);
		}

		// 5. 边框（最上层）
		if (border_a > 0.0) {
			color = mix(color, border_color.rgb, border_a * border_color.a);
		}
	}

	COLOR = vec4(color, screen_color.a);
}
