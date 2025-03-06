const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(
        std.builtin.LinkMode,
        "linkage",
        "Specify static or dynamic linkage",
    ) orelse .dynamic;

    const upstream = b.dependency("yaml", .{});
    var lib = b.addLibrary(.{
        .name = "yaml",
        .root_module = b.createModule(
            .{
                .target = target,
                .optimize = optimize,
                .pic = if (linkage == .dynamic) true else null,
            },
        ),
        .linkage = linkage,
    });

    if (optimize == .ReleaseSmall and linkage == .static) {
        lib.link_function_sections = true;
        lib.link_data_sections = true;
    }

    lib.linkLibC();
    lib.addConfigHeader(b.addConfigHeader(
        .{ .style = .{ .cmake = .{
            .dependency = .{ .dependency = upstream, .sub_path = "cmake/config.h.in" },
        } } },
        .{
            .YAML_VERSION_MAJOR = 0,
            .YAML_VERSION_MINOR = 2,
            .YAML_VERSION_PATCH = 5,
            .YAML_VERSION_STRING = "0.2.5",
        },
    ));
    lib.addIncludePath(.{ .dependency = .{ .dependency = upstream, .sub_path = "include" } });
    lib.addCSourceFiles(.{
        .root = upstream.path(""),
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
        .flags = &.{"-DHAVE_CONFIG_H"},
    });

    lib.installHeader(upstream.path("include/yaml.h"), "yaml.h");
    b.installArtifact(lib);
}
