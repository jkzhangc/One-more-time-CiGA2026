	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture;
	uniform bool is_active = false;
	uniform vec2 mouse_pos = vec2(-10000.0, -10000.0);
	uniform float mouse_radius = 40.0;
	uniform vec2 fixed_pos_1 = vec2(-10000.0, -10000.0);
	uniform vec2 fixed_pos_2 = vec2(-10000.0, -10000.0);
	uniform vec2 fixed_pos_3 = vec2(-10000.0, -10000.0);
	uniform float fixed_radius = 75.0;
	// 边框颜色和宽度参数
	uniform vec4 border_color : source_color = vec4(0.2, 0.6, 1.0, 1.0); // 蓝色
	uniform float border_width = 3.0; // 边框像素宽度
	void fragment() {
	    vec4 screen_color = texture(screen_texture, SCREEN_UV);
	    COLOR = screen_color; // 默认输出原色
	    if (is_active) {
	        vec2 pixel_pos = SCREEN_UV / SCREEN_PIXEL_SIZE;
	        bool make_gray = false;
	        float max_border_alpha = 0.0; // 记录最大的边框透明度
	        // 1. 判断鼠标指示器范围 (仅用于黑白处理，不画边框，交给Sprite2D)
	        float dist_to_mouse = distance(pixel_pos, mouse_pos);
	        if (dist_to_mouse < mouse_radius) {
	            make_gray = true;
	        }
	        // 2. 判断固定遮罩范围及边框
	        float dist_to_fix1 = distance(pixel_pos, fixed_pos_1);
	        float dist_to_fix2 = distance(pixel_pos, fixed_pos_2);
	        float dist_to_fix3 = distance(pixel_pos, fixed_pos_3);
	        if (dist_to_fix1 < fixed_radius || dist_to_fix2 < fixed_radius || dist_to_fix3 < fixed_radius) {
	            make_gray = true;
	        }
	        // 计算固定遮罩的边框透明度 (带抗锯齿)
	        float fix1_border_diff = abs(dist_to_fix1 - fixed_radius);
	        float fix2_border_diff = abs(dist_to_fix2 - fixed_radius);
	        float fix3_border_diff = abs(dist_to_fix3 - fixed_radius);
	        // 使用 smoothstep 实现平滑的边缘过渡
	        max_border_alpha = max(max_border_alpha, smoothstep(border_width / 2.0 + 0.5, border_width / 2.0 - 0.5, fix1_border_diff));
	        max_border_alpha = max(max_border_alpha, smoothstep(border_width / 2.0 + 0.5, border_width / 2.0 - 0.5, fix2_border_diff));
	        max_border_alpha = max(max_border_alpha, smoothstep(border_width / 2.0 + 0.5, border_width / 2.0 - 0.5, fix3_border_diff));
	        // 3. 应用黑白效果
	        if (make_gray) {
	            float gray = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));
	            COLOR = vec4(gray, gray, gray, 1.0);
	        }
	        // 4. 应用固定遮罩的蓝色边框
	        if (max_border_alpha > 0.0) {
	            COLOR = mix(COLOR, border_color, max_border_alpha);
	        }
	    }
	}