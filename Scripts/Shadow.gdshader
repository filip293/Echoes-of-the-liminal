shader_type spatial;

// Render mode to make the object ignore light and render both front and back faces.
render_mode unshaded, cull_disabled;

// --- Inspector Uniforms ---

//- Core Settings
uniform vec4 fuzz_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float fuzz_width : hint_range(0.0, 0.5, 0.001) = 0.12;

//- Boiling & Distortion (for the aura's texture)
uniform float noise_scale : hint_range(0.1, 20.0) = 4.0;
uniform float boil_speed : hint_range(0.1, 2.0) = 0.4;
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.2;
uniform int octaves : hint_range(1, 8) = 3;

//- Intensity & Shape (SOFTNESS CONTROLS)
uniform float edge_hardness : hint_range(0.01, 2.0) = 0.5; // HIGHER = SOFTER EDGE
uniform float cutoff : hint_range(0.0, 1.0) = 0.5;
uniform float fresnel_power : hint_range(1.0, 8.0) = 4.0; // HIGHER = TIGHTER AURA

//- Vertex Wobble (for the outline's shape)
uniform float wobble_amount : hint_range(0.0, 0.2, 0.001) = 0.05;
uniform float wobble_speed : hint_range(0.1, 10.0) = 2.0;
uniform float wobble_scale : hint_range(0.1, 10.0) = 1.0;


// --- Procedural Noise Functions (No Texture Needed) ---

// 2D pseudo-random function for the boiling effect
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// A new, smoother noise function for the vertices
float smooth_noise(vec3 pos) {
    // We sample the same random function at three different offsets
    // and blend them. This creates a much smoother, less spiky result
    // without needing a complex Simplex noise function.
    float total = 0.0;
    total += random(pos.xy);
    total += random(pos.yz);
    total += random(pos.xz);
    return total / 3.0;
}

// 2D Fractional Brownian Motion (fBm) - This creates the "boiling" cloud effect.
float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    
    for (int i = 0; i < octaves; i++) {
        value += amplitude * random(st);
        st *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}


void vertex() {
	// --- SMOOTHER Vertex Wobble ---
	// We use our new smooth_noise function with the vertex position and time.
	// This creates a much more organic, wavy motion instead of spiky jitter.
	vec3 pos = VERTEX.xyz * wobble_scale + TIME * wobble_speed;
	float jitter_noise = smooth_noise(pos);
	
	// We apply this noise value along the normal to make the silhouette distort.
	float jitter_displacement = (jitter_noise * 2.0 - 1.0) * wobble_amount;
	
	// Push ALL vertices outwards to create the "hull" for the outline.
	VERTEX.xyz += NORMAL * (fuzz_width + jitter_displacement);
}

void fragment() {
	// The solid black core of the character.
	if (FRONT_FACING) {
		ALBEDO = vec3(0.0, 0.0, 0.0);
		ALPHA = 1.0;
	} 
	// The back-facing polygons of the expanded shell for the aura.
	else {
		// --- The SOFTER Chaotic Outline ---

		// 1. Create scrolling coordinates for our noise functions.
		vec2 base_uv = SCREEN_UV * noise_scale;
		vec2 uv1 = base_uv + TIME * boil_speed;
		vec2 uv2 = base_uv * 0.7 - TIME * boil_speed * 0.8;
		
		// 2. Sample a single noise layer for distortion.
		float distortion = (random(uv2) * 2.0 - 1.0) * distortion_strength;
		
		// 3. Use fbm to create the main boiling effect.
		float main_noise = fbm(uv1 + distortion);

		// 4. Use Fresnel to fade the effect at the center. Higher power makes it tighter.
		float fresnel = pow(1.0 - dot(NORMAL, VIEW), fresnel_power);
		
		// 5. Combine the fresnel and the final chaotic noise.
		float combined_effect = main_noise * fresnel;
		
		// 6. Use smoothstep for the fade. A larger 'edge_hardness' makes the fade SOFTER.
		float final_alpha = smoothstep(cutoff, cutoff + edge_hardness, combined_effect);
		
		// 7. Output the final color and alpha.
		ALBEDO = fuzz_color.rgb;
		ALPHA = final_alpha * fuzz_color.a;

		// **CRITICAL FIX**: This prevents rendering glitches.
		if (ALPHA < 0.01) {
			discard;
		}
	}
}