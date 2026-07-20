# [bazic-math](https://github.com/denkuzox/bazic-math)

bazic_math is math library for graphic/game development

Oriented towards OpenGL graphics API. (Vulkan in future)

Documentation currently in development

## Getting started

How to get dependencies

main branch version: `zig fetch --save git+https://github.com/denkuzox/bazic-math.git`

Example `build.zig`

```zig
pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{ ... });

    const bazic_math = b.dependency("bazic_math", .{});
    exe.root_module.addImport("bazic_math", bazic_math.module("root"));
}
```

Now in your code you may import and use bazic-math:
```zig
const bmath = @import("bazic_math");
const vec = bmath.Vectors;
const mat = bmath.Matrices;
const Matrix4f = bmath.Matrices.Matrix4f;
```