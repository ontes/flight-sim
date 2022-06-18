#version 450

layout(location = 0) uniform mat4 cam_mat;
layout(location = 2) uniform mat4 model_mat;

layout(location = 0) in vec3 pos;
layout(location = 1) in vec2 _;
layout(location = 2) in vec3 normal;

layout(location = 0) out vec3 fs_pos;
layout(location = 2) out vec3 fs_normal;

void main() {
    fs_pos = vec3(model_mat * vec4(pos, 1));
    fs_normal = transpose(inverse(mat3(model_mat))) * normal;
    gl_Position = cam_mat * vec4(fs_pos, 1);
}
