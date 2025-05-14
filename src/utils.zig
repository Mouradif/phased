const std = @import("std");

pub fn midiToFreq(midi: u8) f32 {
    return 440.0 * std.math.pow(f32, 2.0, (@as(f32, @floatFromInt(midi)) - 69.0) / 12.0);
}
