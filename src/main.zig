const std = @import("std");
const fr = @import("framework");
const earth = @import("earth.zig");
const plane = @import("plane.zig");
const presents = @import("presents.zig");

var input = fr.Input{};
var timer = fr.Timer{};
var cam = fr.Camera{
    .position = .{ .z = 2 },
    .direction = .{ .z = 1 },
    .fov = std.math.pi / 4.0,
    .aspect = 1,
    .near = 0.01,
    .far = 10,
};

var cam_distance: f32 = 1.8;
var snap_cam = false;
var headlights_on = false;

pub fn main() anyerror!void {
    try fr.init();
    defer fr.deinit();

    var win = try fr.Window.create(.{ 0, 0 }, .{ 1280, 720 }, "Hyper-Realistic Flight Simulator", eventCallback);
    defer win.destroy();
    win.show();

    try win.createGlContext(8, 8, 8, 0, 0);
    try win.makeCurrent();

    fr.gl.init();
    std.log.info("GL Version: {s}", .{fr.gl.getVersion()});

    // win.setSwapInterval(0);
    fr.gl.enableDepthTest();
    fr.gl.enableFaceCulling();
    // fr.gl.setPolygonMode(.line);

    try earth.init();
    defer earth.deinit();

    try plane.init();
    defer plane.deinit();

    try presents.init();
    defer presents.deinit();

    timer.update();

    while (!input.should_close) {
        win.pollEvents();

        timer.update();
        if (timer.second) {
            std.log.info("{} FPS", .{timer.fps});
        }

        earth.update(timer);

        var speed = fr.Vec2{};
        if (input.isPressed(.w)) speed.x += 1;
        if (input.isPressed(.s)) speed.x -= 1;
        if (input.isPressed(.a)) speed.y += 1;
        if (input.isPressed(.d)) speed.y -= 1;
        plane.update(timer, speed);
        presents.update(plane.rotation);

        cam.up = if (snap_cam) plane.rotation.multiplyVec3(.{ .y = 1 }) else .{ .y = 1 };
        cam.direction = plane.rotation.multiplyVec3(.{ .z = 1 });
        cam.position = plane.rotation.multiplyVec3(.{ .z = cam_distance });

        fr.gl.clearColor(.{ 0, 0, 0, 1 });
        fr.gl.clearDepth(1);
        fr.gl.setViewport(.{ 0, 0 }, input.window_size);
        cam.aspect = @intToFloat(f32, input.window_size[0]) / @intToFloat(f32, input.window_size[1]);

        const headlight_pos = plane.headlightTransform().multiplyVec3(.{});
        const headlight_dir = plane.headlightTransform().multiplyVec3(.{ .y = -1, .z = 0.5 }).add(headlight_pos.negate()).negate().normalize();
        const headlight_cutoff: f32 = if (headlights_on) 0.9 else 1.0;

        plane.draw(cam, earth.sunDirection());
        presents.draw(cam, earth.sunDirection(), headlight_pos, headlight_dir, headlight_cutoff);
        earth.draw(cam, headlight_pos, headlight_dir, headlight_cutoff);

        win.swapBuffers();
    }
}

fn eventCallback(event: fr.Event) void {
    input.handleEvent(event);

    switch (event) {
        .key_press => |key| switch (key) {
            .e => snap_cam = !snap_cam,
            .f => headlights_on = !headlights_on,
            else => {},
        },
        .mouse_scroll => |offset| {
            cam_distance = std.math.clamp(cam_distance - @intToFloat(f32, offset) / 10, 1.2, 8.0);
        },
        else => {},
    }
}
