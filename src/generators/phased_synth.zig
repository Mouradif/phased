const std = @import("std");
const Osc = @import("../osc.zig");
const Generator = @import("../generator.zig");
const Event = @import("../event.zig");

const PhasedSynth = @This();

const Initializer = struct {
    attack: f32 = 0.021,
    decay: f32 = 0.05,
    sustain: f32 = 0.7,
    release: f32 = 0.1,
};

allocator: std.mem.Allocator,
oscillators: std.ArrayList(Osc),
attack: f32 = 0.021,
decay: f32 = 0.05,
sustain: f32 = 0.7,
release: f32 = 0.1,

pub fn create(allocator: std.mem.Allocator, params: Initializer) !*PhasedSynth {
    const self = try allocator.create(PhasedSynth);
    self.* = .{
        .allocator = allocator,
        .oscillators = std.ArrayList(Osc).init(allocator),
        .attack = params.attack,
        .decay = params.decay,
        .sustain = params.sustain,
        .release = params.release,
    };
    return self;
}

pub fn addOscillator(self: *PhasedSynth, oscillator: Osc) !void {
    try self.oscillators.append(oscillator);
}

pub fn a(self: *PhasedSynth, attack: f32) void {
    self.attack = attack;
}

pub fn d(self: *PhasedSynth, decay: f32) void {
    self.decay = decay;
}

pub fn s(self: *PhasedSynth, sustain: f32) void {
    self.sustain = sustain;
}

pub fn r(self: *PhasedSynth, release: f32) void {
    self.release = release;
}

pub fn releaseTime(self: PhasedSynth) f32 {
    return self.release;
}

fn envelope(self: *PhasedSynth, event: Event, sample_rate: f32) f32 {
    const note_on = event.startTime(sample_rate);
    const note_off = event.endTime(sample_rate) - note_on;
    const t = event.time(sample_rate);

    if (t >= note_off + self.release) return 0;

    if (t < note_off) {
        if (t < self.attack) {
            return t / self.attack;
        } else if (t < self.attack + self.decay) {
            const decay_t = t - self.attack;
            const decay_progress = decay_t / self.decay;
            return (1.0 - decay_progress * (1.0 - self.sustain));
        } else {
            return self.sustain;
        }
    } else {
        const release_t = t - note_off;
        const release_progress = release_t / self.release;
        return self.sustain * (1.0 - release_progress);
    }
}

fn normalize(self: PhasedSynth, sample: f32) f32 {
    return sample / @as(f32, @floatFromInt(self.oscillators.items.len));
}

pub fn render(
    self: *PhasedSynth,
    event: Event,
    sample_rate: f32,
) f32 {
    const amp = @max(0, self.envelope(event, sample_rate));
    if (amp <= 0.00001) return 0;

    const event_phase = event.time(sample_rate) - event.startTime(sample_rate);
    var sample: f32 = 0;
    for (self.oscillators.items) |osc| {
        const freq = event.frequency * osc.octave * osc.detune;
        const t = event_phase * freq;
        sample += osc.waveform.timeFunction(t) * osc.amplitude;
    }
    return amp * self.normalize(sample);
}

pub fn deinit(self: *PhasedSynth) void {
    self.oscillators.deinit();
    self.allocator.destroy(self);
}

fn renderGenerator(self_ptr: *anyopaque, event: Event, sample_rate: f32) f32 {
    const self: *PhasedSynth = @alignCast(@ptrCast(self_ptr));
    return self.render(event, sample_rate);
}

fn releaseTimeGenerator(self_ptr: *anyopaque) f32 {
    const self: *PhasedSynth = @alignCast(@ptrCast(self_ptr));
    return self.releaseTime();
}

fn deinitGenerator(self_ptr: *anyopaque) void {
    const self: *PhasedSynth = @alignCast(@ptrCast(self_ptr));
    self.deinit();
}

pub fn generator(self: *PhasedSynth) Generator {
    return .{
        .ctx = self,
        .vtable = &.{
            .render = renderGenerator,
            .releaseTime = releaseTimeGenerator,
            .deinit = deinitGenerator,
        },
    };
}
