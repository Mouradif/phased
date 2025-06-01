const std = @import("std");
const Effect = @import("../effect.zig");

const Tremolo = @This();

allocator: std.mem.Allocator,
rate: f32,
depth: f32,
sample_rate: f32,
frame: u64 = 0,

pub fn create(allocator: std.mem.Allocator, rate: f32, depth: f32, sample_rate: f32) !*Tremolo {
    const self = try allocator.create(Tremolo);
    self.* = .{
        .allocator = allocator,
        .rate = rate,
        .depth = depth,
        .sample_rate = sample_rate,
        .frame = 0,
    };
    return self;
}

pub fn process(self: *Tremolo, input: f32) f32 {
    const phase = (@as(f32, @floatFromInt(self.frame)) / self.sample_rate) * self.rate * std.math.tau;
    const lfo = (1.0 - self.depth) + self.depth * std.math.sin(phase);
    self.frame += 1;
    return input * lfo;
}

pub fn deinit(self: *Tremolo) void {
    self.allocator.destroy(self);
}

fn processEffect(self_ptr: *anyopaque, input: f32) f32 {
    const self: *Tremolo = @alignCast(@ptrCast(self_ptr));
    return self.process(input);
}

fn deinitEffect(self_ptr: *anyopaque) void {
    const self: *Tremolo = @alignCast(@ptrCast(self_ptr));
    self.deinit();
}

pub fn effect(self: *Tremolo) Effect {
    return .{
        .ctx = self,
        .vtable = &.{
            .process = processEffect,
            .deinit = deinitEffect,
        },
    };
}

