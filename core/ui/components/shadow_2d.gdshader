/**
* Shadow 2D.
* License: CC0
* https://creativecommons.org/publicdomain/zero/1.0/
*/
shader_type canvas_item;
render_mode blend_mix;

uniform vec2 deform = vec2(2.0, 2.0);
uniform vec2 offset = vec2(0.0, 0.0);
uniform vec4 modulate: source_color;

//uniform vec2 texture_size; //uncomment for GLES2

void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE;
	vec2 uv = UV;
	float sizex = float(textureSize(TEXTURE,int(ps.x)).x); //comment for GLES2
	float sizey = float(textureSize(TEXTURE,int(ps.y)).y); //comment for GLES2
	//float sizex = texture_size.x; //uncomment for GLES2
	//float sizey = texture_size.y; //uncomment for GLES2
	uv.y+=offset.y*ps.y;
	uv.x+=offset.x*ps.x;
	float decalx=((uv.y-ps.x*sizex)*deform.x);
	float decaly=((uv.y-ps.y*sizey)*deform.y);
	uv.x += decalx;
	uv.y += decaly;
	vec4 shadow = vec4(modulate.rgb, texture(TEXTURE, uv).a * modulate.a);
	vec4 col = texture(TEXTURE, UV);
	COLOR = mix(shadow, col, col.a);
}