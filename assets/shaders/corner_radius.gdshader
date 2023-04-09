shader_type canvas_item;

uniform float corner_radius = 120;

bool in_rect(vec2 uv,vec2 orign,vec2 end)
{
  return all(lessThan(uv,end))&&all( greaterThan(uv,orign));
}

bool is_hid(vec2 uv, vec2 size, float radius)
{
  vec2 center = vec2(size.x*0.5,size.y*0.5);
  vec2 a = vec2(radius,radius);
  vec2 b = vec2(size.x-radius,size.y-radius);
	
  vec2 c = vec2(size.x-radius,radius);
  vec2 d = vec2(radius,size.y-radius);
	
  vec2 rd_origin = vec2(size.x - radius,0);
  vec2 rd_end = vec2(size.x,radius);
	
  vec2 lu_origin = vec2(0,size.y - radius);
  vec2 lu_end = vec2(radius,size.y);
	
	
  if(!in_rect(uv,a,b))
  {
    float dis = radius - 1.f;
    if(in_rect(uv,vec2(0.f),a))
    {
      dis = distance(a,uv);
    }
    if(in_rect(uv,b,size))
    {
      dis = distance(b,uv);
    }
    if(in_rect(uv,rd_origin,rd_end))
    {			
      dis = distance(c,uv);
    }
    if(in_rect(uv,lu_origin,lu_end))
    {
      dis = distance(d,uv);
    }
    return dis > radius;		
  }
  return false;
}


void fragment() 
{
  float pixel_size_x = 1.0 / TEXTURE_PIXEL_SIZE.x;
  float pixel_size_y = 1.0 / TEXTURE_PIXEL_SIZE.y;
  float max_r = min(pixel_size_x,pixel_size_y) / 2.f;

if(is_hid(vec2(UV.x*pixel_size_x,UV.y*pixel_size_y),vec2(pixel_size_x,pixel_size_y),min(corner_radius,max_r)))  
  {
    COLOR = vec4(0.0);
  }
  else 
  {
    COLOR = texture(TEXTURE,UV);
  }
}