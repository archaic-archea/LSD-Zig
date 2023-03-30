pub const Uart16550 = extern struct {
    /// data line, used for input and output
    data: u8,
    int_enable: u8,
    int_id_fifo_ctrl: u8,
    line_ctrl: u8,
    modem_ctrl: u8,
    line_status: u8,
    modem_status: u8,
    scratch: u8,

    pub fn write(self: *volatile Uart16550, byte: u8) void {
        self.data = byte;
    }

    pub fn write_string(self: *volatile Uart16550, str: []const u8) void {
        for (str) |byte| {
            self.write(byte);
        }
    }
};
