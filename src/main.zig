const std = @import("std");
const serial = @import("./serial.zig");
const limine = @import("./limine.zig");
const kstdout = @import("./kstdout.zig");

pub export var boot: limine.BootloaderInfoRequest = .{};

fn kmain() !u8 {
    var uart: *volatile serial.Uart16550 = @intToPtr(*volatile serial.Uart16550, 0x1000_0000);
    var kern_stdout: kstdout.Kstdout = .{};
    var stdout = kern_stdout.writer();

    try stdout.print("foo {s}", .{"bar"});

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
    var uart: *volatile serial.Uart16550 = @intToPtr(*volatile serial.Uart16550, 0x1000_0000);
    var result = kmain() catch 0;

    if (result == 0) {
        uart.write_string("KERNEL RETURNED WITH CODE 0");
    }
}
