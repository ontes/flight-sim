#version 450

layout(location = 0) uniform float progress;

const float height = 0.005;

const vec2 positions[6] = {
    vec2(0, 0),
    vec2(1, 1),
    vec2(0, 1),
    vec2(0, 0),
    vec2(1, 0),
    vec2(1, 1)
};

void main() {
    gl_Position = vec4(vec2(progress, height) * positions[gl_VertexID] * 2 - 1, 0, 1);
}