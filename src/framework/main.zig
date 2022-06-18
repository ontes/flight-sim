usingnamespace @import("camera.zig");
usingnamespace @import("input.zig");
usingnamespace @import("math.zig");
usingnamespace @import("timer.zig");
usingnamespace @import("image.zig");
usingnamespace @import("geometry.zig");

pub const gl = @import("gl.zig");

usingnamespace switch (@import("builtin").os.tag) {
    .linux => @import("linux.zig"),
    .windows => @import("windows.zig"),
    else => @compileError("unsupported os"),
};
