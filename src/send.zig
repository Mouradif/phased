const std = @import("std");

const Send = @This();

bus: usize,
level: f32 = 1,

pub fn init(bus: usize) Send {
    return .{
        .bus = bus
    };
}

pub const List = std.ArrayList(Send);
