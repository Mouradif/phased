const std = @import("std");

pub const WaveForm = enum {
    sine,
    saw,
    square,
    triangle,

    pub fn timeFunction(self: WaveForm, t: f32) f32 {
        const two_pi = 2.0 * std.math.pi;
        const phase = two_pi * t;

        return switch (self) {
            .sine => std.math.sin(phase),
            .saw => 2.0 * (t - @floor(t + 0.5)),
            .square => if (@mod(t, 1.0) < 0.5) 1.0 else -1.0,
            .triangle => 2.0 * @abs(2.0 * (t - @floor(t + 0.5))) - 1.0,
        };
    }
};
