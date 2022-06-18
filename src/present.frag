#version 450

layout(location = 1) uniform vec3 cam_pos;
layout(location = 3) uniform vec3 sun_direction;
layout(location = 4) uniform vec3 diffuse_color;
layout(location = 5) uniform vec3 headlight_pos;
layout(location = 6) uniform vec3 headlight_center_dir;
layout(location = 7) uniform float headlight_cutoff;

layout(location = 0) in vec3 fs_pos;
layout(location = 1) in vec2 _;
layout(location = 2) in vec3 fs_normal;

layout(location = 0) out vec4 color;

void main() {
    vec3 headlight_dir = normalize(headlight_pos - fs_pos);
    bool use_headlight = (dot(headlight_dir, headlight_center_dir) > headlight_cutoff);
    float headlight_dist = length(headlight_pos - fs_pos);
    float headlight_attuenation = 1 / (100 * headlight_dist * headlight_dist);

    float sun_diffuse_coef = max(dot(normalize(fs_normal), sun_direction), 0);
    float headlight_diffuse_coef = use_headlight ? max(dot(normalize(fs_normal), headlight_dir), 0) * headlight_attuenation : 0;
    float diffuse_coef = max(sun_diffuse_coef, headlight_diffuse_coef);

    float shininess = 50;
    vec3 specular_color = vec3(0.25);
	float specular_coef = max(dot(normalize(fs_normal), normalize(sun_direction + normalize(cam_pos - fs_pos))), 0);
    
    color = vec4(diffuse_color * diffuse_coef + pow(specular_coef, shininess) * specular_color, 1);
}