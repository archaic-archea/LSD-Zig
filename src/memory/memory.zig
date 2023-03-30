const pmm = @import("./pmm.zig");
const lla = @import("./kern_alloc.zig");

var HEAP: [262144]u8 = [_]u8{0} ** 262144;

pub fn init() void {}
