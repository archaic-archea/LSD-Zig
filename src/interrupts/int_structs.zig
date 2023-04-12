pub const Scause = packed struct {
    code: Code,
    interrupt: bool,
};

pub const Code = packed union {
    exception: ExceptionCode,
    interrupt: InterruptCode,
};

pub const ExceptionCode = enum(u63) {
    InstructionAddrMisalign = 0,
    InstructionAccessFault = 1,
    IllegalInstruction = 2,
    BreakPoint = 3,
    LoadAddrMisalign = 4,
    LoadAccessFault = 5,
    StoreAMOAddrMisalign = 6,
    StoreAMOAccessFault = 7,
    EnvCallUser = 8,
    EnvCallSuper = 9,
    InstructionPageFault = 12,
    LoadPageFault = 13,
    StoreAMOPageFault = 15,
};

pub const InterruptCode = enum(u63) {
    SuperSoftwareInterrupt = 1,
    SuperTimerInterrupt = 5,
    SuperExternInterrupt = 9,
};
