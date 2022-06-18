const std = @import("std");

pub const Timer = struct {
    last_time: u64 = 0,
    delta_time: f32 = 0,
    second: bool = false,
    fps: u32 = 0,
    fps_counter: u32 = 0,

    pub fn update(self: *Timer) void {
        const time = @intCast(u64, std.time.milliTimestamp());
        self.delta_time = @intToFloat(f32, time - self.last_time) / 1000;

        self.fps_counter += 1;
        self.second = (self.last_time / 1000 != time / 1000);
        if (self.second) {
            self.fps = self.fps_counter;
            self.fps_counter = 0;
        }

        self.last_time = time;
    }
};
