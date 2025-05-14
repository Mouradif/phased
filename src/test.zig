const Phased = @import("root.zig");
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var phased = Phased.init(allocator);
    try phased.addOscillator(Phased.Osc.init(.{}));
    try phased.connect();
    try phased.play(440, 1);
}
