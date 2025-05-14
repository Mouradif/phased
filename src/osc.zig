const std = @import("std");
const WaveForm = @import("waveform.zig").WaveForm;

const Osc = @This();

const Initializer = struct {
    waveform: WaveForm = .sine,
    amplitude: f32 = 0.1,
    detune: f32 = 0,
    phase: f32 = 0,
    attack: f32 = 0,
    decay: f32 = 0,
    release: f32 = 0,
    sustain: f32 = 0,
};

waveform: WaveForm,
detune: f32,
amplitude: f32,
phase: f32,
attack: f32,
decay: f32,
release: f32,
sustain: f32,

pub fn init(params: Initializer) Osc {
    return .{
        .waveform = params.waveform,
        .detune = params.detune,
        .amplitude = params.amplitude,
        .phase = params.phase,
        .attack = params.attack,
        .decay = params.decay,
        .release = params.release,
        .sustain = params.sustain,
    };
}

pub const List = std.ArrayList(Osc);
