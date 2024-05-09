const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(std.build.Step.Compile.Linkage, "linkage", "Specify static or dynamic linkage") orelse .dynamic;

    const upstream = b.dependency("yaml", .{});
    var lib = std.build.Step.Compile.create(b, .{
        .name = "yaml",
        .target = target,
        .optimize = optimize,
        .kind = .lib,
        .linkage = linkage,
    });

    lib.linkLibC();
    lib.addConfigHeader(b.addConfigHeader(
        .{ .style = .{ .cmake = .{ .dependency = .{ .dependency = upstream, .sub_path = "cmake/config.h.in" } } } },
        .{
            // TODO figure out if there's a way I can read this from the zon file so its only set in one place?
            .YAML_VERSION_MAJOR = 0,
            .YAML_VERSION_MINOR = 2,
            .YAML_VERSION_PATCH = 5,
            .YAML_VERSION_STRING = "0.2.5",
        },
    ));
    lib.addIncludePath(.{ .dependency = .{ .dependency = upstream, .sub_path = "include" } });
    lib.addCSourceFiles(.{
        .dependency = upstream,
        .files = &.{
            "src/api.c",
            "src/dumper.c",
            "src/emitter.c",
            "src/loader.c",
            "src/parser.c",
            "src/reader.c",
            "src/scanner.c",
            "src/writer.c",
        },
        .flags = &[_][]const u8{"-DHAVE_CONFIG_H"},
    });

    lib.installHeadersDirectoryOptions(.{
        .source_dir = .{ .dependency = .{ .dependency = upstream, .sub_path = "include" } },
        .install_dir = .header,
        .install_subdir = "",
        .include_extensions = &.{"yaml.h"},
    });
    b.installArtifact(lib);
}
