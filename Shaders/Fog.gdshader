shader_type fog;

uniform float density : hint_range(0, 50) = 25.0; // Boosted base density
uniform vec3 fog_color : source_color = vec3(0.05, 0.07, 0.1);
uniform float height_falloff : hint_range(0.0, 10.0) = 5.0;
uniform float edge_fade : hint_range(0.0, 1.0) = 0.4;
uniform float speed = 0.08; // Slightly slower to help reprojection
uniform float noise_scale = 1.0;
uniform float detail_strength : hint_range(0.0, 1.0) = 0.75;
uniform float emission_strength : hint_range(0.0, 5.0) = 0.2;

float hash(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
			mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
			mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), 
		f.z);
}

void fog() {
	vec3 world_pos = WORLD_POSITION;
	float time = TIME * speed;
	
	// 1. Large base shapes
	float base_noise = noise(world_pos * noise_scale * 0.2 + time);
	
	// 2. High-frequency detail (the "strings")
	float detail_noise = noise(world_pos * noise_scale * 1.8 - time * 1.4);
	
	// 3. SHARP EROSION:
	// Instead of just subtracting, we use smoothstep to sharpen the gaps.
	// This prevents Temporal Reprojection from blurring the clumps into nothing.
	float erosion = smoothstep(0.2, 0.8, detail_noise * detail_strength);
	float final_n = clamp(base_noise - erosion, 0.0, 1.0);
	
	// Re-sharpen the final result
	final_n = smoothstep(0.1, 0.5, final_n);
	
	// 4. Ground hugger logic
	float h_fade = clamp(pow(1.0 - UVW.y, height_falloff), 0.0, 1.0);
	
	// 5. Masking
	vec3 edge_dist = abs(UVW * 2.0 - 1.0);
	float mask = 1.0 - max(edge_dist.x, max(edge_dist.y, edge_dist.z));
	mask = smoothstep(0.0, edge_fade, mask);
	
	DENSITY = final_n * density * h_fade * mask;
	ALBEDO = fog_color;
	EMISSION = fog_color * emission_strength;
}