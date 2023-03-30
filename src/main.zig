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
    switch (@typeInfo(@typeInfo(@TypeOf(kmain)).Fn.return_type.?)) {
        .NoReturn => {
            kmain();
        },
        .Void => {
            kmain();
        },
        .ErrorUnion => {
            const result = kmain() catch |err| {
                var kern_out: kstdout.Kstdout = .{};
                var kout = kern_out.writer();

                kout.print("\nError: {s}\n", .{@errorName(err)});
                if (@errorReturnTrace()) |_| {}
            };
            switch (@typeInfo(@TypeOf(result))) {
                .Void => {},
                else => @compileError("Bad return type"),
            }
        },
        else => @compileError("Bad return type"),
    }
}
