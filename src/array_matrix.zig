const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expectApproxEqAbs = std.testing.expectApproxEqAbs;

const Vec = @import("array_vector.zig");
const Vec4f = Vec.Vector4f;
const Vec3f = Vec.Vector3f;

/// A 4×4 column-major matrix using `extern` layout.
/// Stores 4 columns as `[4][4]f32` array. Default is zero-filled.
pub const Matrix4f = extern struct {
    cols: [4][4]f32 = [_][4]f32{ @splat(0) } ** 4,

    pub const identity: Matrix4f = .{ .cols = .{
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    }};

    /// Creates a matrix from a row-major `[4][4]f32` array, converting to column-major storage internally.
    pub fn init(mat: [4][4]f32) Matrix4f {
        return .{.cols = .{
            .{ mat[0][0], mat[1][0], mat[2][0], mat[3][0] },
            .{ mat[0][1], mat[1][1], mat[2][1], mat[3][1] },
            .{ mat[0][2], mat[1][2], mat[2][2], mat[3][2] },
            .{ mat[0][3], mat[1][3], mat[2][3], mat[3][3] },
        }};
    }

    test "row major init" {
        const mat_arr = [4][4]f32{
            .{ 0.0, 0.1, 0.2, 0.3 },
            .{ 0.4, 0.5, 0.6, 0.7 },
            .{ 0.8, 0.9, 1.0, 1.1 },
            .{ 1.2, 1.3, 1.4, 1.5 },
        };
        const result = init(mat_arr);
        const expected = Matrix4f{ .cols = .{
            .{ 0.0, 0.4, 0.8, 1.2 },
            .{ 0.1, 0.5, 0.9, 1.3 },
            .{ 0.2, 0.6, 1.0, 1.4 },
            .{ 0.3, 0.7, 1.1, 1.5 },
        }};

        try expectEqual(expected, result);
    }

    /// Creates a matrix from a colum-major `[4][4]f32` array. No transposition is performed.
    pub fn initColumnMajor(mat: [4][4]f32) Matrix4f {
        return Matrix4f{ .cols = mat };
    }

    test "column major init" {
        const mat_arr = [4][4]f32{
            .{ 0.0, 0.1, 0.2, 0.3 },
            .{ 0.4, 0.5, 0.6, 0.7 },
            .{ 0.8, 0.9, 1.0, 1.1 },
            .{ 1.2, 1.3, 1.4, 1.5 },
        };
        const result = initColumnMajor(mat_arr);
        const expected = Matrix4f{ .cols = .{
            .{ 0.0, 0.1, 0.2, 0.3 },
            .{ 0.4, 0.5, 0.6, 0.7 },
            .{ 0.8, 0.9, 1.0, 1.1 },
            .{ 1.2, 1.3, 1.4, 1.5 },
        }};

        try expectEqual(expected, result);
    }

    /// Returns a scaling matrix with `vec` components on the diagonal.
    fn scaling(vec: [3]f32) Matrix4f {
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

    /// Returns a translation matrix that moves points by `pos`.
    fn translation(pos: [3]f32) Matrix4f {
        return Matrix4f.init(.{
            .{ 1, 0, 0, pos[0] },
            .{ 0, 1, 0, pos[1] },
            .{ 0, 0, 1, pos[2] },
            .{ 0, 0, 0,   1    },
        });
    }

    /// Returns a rotation matrix around an arbitrary normalized axis by `angle_radians`.
    /// Uses Rodrigues' rotation formula.
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

    /// Returns a rotation matrix around the X axis by `angle_radians`.
    pub fn rotationX(angle_radians: f32) Matrix4f {
        const cos = @cos(angle_radians);
        const sin = @sin(angle_radians);
        return Matrix4f.init(.{
            .{ 1,  0,    0,  0 },
            .{ 0, cos, -sin, 0 },
            .{ 0, sin,  cos, 0 },
            .{ 0,  0,    0,  1 },
        });
    }

    /// Returns a rotation matrix around the Y axis by `angle_radians`.
    pub fn rotationY(angle_radians: f32) Matrix4f {
        const cos = @cos(angle_radians);
        const sin = @sin(angle_radians);
        return Matrix4f.init(.{
            .{  cos, 0, sin, 0 },
            .{   0,  1,  0,  0 },
            .{ -sin, 0, cos, 0 },
            .{   0,  0,  0,  1 },
        });
    }

    /// Returns a rotation matrix around the Z axis by `angle_radians`.
    pub fn rotationZ(angle_radians: f32) Matrix4f {
        const cos = @cos(angle_radians);
        const sin = @sin(angle_radians);
        return Matrix4f.init(.{
            .{ cos, -sin, 0, 0 },
            .{ sin,  cos, 0, 0 },
            .{  0,    0,  1, 0 },
            .{  0,    0,  0, 1 },
        });
    }

    /// Post-multiplies `self` by a scaling matrix built from `vec`.
    /// Returns a new matrix: `self * Scaling(vec)`.
    pub fn scale(self: Matrix4f, vec: [3]f32) Matrix4f {
        return self.mul(scaling(vec));
    }

    test "scaling" {
        const mat = Matrix4f.identity;
        const svec = [3]f32{ 2, 3, 4 };
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

    /// Post-multiplies `self` by a translation matrix built from `pos`.
    /// Returns a new matrix: `self * translation(pos)`.
    pub fn translate(self: Matrix4f, pos: [3]f32) Matrix4f {
        return self.mul(translation(pos));
    }

    test "translation" {
        const mat = Matrix4f.identity;
        const pos = [3]f32{ 2, 3, 4 };
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

    /// Post-multiplies `self` by a rotation matrix around `axis` by `angle_radians`.
    /// Returns a new matrix: `self * rotationAxis(axis, angle)`.
    pub fn rotate(self: Matrix4f, angle_radians: f32, axis: [3]f32) Matrix4f {
        return self.mul(rotationAxis(axis, angle_radians));
    }

    test "any axis rotations" {
        {
            const axis = [3]f32{ 0.0, 0.0, 1.0 };
            const angle = std.math.pi / 2.0; // 90
            const result = rotationAxis(axis, angle);
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
            const result = rotationAxis(axis, angle);
            const expected = rotationX(std.math.pi / 2.0);

            const eps = 0.00001;
            try Matrix4f.expectApproxEqAbs(expected, result, eps);
        }
        {
            const axis = Vec3f{ 0.0, 1.0, 0.0 };
            const angle = std.math.pi / 2.0; // 90
            const result = rotationAxis(axis, angle);
            const expected = rotationY(std.math.pi / 2.0);

            const eps = 0.00001;
            try Matrix4f.expectApproxEqAbs(expected, result, eps);
        }
        {
            const axis = Vec3f{ 0.0, 0.0, 1.0 };
            const angle = std.math.pi / 2.0; // 90
            const result = rotationAxis(axis, angle);
            const expected = rotationZ(std.math.pi / 2.0);

            const eps = 0.00001;
            try Matrix4f.expectApproxEqAbs(expected, result, eps);
        }
    }

    /// Post-multiplies `self` by an X-axis rotation matrix.
    pub fn rotateX(self: Matrix4f, angle_radians: f32) Matrix4f {
        return self.mul(rotationX(angle_radians));
    }

    /// Post-multiplies `self` by a Y-axis rotation matrix.
    pub fn rotateY(self: Matrix4f, angle_radians: f32) Matrix4f {
        return self.mul(rotationY(angle_radians));
    }

    /// Post-multiplies `self` by a Z-axis rotation matrix.
    pub fn rotateZ(self: Matrix4f, angle_radians: f32) Matrix4f {
        return self.mul(rotationZ(angle_radians));
    }

    /// Matrix * Matrix multiplication: `a * b`. Returns a new matrix.
    /// Operates in column-major order using SIMD splat and multiply-add.
    pub fn mul(a: Matrix4f, b: Matrix4f) Matrix4f {
        var result = Matrix4f{};

        for (&result.cols, 0..) |*col, i| {
            const b_col = b.cols[i];

            const bx = Vec.splat(Vec4f, b_col[0]);
            const by = Vec.splat(Vec4f, b_col[1]);
            const bz = Vec.splat(Vec4f, b_col[2]);
            const bw = Vec.splat(Vec4f, b_col[3]);

            col.* = Vec.add(Vec.add(Vec.add(
                Vec.multiply(a.cols[0], bx),
                Vec.multiply(a.cols[1], by)),
                Vec.multiply(a.cols[2], bz)),
                Vec.multiply(a.cols[3], bw),
            );
        }

        return result;
    }

    test "multiplication mat*mat calculation" {
        const a = Matrix4f{ .cols = .{
            .{ 1.0,  0  , 0  , 0   },
            .{ 0  , -2.0, 0  , 0   },
            .{ 0  ,  0  , 3.8, 0   },
            .{ 5.0,  6.0, 7.0, 1   },
        }};
        const b = Matrix4f{ .cols = .{
            .{  2.5,  0  , 0   , 0 },
            .{  0  , -3.0, 0   , 0 },
            .{  0  ,  0  , 40.0, 0 },
            .{ -2.0,  4.0, 13.0, 1 },
        }};
        const result = mul(a, b);

        const expected = Matrix4f{ .cols = .{
            Vec.add(Vec.add(Vec.add(
                Vec.multiply(a.cols[0], Vec.splat(Vec4f, b.cols[0][0])),
                Vec.multiply(a.cols[1], Vec.splat(Vec4f, b.cols[0][1]))),
                Vec.multiply(a.cols[2], Vec.splat(Vec4f, b.cols[0][2]))),
                Vec.multiply(a.cols[3], Vec.splat(Vec4f, b.cols[0][3])),
            ),
            Vec.add(Vec.add(Vec.add(
                Vec.multiply(a.cols[0], Vec.splat(Vec4f, b.cols[1][0])),
                Vec.multiply(a.cols[1], Vec.splat(Vec4f, b.cols[1][1]))),
                Vec.multiply(a.cols[2], Vec.splat(Vec4f, b.cols[1][2]))),
                Vec.multiply(a.cols[3], Vec.splat(Vec4f, b.cols[1][3])),
            ),
            Vec.add(Vec.add(Vec.add(
                Vec.multiply(a.cols[0], Vec.splat(Vec4f, b.cols[2][0])),
                Vec.multiply(a.cols[1], Vec.splat(Vec4f, b.cols[2][1]))),
                Vec.multiply(a.cols[2], Vec.splat(Vec4f, b.cols[2][2]))),
                Vec.multiply(a.cols[3], Vec.splat(Vec4f, b.cols[2][3])),
            ),
            Vec.add(Vec.add(Vec.add(
                Vec.multiply(a.cols[0], Vec.splat(Vec4f, b.cols[3][0])),
                Vec.multiply(a.cols[1], Vec.splat(Vec4f, b.cols[3][1]))),
                Vec.multiply(a.cols[2], Vec.splat(Vec4f, b.cols[3][2]))),
                Vec.multiply(a.cols[3], Vec.splat(Vec4f, b.cols[3][3])),
            ),
        }};
        try expectEqual(result, expected);
    }

    test "multiplication mat*mat" {
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
        const result = mul(a, b);
        const expected = Matrix4f{ .cols = .{
            .{ 1 * 2.5, 0     , 0     , 0 },
            .{ 0      , 1 * -3, 0     , 0 },
            .{ 0      , 0     , 1 * 40, 0 },
            .{ 0      , 0     , 0     , 1 },
        }};

        const eps = 0.00001;
        try Matrix4f.expectApproxEqAbs(expected, result, eps);
    }

    /// Multiplies a 4D vector by the matrix: `mat * vec`. Returns the transformed vector.
    pub fn mulVec(mat: Matrix4f, vec: Vec4f) Vec4f {
        const t0 = Vec.multiply(mat.cols[0], Vec.splat(Vec4f, vec[0]));
        const t1 = Vec.multiply(mat.cols[1], Vec.splat(Vec4f, vec[1]));
        const t2 = Vec.multiply(mat.cols[2], Vec.splat(Vec4f, vec[2]));
        const t3 = Vec.multiply(mat.cols[3], Vec.splat(Vec4f, vec[3]));
        // return t0 + t1 + t2 + t3;
        return Vec.add(Vec.add(Vec.add(t0, t1), t2), t3);
    }

    test "multiplication mat*vec4f" {
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

    /// Multiplies a 3D vector by the matrix, treating it as homogeneous `(vec, 1)`.
    /// Returns a 4D vector.
    pub fn mulVec3(mat: Matrix4f, vec: Vec3f) Vec4f {
        return mulVec(mat, .{ vec[0], vec[1], vec[2], 1});
    }

    test "multiplication mat*vec3f" {
        const mat = Matrix4f.identity;
        const vec = Vec3f{ 1.5, 2, -3 };
        const result = mat.mulVec3(vec);
        const expected = Vec4f{
            1 *  1.5 + 0 *  1.5 + 0 *  1.5 + 0 *  1.5,
            0 *  2   + 1 *  2   + 0 *  2   + 0 *  2  ,
            0 * -3   + 0 * -3   + 1 * -3   + 0 * -3  ,
            0 *  1   + 0 *  1   + 0 *  1   + 1 *  1  ,
        };
        try expectEqual(expected, result);
    }

    /// Returns the transpose of the matrix (rows become columns).
    pub fn transpose(mat: Matrix4f) Matrix4f {
        return Matrix4f{ .cols = .{
            .{ mat.cols[0][0], mat.cols[1][0], mat.cols[2][0], mat.cols[3][0] },
            .{ mat.cols[0][1], mat.cols[1][1], mat.cols[2][1], mat.cols[3][1] },
            .{ mat.cols[0][2], mat.cols[1][2], mat.cols[2][2], mat.cols[3][2] },
            .{ mat.cols[0][3], mat.cols[1][3], mat.cols[2][3], mat.cols[3][3] },
        }};
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

    pub fn toRowMajor(mat: Matrix4f) [4][4]f32 {
        return .{
            .{ mat.cols[0][0], mat.cols[1][0],  mat.cols[2][0], mat.cols[3][0] },
            .{ mat.cols[0][1], mat.cols[1][1],  mat.cols[2][1], mat.cols[3][1] },
            .{ mat.cols[0][2], mat.cols[1][2],  mat.cols[2][2], mat.cols[3][2] },
            .{ mat.cols[0][3], mat.cols[1][3],  mat.cols[2][3], mat.cols[3][3] },
        };
    }

    /// Tests two matrices for approximate equality within `tolerance`.
    /// On mismatch, prints a detailed comparison of column values.
    fn expectApproxEqAbs(expected: Matrix4f, actual: Matrix4f, tolerance: comptime_float) !void {
        for (expected.cols, actual.cols) |e_col, a_col| {
            for (e_col, a_col) |e_value, a_value| {
                std.testing.expectApproxEqAbs(e_value, a_value, tolerance) catch {
                    try std.testing.expectEqualSlices(Vec4f, &expected.cols, &actual.cols);
                };
            }
        }
    }
};