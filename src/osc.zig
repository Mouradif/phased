const std = @import("std");
const WaveForm = @import("waveform.zig").WaveForm;

const Osc = @This();

const Initializer = struct {
    waveform: WaveForm = .sine,
    octave: f32 = 1,
    amplitude: f32 = 0.1,
    detune: f32 = 0,
};

waveform: WaveForm,
octave: f32,
detune: f32,
amplitude: f32,

pub fn init(params: Initializer) Osc {
    return .{
        .waveform = params.waveform,
        .octave = params.octave,
        .detune = params.detune,
        .amplitude = params.amplitude,
    };
}

pub const List = std.ArrayList(Osc);
