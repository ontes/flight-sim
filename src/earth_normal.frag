#version 450

layout(binding = 0) uniform sampler2D elev_texture;
layout(location = 0) uniform vec2 texture_size;

layout(location = 0) out vec3 normal;

#define PI 3.1415926535897932384626433832795

vec3 from_coord(in vec2 p) {
    p.x *= PI * 2;
    p.y = (0.5 - p.y) * PI;
    return normalize(vec3(
        cos(p.y) * sin(p.x),
        sin(p.y),
        cos(p.y) * cos(p.x)
    ));
}

vec3 elevate(in vec3 p, float elev) {
    return (1 + elev / 32) * p;
}

vec3 earth_pos(ivec2 p) {
    return elevate(from_coord(vec2(p) / texture_size), texelFetch(elev_texture, p, 0).x);
}

void main() {
    vec3 north = earth_pos(ivec2(gl_FragCoord.xy) + ivec2(0, 1));
    vec3 south = earth_pos(ivec2(gl_FragCoord.xy) + ivec2(0, -1));
    vec3 east = earth_pos(ivec2(gl_FragCoord.xy) + ivec2(1, 0));
    vec3 west = earth_pos(ivec2(gl_FragCoord.xy) + ivec2(-1, 0));

    normal = normalize(cross(north - south, east - west));
}