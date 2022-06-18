const math = @import("math.zig");

pub const Camera = struct {
    position: math.Vec3,
    direction: math.Vec3,
    up: math.Vec3 = .{ .y = 1 },

    fov: f32,
    aspect: f32,
    near: f32,
    far: f32,

    pub fn lookMat(self: Camera) math.Mat3 {
        const az = self.direction.normalize();
        const ax = self.up.cross(az).normalize();
        const ay = az.cross(ax).normalize();
        return math.Mat3.fromVectors(ax, ay, az).transpose();
    }

    pub fn viewMat(self: Camera) math.Mat4 {
        return self.lookMat().toMat4().multiply(math.Mat4.translation(self.position.negate()));
    }

    pub fn perspectiveMat(self: Camera) math.Mat4 {
        return math.Mat4.perspective(self.fov, self.aspect, self.near, self.far);
    }

    pub fn mat(self: Camera) math.Mat4 {
        return self.perspectiveMat().multiply(self.viewMat());
    }

    pub fn moveRelative(self: *Camera, offset: math.Vec3) void {
        self.position = self.position.add(self.lookMat().transpose().multiplyVec3(offset));
    }
};
