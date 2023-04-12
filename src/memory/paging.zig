pub const std = @import("std");

pub const memory = @import("./memory.zig");

pub const PageTable = struct { entries: [512]PageTableEntry };

pub const PageSize = enum(u64) {
    Small = 0x1000,
    Medium = 0x8_0000,
    Large = 0x4000_0000,
};

pub const LowerPageTableFlags = packed struct {
    valid: bool = false,
    read: bool = false,
    write: bool = false,
    execute: bool = false,
    user_accessible: bool = false,
    global: bool = false,
    accessed: bool = false,
    dirty: bool = false,
    rsw: u2 = 0,
};

pub const UpperPageTableFlags = packed struct {
    pbmt: u2 = 0,
    n: bool = false,
};

pub const PageTableFlags = struct {
    upper: UpperPageTableFlags = .{},
    lower: LowerPageTableFlags = .{},
};

pub const Ppn = packed union {
    ppn: packed struct {
        ppn0: u9 = 0,
        ppn1: u9 = 0,
        ppn2: u9 = 0,
        ppn3: u9 = 0,
        ppn4: u8 = 0,

        pub fn index(self: *const Ppn.ppn, idx: u3) u9 {
            switch (idx) {
                0 => return self.ppn0,
                1 => return self.ppn1,
                2 => return self.ppn2,
                3 => return self.ppn3,
                4 => return @intCast(u9, self.ppn4),
                else => @panic("Indexed too far into physical address"),
            }
        }
    },
    full: u44,

    pub fn phys(self: Ppn) PhysicalAddress {
        var phys_addr = PhysicalAddress{ .full = 0 };
        phys_addr.segs.ppns = self;

        return phys_addr;
    }
};

pub const PageTableEntry = packed struct {
    lower_flags: LowerPageTableFlags = .{},
    addr: Ppn = .{ .full = 0 },
    _reserved: u11 = 0,
    upper_flags: UpperPageTableFlags = .{},

    pub fn valid(self: *const PageTableEntry) bool {
        return self.lower_flags.valid;
    }

    pub fn leaf(self: *const PageTableEntry) bool {
        return self.valid() and (self.lower_flags.read or self.lower_flags.write or self.lower_flags.execute);
    }

    pub fn branch(self: *const PageTableEntry) bool {
        return self.valid() and !self.leaf();
    }

    pub fn table(self: *const PageTableEntry) *const PageTable {
        var phys = PhysicalAddress{ .full = 0 };
        phys.segs.ppns = self.addr;

        var virt = @ptrCast(*const PageTable, @alignCast(16, phys.ptr()));

        return virt;
    }
};

pub const VirtualAddress = packed union {
    segs: packed struct {
        offset: u12 = 0,
        vpns: VirtualPageNumbers,
    },
    full: u64,

    pub fn phys(self: *const VirtualAddress) PhysicalAddress {
        return PhysicalAddress{ .full = self.full - memory.HHDM_OFFSET.load(std.atomic.Ordering.Unordered) };
    }

    pub fn from_ptr(ptr: anytype) VirtualAddress {
        return VirtualAddress{ .full = @ptrToInt(ptr) };
    }

    pub fn to_ptr(self: *const VirtualAddress) *void {
        return @intToPtr(*void, self.full);
    }
};

pub const PhysicalAddress = packed union {
    segs: packed struct {
        offset: u12 = 0,
        ppns: Ppn = .{ .full = 0 },
    },
    full: u64,

    pub fn virt(self: *const PhysicalAddress) VirtualAddress {
        return VirtualAddress{ .full = self.full + memory.HHDM_OFFSET.load(std.atomic.Ordering.Unordered) };
    }

    pub fn ptr(self: *const PhysicalAddress) *void {
        return self.virt().to_ptr();
    }
};

pub const VirtualPageNumbers = packed struct {
    vpn0: u9 = 0,
    vpn1: u9 = 0,
    vpn2: u9 = 0,
    vpn3: u9 = 0,
    vpn4: u9 = 0,

    pub fn index(self: *align(8:12:8) const VirtualPageNumbers, idx: u3) u9 {
        switch (idx) {
            0 => return self.vpn0,
            1 => return self.vpn1,
            2 => return self.vpn2,
            3 => return self.vpn3,
            4 => return self.vpn4,
            else => @panic("Indexed too far into virtual address"),
        }
    }
};

pub const Satp = packed union {
    segs: packed struct {
        ppn: Ppn,
        asid: u16,
        mode: Mode,
    },
    full: u64,
};

pub const Mode = enum(u4) {
    Bare = 0,
    Sv39 = 8,
    Sv48 = 9,
    Sv57 = 10,
    Sv64 = 11,
};
