shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D albedo_texture:source_color,filter_linear_mipmap;

uniform vec4 outline_color:source_color=
vec4(0.015, 0.012, 0.02, 1.0);

uniform float outline_width:
	hint_range(0.0, 5.0, 0.1)=1.5;

uniform float alpha_threshold:
	hint_range(0.0, 1.0)=0.5;

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 tex = texture(albedo_texture, UV);
	
	// discard transparent pixels
	if(tex.a<alpha_threshold){
		discard;
	}
	
	vec2 pixel_size=1.0/vec2(textureSize(albedo_texture, 0));
	vec2 offset=pixel_size*outline_width;
	
	float min_alpha=1.0;
	
	// sample eight neighboring texels.
	for(int x=-1;x<=1;x++){
		for(int y=-1;y<=1;y++){
			vec2 sample_uv = UV+vec2(float(x), float(y))*offset;
			
			float a = texture(albedo_texture, sample_uv).a;
			min_alpha=min(min_alpha, a);
		}
	}
	
	// draw outline inside the leaf sihouette
	if(min_alpha<alpha_threshold){
		ALBEDO=outline_color.rgb;
	}else{
		// for standalone testing, show the leaf texture
		ALBEDO=tex.rgb;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
