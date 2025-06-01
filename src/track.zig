const std = @import("std");
const Generator = @import("generator.zig");
const Send = @import("send.zig");

const Track = @This();

allocator: std.mem.Allocator,
generator: ?Generator = null,
volume: f32 = 1.0,
sends: Send.List,

pub fn init(allocator: std.mem.Allocator) Track {
    return .{
        .allocator = allocator,
        .sends = Send.List.init(allocator),
    };
}

pub fn deinit(self: *Track) void {
    self.sends.deinit();
}

pub fn setGenerator(self: *Track, generator: Generator) void {
    self.generator = generator;
}

pub const List = std.ArrayList(Track);
