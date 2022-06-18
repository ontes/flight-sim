// partially based on https://github.com/ziglibs/wavefront-obj

const std = @import("std");
const math = @import("math.zig");

const allocator = std.heap.c_allocator;

pub const Geometry = struct {
    pub const Vertex = struct {
        pos: math.Vec3,
        coords: math.Vec2,
        normal: math.Vec3,
    };

    pub const Group = struct {
        first: u32,
        len: u32,
    };

    vertices: []Vertex,
    groups: []Group,

    pub fn loadFromStream(stream: anytype) !Geometry {
        var vertices = std.ArrayList(Vertex).init(allocator);
        defer vertices.deinit();
        var groups = std.ArrayList(Group).init(allocator);
        defer groups.deinit();

        var pos_list = std.ArrayList(math.Vec3).init(allocator);
        defer pos_list.deinit();
        var normal_list = std.ArrayList(math.Vec3).init(allocator);
        defer normal_list.deinit();
        var coords_list = std.ArrayList(math.Vec2).init(allocator);
        defer coords_list.deinit();
        var buffer = std.ArrayList(u8).init(allocator);
        defer buffer.deinit();

        while (try getLine(stream, &buffer)) |line| {
            errdefer std.log.err("error parsing line: '{s}'", .{line});

            // parse position
            if (std.mem.startsWith(u8, line, "v ")) {
                var words = std.mem.tokenize(u8, line[2..], " ");
                var pos = math.Vec3{};
                var i: u8 = 0;
                while (words.next()) |word| {
                    switch (i) {
                        0 => pos.x = try std.fmt.parseFloat(f32, word),
                        1 => pos.y = try std.fmt.parseFloat(f32, word),
                        2 => pos.z = try std.fmt.parseFloat(f32, word),
                        3 => pos = pos.divide(try std.fmt.parseFloat(f32, word)),
                        else => return error.InvalidFormat,
                    }
                    i += 1;
                }
                try pos_list.append(pos);
            } // parse texture coord
            else if (std.mem.startsWith(u8, line, "vt ")) {
                var words = std.mem.tokenize(u8, line[3..], " ");
                var coords = math.Vec2{};
                var i: u8 = 0;
                while (words.next()) |word| {
                    switch (i) {
                        0 => coords.x = try std.fmt.parseFloat(f32, word),
                        1 => coords.y = 1.0 - (try std.fmt.parseFloat(f32, word)),
                        2 => {},
                        else => return error.InvalidFormat,
                    }
                    i += 1;
                }
                try coords_list.append(coords);
            } // parse normal
            else if (std.mem.startsWith(u8, line, "vn ")) {
                var words = std.mem.tokenize(u8, line[3..], " ");
                var normal = math.Vec3{};
                var i: u8 = 0;
                while (words.next()) |word| {
                    switch (i) {
                        0 => normal.x = try std.fmt.parseFloat(f32, word),
                        1 => normal.y = try std.fmt.parseFloat(f32, word),
                        2 => normal.z = try std.fmt.parseFloat(f32, word),
                        else => return error.InvalidFormat,
                    }
                    i += 1;
                }
                try normal_list.append(normal);
            } // parse face
            else if (std.mem.startsWith(u8, line, "f ")) {
                var words = std.mem.tokenize(u8, line[2..], " ");
                var first_vertex: ?Vertex = null;
                var last_vertex: ?Vertex = null;

                while (words.next()) |word| {
                    var vertex = Vertex{ .pos = .{}, .coords = .{}, .normal = .{} };
                    var parts = std.mem.split(u8, word, "/");
                    var i: u8 = 0;

                    while (parts.next()) |part| {
                        switch (i) {
                            0 => vertex.pos = pos_list.items[(try std.fmt.parseInt(usize, part, 10)) - 1],
                            1 => vertex.coords = coords_list.items[(try std.fmt.parseInt(usize, part, 10)) - 1],
                            2 => vertex.normal = normal_list.items[(try std.fmt.parseInt(usize, part, 10)) - 1],
                            else => return error.InvalidFormat,
                        }
                        i += 1;
                    }

                    if (first_vertex) |first| {
                        if (last_vertex) |last| {
                            try vertices.append(first);
                            try vertices.append(last);
                            try vertices.append(vertex);

                            if (groups.items.len > 0) {
                                groups.items[groups.items.len - 1].len += 3;
                            }
                        }
                        last_vertex = vertex;
                    } else {
                        first_vertex = vertex;
                    }
                }
            } // parse group
            else if (std.mem.startsWith(u8, line, "g ")) {
                try groups.append(.{
                    .first = @intCast(u32, vertices.items.len),
                    .len = 0,
                });
            } else {
                std.log.warn("unknown line type: {s}", .{line});
            }
        }
        return Geometry{ .vertices = vertices.toOwnedSlice(), .groups = groups.toOwnedSlice() };
    }

    pub fn loadFromFile(path: []const u8) !Geometry {
        var file = try std.fs.cwd().openFile(path, .{ .read = true });
        defer file.close();
        return loadFromStream(file.reader());
    }

    pub fn destroy(self: Geometry) void {
        allocator.free(self.vertices);
        allocator.free(self.groups);
    }
};

fn getLine(stream: anytype, buffer: *std.ArrayList(u8)) !?[]const u8 {
    while (true) {
        stream.readUntilDelimiterArrayList(buffer, '\n', 4096) catch |err| switch (err) {
            error.EndOfStream => return null,
            else => return err,
        };

        var line: []const u8 = buffer.items;

        if (std.mem.indexOf(u8, line, "#")) |idx| {
            line = line[0..idx];
        }
        line = std.mem.trim(u8, line, " \r\n\t");

        if (line.len > 0)
            return line;
    }
}
