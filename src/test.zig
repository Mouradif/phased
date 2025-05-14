const Phased = @import("root.zig");
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }
    const allocator = gpa.allocator();

    var osc1 = Phased.init(allocator);
    defer osc1.deinit();
    try osc1.addOscillator(Phased.Osc.init(.{}));
    try osc1.addOscillator(Phased.Osc.init(.{ .waveform = .saw }));
    try osc1.connect();
    try osc1.schedule(660, 0, 1);
    try osc1.schedule(330, 1, 1);
    try osc1.schedule(784.875, 2, 1);
    try osc1.schedule(440, 0, 1);
    try osc1.schedule(220, 1, 1);
    try osc1.schedule(523.25, 2, 1);
    osc1.play();
}
