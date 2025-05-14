const std = @import("std");
pub const Osc = @import("osc.zig");
const Backends = @import("backends/backends.zig");

const Phased = @This();

allocator: std.mem.Allocator,
backend: Backends.Backend,
backend_handle: Backends.BackendHandle,

sample_rate: f32 = 44100,
frequency: f32 = 440,
oscillators: Osc.List,
bpm: f32 = 120.0,

pub fn init(allocator: std.mem.Allocator) Phased {
    return .{
        .allocator = allocator,
        .oscillators = Osc.List.init(allocator),
        .backend = Backends.Backend.default(),
        .backend_handle = undefined,
    };
}

pub fn setBpm(self: *Phased, bpm: f32) void {
    self.bpm = bpm;
}

pub fn setSampleRate(self: *Phased, sample_rate: f32) void {
    self.sample_rate = sample_rate;
}

pub fn addOscillator(self: *Phased, oscillator: Osc) !void {
    try self.oscillators.append(oscillator);
}

pub fn removeOscillator(self: *Phased, index: usize) void {
    if (index < self.oscillators.items.len) {
        _ = self.oscillators.swapRemove(index);
    }
}

pub fn osc(self: *Phased, index: usize) *Osc {
    return &self.oscillators[index];
}

pub fn connect(self: *Phased) !void {
    self.backend_handle = try Backends.connect(self);
}

pub fn computeSample(self: *Phased, frequency: f32) f32 {
    var sample: f32 = 0;

    for (self.oscillators.items) |*oscillator| {
        const t = oscillator.phase * frequency;
        sample += oscillator.waveform.timeFunction(t) * oscillator.amplitude;
    }
    sample /= @floatFromInt(self.oscillators.items.len);
    return sample;
}

pub fn incrementPhases(self: *Phased) void {
    for (self.oscillators.items) |*oscillator| {
        oscillator.phase += 1 / self.sample_rate;
    }
}

pub fn play(self: *Phased, freq: f32, duration_sec: f32) !void {
    self.frequency = freq;

    self.backend_handle.start(self);
    const duration_ns = @as(u64, @intFromFloat(duration_sec * 1_000_000_000.0));
    std.time.sleep(duration_ns);
    self.backend_handle.stop(self);
}
