shader_type spatial;
// We disable culling to render both the inside and outside of the expanded mesh.
render_mode unshaded, cull_disabled;

// --- Uniforms ---
// For the flack effect
uniform vec4 fuzz_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// THE CHANGES ARE HERE:
// 1. Made the default ball size much larger for a bigger, fuzzier effect.
uniform float fuzz_ball_size : hint_range(0.1, 2.0) = 0.8;
// 2. Reduced density to give the larger balls more space and prevent ugly clumping.
uniform float density : hint_range(0.1, 20.0) = 8.0;

uniform float boil_speed : hint_range(0.1, 2.0) = 0.4;
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.25;

// For controlling the shell thickness (distance from mesh)
uniform float shell_thickness : hint_range(0.0, 0.5, 0.001) = 0.03;
uniform float wobble_amount : hint_range(0.0, 0.2, 0.001) = 0.01;
uniform float wobble_speed : hint_range(0.1, 10.0) = 2.5;

// --- NEW UNIFORMS FOR CREEPY EFFECT ---
// Controls how much of the effect is "eaten away" or dissolved.
uniform float erosion_threshold : hint_range(0.0, 1.0) = 0.4;
// Controls the sharpness of the dissolved edges.
uniform float erosion_edge_sharpness : hint_range(1.0, 50.0) = 20.0;
// Speed for the creepy color pulsation.
uniform float pulse_speed : hint_range(0.1, 5.0) = 1.0;

// A 'varying' is used to pass data from the vertex shader to the fragment shader.
varying vec3 local_vertex_pos;

// --- Noise Functions ---
float random(vec2 st) {
    return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec2 worley(vec2 p) {
    vec2 n = floor(p);
    vec2 f = fract(p);
    float F1 = 8.0;
    float F2 = 8.0;
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = vec2(random(n + g), random(n + g + vec2(5.2, 1.3)));
            vec2 o_offset = o * 0.5 + 0.5;
            float d = distance(g + o_offset, f);
            if (d < F1) {
                F2 = F1;
                F1 = d;
            } else if (d < F2) {
                F2 = d;
            }
        }
    }
    return vec2(F1, F2);
}


void vertex() {
    local_vertex_pos = VERTEX;
    float jitter = (random(VERTEX.xy + TIME * wobble_speed) * 2.0 - 1.0) * wobble_amount;
    VERTEX += NORMAL * (shell_thickness + jitter);
}

void fragment() {
    if (FRONT_FACING) {
        discard;
    } else {
        vec2 uv = local_vertex_pos.xy * density + TIME * boil_speed;
        float distortion = random(uv) * distortion_strength;
        uv += distortion;

        vec2 worley_noise = worley(uv);
        
        // This line creates the ball. A larger fuzz_ball_size makes the gradient
        // happen over a larger distance, resulting in a softer, fuzzier look.
        float ball = 1.0 - smoothstep(0.0, fuzz_ball_size, worley_noise.x);

        // --- CREEPY EROSION EFFECT ---
        // We generate a second noise value to control the erosion.
        float erosion_noise = random(uv + vec2(12.34, 56.78)); // Use different offset for different noise
        
        // Use smoothstep to create a sharp transition based on the erosion threshold.
        float erosion_mask = smoothstep(erosion_threshold, erosion_threshold + (1.0 / erosion_edge_sharpness), erosion_noise);

        // --- CREEPY COLOR PULSATION ---
        // Pulsate the alpha channel of the fuzz_color to make it throb.
        vec4 final_color = fuzz_color;
        final_color.a *= (0.75 + sin(TIME * pulse_speed) * 0.25);

        ALBEDO = final_color.rgb;
        // Modulate the original alpha with the erosion mask.
        ALPHA = ball * final_color.a * erosion_mask;

        if (ALPHA < 0.01) {
            discard;
        }
    }
}