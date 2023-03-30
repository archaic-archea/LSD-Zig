pub const AllocError = error{ NotEnoughMemory, Fragmented, OutOfRangeHigh, OutOfRangeLow };

pub const BitmapAllocator = packed struct {
    bytes: [262144]u1 = [262144]u8(0) ** 262144,
    base: [*]u8,
    unused: u64 = 262144,

    pub fn kalloc(self: *BitmapAllocator, bytes: u64) AllocError!*u8 {
        if (bytes > self.unused) {
            return AllocError.NotEnoughMemory;
        }

        var unused_len = 0;
        for (0..262144) |index| {
            if (self.bytes[index] == 0) {
                unused_len += 1;
            } else {
                unused_len = 0;
            }

            if (unused_len == bytes) {
                return self.base[index];
            }
        }

        return AllocError.Fragmented;
    }

    pub fn kdealloc(self: *BitmapAllocator, addr: [*]u8, bytes: u64) AllocError!void {
        var base = self.base;

        var base_idx = @ptrToInt(addr - base);
        var upper_idx = @ptrToInt((addr + bytes) - base);

        if (upper_idx >= 262144) {
            return AllocError.OutOfRangeHigh;
        }
        if (base_idx < 0) {
            return AllocError.OutOfRangeLow;
        }

        for (base_idx..upper_idx) |index| {
            self.bytes[index] = 0;
        }
    }
};
