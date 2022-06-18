const std = @import("std");
const fr = @import("framework");

const Vertex = struct {
    pos: fr.Vec3,
    map_pos: fr.Vec2,
};

const resolution = 256;
const cloud_resolution = 16;

var program: fr.gl.Program = undefined;
var array: fr.gl.VertexArray = undefined;
var index_buf: fr.gl.Buffer = undefined;

var cloud_program: fr.gl.Program = undefined;
var cloud_array: fr.gl.VertexArray = undefined;
var cloud_index_buf: fr.gl.Buffer = undefined;

var elev_texture: fr.gl.Texture = undefined;
var elev_normal_texture: fr.gl.Texture = undefined;
var day_texture: fr.gl.Texture = undefined;
var night_texture: fr.gl.Texture = undefined;
var cloud_texture: fr.gl.Texture = undefined;
var water_normal_texture: fr.gl.Texture = undefined;

pub var time_of_day: f32 = -0.1;
pub var water_time: f32 = 0;

pub fn init() !void {
    program = try fr.gl.Program.create(&.{
        .{ .t = .vertex_shader, .src = @embedFile("earth.vert") },
        .{ .t = .fragment_shader, .src = @embedFile("earth.frag") },
    });
    array = fr.gl.VertexArray.create();
    index_buf = fr.gl.Buffer.create();
    index_buf.storage(u32, &genIndices(resolution));
    array.addIndexBuffer(u32, index_buf);

    cloud_program = try fr.gl.Program.create(&.{
        .{ .t = .vertex_shader, .src = @embedFile("earth_clouds.vert") },
        .{ .t = .fragment_shader, .src = @embedFile("earth_clouds.frag") },
    });
    cloud_array = fr.gl.VertexArray.create();
    cloud_index_buf = fr.gl.Buffer.create();
    cloud_index_buf.storage(u32, &genIndices(cloud_resolution));
    cloud_array.addIndexBuffer(u32, cloud_index_buf);

    {
        const elev_img = try fr.Image.loadFromFile("assets/earth_elev.png");
        defer elev_img.destroy();
        elev_texture = elev_img.toTexture();
        elev_texture.setWrapVertical(.clamp_to_edge);

        elev_normal_texture = fr.gl.Texture.create(.rgb8_snorm, elev_img.size, elev_img.defaultMipmapLevel());
        const framebuffer = fr.gl.Framebuffer.create();
        defer framebuffer.destroy();
        framebuffer.attachColorTexture(elev_normal_texture);
        framebuffer.bind();
        defer fr.gl.Framebuffer.unbind();

        const normal_program = try fr.gl.Program.create(&.{
            .{ .t = .vertex_shader, .src = @embedFile("earth_normal.vert") },
            .{ .t = .fragment_shader, .src = @embedFile("earth_normal.frag") },
        });
        defer normal_program.destroy();

        const normal_array = fr.gl.VertexArray.create();
        defer normal_array.destroy();

        normal_program.setUniform(0, fr.Vec2{ .x = @intToFloat(f32, elev_img.size[0]), .y = @intToFloat(f32, elev_img.size[1]) });
        elev_texture.bind(0);
        fr.gl.setViewport(.{ 0, 0 }, elev_img.size);
        fr.gl.draw(.triangles, normal_program, normal_array, 0, 3);

        elev_normal_texture.generateMipmap();
        elev_normal_texture.setWrapVertical(.clamp_to_edge);
    }
    {
        const day_img = try fr.Image.loadFromFile("assets/earth_day.png");
        defer day_img.destroy();
        day_texture = day_img.toTexture();
        day_texture.setWrapVertical(.clamp_to_edge);
    }
    {
        const night_img = try fr.Image.loadFromFile("assets/earth_night.png");
        defer night_img.destroy();
        night_texture = night_img.toTexture();
        night_texture.setWrapVertical(.clamp_to_edge);
    }
    {
        const clouds_img = try fr.Image.loadFromFile("assets/earth_clouds.png");
        defer clouds_img.destroy();
        cloud_texture = clouds_img.toTexture();
        cloud_texture.setWrapVertical(.clamp_to_edge);
    }
    {
        const water_normal_img = try fr.Image.loadFromFile("assets/water_normal.png");
        defer water_normal_img.destroy();
        water_normal_texture = water_normal_img.toTexture();
    }
}

fn indexCount(r: u32) usize {
    return (r - 1) * (r - 1) * 6;
}

fn genIndices(comptime r: u32) [indexCount(r)]u32 {
    var indices: [indexCount(r)]u32 = undefined;
    var ai: u32 = 0;
    while (ai < r - 1) : (ai += 1) {
        var bi: u32 = 0;
        while (bi < r - 1) : (bi += 1) {
            const i = ai * r + bi;
            const j = ai * (r - 1) + bi;
            indices[6 * j + 0] = i;
            indices[6 * j + 1] = i + r;
            indices[6 * j + 2] = i + r + 1;
            indices[6 * j + 3] = i;
            indices[6 * j + 4] = i + r + 1;
            indices[6 * j + 5] = i + 1;
        }
    }
    return indices;
}

pub fn deinit() void {
    elev_texture.destroy();
    elev_normal_texture.destroy();
    day_texture.destroy();
    night_texture.destroy();
    cloud_texture.destroy();
    water_normal_texture.destroy();
    program.destroy();
    array.destroy();
    index_buf.destroy();
    cloud_program.destroy();
    cloud_array.destroy();
    cloud_index_buf.destroy();
}

pub fn sunDirection() fr.Vec3 {
    return fr.Mat3.rotationY(2.0 * std.math.pi * time_of_day).multiplyVec3(.{ .z = 1 });
}

pub fn update(timer: fr.Timer) void {
    time_of_day += timer.delta_time / 128;
    water_time += timer.delta_time / 64;
}

pub fn draw(cam: fr.Camera, headlight_pos: fr.Vec3, headlight_dir: fr.Vec3, headlight_cutoff: f32) void {
    {
        elev_texture.bind(0);
        elev_normal_texture.bind(1);
        day_texture.bind(2);
        night_texture.bind(3);
        water_normal_texture.bind(4);

        program.setUniform(0, cam.mat());
        program.setUniform(1, cam.position);
        program.setUniform(2, @as(u32, resolution));
        program.setUniform(4, sunDirection());
        program.setUniform(5, headlight_pos);
        program.setUniform(6, headlight_dir);
        program.setUniform(7, headlight_cutoff);
        program.setUniform(8, water_time);

        var i: u8 = 0;
        while (i < 24) : (i += 1) {
            program.setUniform(3, @as(u32, i));
            fr.gl.draw(.triangles, program, array, 0, @intCast(u32, indexCount(resolution)));
        }
    }
    {
        fr.gl.enableAlphaBlending();
        cloud_texture.bind(0);
        cloud_program.setUniform(0, cam.mat());
        cloud_program.setUniform(1, cam.position);
        cloud_program.setUniform(2, @as(u32, cloud_resolution));
        cloud_program.setUniform(4, sunDirection());

        var i: u8 = 0;
        while (i < 24) : (i += 1) {
            cloud_program.setUniform(3, @as(u32, i));
            fr.gl.draw(.triangles, cloud_program, cloud_array, 0, @intCast(u32, indexCount(cloud_resolution)));
        }
    }
}
