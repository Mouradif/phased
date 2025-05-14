const Phased = @import("root.zig");
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }
    const allocator = gpa.allocator();

    var phased = Phased.init(allocator);
    defer phased.deinit();
    try phased.addOscillator(Phased.Osc.init(.{}));
    try phased.connect();
    try phased.schedule(440, 0, 1);
    try phased.schedule(220, 1, 1);
    try phased.schedule(360, 2, 1);
    phased.waitAndStop();
}
