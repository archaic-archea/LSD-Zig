const std = @import("std");
const Target = @import("std").Target;
const CrossTarget = @import("std").zig.CrossTarget;
const Feature = @import("std").Target.Cpu.Feature;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    var stdout = std.io.getStdOut();

    const features = Target.riscv.Feature;

    var enabled_features = Feature.Set.empty;
    enabled_features.addFeature(@enumToInt(features.m));
    enabled_features.addFeature(@enumToInt(features.a));
    enabled_features.addFeature(@enumToInt(features.c));

    const target = CrossTarget{
        .cpu_arch = Target.Cpu.Arch.riscv64,
        .os_tag = Target.Os.Tag.freestanding,
        .abi = Target.Abi.none,
        .cpu_features_add = enabled_features,
    };

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const kernel = b.addExecutable(.{
        .name = "LSD",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    kernel.addAssemblyFileSource(.{ .path = "src/entry.s" });
    kernel.setLinkerScriptPath(.{ .path = "config/linker.ld" });
    kernel.code_model = .medium;
    kernel.rdynamic = true;

    _ = try stdout.write("Building kernel\n");
    kernel.install();
}
