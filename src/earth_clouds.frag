#version 450

layout(binding = 0) uniform sampler2D cloud_texture;

layout(location = 1) uniform vec3 cam_pos;
layout(location = 4) uniform vec3 sun_direction;

layout(location = 0) in vec3 fs_pos;
layout(location = 1) in vec2 fs_coords;

layout(location = 0) out vec4 color;

void main() {
    float alpha = texture(cloud_texture, fs_coords).x / 2;
    float diffuse_coef = max(dot(normalize(fs_pos), normalize(sun_direction)), 0);
    color = vec4(vec3(diffuse_coef), alpha);
}
