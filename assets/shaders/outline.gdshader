shader_type canvas_item;

uniform bool on = true;
uniform vec4 color : source_color = vec4(1.0);
uniform float width : hint_range(0, 10) = 1.0;
uniform int pattern : hint_range(0, 2) = 0; // diamond, circle, square
uniform bool inside = false;
uniform bool add_margins = true; // only useful when inside is false
uniform float width_speed :hint_range(0.1, 10) = 1;
uniform bool Smooth = true;

void vertex() {
	if (on) {
		float _width = width + abs(((sin(TIME*width_speed) + 1.0f) -2.0f) * 5.0f);
		if (add_margins) {
			VERTEX += (UV * 2.0 - 1.0) * _width;
		}
	}
}

bool hasContraryNeighbour(vec2 uv, vec2 texture_pixel_size, sampler2D texture, float _width) {
	for (float i = -ceil(_width); i <= ceil(_width); i++) {
		float x = abs(i) > _width ? _width * sign(i) : i;
		float offset;
		
		if (pattern == 0) {
			offset = _width - abs(x);
		} else if (pattern == 1) {
			offset = floor(sqrt(pow(_width + 0.5, 2) - x * x));
		} else if (pattern == 2) {
			offset = _width;
		}
		
		for (float j = -ceil(offset); j <= ceil(offset); j++) {
			float y = abs(j) > offset ? offset * sign(j) : j;
			vec2 xy = uv + texture_pixel_size * vec2(x, y);
			
			if ((xy != clamp(xy, vec2(0.0), vec2(1.0)) || texture(texture, xy).a == 0.0) == inside) {
				return true;
			}
		}
	}
	
	return false;
}

void fragment() {
	if (on == true) {
		vec2 uv = UV;
		float _width = width + abs(((sin(TIME*width_speed) + 1.0f) -2.0f) * 5.0f);
		
		if (add_margins) {
			vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(_width * 2.0));
			
			uv = (uv - texture_pixel_size * _width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;
			
			if (uv != clamp(uv, vec2(0.0), vec2(1.0))) {
				COLOR.a = 0.0;
			} else {
				COLOR = texture(TEXTURE, uv);
			}
		} else {
			COLOR = texture(TEXTURE, uv);
		}
		
		if ((COLOR.a > 0.0) == inside && hasContraryNeighbour(uv, TEXTURE_PIXEL_SIZE, TEXTURE, _width)) {
			COLOR.rgb = inside ? mix(COLOR.rgb, color.rgb, color.a) : color.rgb;
			COLOR.a += (1.0 - COLOR.a) * color.a;
		}
	}
}