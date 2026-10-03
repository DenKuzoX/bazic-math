const std = @import("std");
const math = std.math;
const expectEqual = std.testing.expectEqual;

pub const Vector2i = [2]i32;
pub const Vector2f = [2]f32;
pub const Vector2d = [2]f64;

pub const Vector3i = [3]i32;
pub const Vector3f = [3]f32;
pub const Vector3d = [3]f64;

pub const Vector4i = [4]i32;
pub const Vector4f = [4]f32;
pub const Vector4d = [4]f64;

// Constructors

pub fn splat(T: type, value: anytype) T {
    return @splat(value);
}

fn castValue(vec: anytype, value: anytype) @typeInfo(@TypeOf(vec)).array.child {
    const VecType = @TypeOf(vec);
    const ChildType = @typeInfo(VecType).array.child;
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

// Standard operation

pub fn add(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    const arr_info = @typeInfo(@TypeOf(a)).array;
    var answer: [arr_info.len]arr_info.child = undefined;
    inline for (a, 0..) |_, i| {
        answer[i] = a[i] + b[i];
    }
    return answer;
}

test "add arrays" {
    const a = Vector2i{ 1, 2 };
    const b = Vector2i{ 3, 4 };
    const result = add(a, b);
    const expected = Vector2i{ 1 + 3, 2 + 4 };
    try expectEqual(expected, result);
}

pub fn subtract(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    const arr_info = @typeInfo(@TypeOf(a)).array;
    var answer: [arr_info.len]arr_info.child = undefined;
    inline for (a, 0..) |_, i| {
        answer[i] = a[i] - b[i];
    }
    return answer;
}

test "subtract arrays" {
    const a = Vector2i{ 1, 2 };
    const b = Vector2i{ 3, 4 };
    const result = subtract(a, b);
    const expected = Vector2i{ 1 - 3, 2 - 4 };
    try expectEqual(expected, result);
}

pub fn multiply(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    const arr_info = @typeInfo(@TypeOf(a)).array;
    var answer: [arr_info.len]arr_info.child = undefined;
    inline for (a, 0..) |_, i| {
        answer[i] = a[i] * b[i];
    }
    return answer;
}

test "multiply arrays" {
    const a = Vector2i{ 1, 2 };
    const b = Vector2i{ 3, 4 };
    const result = multiply(a, b);
    const expected = Vector2i{ 1 * 3, 2 * 4 };
    try expectEqual(expected, result);
}

pub fn divide(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    const arr_info = @typeInfo(@TypeOf(a)).array;
    var answer: [arr_info.len]arr_info.child = undefined;
    if (@typeInfo(arr_info.child) == .int) {
        inline for (a, 0..) |_, i| {
            answer[i] = @divTrunc(a[i], b[i]);
        }
    } else {
        inline for (a, 0..) |_, i| {
            answer[i] = a[i] / b[i];
        }
    }

    return answer;
}

test "divide arrays" {
    const a = Vector2i{ 1, 2 };
    const b = Vector2i{ 3, 4 };
    const result = divide(a, b);
    const expected = Vector2i{ 1 / 3, 2 / 4 };
    try expectEqual(expected, result);
}

pub fn length(vec: anytype) @typeInfo(@TypeOf(vec)).array.child {
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

pub fn lengthSq(vec: anytype) @typeInfo(@TypeOf(vec)).array.child {
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

pub fn distance(a: anytype, b: @TypeOf(a)) @typeInfo(@TypeOf(a)).array.child {
    return length(subtract(a, b));
}

test "distance" {
    const a = Vector2f { 1.2, -3.4 };
    const b = Vector2f { 5.6,  7.8 };
    const result = distance(a, b);
    const expected = @sqrt(dot(subtract(a, b), subtract(a, b)));
    try expectEqual(expected, result);
}

pub fn distanceSq(a: anytype, b: @TypeOf(a)) @typeInfo(@TypeOf(a)).array.child {
    return lengthSq(subtract(a, b));
}

test "distanceSq" {
    const a = Vector2f { 1.2, -3.4 };
    const b = Vector2f { 5.6,  7.8 };
    const result = distanceSq(a, b);
    const expected = dot(subtract(a, b), subtract(a, b));
    try expectEqual(expected, result);
}

// Comparisons

pub const CompareOperation = enum {
    Equal,
    Greater,
    Less,
    EqualOrGreater,
    EqualOrLess,
};

pub fn compareVecAll(
    a: anytype,
    comptime is: CompareOperation,
    b: @TypeOf(a),
) bool {
    const len = @typeInfo(@TypeOf(a)).array.len;
    var result: [len]bool = undefined;
    for (&result, 0..) |*value, i| {
        switch (is) {
            .Equal => value.* = a[i] == b[i],
            .Greater => value.* = a[i] > b[i],
            .Less => value.* = a[i] < b[i],
            .EqualOrGreater => value.* = a[i] >= b[i],
            .EqualOrLess => value.* = a[i] <= b[i],
        }
    }

    var previous_bool: bool = true;
    inline for (result) |value| {
        if (previous_bool == value) {
            previous_bool = value;
        } else return false;
    }

    return true;
}

test "all value comparison equal" {
    const a: Vector3f = .{  0.0, 1.2, -3.4 };
    const b: Vector3f = .{ -0.0, 1.2, -3.4 };
    const result = compareVecAll(a, .Equal, b);
    try expectEqual(true, result);
}

test "all value comparison greater" {
    const a: Vector4f = .{ 4, 5.6, -0.7, 80 };
    const b: Vector4f = .{ 0, 1.5, -2  , 30};
    const result = compareVecAll(a, .Greater, b);
    try expectEqual(true, result);
}

test "all value comparison less" {
    const a: Vector2i = .{ 1, -2 };
    const b: Vector2i = .{ 3, 40 };
    const result = compareVecAll(a, .Less, b);
    try expectEqual(true, result);
}

test "all value comparison, any check" {
    const a: Vector3f = .{ 0, 5.0, 0 };
    const b: Vector3f = .{ 0, 1.5, 0 };
    const result = compareVecAll(a, .Equal, b);
    try expectEqual(false, result);
}

pub fn compareVecAny(
    a: anytype,
    comptime is: CompareOperation,
    b: @TypeOf(a),
) bool {
    const len = @typeInfo(@TypeOf(a)).array.len;
    var result: [len]bool = undefined;
    for (&result, 0..) |*value, i| {
        switch (is) {
            .Equal => value.* = a[i] == b[i],
            .Greater => value.* = a[i] > b[i],
            .Less => value.* = a[i] < b[i],
            .EqualOrGreater => value.* = a[i] >= b[i],
            .EqualOrLess => value.* = a[i] <= b[i],
        }
    }

    inline for (result) |value| {
        if (value == true) return true;
    }

    return false;
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

// Core

pub fn scale(vec: anytype, value: anytype) @TypeOf(vec) {
    const casted_value = castValue(vec, value);
    return multiply(vec, @as(@TypeOf(vec), @splat(casted_value)));
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

pub fn dot(a: anytype, b: @TypeOf(a)) @typeInfo(@TypeOf(a)).array.child {
    const mult = multiply(a, b);
    var result: @typeInfo(@TypeOf(a)).array.child = 0;
    inline for (mult) |value| {
        result += value;
    }
    return result;
}

test "dot" {
    const a = Vector2f{ 2, 3 };
    const b = Vector2f{ 4, 5 };
    const result = dot(a, b);
    const expected: f32 = (2 * 4) + (3 * 5);

    try expectEqual(expected, result);
}

pub fn min(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    var answer: @TypeOf(a) = undefined;
    inline for (answer, 0..) |_, i| {
        answer[i] = @min(a[i], b[i]);
    }
    return answer;
}

test "min" {
    const a = Vector3i{ 0, 1, 2 };
    const b = Vector3i{ -1, 1, 3 };
    const result = min(a, b);
    const expected = Vector3i{ -1, 1, 2};
    try expectEqual(expected, result);
}

pub fn max(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    var answer: @TypeOf(a) = undefined;
    inline for (answer, 0..) |_, i| {
        answer[i] = @max(a[i], b[i]);
    }
    return answer;
}

test "max" {
    const a = Vector3i{ 0, 1, 2 };
    const b = Vector3i{ -1, 1, 3 };
    const result = max(a, b);
    const expected = Vector3i{ 0, 1, 3};
    try expectEqual(expected, result);
}

/// Computes the cross product of two 2-dimensional vectors.
pub fn cross2(a: anytype, b: @TypeOf(a)) @typeInfo(@TypeOf(a)).vector.child {
    const VecType = @TypeOf(a);
    if (@typeInfo(VecType).array.len != 2) {
        @compileError("incompatible vector: cross2 function support only vectors with len = 2");
    }

    return (a[0] * b[1]) - (a[1] * b[0]);
}

/// Computes the cross product of two 3-dimensional vectors.
pub fn cross3(a: anytype, b: @TypeOf(a)) @TypeOf(b) {
    const VecType = @TypeOf(a);
    if (@typeInfo(VecType).array.len != 3) {
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
/// This function interpolates between vector `a` and vector `b` based on the scalar factor `t`
/// The formula used is: `a + (b - a) * t`.
pub fn lerp(a: anytype, b: @TypeOf(a), t: @typeInfo(@TypeOf(a)).array.child) @TypeOf(a) {
    return add(a, multiply(subtract(b, a), @as(@TypeOf(a), @splat(t))));
}

test "lerp" {
    const a: Vector2f = .{ -1,  2 };
    const b: Vector2f = .{  3, -4 };
    const t: f32 = 0.5;
    const result = lerp(a, b, t);
    const expected = add(a, multiply(subtract(b, a), Vector2f{ 0.5, 0.5 }));
    try expectEqual(expected, result);
}

/// Clamps each element of a vector between the corresponding elements of a minimum and maximum vector.
///
/// This function constrains the components of `vec` element-wise. If an element is less than
/// the minimum, it is set to `min`. If it is greater than the maximum, it is set to `max`.
pub fn clamp(vec: anytype, min_vec: @TypeOf(vec), max_vec: @TypeOf(vec)) @TypeOf(vec) {
    var result = max(min_vec, vec);
    result = min(max_vec, result);
    return result;
}

test "clamp float" {
    const vec = Vector4f{ 0.0, 1.0, 5.6, -3.0 };
    const min_vec = Vector4f{ 0.0, -1.0, -2.0, 0.0 };
    const max_vec = Vector4f{ 13.0, 100.0, 5.0, 532.0};
    const result = clamp(vec, min_vec, max_vec);
    const expected = Vector4f{ 0.0, 1.0, 5.0, 0.0 };
    try expectEqual(expected, result);
}

test "clamp int" {
    const vec = Vector2i{ 5, -3 };
    const min_vec = Vector2i{ -2, 0 };
    const max_vec = Vector2i{ 5, 532};
    const result = clamp(vec, min_vec, max_vec);
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

test "projection" {
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
    return subtract(v, project(v, u));
}

test "rejection" {
    const v = Vector3f{ 1.2, 3.0, -4.0 };
    const u = Vector3f{ 5.0, 0.0,  0.0 };
    const result = reject(v, u);
    const expected = subtract(v, scale(
        Vector3f{ 5.0, 0.0,  0.0 },
        dot(v, u) / lengthSq(u)
    ));
    try expectEqual(expected, result);
}

/// Reflects 'v' across a surface normal 'n' (n must be normalized)
pub fn reflect(v: anytype, n: @TypeOf(v)) @TypeOf(v) {
    const scalar = 2.0 * dot(v, n);
    return subtract(v, scale(n, scalar));
}

test "reflection" {
    const v = Vector3f{ 1.2, 3.0, -4.0 };
    const n = Vector3f{ 0.1, 0.2,  0.3 };
    const result = reflect(v, n);
    const expected = subtract(v, scale(n, 2.0 * dot(v, n)));
    try expectEqual(expected, result);
}

// Other

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