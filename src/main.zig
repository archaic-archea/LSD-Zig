const std = @import("std");
const serial = @import("./serial.zig");
const limine = @import("./limine.zig");
const kstdout = @import("./kstdout.zig");
const memory = @import("./memory/memory.zig");

pub export var BOOT: limine.BootloaderInfoRequest = .{};

fn kmain() !void {
    // Initialize kernel output
    var kern_out: kstdout.Kstdout = .{};
    var kout = kern_out.writer();

    var boot = BOOT.response.?;
    try kout.print("Booted with: {s} v{s}\n", .{ boot.name, boot.version });

    memory.init();

    try kout.print("Kernel end reached, looping\n", .{});
    while (true) {}
}

/// kernel wrapper, handles any errors produced by main function
export fn kentry() void {
    var kern_out: kstdout.Kstdout = .{};
    var kout = kern_out.writer();

    var kmainres = kmain();
    kout.print("KERNEL FAILURE\n", .{}) catch {};

    kmainres catch |err| {
        kout.print("\nError: {s}\n", .{@errorName(err)}) catch {};
        if (@errorReturnTrace()) |stack_trace| {
            kout.print("Trace: {}", .{stack_trace}) catch {};
        }
    };

    while (true) {}
}

pub fn panic(msg: []const u8, trace_opt: ?*std.builtin.StackTrace, ret_addr_opt: ?usize) noreturn {
    var kern_out: kstdout.Kstdout = .{};
    var kout = kern_out.writer();

    kout.print("\nKERNEL PANIC!\n{s}\n", .{msg}) catch {};
    if (trace_opt) |trace| {
        kout.print("STACKTRACE: {}\n", .{trace}) catch {};
    } else {
        kout.print("NO STACKTRACE\n", .{}) catch {};
    }

    if (ret_addr_opt) |ret_addr| {
        kout.print("RETURN ADDRESS {*}\n", .{@intToPtr(*void, ret_addr)}) catch {};
    } else {
        kout.print("NO RETURN ADDRESS\n", .{}) catch {};
    }

    while (true) {}
}
