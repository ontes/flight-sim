#version 450

layout(binding = 0) uniform sampler2D color_texture;

layout(location = 1) uniform vec3 cam_pos;
layout(location = 3) uniform vec3 sun_direction;

layout(location = 0) in vec3 fs_pos;
layout(location = 1) in vec2 fs_coords;
layout(location = 2) in vec3 fs_normal;

layout(location = 0) out vec4 color;

void main() {
    vec3 diffuse_color = texture(color_texture, fs_coords).rgb;
    float diffuse_coef = max(dot(normalize(fs_normal), normalize(sun_direction)), 0);

    float shininess = 50;
    vec3 specular_color = vec3(0.25);
	float specular_coef = max(dot(normalize(fs_normal), normalize(normalize(sun_direction) + normalize(cam_pos - fs_pos))), 0);
    
    color = vec4(diffuse_color * diffuse_coef + pow(specular_coef, shininess) * specular_color, 1);
}