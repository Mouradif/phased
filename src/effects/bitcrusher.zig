const Bitcrusher = @This();

const std = @import("std");
const Effect = @import("../effect.zig");

allocator: std.mem.Allocator,
bits: u8,
gain: f32,

pub fn create(allocator: std.mem.Allocator, bits: u8, gain: f32) !*Bitcrusher {
    const self = try allocator.create(Bitcrusher);
    self.* = .{
        .allocator = allocator,
        .bits = bits,
        .gain = gain,
    };
    return self;
}

pub fn process(self: *Bitcrusher, input: f32) f32 {
    const steps = std.math.pow(f32, 2.0, @floatFromInt(self.bits));
    return (@round(input * steps) / steps) * self.gain;
}

pub fn deinit(self: *Bitcrusher) void {
    self.allocator.destroy(self);
}

fn processEffect(self_ptr: *anyopaque, input: f32) f32 {
    const self: *Bitcrusher = @alignCast(@ptrCast(self_ptr));
    return self.process(input);
}

fn deinitEffect(self_ptr: *anyopaque) void {
    const self: *Bitcrusher = @alignCast(@ptrCast(self_ptr));
    self.deinit();
}

pub fn effect(self: *Bitcrusher) Effect {
    return .{
        .ctx = self,
        .vtable = &.{
            .process = processEffect,
            .deinit = deinitEffect,
        },
    };
}

