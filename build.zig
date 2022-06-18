const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    // create an executable from 'app'
    const exe = b.addExecutable("flight-sim", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    // add 'framework' as a package
    exe.addPackagePath("framework", "src/framework/main.zig");
    exe.addIncludeDir("src/framework/include");

    // link C standard library
    exe.linkLibC();

    // link system libraries
    switch (target.os_tag orelse builtin.os.tag) {
        .linux => {
            exe.linkSystemLibrary("X11");
            exe.linkSystemLibrary("GLX");
            exe.linkSystemLibrary("GL");
        },
        .windows => {
            exe.linkSystemLibrary("gdi32");
            exe.linkSystemLibrary("opengl32");
        },
        else => @panic("unsupported os"),
    }

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
