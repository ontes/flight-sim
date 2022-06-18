#version 450

layout(binding = 1) uniform sampler2D elev_normal_texture;
layout(binding = 2) uniform sampler2D day_texture;
layout(binding = 3) uniform sampler2D night_texture;
layout(binding = 4) uniform sampler2D water_normal_texture;

layout(location = 1) uniform vec3 cam_pos;
layout(location = 4) uniform vec3 sun_dir;
layout(location = 5) uniform vec3 headlight_pos;
layout(location = 6) uniform vec3 headlight_center_dir;
layout(location = 7) uniform float headlight_cutoff;
layout(location = 8) uniform float water_time;

layout(location = 0) in vec3 fs_pos;
layout(location = 1) in vec2 fs_coords;

layout(location = 0) out vec4 color;

vec3 get_water_normal_side(vec2 p) {
    float scale = 8;
    return normalize(texture(water_normal_texture, p * scale + vec2(1,0) * water_time).xyz + texture(water_normal_texture, p * scale + vec2(0,1) * water_time).xyz - 1);
}

vec3 get_water_normal() {
    vec3 w = abs(fs_pos);
    w /= dot(w, vec3(1));
    
    vec3 flat_normal = normalize(w.x * get_water_normal_side(fs_pos.yz) + w.y * get_water_normal_side(fs_pos.zx) + w.z * get_water_normal_side(fs_pos.xy));

    vec3 az = normalize(fs_pos);
    vec3 ay = normalize(cross(vec3(0,1,0), az));
    vec3 ax = normalize(cross(ay, az));

    return normalize(flat_normal.x * ax + flat_normal.y * ay + flat_normal.z * az);
}

void main() {
    vec3 day_color = texture(day_texture, fs_coords).rgb;
    vec3 night_color = texture(night_texture, fs_coords).rgb - vec3(0.1);
    vec3 specular_color = vec3(0.25);

    bool is_water = (1.8 * day_color.b > day_color.r + day_color.g);

    vec3 water_normal = normalize(get_water_normal());
    vec3 land_normal = normalize(texture(elev_normal_texture, fs_coords).xyz);
    vec3 normal_vector = is_water ? water_normal : land_normal;

    vec3 headlight_dir = normalize(headlight_pos - fs_pos);
    bool use_headlight = (dot(headlight_dir, headlight_center_dir) > headlight_cutoff);
    float headlight_dist = length(headlight_pos - fs_pos);
    float headlight_attuenation = 1 / (100 * headlight_dist * headlight_dist);

    float sun_diffuse_coef = max(dot(normal_vector, sun_dir), 0);
    float headlight_diffuse_coef = use_headlight ? max(dot(normal_vector, headlight_dir), 0) * headlight_attuenation : 0;
    float diffuse_coef = max(sun_diffuse_coef, headlight_diffuse_coef);

    float shininess = is_water ? 100 : 1;
	float specular_coef = max(dot(normal_vector, normalize(sun_dir + normalize(cam_pos - fs_pos))), 0);

    color = vec4(mix(night_color, day_color, diffuse_coef) + pow(specular_coef, shininess) * specular_color, 1);
}
