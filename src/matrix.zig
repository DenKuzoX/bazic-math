const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expectApproxEqAbs = std.testing.expectApproxEqAbs;

const Vec = @import("vector.zig");
const Vec4f = Vec.Vector4f;
const Vec3f = Vec.Vector3f;

pub const Matrix4f = extern struct {
    cols: [4]Vec4f = [_]Vec4f{ @splat(0) } ** 4,

    pub const identity: Matrix4f = .{ .cols = .{
        Vec4f{ 1, 0, 0, 0 },
        Vec4f{ 0, 1, 0, 0 },
        Vec4f{ 0, 0, 1, 0 },
        Vec4f{ 0, 0, 0, 1 },
    }};

    pub fn init(mat: [4][4]f32) Matrix4f {
        return .{.cols = .{
            // row major -> col major
            Vec4f{ mat[0][0], mat[1][0], mat[2][0], mat[3][0]},
            Vec4f{ mat[0][1], mat[1][1], mat[2][1], mat[3][1]},
            Vec4f{ mat[0][2], mat[1][2], mat[2][2], mat[3][2]},
            Vec4f{ mat[0][3], mat[1][3], mat[2][3], mat[3][3]},
        }};
    }

    pub fn initColumnMajor(mat: [4]Vec4f) Matrix4f {
        return Matrix4f{ .cols = mat};
    }

    fn scaling(vec: Vec3f) Matrix4f {
        const x = vec[0];
        const y = vec[1];
        const z = vec[2];
        return Matrix4f.init(.{
            .{ x, 0, 0, 0 },
            .{ 0, y, 0, 0 },
            .{ 0, 0, z, 0 },
            .{ 0, 0, 0, 1 },
        });
    }

    fn translation(pos: Vec3f) Matrix4f {
        return Matrix4f.init(.{
            .{ 1, 0, 0, pos[0] },
            .{ 0, 1, 0, pos[1] },
            .{ 0, 0, 1, pos[2] },
            .{ 0, 0, 0,   1    },
        });
    }

    fn rotationAxis(axis: Vec3f, angle_radians: f32) Matrix4f {
        const axs = Vec.normalize(axis);
        const x = axs[0];
        const y = axs[1];
        const z = axs[2];

        const cos = @cos(angle_radians);
        const sin = @sin(angle_radians);
        const t = 1.0 - cos;

        return Matrix4f.init(.{
            .{ t*x*x + cos  , t*x*y - sin*z, t*x*z + sin*y, 0 },
            .{ t*x*y + sin*z, t*y*y + cos  , t*y*z - sin*x, 0 },
            .{ t*x*z - sin*y, t*y*z + sin*x, t*z*z + cos  , 0 },
            .{ 0,             0,             0,             1 },
        });
    }

    fn rotationX(angle_radians: f32) Matrix4f {
        const cos = @cos(angle_radians);
        const sin = @sin(angle_radians);
        return Matrix4f.init(.{
            .{ 1,  0,    0,  0 },
            .{ 0, cos, -sin, 0 },
            .{ 0, sin,  cos, 0 },
            .{ 0,  0,    0,  1 },
        });
    }

    fn rotationY(angle_radians: f32) Matrix4f {
        const cos = @cos(angle_radians);
        const sin = @sin(angle_radians);
        return Matrix4f.init(.{
            .{  cos, 0, sin, 0 },
            .{   0,  1,  0,  0 },
            .{ -sin, 0, cos, 0 },
            .{   0,  0,  0,  1 },
        });
    }

    fn rotationZ(angle_radians: f32) Matrix4f {
        const cos = @cos(angle_radians);
        const sin = @sin(angle_radians);
        return Matrix4f.init(.{
            .{ cos, -sin, 0, 0 },
            .{ sin,  cos, 0, 0 },
            .{  0,    0,  1, 0 },
            .{  0,    0,  0, 1 },
        });
    }

    pub fn scale(self: Matrix4f, vec: Vec3f) Matrix4f {
        return self.mul(
            scaling(vec)
        );
    }

    pub fn translate(self: Matrix4f, pos: Vec3f) Matrix4f {
        return self.mul(
            translation(pos)
        );
    }

    pub fn rotate(self: Matrix4f, angle_radians: f32, axis: Vec3f) Matrix4f {
        return self.mul(
            rotationAxis(axis, angle_radians)
        );
    }

    pub fn rotateX(self: Matrix4f, angle_radians: f32) Matrix4f {
        return self.mul(
            rotationX(angle_radians)
        );
    }

    pub fn rotateY(self: Matrix4f, angle_radians: f32) Matrix4f {
        return self.mul(
            rotationY(angle_radians)
        );
    }

    pub fn rotateZ(self: Matrix4f, angle_radians: f32) Matrix4f {
        return self.mul(
            rotationZ(angle_radians)
        );
    }

    pub fn mul(a: Matrix4f, b: Matrix4f) Matrix4f {
        var result = Matrix4f{};

        for (&result.cols, 0..) |*col, i| {
            const b_col = b.cols[i];

            const bx = Vec.splat(Vec4f, b_col[0]);
            const by = Vec.splat(Vec4f, b_col[1]);
            const bz = Vec.splat(Vec4f, b_col[2]);
            const bw = Vec.splat(Vec4f, b_col[3]);

            col.* = a.cols[0] * bx + a.cols[1] * by + a.cols[2] * bz + a.cols[3] * bw;
        }

        return result;
    }

    pub fn mulVec(mat: Matrix4f, vec: Vec4f) Vec4f {
        const t0 = mat.cols[0] * Vec.splat(Vec4f, vec[0]);
        const t1 = mat.cols[1] * Vec.splat(Vec4f, vec[1]);
        const t2 = mat.cols[2] * Vec.splat(Vec4f, vec[2]);
        const t3 = mat.cols[3] * Vec.splat(Vec4f, vec[3]);
        return t0 + t1 + t2 + t3;
    }

    pub fn mulVec3(mat: Matrix4f, vec: Vec3f) Vec4f {
        return mulVec(mat, .{ vec[0], vec[1], vec[2], 1});
    }
    
    pub fn transpose(mat: Matrix4f) Matrix4f {
        return Matrix4f{ .cols = .{
            .{ mat.cols[0][0], mat.cols[1][0], mat.cols[2][0], mat.cols[3][0] },
            .{ mat.cols[0][1], mat.cols[1][1], mat.cols[2][1], mat.cols[3][1] },
            .{ mat.cols[0][2], mat.cols[1][2], mat.cols[2][2], mat.cols[3][2] },
            .{ mat.cols[0][3], mat.cols[1][3], mat.cols[2][3], mat.cols[3][3] },
        }};
    }

    pub fn asArray(mat: Matrix4f) [4][4]f32 {
        return .{
            .{ mat.cols[0][0], mat.cols[1][0],  mat.cols[2][0], mat.cols[3][0] },
            .{ mat.cols[0][1], mat.cols[1][1],  mat.cols[2][1], mat.cols[3][1] },
            .{ mat.cols[0][2], mat.cols[1][2],  mat.cols[2][2], mat.cols[3][2] },
            .{ mat.cols[0][3], mat.cols[1][3],  mat.cols[2][3], mat.cols[3][3] },
        };
    }

    fn expectApproxEqAbs(expected: Matrix4f, actual: Matrix4f, tolerance: comptime_float) !void {
        for (expected.asArray(), actual.asArray()) |e_col, a_col| {
            for (e_col, a_col) |e_value, a_value| {
                std.testing.expectApproxEqAbs(e_value, a_value, tolerance) catch {
                    try std.testing.expectEqualSlices(Vec4f, &expected.cols, &actual.cols);
                };
            }
        }
    }
};

pub fn lookAt(eye: Vec3f, center: Vec3f, up: Vec3f) Matrix4f {
    const forward = Vec.normalize(eye - center);
    const right = Vec.normalize(Vec.cross3(up, forward));
    const up_true = Vec.cross3(forward, right);

    const tx = -Vec.dot(right, eye);
    const ty = -Vec.dot(up_true, eye);
    const tz = -Vec.dot(forward, eye);

    return Matrix4f.init(.{
        .{ right[0]  , right[1]  , right[2]  , tx },
        .{ up_true[0], up_true[1], up_true[2], ty },
        .{ forward[0], forward[1], forward[2], tz },
        .{ 0         , 0         , 0         , 1  },
    });
}

test "lookAt" {
    const eye = Vec3f{ 0, 0, 3 };
    const center = Vec3f{ 0, 0, 0 };
    const world_up = Vec3f{ 0, 1, 0 };

    const result = lookAt(eye, center, world_up);
    const expected = Matrix4f.init(.{
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, -3 },
        .{ 0, 0, 0, 1 },
    });

    try expectEqual(expected, result);
}

pub fn perspective(fov: f32, asp_ratio: f32, near: f32, far: f32) Matrix4f {
    const f = 1 / @tan(fov * 0.5);
    const zmf = near - far;
    return .init(.{
        .{ asp_ratio * f, 0,                  0,                      0 },
        .{ 0,             f,                  0,                      0 },
        .{ 0,             0, (near + far) / zmf, (2 * far * near) / zmf },
        .{ 0,             0,                 -1,                      0 },
    });
}

// TODO add perspective matrix test
// test "perspective matrix" {}

pub fn orthographic(width: f32, height: f32) Matrix4f {
    const left: f32 = 0;
    const right: f32 = width;
    const bottom: f32 = 0;
    const top: f32 = height;
    const near: f32 = -1;
    const far: f32 = 1;

    const rml = right - left;
    const tmb = top - bottom;
    const fmn = far - near;

    return .init(.{
        .{ 2 / rml  , 0        ,  0       , -(right + left) / rml },
        .{ 0        , 2 / tmb  ,  0       , -(top + bottom) / tmb },
        .{ 0        , 0        , -2 / fmn , -(far + near) / fmn   },
        .{ 0        , 0        ,  0       , 1                     },
    });
}

// TODO add orthographic matrix test
// test "orthographic matrix" {}

test "row major init" {
    const mat_arr = [4][4]f32{
        .{ 0.0, 0.1, 0.2, 0.3 },
        .{ 0.4, 0.5, 0.6, 0.7 },
        .{ 0.8, 0.9, 1.0, 1.1 },
        .{ 1.2, 1.3, 1.4, 1.5 },
    };
    const result = Matrix4f.init(mat_arr);
    const expected = Matrix4f{ .cols = .{
        .{ 0.0, 0.4, 0.8, 1.2 },
        .{ 0.1, 0.5, 0.9, 1.3 },
        .{ 0.2, 0.6, 1.0, 1.4 },
        .{ 0.3, 0.7, 1.1, 1.5 },
    }};

    try expectEqual(expected, result);
}

test "scaling" {
    const mat = Matrix4f.identity;
    const svec = Vec3f{ 2, 3, 4 };
    const result = mat.scale(svec);
    const expected = Matrix4f.init(.{
        .{ 1*2, 0  , 0  , 0 },
        .{ 0  , 1*3, 0  , 0 },
        .{ 0  , 0  , 1*4, 0 },
        .{ 0  , 0  , 0  , 1 },
    });

    const eps = 0.00001;
    try Matrix4f.expectApproxEqAbs(expected, result, eps);
}

test "translation" {
    const mat = Matrix4f.identity;
    const pos = Vec3f{ 2, 3, 4 };
    const result = mat.translate(pos);
    const expected = Matrix4f.init(.{
        .{ 1, 0, 0, 2 },
        .{ 0, 1, 0, 3 },
        .{ 0, 0, 1, 4 },
        .{ 0, 0, 0, 1 },
    });

    const eps = 0.00001;
    try Matrix4f.expectApproxEqAbs(expected, result, eps);
}

test "any axis rotations" {
    {
        const axis = Vec3f{ 0.0, 0.0, 1.0 };
        const angle = std.math.pi / 2.0; // 90
        const result = Matrix4f.rotationAxis(axis, angle);
        const expected = Matrix4f{ .cols = .{
            .{  0, 1, 0, 0 },
            .{ -1, 0, 0, 0 },
            .{  0, 0, 1, 0 },
            .{  0, 0, 0, 1 },
        }};

        const eps = 0.00001;
        try Matrix4f.expectApproxEqAbs(expected, result, eps);
    }
    {
        const axis = Vec3f{ 1.0, 0.0, 0.0 };
        const angle = std.math.pi / 2.0; // 90
        const result = Matrix4f.rotationAxis(axis, angle);
        const expected = Matrix4f.rotationX(std.math.pi / 2.0);

        const eps = 0.00001;
        try Matrix4f.expectApproxEqAbs(expected, result, eps);
    }
    {
        const axis = Vec3f{ 0.0, 1.0, 0.0 };
        const angle = std.math.pi / 2.0; // 90
        const result = Matrix4f.rotationAxis(axis, angle);
        const expected = Matrix4f.rotationY(std.math.pi / 2.0);

        const eps = 0.00001;
        try Matrix4f.expectApproxEqAbs(expected, result, eps);
    }
    {
        const axis = Vec3f{ 0.0, 0.0, 1.0 };
        const angle = std.math.pi / 2.0; // 90
        const result = Matrix4f.rotationAxis(axis, angle);
        const expected = Matrix4f.rotationZ(std.math.pi / 2.0);

        const eps = 0.00001;
        try Matrix4f.expectApproxEqAbs(expected, result, eps);
    }
}

// TODO add matrix X,Y,Z rotation test
// test "matrix4f axis rotations"

test "matrix4f multiplication mat*mat" {
    const a = Matrix4f{ .cols = .{
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    }};
    const b = Matrix4f{ .cols = .{
        .{ 2.5,  0, 0 , 0 },
        .{ 0  , -3, 0 , 0 },
        .{ 0  ,  0, 40, 0 },
        .{ 0  ,  0, 0 , 1 },
    }};
    const result = Matrix4f.mul(a, b);
    const expected = Matrix4f{ .cols = .{
        .{ 1 * 2.5, 0     , 0     , 0 },
        .{ 0      , 1 * -3, 0     , 0 },
        .{ 0      , 0     , 1 * 40, 0 },
        .{ 0      , 0     , 0     , 1 },
    }};

    const eps = 0.00001;
    try Matrix4f.expectApproxEqAbs(expected, result, eps);
}

test "multiplication mat*vec" {
    const mat = Matrix4f.identity;
    const vec = Vec4f{ 1.5, 2, -3, 40 };
    const result = mat.mulVec(vec);
    const expected = Vec4f{
        1 *  1.5 + 0 *  1.5 + 0 *  1.5 + 0 *  1.5,
        0 *  2   + 1 *  2   + 0 *  2   + 0 *  2  ,
        0 * -3   + 0 * -3   + 1 * -3   + 0 * -3  ,
        0 *  40  + 0 *  40  + 0 *  40  + 1 *  40 ,
    };
    try expectEqual(expected, result);
}

test "transpose" {
    const mat = Matrix4f{ .cols = .{
        .{ 1, 2, 3, 4 },
        .{ 5, 1, 0, 0 },
        .{ 6, 0, 1, 0 },
        .{ 7, 0, 0, 1 },
    }};
    const result = mat.transpose();
    const expected = Matrix4f{ .cols = .{
        .{ 1, 5, 6, 7 },
        .{ 2, 1, 0, 0 },
        .{ 3, 0, 1, 0 },
        .{ 4, 0, 0, 1 },
    }};

    const eps = 0.00001;
    try Matrix4f.expectApproxEqAbs(expected, result, eps);
}

test "return as array" {
    const arr_mat = [4][4]f32{
        .{ 1, 2, 3, 4 },
        .{ 5, 1, 0, 0 },
        .{ 6, 0, 1, 0 },
        .{ 7, 0, 0, 1 },
    };
    const mat = Matrix4f.init(arr_mat);
    const result = mat.asArray();
    const expected = arr_mat;

    try expectEqual(expected, result);
}