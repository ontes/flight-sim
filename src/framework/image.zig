const std = @import("std");
const c = @import("c.zig");
const gl = @import("gl.zig");

pub const Image = struct {
    size: [2]u32,
    channels: u8,
    data: [*]u8,

    pub fn load(data: []const u8) !Image {
        var width: c_int = 0;
        var height: c_int = 0;
        var channels: c_int = 0;
        const loaded_data = c.stbi_load_from_memory(data.ptr, @intCast(c_int, data.len), &width, &height, &channels, 0) orelse return error.ImageParsingError;
        return Image{ .size = .{ @intCast(u32, width), @intCast(u32, height) }, .channels = @intCast(u8, channels), .data = loaded_data };
    }

    pub fn loadFromFile(path: []const u8) !Image {
        var data = try std.fs.cwd().readFileAlloc(std.heap.c_allocator, path, 100_000_000);
        defer std.heap.c_allocator.free(data);
        return load(data);
    }

    pub fn destroy(self: Image) void {
        c.stbi_image_free(self.data);
    }

    pub fn defaultTextureFormat(self: Image) gl.TextureFormat {
        return switch (self.channels) {
            1 => .r8,
            2 => .rg8,
            3 => .rgb8,
            4 => .rgba8,
            else => unreachable,
        };
    }

    pub fn defaultMipmapLevel(self: Image) u8 {
        return @intCast(u8, std.math.log2(std.math.min(self.size[0], self.size[1])));
    }

    pub fn toTexture(self: Image) gl.Texture {
        const texture = gl.Texture.create(self.defaultTextureFormat(), self.size, self.defaultMipmapLevel());
        texture.storage(self.size, self.channels, self.data);
        texture.generateMipmap();
        return texture;
    }
};
