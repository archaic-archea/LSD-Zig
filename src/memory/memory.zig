const std = @import("std");

const kstdout = @import("../kstdout.zig");
const pmm = @import("./pmm.zig");
const limine = @import("../limine.zig");

pub const kern_alloc = @import("./kern_alloc.zig");

var HHDM_OFFSET: std.atomic.Atomic(u64) = std.atomic.Atomic(u64).init(0);

var HEAP: [262144]u8 = [_]u8{0} ** 262144;
pub var HEAP_ALLOC: kern_alloc.BitmapAllocator = .{ .base = &HEAP };

pub export var HHDM: limine.HhdmRequest = .{};
pub export var MEMMAP: limine.MemoryMapRequest = .{};

pub fn init() void {
    var kstd: kstdout.Kstdout = .{};
    var kout = kstd.writer();

    HHDM_OFFSET.store(HHDM.response.?.offset, std.atomic.Ordering.Unordered);
    kout.print("Stored HHDM offset of 0x{x}\n", .{HHDM.response.?.offset}) catch {};
    var mmap = MEMMAP.response.?.*;

    var i = false;
    kout.print("Storing free list entries\n", .{}) catch {};
    for (mmap.entries()) |entry| {
        if (entry.kind == limine.MemoryMapEntryType.usable) {
            var memory = @intToPtr(*void, entry.base + HHDM_OFFSET.load(std.atomic.Ordering.Unordered));

            for (0..entry.length / 4096) |_| {
                if (!i) {
                    pmm.FREE_MEM.init(memory);
                    i = true;
                } else {
                    pmm.FREE_MEM.push(memory);
                }

                memory = @intToPtr(*void, @ptrToInt(memory) + 4096);
            }
        }
    }

    kout.print("Free memory: {}k\n", .{pmm.FREE_MEM.len * 4}) catch {};
}
