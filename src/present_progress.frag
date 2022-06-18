#version 450

layout(location = 1) uniform vec3 ribbon_color;

layout(location = 0) out vec4 color;

void main() {
    color = vec4(ribbon_color, 1);
}