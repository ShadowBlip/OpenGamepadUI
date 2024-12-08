shader_type canvas_item;
render_mode blend_premul_alpha;

uniform float Line_Smoothness : hint_range(0, 0.1) = 0.045;
uniform float Line_Width : hint_range(0, 0.2) = 0.09;
uniform float Brightness = 3.0;
uniform float Rotation_deg : hint_range(-90, 90) = 30;
uniform float Distortion : hint_range(1, 2) = 1.8;
uniform float Speed = 0.7;
uniform float Position : hint_range(0, 1) = 0;
uniform float Position_Min = 0.25;
uniform float Position_Max = 0.5;
uniform float Alpha : hint_range(0, 1) = 1;

vec2 rotate_uv(vec2 uv, vec2 center, float rotation, bool use_degrees){
		float _angle = rotation;
		if(use_degrees){
			_angle = rotation * (3.1415926/180.0);
		}
		mat2 _rotation = mat2(
			vec2(cos(_angle), -sin(_angle)),
			vec2(sin(_angle), cos(_angle))
		);
		vec2 _delta = uv - center;
		_delta = _rotation * _delta;
		return _delta + center;
	}

void fragment() {

	vec2 center_uv = UV - vec2(0.5, 0.5);
	float gradient_to_edge = max(abs(center_uv.x), abs(center_uv.y));
	gradient_to_edge = gradient_to_edge * Distortion;
	gradient_to_edge = 1.0 - gradient_to_edge;
	vec2 rotaded_uv = rotate_uv(UV, vec2(0.5, 0.5), Rotation_deg, true);

	float remapped_position;
	{
		float output_range = Position_Max - Position_Min;
		remapped_position = Position_Min + output_range * Position;
	}

	float remapped_time = TIME * Speed + remapped_position;
	remapped_time = fract(remapped_time);
	{
		float output_range = 2.0 - (-2.0);
		remapped_time = -2.0 + output_range * remapped_time;
	}

	vec2 offset_uv = vec2(rotaded_uv.xy) + vec2(remapped_time, 0.0);
	float line = vec3(offset_uv, 0.0).x;
	line = abs(line);
	line = gradient_to_edge * line;
	line = sqrt(line);

	float line_smoothness = clamp(Line_Smoothness, 0.001, 1.0);
	float offset_plus = Line_Width + line_smoothness;
	float offset_minus = Line_Width - line_smoothness;

	float remapped_line;
	{
		float input_range = offset_minus - offset_plus;
		remapped_line = (line - offset_plus) / input_range;
	}
	remapped_line = remapped_line * Brightness;
	remapped_line = min(remapped_line, Alpha);
	COLOR.rgb = vec3(COLOR.xyz) * vec3(remapped_line);
	COLOR.a = remapped_line;
}
