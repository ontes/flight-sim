const std = @import("std");
const fr = @import("framework");

const Vertex = fr.Geometry.Vertex;

var program: fr.gl.Program = undefined;
var array: fr.gl.VertexArray = undefined;

var vertex_buf: fr.gl.Buffer = undefined;
var texture: fr.gl.Texture = undefined;
var groups: []fr.Geometry.Group = undefined;

const scale = 0.002;
const height = 1.1;
const base_speed = fr.Vec2{ .x = 0.075 };
const top_speed = fr.Vec2{ .x = 0.05, .y = 1.5 };

pub var speed = fr.Vec2{};
pub var rotation = fr.Mat3{};
var propeller_angle: f32 = 0;

pub fn init() !void {
    program = try fr.gl.Program.create(&.{
        .{ .t = .vertex_shader, .src = @embedFile("plane.vert") },
        .{ .t = .fragment_shader, .src = @embedFile("plane.frag") },
    });
    array = fr.gl.VertexArray.create();

    var geometry = try fr.Geometry.loadFromFile("assets/plane.obj");
    defer geometry.destroy();

    groups = try std.heap.c_allocator.dupe(fr.Geometry.Group, geometry.groups);

    vertex_buf = fr.gl.Buffer.create();
    vertex_buf.storage(Vertex, geometry.vertices);
    array.addVertexBuffer(Vertex, vertex_buf);

    {
        const plane_img = try fr.Image.loadFromFile("assets/plane.png");
        defer plane_img.destroy();
        texture = plane_img.toTexture();
    }
}

pub fn deinit() void {
    vertex_buf.destroy();
    texture.destroy();
    std.heap.c_allocator.free(groups);
    program.destroy();
    array.destroy();
}

pub fn update(timer: fr.Timer, forces: fr.Vec2) void {
    propeller_angle += 16 * std.math.pi * timer.delta_time;

    const delta_speed = speed.multiply(-timer.delta_time).add(forces.multiply(timer.delta_time));
    speed = speed.add(delta_speed);

    const delta_rotation = fr.Mat3.rotationZ((base_speed.y + top_speed.y * speed.y) * timer.delta_time).multiply(fr.Mat3.rotationX(-(base_speed.x + top_speed.x * speed.x) * timer.delta_time));
    rotation = rotation.multiply(delta_rotation);
}

fn transform() fr.Mat4 {
    var mat = fr.Mat4.scalingXYZ(scale);
    mat = fr.Mat4.rotationX(std.math.pi * 0.1 * (speed.x - 0.5)).multiply(fr.Mat4.rotationZ(-std.math.pi * 0.5 * speed.y).multiply(mat));
    mat = fr.Mat4.rotationX(std.math.pi * 0.5).multiply(fr.Mat4.rotationY(std.math.pi).multiply(mat));
    mat = fr.Mat4.translation(.{ .z = height }).multiply(mat);
    mat = rotation.toMat4().multiply(mat);
    return mat;
}

pub fn headlightTransform() fr.Mat4 {
    var mat = fr.Mat4.scalingXYZ(scale);
    mat = fr.Mat4.rotationX(std.math.pi * 0.05 * (speed.x - 0.5)).multiply(fr.Mat4.rotationZ(-std.math.pi * 0.2 * speed.y).multiply(mat));
    mat = fr.Mat4.rotationX(std.math.pi * 0.5).multiply(fr.Mat4.rotationY(std.math.pi).multiply(mat));
    mat = fr.Mat4.translation(.{ .z = height }).multiply(mat);
    mat = rotation.toMat4().multiply(mat);
    return mat;
}

pub fn draw(cam: fr.Camera, sun_direction: fr.Vec3) void {
    texture.bind(0);
    program.setUniform(0, cam.mat());
    program.setUniform(1, cam.position);
    program.setUniform(3, sun_direction);

    const model_mat = transform();

    for (groups) |group, i| {
        program.setUniform(2, switch (i) {
            1 => model_mat.multiply(fr.Mat4.translation(.{ .y = -0.2 }).multiply(fr.Mat4.rotationZ(propeller_angle).multiply(fr.Mat4.translation(.{ .y = 0.2 })))),
            else => model_mat,
        });
        fr.gl.draw(.triangles, program, array, group.first, group.len);
    }
}
