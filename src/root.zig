//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

pub const Vectors = @import("vector.zig");
pub const Matrices = @import("matrix.zig");

test {
    _ = @import("vector.zig");
    _ = @import("matrix.zig");
}