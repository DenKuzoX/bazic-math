const std = @import("std");
const math = std.math;
const expectEqual = std.testing.expectEqual;

// TODO research the @TypeOf(a).Child instead of @typeInfo(@TypeOf(a)).vector.child

// TODO add Nan, inf, -inf checks

pub const Vector2i = @Vector(2, i32);
pub const Vector2f = @Vector(2, f32);
pub const Vector2d = @Vector(2, f64);

pub const Vector3i = @Vector(3, i32);
pub const Vector3f = @Vector(3, f32);
pub const Vector3d = @Vector(3, f64);

pub const Vector4i = @Vector(4, i32);
pub const Vector4f = @Vector(4, f32);
pub const Vector4d = @Vector(4, f64);

/// Returns a vector filled with zeros.
pub fn zero(T: type) @Vector(@typeInfo(T).vector.len, @typeInfo(T).vector.child) {
    return @splat(0);
}

test "filled with zero vector" {
    const result = zero(Vector3f);
    const expected = Vector3f{ 0, 0, 0 };
    try expectEqual(expected, result);
}

/// Converts an array `[len]T` to a vector `@Vector(len, T)` of the same length and element type
pub fn arrayToVec(arr: anytype) @Vector(@typeInfo(@TypeOf(arr)).array.len, @typeInfo(@TypeOf(arr)).array.child) {
    const ArrTypeInfo = @typeInfo(@TypeOf(arr)).array;
    const ChildType = ArrTypeInfo.child;
    const len = ArrTypeInfo.len;
    const vec: @Vector(len, ChildType) = @bitCast(arr);
    return vec;
}

test "array to vector float" {
    const arr = [_]f32{ 0.0, 1.2, -3.0 };
    const result = arrayToVec(arr);
    const expected = Vector3f{ 0.0, 1.2, -3.0 };
    try expectEqual(expected, result);
}

test "array to vector int" {
    const arr = [_]i32{ 4, -5 };
    const result = arrayToVec(arr);
    const expected = Vector2i{ 4, -5 };
    try expectEqual(expected, result);
}

/// Converts an vector `@Vector(len, T)` to a array `[len]T` of the same length and element type
pub fn vecToArray(vec: anytype) [@typeInfo(@TypeOf(vec)).vector.len]@typeInfo(@TypeOf(vec)).vector.child {
    const VecTypeInfo = @typeInfo(@TypeOf(vec)).vector;
    const ChildType = VecTypeInfo.child;
    const len = VecTypeInfo.len;
    const arr: [len]ChildType = @bitCast(vec);
    return arr;
}

test "vector to array float" {
    const vec = Vector2f{ 0.0, 2.5 };
    const result = vecToArray(vec);
    const expected = [2]f32{ 0.0, 2.5 };
    try expectEqual(expected, result);
}

test "vector to array int" {
    const vec = Vector4i{ 0, 1, 2, 3 };
    const result = vecToArray(vec);
    const expected = [4]i32{ 0, 1, 2, 3 };
    try expectEqual(expected, result);
}

/// Converts an 3D vector into 4D vector where last element `vec4[3] = w`.
///
/// The `w` value is cast to the same type as vector elements via `castValue`.
pub fn vec3ToVec4(vec: anytype, w: anytype) @Vector(4, @typeInfo(@TypeOf(vec)).vector.child) {
    const T = @typeInfo(@TypeOf(vec)).vector.child;
    const casted_value = castValue(vec, w);
    return @Vector(4, T){ vec[0], vec[1], vec[2], casted_value };
}

test "vector3 to vector4" {
    const vec = Vector3f{ 0.0, 1.5, -2.0 };
    const w: i32 = 3;
    const result = vec3ToVec4(vec, w);
    const expected = Vector4f{ 0.0, 1.5, -2.0, 3.0};
    try expectEqual(expected, result);
}

// TODO add zero check
// Does not include guard logic for when `vec[3] == 0`. Dividing by zero will result
// in `NaN` or inf values for floating-point vectors.
/// Converts a 4D homogeneous vector to a 3D spatial vector by performing perspective division.
///
/// This function divides the spatial components (X, Y, Z) by the homogeneous coordinate (W or`vec[3]`).
/// It is commonly used in 3D graphics pipelines to project 4D clip-space coordinates
/// into 3D normalized device coordinates (NDC).
pub fn vec4ToVec3(vec: anytype) @Vector(3, @typeInfo(@TypeOf(vec)).vector.child) {
    const T = @typeInfo(@TypeOf(vec)).vector.child;
    const vec3 = @Vector(3, T){
        vec[0] / vec[3],
        vec[1] / vec[3],
        vec[2] / vec[3],
    };
    return vec3;
}

/// Alias for `vec4ToVec3`.
///
/// Named after the graphics pipeline operation: perspective division
/// transforms clip-space coordinates to normalized device coordinates (NDC).
pub fn perspectiveDivide(vec: Vector4f) Vector3f {
    return vec4ToVec3(vec);
}

test "vector4 to vector3" {
    const vec = Vector4f{ 0.0, 4.0, -5.0, 2.0 };
    const result = vec4ToVec3(vec);
    const expected = Vector3f{ 0.0 / 2.0 , 4.0 / 2.0, -5.0 / 2.0 };
    try expectEqual(expected, result);
}

/// Converts an 4D vector into 3D vector through removing last element of vec4
pub fn vec4ToVec3NoDiv(vec: anytype) @Vector(3, @typeInfo(@TypeOf(vec)).vector.child) {
    const T = @typeInfo(@TypeOf(vec)).vector.child;
    return @Vector(3, T){ vec[0], vec[1], vec[2] };
}

test "vector4 to vector3 without division" {
    const vec = Vector4f{ 0.0, 4.0, -5.0, 2.0 };
    const result = vec4ToVec3NoDiv(vec);
    const expected = Vector3f{ 0.0, 4.0, -5.0 };
    try expectEqual(expected, result);
}

pub const CompareOperation = enum {
    Equal,
    Greater,
    Less,
    EqualOrGreater,
    EqualOrLess,
};

/// Compares two vectors element-wise and reduces the boolean result into a single value.
fn compareVectors(
    a: anytype,
    is: CompareOperation,
    b: @TypeOf(a),
    comptime op: std.builtin.ReduceOp
) bool {
    const len = @typeInfo(@TypeOf(a)).vector.len;
    var result: @Vector(len, bool) = undefined;
    switch (is) {
        .Equal => result = a == b,
        .Greater => result = a > b,
        .Less => result = a < b,
        .EqualOrGreater => result = a >= b,
        .EqualOrLess => result = a <= b,
    }
    return @reduce(op, result);
}

pub fn compareVec(a: anytype, is: CompareOperation, b: @TypeOf(a)) bool {
    return compareVectors(a, is, b, .And);
}

test "all value comparison equal" {
    const a: Vector3f = .{  0.0, 1.2, -3.4 };
    const b: Vector3f = .{ -0.0, 1.2, -3.4 };
    const result = compareVec(a, .Equal, b);
    try expectEqual(true, result);
}

test "all value comparison greater" {
    const a: Vector4f = .{ 4, 5.6, -0.7, 80 };
    const b: Vector4f = .{ 0, 1.5, -2  , 30};
    const result = compareVec(a, .Greater, b);
    try expectEqual(true, result);
}

test "all value comparison less" {
    const a: Vector2i = .{ 1, -2 };
    const b: Vector2i = .{ 3, 40 };
    const result = compareVec(a, .Less, b);
    try expectEqual(true, result);
}

test "all value comparison, any check" {
    const a: Vector3f = .{ 0, 5.0, 0 };
    const b: Vector3f = .{ 0, 1.5, 0 };
    const result = compareVec(a, .Equal, b);
    try expectEqual(false, result);
}

pub fn compareVecAny(a: anytype, is: CompareOperation, b: @TypeOf(a)) bool {
    return compareVectors(a, is, b, .Or);
}

test "any value comparison equal" {
    const a: Vector3f = .{ 1.0, 0.0, 0.0 };
    const b: Vector3f = .{ 1.0, 0.0, 0.0 };
    const result = compareVecAny(a, .Equal, b);
    try expectEqual(true, result);
}

test "any value comparison greater" {
    const a: Vector2i = .{ 12, 0 };
    const b: Vector2i = .{ 3 , 0 };
    const result = compareVecAny(a, .Greater, b);
    try expectEqual(true, result);
}

test "any value comparison Less" {
    const a: Vector2f = .{ -1.2, 0 };
    const b: Vector2f = .{  3.4, 0 };
    const result = compareVecAny(a, .Less, b);
    try expectEqual(true, result);
}


pub fn splat(T: type, value: anytype) T {
    return @splat(value);
}

test "splat" {
    const result = splat(Vector3d, 3.0);
    const expected = Vector3d{ 3.0, 3.0, 3.0 };
    try expectEqual(expected, result);
}

/// Casts a scalar value to the element (child) type of a given vector
fn castValue(vec: anytype, value: anytype) @typeInfo(@TypeOf(vec)).vector.child {
    const VecType = @TypeOf(vec);
    const ChildType = @typeInfo(VecType).vector.child;
    const ValueType = @TypeOf(value);

    return casted_value: {
        if (ValueType == ChildType) break :casted_value value;

        if (ValueType == comptime_int or ValueType == comptime_float) {
            break :casted_value @as(ChildType, value);
        }

        if (@typeInfo(ChildType) == .float and @typeInfo(ValueType) == .int) {
            break :casted_value @as(ChildType, @floatFromInt(value));
        }

        if (@typeInfo(ChildType) == .int and @typeInfo(ValueType) == .int) {
            break :casted_value @as(ChildType, @intCast(value));
        }

        if (@typeInfo(ChildType) == .float and @typeInfo(ValueType) == .float) {
            break :casted_value @as(ChildType, @floatCast(value));
        }

        @compileError(
            "Type mismatch: cannot cast value of type '" ++ @typeName(ValueType)
                ++ "' into value of type '" ++ @typeName(ChildType) ++ "'"
        );
    };
}

test "cast value comtime_int -> f32" {
    const value: comptime_int = 1;
    const vec = Vector2f{ 0, 0 };
    const result = castValue(vec, value);
    try expectEqual(1.0, result);
}

test "cast value i32 -> f64" {
    const value: i32 = -2;
    const vec = Vector2d{ 0, 0 };
    const result = castValue(vec, value);
    try expectEqual(-2.0, result);
}

test "cast value f64 -> f32" {
    const value: f64 = 3.4;
    const vec = Vector2f{ 0, 0 };
    const result = castValue(vec, value);
    try expectEqual(3.4, result);
}

pub fn scale(vec: anytype, value: anytype) @TypeOf(vec) {
    const casted_value = castValue(vec, value);
    return vec * @as(@TypeOf(vec), @splat(casted_value));
}

test "scaling" {
    const vec = Vector3f{ 0, 1, 2 };
    const value: i32 = 3;
    const result = scale(vec, value);
    const expected = Vector3f{ 0, 3, 6 };
    try expectEqual(expected, result);
}

/// Negates all elements of a vector by multiplying them by -1.
pub fn neg(vec: anytype) @TypeOf(vec) {
    return scale(vec, -1);
}

test "negation float" {
    const vec = Vector4f{ 0.0, 1.0, 2.0, -3.0 };
    const result = neg(vec);
    const expected = Vector4f{ 0.0 * -1.0, 1.0 * -1.0, 2.0 * -1.0, -3.0 * -1.0 };
    try expectEqual(expected, result);
}

test "negation int" {
    const vec = Vector2i{ -4, 567 };
    const result = neg(vec);
    const expected = Vector2i{ -4 * -1, 567 * -1 };
    try expectEqual(expected, result);
}

/// Computes the dot product (scalar product) of two vectors.
///
/// This function performs an element-wise multiplication of vectors `a` and `b`,
/// and then sums up all the resulting components into a single scalar value.
pub fn dot(a: anytype, b: @TypeOf(a)) @typeInfo(@TypeOf(a)).vector.child {
    return @reduce(.Add, a * b);
}

test "vectors: dot" {
    const a = Vector2f{ 2, 3 };
    const b = Vector2f{ 4, 5 };
    const result = dot(a, b);
    const expected: @TypeOf(result) = (2 * 4) + (3 * 5);

    try expectEqual(expected, result);
}

/// Computes the cross product of two 2-dimensional vectors.
pub fn cross2(a: anytype, b: @TypeOf(a)) @typeInfo(@TypeOf(a)).vector.child {
    const VecType = @TypeOf(a);
    if (@typeInfo(VecType).vector.len != 2) {
        @compileError("incompatible vector: cross2 function support only vectors with len = 2");
    }

    return (a[0] * b[1]) - (a[1] * b[0]);
}

/// Computes the cross product of two 3-dimensional vectors.
pub fn cross3(a: anytype, b: @TypeOf(a)) @TypeOf(b) {
    const VecType = @TypeOf(a);
    if (@typeInfo(VecType).vector.len != 3) {
        @compileError("incompatible vector: cross3 function support only vectors with len = 3");
    }

    return @TypeOf(a){
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    };
}

test "cross3" {
    const a = Vector3f{ 0, 1, 2 };
    const b = Vector3f{ 3, 4, 5 };
    const result = cross3(a, b);
    const expected = Vector3f{
        1 * 5 - 2 * 4,
        2 * 3 - 0 * 5,
        0 * 4 - 1 * 3,
    };

    try expectEqual(expected, result);
}

/// Computes the magnitude (length) of a vector.
pub fn length(vec: anytype) @typeInfo(@TypeOf(vec)).vector.child {
    return @sqrt(dot(vec, vec));
}

test "length" {
    const vec = Vector4d{ 0, 1, 2, 3 };
    const result = length(vec);
    const expected: f64 = @sqrt(0*0 + 1*1 + 2*2 + 3*3);
    try expectEqual(expected, result);
}

test "length 0 check" {
    const vec = Vector2d{ -0.0, 0.0 };
    const result = length(vec);
    try expectEqual(0, result);
}

/// Computes the squared magnitude (squared length) of a vector.
pub fn lengthSq(vec: anytype) @typeInfo(@TypeOf(vec)).vector.child {
    return dot(vec, vec);
}

test "lengthSq" {
    const vec = Vector3i{ 0, 1, 2 };
    const result = lengthSq(vec);
    const expected: i32 = 0*0 + 1*1 + 2*2;
    try expectEqual(expected, result);
}

test "lengthSq 0 check" {
    const vec = Vector2i{ 0, 0 };
    const result = lengthSq(vec);
    try expectEqual(0, result);
}

/// Computes the straight-line (Euclidean) distance between two spatial points.
pub fn distance(a: anytype, b: @TypeOf(a)) @typeInfo(@TypeOf(a)).vector.child {
    return length(a - b);
}

test "distance" {
    const a = Vector2f { 1.2, -3.4 };
    const b = Vector2f { 5.6,  7.8 };
    const result = distance(a, b);
    const expected = @sqrt(dot(a - b, a - b));
    try expectEqual(expected, result);
}

/// Computes the squared Euclidean distance between two spatial points.
pub fn distanceSq(a: anytype, b: @TypeOf(a)) @typeInfo(@TypeOf(a)).vector.child {
    return lengthSq(a - b);
}

test "distanceSq" {
    const a = Vector2f { 1.2, -3.4 };
    const b = Vector2f { 5.6,  7.8 };
    const result = distanceSq(a, b);
    const expected = dot(a - b, a - b);
    try expectEqual(expected, result);
}

/// Normalizes a vector into a unit vector (a vector with a length of 1.0).
pub fn normalize(vec: anytype) @TypeOf(vec) {
    const len = length(vec);
    if (len == 0) return vec;
    return scale(vec, 1 / len);
}

test "normalize" {
    const vec = Vector3f{ 0, 1, 2 };
    const result = normalize(vec);
    const expected = Vector3f{
        0.0,
        1.0 / @sqrt(0.0*0.0 + 1.0*1.0 + 2.0*2.0),
        2.0 / @sqrt(0.0*0.0 + 1.0*1.0 + 2.0*2.0),
    };
    try expectEqual(expected, result);
}

test "normalize 0 check" {
    const vec = Vector2d{ -0.0, -0.0 };
    const result = normalize(vec);
    const expected = Vector2d{ 0.0, 0.0 };
    try expectEqual(expected, result);
}

/// Performs linear interpolation (lerp) between two vectors.
///
/// This function interpolates between vector `a` and vector `b` based on the scalar factor `t`.
/// The formula used is: `a + (b - a) * t`.
pub fn lerp(a: anytype, b: @TypeOf(a), t: @typeInfo(@TypeOf(a)).vector.child) @TypeOf(a) {
    return a + (b - a) * @as(@TypeOf(a), @splat(t));
}

test "lerp" {
    const a: Vector2f = .{ -1,  2 };
    const b: Vector2f = .{  3, -4 };
    const t: f32 = 0.5;
    const result = lerp(a, b, t);
    const expected = a + (b - a) * Vector2f{ 0.5, 0.5 };
    try expectEqual(expected, result);
}

/// Clamps each element of a vector between the corresponding elements of a minimum and maximum vector.
///
/// This function constrains the components of `vec` element-wise. If an element is less than
/// the minimum, it is set to `min`. If it is greater than the maximum, it is set to `max`.
pub fn clamp(vec: anytype, min: @TypeOf(vec), max: @TypeOf(vec)) @TypeOf(vec) {
    var result = @max(min, vec);
    result = @min(max, result);
    return result;
}

test "clamp float" {
    const vec = Vector4f{ 0.0, 1.0, 5.6, -3.0 };
    const min = Vector4f{ 0.0, -1.0, -2.0, 0.0 };
    const max = Vector4f{ 13.0, 100.0, 5.0, 532.0};
    const result = clamp(vec, min, max);
    const expected = Vector4f{ 0.0, 1.0, 5.0, 0.0 };
    try expectEqual(expected, result);
}

test "clamp int" {
    const vec = Vector2i{ 5, -3 };
    const min = Vector2i{ -2, 0 };
    const max = Vector2i{ 5, 532};
    const result = clamp(vec, min, max);
    const expected = Vector2i{ 5, 0 };
    try expectEqual(expected, result);
}

/// Projects 'v' onto 'u'
pub fn project(v: anytype, u: @TypeOf(v)) @TypeOf(v) {
    const len = lengthSq(u);
    if (len == 0.0) return splat(@TypeOf(v), 0);

    const scalar = dot(v, u) / len;
    return scale(u, scalar);
}

test "vector projection" {
    const v = Vector3f{ 1.2, 3.0, -4.0 };
    const u = Vector3f{ 5.0, 0.0,  0.0 };
    const result = project(v, u);
    const expected = scale(
        Vector3f{ 5.0, 0.0,  0.0 },
        dot(v, u) / lengthSq(u)
    );
    try expectEqual(expected, result);
}

/// Rejects 'v' from 'u' (perpendicular component)
pub fn reject(v: anytype, u: @TypeOf(v)) @TypeOf(v) {
    return v - project(v, u);
}

test "vector rejection" {
    const v = Vector3f{ 1.2, 3.0, -4.0 };
    const u = Vector3f{ 5.0, 0.0,  0.0 };
    const result = reject(v, u);
    const expected = v - scale(
        Vector3f{ 5.0, 0.0,  0.0 },
        dot(v, u) / lengthSq(u)
    );
    try expectEqual(expected, result);
}

/// Reflects 'v' across a surface normal 'n' (n must be normalized)
pub fn reflect(v: anytype, n: @TypeOf(v)) @TypeOf(v) {
    const scalar = 2.0 * dot(v, n);
    return v - scale(n, scalar);
}

test "vector reflection" {
    const v = Vector3f{ 1.2, 3.0, -4.0 };
    const n = Vector3f{ 0.1, 0.2,  0.3 };
    const result = reflect(v, n);
    const expected = v - scale(n, 2.0 * dot(v, n));
    try expectEqual(expected, result);
}

/// Calculates a 3D forward direction vector from pitch and yaw angles(radians).
pub fn forward(pitch: f32, yaw: f32) Vector3f {
    return normalize(Vector3f{
        @cos(pitch) * @sin(yaw),
        @sin(pitch),
        @cos(pitch) * @cos(yaw),
    });
}

test "forward" {
    const pitch = -200.5;
    const yaw = 8.0;
    const result = forward(pitch, yaw);
    const expected = Vector3f{
        math.cos(pitch) * math.sin(yaw),
        math.sin(pitch),
        math.cos(pitch) * math.cos(yaw),
    };

    const eps = 0.00001;
    try std.testing.expectApproxEqAbs(expected[0], result[0], eps);
    try std.testing.expectApproxEqAbs(expected[1], result[1], eps);
    try std.testing.expectApproxEqAbs(expected[2], result[2], eps);
}

/// Calculates a 3D forward direction vector projected onto the horizontal (X-Z) plane.
pub fn forwardHorizontal(pitch: f32, yaw: f32) Vector3f {
    return normalize(Vector3f{
        @cos(pitch) * @sin(yaw),
        0,
        @cos(pitch) * @cos(yaw),
    });
}

test "forward horizontal" {
    const pitch = -200.5;
    const yaw = 8.0;
    const result = forwardHorizontal(pitch, yaw);
    const expected = normalize(Vector3f{
        math.cos(pitch) * math.sin(yaw),
        0,
        math.cos(pitch) * math.cos(yaw),
    });

    const eps = 0.00001;
    try std.testing.expectApproxEqAbs(expected[0], result[0], eps);
    try expectEqual(0.0, result[1]);
    try std.testing.expectApproxEqAbs(expected[2], result[2], eps);
}