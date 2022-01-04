const std = @import("std");

fn getRelativePath() []const u8 {
    comptime var src: std.builtin.SourceLocation = @src();
    return std.fs.path.dirname(src.file).? ++ std.fs.path.sep_str;
}

pub const rayPkg = std.build.Pkg{ .name = "raylib", .path = std.build.FileSource{ .path = getRelativePath() ++ "libs/raylib.zig" } };
pub const rlglPkg = std.build.Pkg{ .name = "rlgl", .path = std.build.FileSource{ .path = getRelativePath() ++ "libs/rlgl.zig" } };
pub const nbnetPkg = std.build.Pkg{ .name = "nbnet", .path = std.build.FileSource{ .path = getRelativePath() ++ "libs/nbnet.zig" } };
pub const zlmPkg = std.build.Pkg{ .name = "zlm", .path = std.build.FileSource{ .path = getRelativePath() ++ "libs/zlm/zlm.zig" } };
pub const rligPkg = std.build.Pkg{ .name = "rlig", .path = std.build.FileSource{ .path = getRelativePath() ++ "libs/rlig.zig" }, .dependencies = &[_]std.build.Pkg{
    rayPkg,
    rlglPkg,
} };

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("example", "example/src/main.zig");
    link(b, exe, target);
    exe.addIncludeDir("libs/raylib/src");
    exe.addIncludeDir("libs/raylib/external");
    exe.addIncludeDir("libs/raylib/src/external/glfw/include");
    exe.addIncludeDir("libs/cimgui/imgui");
    exe.addIncludeDir("libs/cimgui");
    exe.addIncludeDir("libs/cimgui/generator/output");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    addBinaryContent("example/assets") catch unreachable;

    // Run cmd
    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

pub fn link(b: *std.build.Builder, exe: *std.build.LibExeObjStep, target: std.zig.CrossTarget) void {
    // Link step
    exe.linkLibrary(imguiLibrary(b, target));
    exe.linkLibrary(raylibLibrary(b, target));
    exe.addPackage(zlmPkg);
    exe.addPackage(rayPkg);
    exe.addPackage(rlglPkg);
    exe.addPackage(rligPkg);
    exe.addPackage(nbnetPkg);
}

pub fn imguiLibrary(b: *std.build.Builder, target: std.zig.CrossTarget) *std.build.LibExeObjStep {
    comptime var path = getRelativePath();
    var imgui = b.addStaticLibrary("imgui", null);
    imgui.linkLibC();
    imgui.linkSystemLibrary("c++");

    // Generate flags.
    var flagContainer = std.ArrayList([]const u8).init(std.heap.page_allocator);
    if (b.is_release) flagContainer.append("-Os") catch unreachable;
    flagContainer.append("-Wno-return-type-c-linkage") catch unreachable;

    // Link libraries.
    if (target.isWindows()) {
        imgui.linkSystemLibrary("winmm");
        imgui.linkSystemLibrary("user32");
        imgui.linkSystemLibrary("imm32");
        imgui.linkSystemLibrary("gdi32");
    }

    // Include dirs.
    imgui.addIncludeDir(path ++ "libs/cimgui/imgui");
    imgui.addIncludeDir(path ++ "libs/cimgui");

    // Add C
    imgui.addCSourceFiles(&.{ path ++ "libs/cimgui/imgui/imgui.cpp", path ++ "libs/cimgui/imgui/imgui_demo.cpp", path ++ "libs/cimgui/imgui/imgui_draw.cpp", 
    path ++ "libs/cimgui/imgui/imgui_tables.cpp", path ++ "libs/cimgui/imgui/imgui_widgets.cpp", path ++ "libs/cimgui/cimgui.cpp" }, flagContainer.items);

    return imgui;
}

pub fn raylibLibrary(b: *std.build.Builder, target: std.zig.CrossTarget) *std.build.LibExeObjStep {
    comptime var path = getRelativePath();
    var raylib = b.addStaticLibrary("raylib", null);
    raylib.linkLibC();
    raylib.linkSystemLibrary("c++");

    // Generate flags.
    var flagContainer = std.ArrayList([]const u8).init(std.heap.page_allocator);
    if (b.is_release) flagContainer.append("-Os") catch unreachable;
    flagContainer.append("-std=gnu99") catch unreachable;
    flagContainer.append("-DPLATFORM_DESKTOP") catch unreachable;
    flagContainer.append("-DGL_SILENCE_DEPRECATION") catch unreachable;
    flagContainer.append("-fno-sanitize=undefined") catch unreachable;
    flagContainer.append("-D_POSIX_C_SOURCE=199309L") catch unreachable;

    // Link libraries.
    if (target.isWindows()) {
        raylib.linkSystemLibrary("winmm");
        raylib.linkSystemLibrary("opengl32");
        raylib.linkSystemLibrary("gdi32");
        raylib.addIncludeDir(path ++ "libs/raylib/src/external/glfw/deps/mingw");
    }
    if (target.isLinux()) {
        raylib.addIncludeDir("/usr/include");
    }

    // Include dirs.
    raylib.addIncludeDir(path ++ "libs/raylib/src");
    raylib.addIncludeDir(path ++ "libs/raylib/external");
    raylib.addIncludeDir(path ++ "libs/raylib/src/external/glfw/include");

    // Add C
    raylib.addCSourceFiles(&.{ path ++ "libs/raylib/src/rcore.c", path ++ "libs/raylib/src/rmodels.c", path ++ "libs/raylib/src/raudio.c",
    path ++ "libs/raylib/src/rshapes.c", path ++ "libs/raylib/src/rtext.c", path ++ "libs/raylib/src/rtextures.c",
    path ++ "libs/raylib/src/utils.c", path ++ "libs/raylib/src/rglfw.c"}, flagContainer.items);

    return raylib;
}

pub const AddContentErrors = error{ PermissionError, WriteError, FileError, FolderError, RecursionError };
const fs = std.fs;

/// Pass in a relative path to a folder, and its content is added to the zig-cache/bin output.
/// TODO: Lookup where zig defines the output folder to make it more bulletproof.
pub fn addBinaryContent(comptime baseContentPath: []const u8) AddContentErrors!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    const zigBin: []const u8 = std.fs.path.join(allocator, &[_][]const u8{ "zig-out", "bin" }) catch return error.FolderError;
    defer allocator.free(zigBin);
    fs.cwd().makePath(zigBin) catch return error.FolderError;

    var sourceFolder: fs.Dir = fs.cwd().openDir(baseContentPath, .{ .iterate = true }) catch return error.FolderError;
    defer sourceFolder.close();
    var iterator: fs.Dir.Iterator = sourceFolder.iterate();
    while (iterator.next() catch return error.FolderError) |target| {
        var x: fs.Dir.Entry = target;
        if (x.kind == .Directory) {
            const source: []const u8 = std.fs.path.join(allocator, &[_][]const u8{ baseContentPath, x.name }) catch return error.RecursionError;
            const targetFolder: []const u8 = std.fs.path.join(allocator, &[_][]const u8{ zigBin, x.name }) catch return error.RecursionError;
            defer allocator.free(source);
            defer allocator.free(targetFolder);
            try innerAddContent(allocator, source, targetFolder);
        }
        if (x.kind == .File) {
            try copy(baseContentPath, zigBin, x.name);
        }
    }
}

fn innerAddContent(allocator: std.mem.Allocator, folder: []const u8, dest: []const u8) AddContentErrors!void {
    var sourceFolder: fs.Dir = fs.cwd().openDir(folder, .{ .iterate = true }) catch return error.FolderError;
    defer sourceFolder.close();

    var iterator: fs.Dir.Iterator = sourceFolder.iterate();
    while (iterator.next() catch return error.FolderError) |target| {
        var x: fs.Dir.Entry = target;
        if (x.kind == .Directory) {
            const source: []const u8 = std.fs.path.join(allocator, &[_][]const u8{ folder, x.name }) catch return error.RecursionError;
            const targetFolder: []const u8 = std.fs.path.join(allocator, &[_][]const u8{ dest, x.name }) catch return error.RecursionError;
            defer allocator.free(source);
            defer allocator.free(targetFolder);
            try innerAddContent(allocator, source, targetFolder);
        }
        if (x.kind == .File) {
            try copy(folder, dest, x.name);
        }
    }
}

fn copy(from: []const u8, to: []const u8, filename: []const u8) AddContentErrors!void {
    fs.cwd().makePath(to) catch return error.FolderError;
    var source = fs.cwd().openDir(from, .{}) catch return error.FileError;
    var dest = fs.cwd().openDir(to, .{}) catch return error.FileError;

    var sfile = source.openFile(filename, .{}) catch return error.FileError;
    defer sfile.close();
    var dfile = dest.openFile(filename, .{}) catch {
        source.copyFile(filename, dest, filename, .{}) catch return error.PermissionError;
        std.debug.print("COPY: {s}/{s} to {s}/{s}\n", .{ from, filename, to, filename });
        return;
    };

    var sstat = sfile.stat() catch return error.FileError;
    var dstat = dfile.stat() catch return error.FileError;

    if (sstat.mtime > dstat.mtime) {
        dfile.close();
        dest.deleteFile(filename) catch return error.PermissionError;
        source.copyFile(filename, dest, filename, .{}) catch return error.PermissionError;
        std.debug.print("OVERWRITE: {s}\\{s} to {s}\\{s}\n", .{ from, filename, to, filename });
    } else {
        defer dfile.close();
        std.debug.print("SKIP: {s}\\{s}\n", .{ from, filename });
    }
}