const std = @import("std");

const generic = struct {
    fn multiply(comptime cols: comptime_int, comptime rows: comptime_int, comptime len: comptime_int, a: [len][rows]f32, b: [cols][len]f32) [cols][rows]f32 {
        var out = std.mem.zeroes([cols][rows]f32);
        comptime var c = 0;
        inline while (c < cols) : (c += 1) {
            comptime var r = 0;
            inline while (r < rows) : (r += 1) {
                comptime var l = 0;
                inline while (l < len) : (l += 1) {
                    out[c][r] += a[l][r] * b[c][l];
                }
            }
        }
        return out;
    }

    fn transpose(comptime cols: comptime_int, comptime rows: comptime_int, a: [cols][rows]f32) [cols][rows]f32 {
        var out: [cols][rows]f32 = undefined;
        comptime var c = 0;
        inline while (c < cols) : (c += 1) {
            comptime var r = 0;
            inline while (r < rows) : (r += 1) {
                out[c][r] = a[r][c];
            }
        }
        return out;
    }

    fn add(comptime len: comptime_int, a: [len]f32, b: [len]f32) [len]f32 {
        var out: [len]f32 = undefined;
        comptime var i = 0;
        inline while (i < len) : (i += 1) {
            out[i] = a[i] + b[i];
        }
        return out;
    }
};

pub const Vec2 = packed struct {
    x: f32 = 0,
    y: f32 = 0,

    pub fn asArray(v: Vec2) [2]f32 {
        return @bitCast([2]f32, v);
    }

    pub fn fromArray(v: [2]f32) Vec2 {
        return @bitCast(Vec2, v);
    }

    pub fn add(a: Vec2, b: Vec2) Vec2 {
        return .{ .x = a.x + b.x, .y = a.y + b.y };
    }

    pub fn negate(a: Vec2) Vec2 {
        return .{ .x = -a.x, .y = -a.y };
    }

    pub fn multiply(a: Vec2, b: f32) Vec2 {
        return .{ .x = a.x * b, .y = a.y * b };
    }

    pub fn divide(a: Vec2, b: f32) Vec2 {
        return .{ .x = a.x / b, .y = a.y / b };
    }

    pub fn size(a: Vec2) f32 {
        return @sqrt(a.x * a.x + a.y * a.y);
    }

    pub fn normalize(a: Vec2) Vec2 {
        return a.divide(a.size());
    }

    pub fn toVec3(v: Vec2) Vec3 {
        return .{ .x = v.x, .y = v.y, .z = 1.0 };
    }
};

pub const Vec3 = packed struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,

    pub fn asArray(v: Vec3) [3]f32 {
        return @bitCast([3]f32, v);
    }

    pub fn fromArray(v: [3]f32) Vec3 {
        return @bitCast(Vec3, v);
    }

    pub fn add(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
    }

    pub fn negate(a: Vec3) Vec3 {
        return .{ .x = -a.x, .y = -a.y, .z = -a.z };
    }

    pub fn multiply(a: Vec3, b: f32) Vec3 {
        return .{ .x = a.x * b, .y = a.y * b, .z = a.z * b };
    }

    pub fn divide(a: Vec3, b: f32) Vec3 {
        return .{ .x = a.x / b, .y = a.y / b, .z = a.z / b };
    }

    pub fn dot(a: Vec3, b: Vec3) f32 {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }

    pub fn cross(a: Vec3, b: Vec3) Vec3 {
        return .{
            .x = a.y * b.z - a.z * b.y,
            .y = a.z * b.x - a.x * b.z,
            .z = a.x * b.y - a.y * b.x,
        };
    }

    pub fn size(a: Vec3) f32 {
        return @sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
    }

    pub fn normalize(a: Vec3) Vec3 {
        return a.divide(a.size());
    }

    pub fn toVec2(v: Vec3) Vec2 {
        return .{ .x = v.x / v.z, .y = v.y / v.z };
    }

    pub fn toVec4(v: Vec3) Vec4 {
        return .{ .x = v.x, .y = v.y, .z = v.z, .w = 1.0 };
    }

    pub fn fromAngles(v: Vec2) Vec3 {
        return .{
            .x = @cos(v.y) * @sin(v.x),
            .y = @sin(v.y),
            .z = @cos(v.y) * @cos(v.x),
        };
    }
};

pub const Vec4 = packed struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
    w: f32 = 0,

    pub fn asArray(v: Vec4) [4]f32 {
        return @bitCast([4]f32, v);
    }

    pub fn fromArray(v: [4]f32) Vec4 {
        return @bitCast(Vec4, v);
    }

    pub fn toVec3(v: Vec4) Vec3 {
        return .{ .x = v.x / v.w, .y = v.y / v.w, .z = v.z / v.w };
    }
};

pub const Mat3 = packed struct {
    xx: f32 = 1,
    xy: f32 = 0,
    xz: f32 = 0,
    yx: f32 = 0,
    yy: f32 = 1,
    yz: f32 = 0,
    zx: f32 = 0,
    zy: f32 = 0,
    zz: f32 = 1,

    pub fn asArray(v: Mat3) [3][3]f32 {
        return @bitCast([3][3]f32, v);
    }

    pub fn fromArray(v: [3][3]f32) Mat3 {
        return @bitCast(Mat3, v);
    }

    pub fn translation(vec: Vec2) Mat3 {
        return .{ .zx = vec.x, .zy = vec.y };
    }

    pub fn scaling(scale: Vec3) Mat3 {
        return .{ .xx = scale.x, .yy = scale.y, .zz = scale.z };
    }

    pub fn scalingXYZ(scale: f32) Mat3 {
        return .{ .xx = scale, .yy = scale, .zz = scale };
    }

    pub fn rotationX(a: f32) Mat3 {
        return .{ .yy = @cos(a), .yz = @sin(a), .zy = -@sin(a), .zz = @cos(a) };
    }

    pub fn rotationY(a: f32) Mat3 {
        return .{ .xx = @cos(a), .xz = -@sin(a), .zx = @sin(a), .zz = @cos(a) };
    }

    pub fn rotationZ(a: f32) Mat3 {
        return .{ .xx = @cos(a), .xy = @sin(a), .yx = -@sin(a), .yy = @cos(a) };
    }

    pub fn multiply(a: Mat3, b: Mat3) Mat3 {
        return fromArray(generic.multiply(3, 3, 3, a.asArray(), b.asArray()));
    }

    pub fn multiplyVec3(a: Mat3, b: Vec3) Vec3 {
        return Vec3.fromArray(generic.multiply(1, 3, 3, a.asArray(), .{b.asArray()})[0]);
    }

    pub fn multiplyVec2(a: Mat3, b: Vec2) Vec2 {
        return multiplyVec3(a, b.toVec3()).toVec2();
    }

    pub fn transpose(a: Mat3) Mat3 {
        return fromArray(generic.transpose(3, 3, a.asArray()));
    }

    pub fn toMat4(a: Mat3) Mat4 {
        return .{ .xx = a.xx, .xy = a.xy, .xz = a.xz, .yx = a.yx, .yy = a.yy, .yz = a.yz, .zx = a.zx, .zy = a.zy, .zz = a.zz };
    }

    pub fn fromVectors(x: Vec3, y: Vec3, z: Vec3) Mat3 {
        return .{ .xx = x.x, .xy = x.y, .xz = x.z, .yx = y.x, .yy = y.y, .yz = y.z, .zx = z.x, .zy = z.y, .zz = z.z };
    }
};

pub const Mat4 = packed struct {
    xx: f32 = 1,
    xy: f32 = 0,
    xz: f32 = 0,
    xw: f32 = 0,
    yx: f32 = 0,
    yy: f32 = 1,
    yz: f32 = 0,
    yw: f32 = 0,
    zx: f32 = 0,
    zy: f32 = 0,
    zz: f32 = 1,
    zw: f32 = 0,
    wx: f32 = 0,
    wy: f32 = 0,
    wz: f32 = 0,
    ww: f32 = 1,

    pub fn asArray(v: Mat4) [4][4]f32 {
        return @bitCast([4][4]f32, v);
    }

    pub fn fromArray(v: [4][4]f32) Mat4 {
        return @bitCast(Mat4, v);
    }

    pub fn translation(pos: Vec3) Mat4 {
        return .{ .wx = pos.x, .wy = pos.y, .wz = pos.z };
    }

    pub fn scaling(scale: Vec3) Mat4 {
        return Mat3.scaling(scale).toMat4();
    }

    pub fn scalingXYZ(scale: f32) Mat4 {
        return Mat3.scalingXYZ(scale).toMat4();
    }

    pub fn rotationX(a: f32) Mat4 {
        return Mat3.rotationX(a).toMat4();
    }

    pub fn rotationY(a: f32) Mat4 {
        return Mat3.rotationY(a).toMat4();
    }

    pub fn rotationZ(a: f32) Mat4 {
        return Mat3.rotationZ(a).toMat4();
    }

    pub fn multiply(a: Mat4, b: Mat4) Mat4 {
        return fromArray(generic.multiply(4, 4, 4, a.asArray(), b.asArray()));
    }

    pub fn multiplyVec4(a: Mat4, b: Vec4) Vec4 {
        return Vec4.fromArray(generic.multiply(1, 4, 4, a.asArray(), .{b.asArray()})[0]);
    }

    pub fn multiplyVec3(a: Mat4, b: Vec3) Vec3 {
        return multiplyVec4(a, b.toVec4()).toVec3();
    }

    pub fn transpose(a: Mat4) Mat4 {
        return fromArray(generic.transpose(4, 4, a.asArray()));
    }

    pub fn perspective(fov: f32, aspect: f32, near: f32, far: f32) Mat4 {
        return .{
            .xx = 1 / std.math.tan(fov / 2),
            .yy = 1 / std.math.tan(fov / 2) * aspect,
            .zz = -(far + near) / (far - near),
            .zw = -1,
            .wz = -2 * far * near / (far - near),
            .ww = 0,
        };
    }
};
