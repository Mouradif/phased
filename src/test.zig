const PhasedSynth = @import("generators/phased_synth.zig");
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
    var synth = try PhasedSynth.create(allocator);
    for (0..5) |i| {
        try synth.addOscillator(Phased.Osc.init(.{
            .waveform = .sine,
            .detune = detune_ratios[i],
            .octave = @floatFromInt(i),
            .amplitude = amps[i],
        }));
    }
    synth.adsr(0.021, 0.05, 0.7, 0.5);
    var wave = try PhasedSynth.create(allocator);
    for (0..5) |i| {
        try wave.addOscillator(Phased.Osc.init(.{
            .waveform = .sine,
            .detune = detune_ratios[i],
            .octave = @floatFromInt(i),
            .amplitude = amps[i],
        }));
    }
    wave.adsr(0.5, 0, 0, 0);
    try phased.addTrack();
    try phased.addTrack();
    try phased.assignTrack(0, synth.generator());
    try phased.assignTrack(1, wave.generator());
    try phased.connect();
    try phased.schedule(1, base_freq, 0, 0.3);
    try phased.schedule(0, base_freq * 1.5, 0.3, 0.3);
    try phased.schedule(0, base_freq * 1.5, 0.6, 0.3);
    phased.loop(true);
    try phased.play();
}
