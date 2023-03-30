const std = @import("std");
const serial = @import("./serial.zig");

pub const Kstdout = struct {
    address: *volatile serial.Uart16550 = @intToPtr(*volatile serial.Uart16550, 0x1000_0000),

    const Writer = std.io.Writer(
        *Kstdout,
        error{Unknown},
        derefWrite,
    );

    fn derefWrite(
        self: *Kstdout,
        string: []const u8,
    ) error{Unknown}!usize {
        for (string) |char| {
            self.address.write(char);
        }

        return string.len;
    }

    pub fn writer(self: *Kstdout) Writer {
        return .{ .context = self };
    }
};
