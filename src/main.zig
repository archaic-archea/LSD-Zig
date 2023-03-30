const std = @import("std");
const serial = @import("./serial.zig");
const limine = @import("./limine.zig");
const kstdout = @import("./kstdout.zig");
const memory = @import("./memory/memory.zig");

pub export var boot: limine.BootloaderInfoRequest = .{};
pub export var hhdm: limine.HhdmRequest = .{};

fn kmain() !void {
    // Initialize kernel output
    var kern_out: kstdout.Kstdout = .{};
    var kout = kern_out.writer();

    var bootresponse = boot.response.?;
    try kout.print("Booted with: {s} v{s}\n", .{ bootresponse.name, bootresponse.version });

    var hhdmresponse = hhdm.response.?;
    try kout.print("HHDM offset: 0x{x}\n", .{hhdmresponse.offset});

    while (true) {}
}

/// kernel wrapper, handles any errors produced by main function
export fn kentry() void {
    var kern_out: kstdout.Kstdout = .{};
    var kout = kern_out.writer();

    kmain() catch |err| {
        kout.print("\nError: {s}\n", .{@errorName(err)}) catch {};
        if (@errorReturnTrace()) |_| {}
    };
}
