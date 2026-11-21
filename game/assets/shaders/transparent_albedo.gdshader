shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D albedo_texture:source_color, filter_linear_mipmap;

uniform vec4 base_color:source_color=vec4(1.0);

uniform vec3 shadow_color:source_color=
	vec3(0.45, 0.50, 0.65);

uniform float shadow_threshold:
	hint_range(0.0, 1.0)=0.45;

uniform float shadow_softness:
	hint_range(0.001, 0.5)=0.12;

uniform float ambient_strength:
	hint_range(0.0, 1.0)=0.35;

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 tex=texture(albedo_texture,UV);
	
	ALBEDO=tex.rgb*base_color.rgb;
	
	ROUGHNESS=1.0;
	METALLIC=0.0;
}

void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
	float ndotl = max(dot(NORMAL,LIGHT),0.0);
	
	float toon = smoothstep(
		shadow_threshold-shadow_softness,
		shadow_threshold+shadow_softness,
		ndotl
	);
	
	vec3 shade = mix(shadow_color,vec3(1.0), toon);
	
	float visibility=mix(
		ambient_strength,
		1.0,
		ATTENUATION
	);
	
	DIFFUSE_LIGHT+=
		ALBEDO*
		shade*
		LIGHT_COLOR*
		visibility;
}
