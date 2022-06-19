#version 450

layout(binding = 0) uniform sampler2D elev_texture;

layout(location = 0) uniform mat4 cam_mat;
layout(location = 2) uniform uint r;
layout(location = 3) uniform uint i;

layout(location = 0) out vec3 fs_pos;
layout(location = 1) out vec2 fs_coords;

#define PI 3.1415926535897932384626433832795

vec2 to_coords(in vec3 p) {
    float x = atan(p.x, p.z) / PI / 2;
    x = x < 0 ? x + 1 : x;
    x = abs(x) < 0.0001 && (i / 3) % 2 != 0 ? 1 : x;
    x = abs(x-1) < 0.0001 && (i / 3) % 2 == 0 ? 0 : x;
    return vec2(
        x,
        0.5 - asin(p.y) / PI
    );
}

vec3 elevate(in vec3 p, float elev) {
    return (1 + elev / 32) * p;
}

vec3 to_sphere(in vec3 p) {
    return vec3(
        p.x * sqrt(1 - p.y * p.y / 2 - p.z * p.z / 2 + p.y * p.y * p.z * p.z / 3),
        p.y * sqrt(1 - p.z * p.z / 2 - p.x * p.x / 2 + p.z * p.z * p.x * p.x / 3),
        p.z * sqrt(1 - p.x * p.x / 2 - p.y * p.y / 2 + p.x * p.x * p.y * p.y / 3)
    );
}

void main() {
    uint start_i = i / 3;
    vec3 start = vec3(
        start_i % 2 == 0 ? 1 : -1,
        start_i / 4 == 0 ? 1 : -1,
        (start_i % 4) / 2 == 0 ? 1 : -1
    );

    uint dir_i = i % 3;
    vec3 da = -start * vec3(
        dir_i == 0,
        dir_i == 1,
        dir_i == 2
    );
    vec3 db = -start * vec3(
        dir_i == 1,
        dir_i == 2,
        dir_i == 0
    );
    bool orientation = (start_i % 2 + start_i / 4 + (start_i % 4) / 2) % 2 != 0;
    vec3 dx = orientation ? da : db;
    vec3 dy = orientation ? db : da;

    vec3 cube_pos = start + (uint(gl_VertexID / r) * dx + uint(gl_VertexID % r) * dy) / (r - 1);
    vec3 sphere_pos = to_sphere(cube_pos);
    fs_coords = to_coords(sphere_pos);
    fs_pos = elevate(sphere_pos, texture(elev_texture, fs_coords).x);
    gl_Position = cam_mat * vec4(fs_pos, 1);
}