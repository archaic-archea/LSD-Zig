const std = @import("std");

const kstdout = @import("../kstdout.zig");
const pmm = @import("./pmm.zig");
const limine = @import("../limine.zig");

const interrupt = @import("../interrupts/interrupt.zig");

const vmm = @import("./vmm.zig");

pub const kern_alloc = @import("./kern_alloc.zig");

pub var HHDM_OFFSET: std.atomic.Atomic(u64) = std.atomic.Atomic(u64).init(0);

var HEAP: [262144]u8 = [_]u8{0} ** 262144;
pub var HEAP_ALLOC: kern_alloc.BitmapAllocator = .{ .base = &HEAP };

pub export var HHDM: limine.HhdmRequest = .{};
pub export var MEMMAP: limine.MemoryMapRequest = .{};

extern const __tdata_start: void;
extern const __tdata_end: void;

pub fn init() !void {
    var kstd: kstdout.Kstdout = .{};
    var kout = kstd.writer();

    store_usable(kout);
    try kout.print("Making tls\n", .{});
    try new_thread_local(kout);
    try kout.print("Making sscratch\n", .{});
    try new_thread_sscratch(kout);
    try kout.print("Thread locals initialized\n", .{});

    try kout.print("Initializing paging\n", .{});
    try vmm.init_paging(kout);
    try kout.print("Initialized paging\n", .{});
    // before: fffffe000002e95a
}

pub fn new_thread_sscratch(kout: anytype) !void {
    _ = kout;
    var mem = pmm.FREE_MEM.lockOrPanic();
    defer mem.unlock();

    var scratch_ptr = @ptrCast(*interrupt.Sscratch, @alignCast(16, try mem.deref().claim()));

    var int_stack = try mem.deref().contiguous_claim(4);

    var tp = asm ("mv %[val], tp"
        : [val] "=r" (-> usize),
    );

    var gp = asm ("mv %[val], gp"
        : [val] "=r" (-> usize),
    );

    scratch_ptr.kern_gp = @intToPtr(*void, gp);
    scratch_ptr.kern_tp = @intToPtr(*void, tp);
    scratch_ptr.kern_stack = int_stack;

    asm volatile ("csrw sscratch, %[scratch_ptr]"
        :
        : [scratch_ptr] "r" (scratch_ptr),
    );
}

pub fn new_thread_local(kout: anytype) !void {
    var mem = pmm.FREE_MEM.lockOrPanic();
    defer mem.unlock();

    var tp_start = @ptrToInt(&__tdata_start);
    var tp_end = @ptrToInt(&__tdata_end);
    var tp_size = tp_end - tp_start;

    kout.print("Thread pointer size {x}\n", .{tp_size}) catch {};

    if (tp_size == 0) {
        return;
    }

    var base_tp = @intToPtr([*]u8, tp_start);

    var new_tp = @ptrCast([*]u8, @alignCast(1, try mem.deref().contiguous_claim(tp_size / 4096)));

    for (0..tp_size) |offset| {
        new_tp[offset] = base_tp[offset];
    }

    asm volatile ("mv tp, t0"
        :
        : [new_tp] "r" (new_tp),
    );
}

fn store_usable(kout: anytype) void {
    HHDM_OFFSET.store(HHDM.response.?.offset, std.atomic.Ordering.Unordered);
    kout.print("Stored HHDM offset of 0x{x}\n", .{HHDM.response.?.offset}) catch {};
    var mmap = MEMMAP.response.?.*;

    var mem = pmm.FREE_MEM.lockOrPanic();
    defer mem.unlock();

    var i = false;
    kout.print("Storing free list entries\n", .{}) catch {};
    for (mmap.entries()) |entry| {
        if (entry.kind == limine.MemoryMapEntryType.usable) {
            var memory = @intToPtr(*void, entry.base + HHDM_OFFSET.load(std.atomic.Ordering.Unordered));

            for (0..entry.length / 4096) |_| {
                if (!i) {
                    mem.deref().init(memory);
                    i = true;
                } else {
                    mem.deref().push(memory);
                }

                memory = @intToPtr(*void, @ptrToInt(memory) + 4096);
            }
        }
    }

    kout.print("Free memory: {}k\n", .{mem.deref().len * 4}) catch {};
}
