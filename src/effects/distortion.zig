const Distortion = @This();

const std = @import("std");
const Effect = @import("../effect.zig");

allocator: std.mem.Allocator,
gain: f32, // How much to amplify before clipping
threshold: f32, // Max absolute amplitude before clipping

pub fn create(allocator: std.mem.Allocator, gain: f32, threshold: f32) !*Distortion {
    const self = try allocator.create(Distortion);
    self.* = .{
        .allocator = allocator,
        .gain = gain,
        .threshold = threshold,
    };
    return self;
}

pub fn process(self: *Distortion, input: f32) f32 {
    const x = input * self.gain;
    return @min(@max(x, -self.threshold), self.threshold);
}

pub fn deinit(self: *Distortion) void {
    self.allocator.destroy(self);
}

fn processEffect(self_ptr: *anyopaque, input: f32) f32 {
    const self: *Distortion = @alignCast(@ptrCast(self_ptr));
    return self.process(input);
}

fn deinitEffect(self_ptr: *anyopaque) void {
    const self: *Distortion = @alignCast(@ptrCast(self_ptr));
    self.deinit();
}

pub fn effect(self: *Distortion) Effect {
    return .{
        .ctx = self,
        .vtable = &.{
            .process = processEffect,
            .deinit = deinitEffect,
        },
    };
}

