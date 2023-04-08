const std = @import("std");
const kstdout = @import("../kstdout.zig");
const KoutErr = kstdout.KoutErr;
const WriteFailure = KoutErr.WriteFailure;

pub const AllocError = error{ NotEnoughMemory, Fragmented, OutOfRangeHigh, OutOfRangeLow, WriteFailure };

pub const BitmapAllocator = struct {
    bytes: std.bit_set.IntegerBitSet(16384) = std.bit_set.IntegerBitSet(16384).initEmpty(),
    base: [*]u8,
    unused: u64 = 16384,

    pub fn kalloc(self: *BitmapAllocator, bytes: u64) AllocError!*u8 {
        var kern_out: kstdout.Kstdout = .{};
        var kout = kern_out.writer();
        _ = kout;

        if (bytes > self.unused) {
            return AllocError.NotEnoughMemory;
        }

        var unused_len: u16 = 0;
        for (0..16384) |index| {
            if (!self.bytes.isSet(index)) {
                unused_len += 1;
            } else {
                unused_len = 0;
            }

            if (unused_len >= bytes) {
                var set_idx_up = index + 1;
                var set_idx_low = set_idx_up - bytes;

                for (set_idx_low..set_idx_up) |set_idx| {
                    self.bytes.set(set_idx);
                }

                var base = self.base + set_idx_low;
                return @ptrCast(*u8, base);
            }
        }

        return AllocError.Fragmented;
    }

    pub fn kdealloc(self: *BitmapAllocator, addr: *u8, bytes: u64) AllocError!void {
        var base: u64 = @ptrToInt(self.base);
        var intaddr: u64 = @ptrToInt(addr);

        var base_idx: u64 = intaddr - base;
        var upper_idx: u64 = intaddr + bytes - base;

        if (upper_idx >= 16384) {
            return AllocError.OutOfRangeHigh;
        }
        if (base_idx < 0) {
            return AllocError.OutOfRangeLow;
        }

        for (base_idx..upper_idx) |index| {
            self.bytes.unset(index);
        }
    }
};
