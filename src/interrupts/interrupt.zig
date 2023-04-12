// Most of this is based off of vanadinite interrupt entry code, which is licensed under MPL-2.0, see https://github.com/repnop/vanadinite for info on the project

const arch = @import("../arch/arch.zig");
const kstdout = @import("../kstdout.zig");
const int_structs = @import("./int_structs.zig");

pub const Sscratch = packed struct {
    kern_stack: *void,
    kern_tp: *void,
    kern_gp: *void,
    scratch: *void,
};

const TrapFrame = packed struct {
    sepc: usize, //size 8
    registers: arch.GeneralRegisters, //size 248
};

pub export fn handler(regs: *TrapFrame, scause: int_structs.Scause, stval: usize) void {
    var kstd: kstdout.Kstdout = .{};
    var kout = kstd.writer();

    kout.print("Trapping\n", .{}) catch {};

    switch (scause.interrupt) {
        true => {
            kout.print("Cause {}\n", .{scause.code.interrupt}) catch {};
        },
        false => {
            kout.print("Cause {}\n", .{scause.code.exception}) catch {};
        },
    }

    _ = stval;
    _ = regs;

    while (true) {}
}
