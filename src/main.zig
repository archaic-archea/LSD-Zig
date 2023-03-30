const std = @import("std");
const serial = @import("./serial.zig");
const limine = @import("./limine.zig");
const kstdout = @import("./kstdout.zig");

pub export var boot: limine.BootloaderInfoRequest = .{};

export fn kmain() void {
    var uart: *volatile serial.Uart16550 = @intToPtr(*volatile serial.Uart16550, 0x1000_0000);

    var pot_response = boot.response;

    if (pot_response) |response| {
        _ = response;
        uart.write_string("boot info success");
    } else {
        uart.write_string("boot info failure");
    }

    while (true) {}
}

export fn kentry() void {
    var kern_out: kstdout.Kstdout = .{};
    var kout = kern_out.writer();

    kmain() catch |err| {
        kout.print("\nError: {s}\n", .{@errorName(err)});
        if (@errorReturnTrace()) |_| {}
    };
}
