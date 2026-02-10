shader_type fog;

uniform float density : hint_range(0, 50) = 15.0;
uniform sampler2D noise_tex: repeat_enable; 
uniform float noise_scale = 0.1; 
uniform float contrast : hint_range(1.0, 5.0) = 2.5;
uniform float height_falloff = 3.0;
uniform float speed = 0.05;
uniform vec3 fog_color : source_color = vec3(0.05, 0.05, 0.07);

void fog() {
	// 1. Get the world position of the current 'fog bit'
	vec3 world_pos = WORLD_POSITION;
	
	// 2. Create coordinates for the noise
	// We use the world coordinates so the fog is pinned to the map
	// Dividing by noise_scale makes the clumps bigger or smaller
	vec2 moving_uv = world_pos.xz * noise_scale + vec2(TIME * speed);
	
	// 3. Sample the texture
	float n = texture(noise_tex, moving_uv).r;
	
	// 4. Contrast to get those 'Shrine' stringy gaps
	float final_n = pow(n * 1.5, contrast);
	
	// 5. Height falloff (UVW.y is always safe to use for height)
	float h_fade = clamp(pow(1.0 - UVW.y, height_falloff), 0.0, 1.0);
	
	// 6. Box masking (softens the square edges)
	vec3 edge_dist = abs(UVW * 2.0 - 1.0);
	float mask = 1.0 - max(edge_dist.x, max(edge_dist.y, edge_dist.z));
	mask = smoothstep(0.0, 0.4, mask);
	
	DENSITY = final_n * density * h_fade * mask;
	ALBEDO = fog_color;
	EMISSION = fog_color * 0.1;
}