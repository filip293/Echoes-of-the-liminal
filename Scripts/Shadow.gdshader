// Shader for an intense, procedural boiling shadow effect (No Texture Required).
shader_type spatial;

// Render mode to make the object ignore light and render both front and back faces.
render_mode unshaded, cull_disabled;

// --- Inspector Uniforms ---

//- Core Settings
uniform vec4 fuzz_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float fuzz_width : hint_range(0.0, 0.5, 0.001) = 0.25;

//- Boiling & Distortion
uniform float noise_scale : hint_range(0.1, 20.0) = 4.0;
uniform float boil_speed : hint_range(0.1, 2.0) = 0.6;
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.4;
uniform int octaves : hint_range(1, 8) = 5; // More octaves = more detail, higher cost

//- Intensity & Shape
uniform float edge_hardness : hint_range(0.01, 1.0) = 0.05;
uniform float cutoff : hint_range(0.0, 1.0) = 0.5;

//- Vertex Jitter
uniform float jitter_amount : hint_range(0.0, 0.1, 0.001) = 0.015;
uniform float jitter_speed : hint_range(0.1, 10.0) = 6.0;


// --- Procedural Noise Functions (No Texture Needed) ---

// 2D pseudo-random function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 2D Fractional Brownian Motion (fBm) - This creates the "boiling" cloud effect.
float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 0.0;
	
    for (int i = 0; i < octaves; i++) {
        value += amplitude * random(st);
        st *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}


void vertex() {
	// --- Vertex Jitter ---
	// We generate a simple random value based on vertex position and time.
	float jitter_noise = random(VERTEX.xy * 0.5 + TIME * jitter_speed);
	
	// We apply this noise value along the normal to make the silhouette distort.
	float jitter_displacement = (jitter_noise * 2.0 - 1.0) * jitter_amount;
	
	// Push the vertex outwards for the base outline and add the jitter.
	VERTEX.xyz += NORMAL * (fuzz_width + jitter_displacement);
}

void fragment() {
	// The solid black core of the character.
	if (FRONT_FACING) {
		ALBEDO = vec3(0.0, 0.0, 0.0);
		ALPHA = 1.0;

	} else {
		// --- The Chaotic Outline ---

		// 1. Create two layers of scrolling coordinates for our noise functions.
		vec2 base_uv = SCREEN_UV * noise_scale * 5.0; // Use SCREEN_UV for a more stable effect
		vec2 uv1 = base_uv + TIME * boil_speed;
		vec2 uv2 = base_uv * 0.7 - TIME * boil_speed * 0.8;
		
		// 2. Sample a single noise layer for distortion.
		float distortion = (random(uv2) * 2.0 - 1.0) * distortion_strength;
		
		// 3. Use the powerful fbm function to create the main boiling effect.
		// We apply the distortion to make the boiling warp and swirl.
		float main_noise = fbm(uv1 + distortion);

		// 4. Use Fresnel to fade the effect at the center of the silhouette.
		float fresnel = pow(1.0 - dot(NORMAL, VIEW), 2.0);
		
		// 5. Combine the fresnel and the final chaotic noise.
		float combined_effect = main_noise * fresnel;
		
		// 6. Use smoothstep for a high-contrast, inky result.
		float final_alpha = smoothstep(cutoff, cutoff + edge_hardness, combined_effect);
		
		// 7. Output the final color and alpha.
		ALBEDO = fuzz_color.rgb;
		ALPHA = final_alpha * fuzz_color.a;
	}
}