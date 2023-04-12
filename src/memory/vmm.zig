pub const std = @import("std");

const paging = @import("./paging.zig");
const pmm = @import("./pmm.zig");
const memory = @import("./memory.zig");
const kstdout = @import("../kstdout.zig");

pub var ROOT_TABLE: ?*paging.PageTable = null;

pub fn init_paging(kout: anytype) !void {
    var mem = pmm.FREE_MEM.lockOrPanic();
    ROOT_TABLE = @ptrCast(*paging.PageTable, @alignCast(16, try mem.deref().claim()));
    mem.unlock();

    //TODO fill page tables
    try kout.print("mapping 0x0-0x8000_0000 to 0x0-0x8000_0000\n", .{});
    //Map IO
    for (@as(u64, 0)..@as(u64, 0x80000000) / @enumToInt(paging.PageSize.Large)) |addr_page| {
        var phys_addr_num = addr_page * @enumToInt(paging.PageSize.Large);
        var phys: paging.PhysicalAddress = .{ .full = phys_addr_num };
        var virt: paging.VirtualAddress = .{ .full = phys_addr_num };

        var flags: paging.PageTableFlags = .{
            .lower = .{
                .valid = true,
                .read = true,
                .write = true,
                .execute = false,
                .accessed = true,
                .dirty = true,
            },
        };

        try page(ROOT_TABLE.?, virt, phys, 1, 2, flags);
    }

    try kout.print("Loading satp with root table\n", .{});
    try prnt_table(ROOT_TABLE.?.*, kout);

    try load_satp(paging.VirtualAddress.from_ptr(ROOT_TABLE).phys(), kout);
}

fn prnt_table(table: paging.PageTable, kout: anytype) !void {
    for (table.entries) |entry| {
        if (entry.valid()) {
            try kout.print("\nentry full: 0x{x}\n", .{entry.addr.phys().full});
            if (entry.branch()) {
                try kout.print("Entry is branch\n", .{});
                try prnt_table(entry.table().*, kout);
            } else if (entry.leaf()) {
                try kout.print("Entry is leaf\n", .{});
            } else {}
        }
    }
}

pub fn load_satp(phys: paging.PhysicalAddress, kout: anytype) !void {
    var satp: paging.Satp = .{
        .segs = .{
            .ppn = phys.segs.ppns,
            .asid = 0,
            .mode = paging.Mode.Sv48,
        },
    };

    var full_satp = satp.full;

    try kout.print("\nLoading satp with 0x{x}\n", .{full_satp});

    asm volatile ("csrw satp, %[full_satp]"
        :
        : [full_satp] "r" (full_satp),
    );
}

/// Fails in some unknown way
pub fn page(table: *paging.PageTable, vaddr: paging.VirtualAddress, paddr: paging.PhysicalAddress, depth: u3, depth_offset: u3, flags: paging.PageTableFlags) !void {
    var kern_out: kstdout.Kstdout = .{};
    var kout = kern_out.writer();

    try kout.print("Paging idx {}\n", .{depth + depth_offset});

    if (depth != 0) {
        var entry = &table.entries[vaddr.segs.vpns.index(depth + depth_offset)];
        var next_table: paging.PhysicalAddress = .{ .full = 0 };

        if (entry.branch()) {
            // Read current table since we found a branch
            next_table = entry.addr.phys();
        } else {
            var mem = pmm.FREE_MEM.lockOrPanic();
            defer mem.unlock();

            var new_table_ptr = try mem.deref().claim();

            var zeroing_addr = @ptrCast([*]u64, @alignCast(16, new_table_ptr));
            for (0..512) |idx| {
                zeroing_addr[idx] = 0;
            }

            // Allocates a new table since the entry we found was not a branch
            var new_table = paging.VirtualAddress.from_ptr(new_table_ptr);

            next_table = new_table.phys();

            entry.addr = next_table.segs.ppns;
            entry.lower_flags = paging.LowerPageTableFlags{
                .valid = true,
            };

            try kout.print("Set new entry at index {}\n", .{vaddr.segs.vpns.index(depth + depth_offset)});
        }

        try page(@ptrCast(*paging.PageTable, @alignCast(16, next_table.ptr())), vaddr, paddr, depth - 1, depth_offset, flags);
    } else {
        try kout.print("Adding entry\n", .{});
        try kout.print("Storing 0x{x} at 0x{x}\n", .{ paddr.segs.ppns.phys().full, vaddr.full });
        var entry = &table.entries[vaddr.segs.vpns.index(depth + depth_offset)];

        entry.* = .{};

        entry.addr = paddr.segs.ppns;
        entry.lower_flags = flags.lower;
        entry.upper_flags = flags.upper;
    }
}
