//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

pub const vector = @import("vector.zig");
pub const matrix = @import("matrix.zig");
pub const array_vector = @import("array_vector.zig");
pub const array_matrix = @import("array_matrix.zig");

test {
    std.testing.refAllDecls(@import("vector.zig"));
    std.testing.refAllDecls(@import("matrix.zig"));
    std.testing.refAllDecls(@import("array_vector.zig"));
    std.testing.refAllDecls(@import("array_matrix.zig"));
}