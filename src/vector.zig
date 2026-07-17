const std = @import("std");
const math = std.math;
const expectEqual = std.testing.expectEqual;

pub const Vector2i = @Vector(2, i32);
pub const Vector2f = @Vector(2, f32);
pub const Vector2d = @Vector(2, f64);

pub const Vector3i = @Vector(3, i32);
pub const Vector3f = @Vector(3, f32);
pub const Vector3d = @Vector(3, f64);

pub const Vector4i = @Vector(4, i32);
pub const Vector4f = @Vector(4, f32);
pub const Vector4d = @Vector(4, f64);


pub fn arrayToVec(arr: anytype) @Vector(@typeInfo(@TypeOf(arr)).array.len, @typeInfo(@TypeOf(arr)).array.child) {
    const ArrTypeInfo = @typeInfo(@TypeOf(arr)).array;
    const ChildType = ArrTypeInfo.child;
    const len = ArrTypeInfo.len;
    const vec: @Vector(len, ChildType) = @bitCast(arr);
    return vec;
}

test "array to vector" {
    const arr = [_]f32{ 0.0, 1.2, -3.0 };
    const result = arrayToVec(arr);
    const expected = Vector3f{ 0.0, 1.2, -3.0 };
    try expectEqual(expected, result);
}

pub fn vecToArray(vec: anytype) [@typeInfo(@TypeOf(vec)).vector.len]@typeInfo(@TypeOf(vec)).vector.child {
    const VecTypeInfo = @typeInfo(@TypeOf(vec)).vector;
    const ChildType = VecTypeInfo.child;
    const len = VecTypeInfo.len;
    const arr: [len]ChildType = @bitCast(vec);
    return arr;
}

test "vector to array" {
    const vec = Vector2f{ 0.0, 2.5 };
    const result = vecToArray(vec);
    const expected = [2]f32{ 0.0, 2.5 };
    try expectEqual(expected, result);
}

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

pub fn vec4ToVec3(vec: anytype) @Vector(3, @typeInfo(@TypeOf(vec)).vector.child) {
    const T = @typeInfo(@TypeOf(vec)).vector.child;
    const vec3 = @Vector(3, T){
        vec[0] / vec[3],
        vec[1] / vec[3],
        vec[2] / vec[3],
    };
    return vec3;
}

test "vector4 to vector3" {
    const vec = Vector4f{ 0.0, 4.0, -5.0, 2.0 };
    const result = vec4ToVec3(vec);
    const expected = Vector3f{ 0.0 / 2.0 , 4.0 / 2.0, -5.0 / 2.0 };
    try expectEqual(expected, result);
}

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

pub fn compareVecAny(a: anytype, is: CompareOperation, b: @TypeOf(a)) bool {
    return compareVectors(a, is, b, .Or);
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
                ++ "' int value of type '" ++ @typeName(ChildType) ++ "'"
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
    const exprected = Vector3f{ 0, 3, 6};
    try expectEqual(exprected, result);
}

pub fn neg(vec: anytype) @TypeOf(vec) {
    return scale(vec, -1);
}

test "negation" {
    const vec = Vector4f{ 0.0, 1.0, 2.0, 3.0 };
    const result = neg(vec);
    const expected = Vector4f{ 0.0 * -1.0, 1.0 * -1.0, 2.0 * -1.0, 3.0 * -1.0 };
    try expectEqual(expected, result);
}

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

test "cross" {
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

pub fn lerp(a: anytype, b: @TypeOf(a), t: anytype) @TypeOf(a) {
    return a + (b - a) * @as(@TypeOf(a), @splat(t));
}

test "lerp" {
    const a: Vector2i = .{ 0, 1 };
    const b: Vector2i = .{ 2, 3 };
    const t: i32 = 4;
    const result = lerp(a, b, t);
    const expected = a + (b - a) * Vector2i{ 4, 4 };
    try expectEqual(expected, result);
}

pub fn clamp(vec: anytype, min: @TypeOf(vec), max: @TypeOf(vec)) @TypeOf(vec) {
    var result = @max(min, vec);
    result = @min(max, result);
    return result;
}

test "clamp" {
    const vec = Vector4f{ 0.0, 1.0, 5.6, -3.0 };
    const min = Vector4f{ 0.0, -1.0, -2.0, 0.0 };
    const max = Vector4f{ 13.0, 100.0, 5.0, 532.0};
    const result = clamp(vec, min, max);
    const expected = Vector4f{ 0.0, 1.0, 5.0, 0.0 };
    try expectEqual(expected, result);
}

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