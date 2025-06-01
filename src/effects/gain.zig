const Gain = @This();

const std = @import("std");
const Effect = @import("../effect.zig");

allocator: std.mem.Allocator,
factor: f32,

pub fn create(allocator: std.mem.Allocator, factor: f32) !*Gain {
    const self = try allocator.create(Gain);
    self.* = .{ .allocator = allocator, .factor = factor };
    return self;
}

pub fn process(self: *Gain, input: f32) f32 {
    return input * self.factor;
}

pub fn deinit(self: *Gain) void {
    self.allocator.destroy(self);
}

fn processEffect(self_ptr: *anyopaque, input: f32) f32 {
    const self: *Gain = @alignCast(@ptrCast(self_ptr));
    return self.process(input);
}

fn deinitEffect(self_ptr: *anyopaque) void {
    const self: *Gain = @alignCast(@ptrCast(self_ptr));
    self.deinit();
}

pub fn effect(self: *Gain) Effect {
    return .{
        .ctx = self,
        .vtable = &.{
            .process = processEffect,
            .deinit = deinitEffect,
        },
    };
}

