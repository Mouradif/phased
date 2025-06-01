const PhasedSynth = @import("generators/phased_synth.zig");
const Tremolo = @import("effects/tremolo.zig");
const Distortion = @import("effects/distortion.zig");
const Gain = @import("effects/gain.zig");
const Bitcrusher = @import("effects/bitcrusher.zig");

const Phased = @import("root.zig");
const std = @import("std");

const base_freq: f32 = 261.63;

const amps = [5]f32{ 1.0, 0.7, 0.35, 0.2, 0.4 };
const detune_ratios = [5]f32{ 1, 1.010296, 1.010296, 1.008687, 1.010811 };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }
    const allocator = gpa.allocator();

    var phased = Phased.init(allocator);
    defer phased.deinit();
    var bc = try Bitcrusher.create(allocator, 2, 0.2);
    defer bc.deinit();
    phased.assignEffect(0, bc.effect());
    var synth1 = try PhasedSynth.create(allocator, .{});
    defer synth1.deinit();
    var synth2 = try PhasedSynth.create(allocator, .{});
    defer synth2.deinit();
    for (0..5) |i| {
        try synth1.addOscillator(Phased.Osc.init(.{
            .waveform = .sine,
            .detune = detune_ratios[i],
            .octave = @floatFromInt(i + 1),
            .amplitude = amps[i],
        }));
        try synth2.addOscillator(Phased.Osc.init(.{
            .waveform = .sine,
            .detune = detune_ratios[i],
            .octave = @floatFromInt(i + 1),
            .amplitude = amps[i],
        }));
    }
    try phased.addTrack();
    try phased.addTrack();
    try phased.assignTrack(0, synth1.generator());
    try phased.assignTrack(1, synth2.generator());
    try phased.tracks.items[1].sends.append(.{ .bus = 0, .level = 1.0 });
    try phased.connect();
    try phased.schedule(0, base_freq, 0, 1);
    try phased.schedule(1, base_freq, 1, 1);
    try phased.play();
}
