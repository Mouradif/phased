const std = @import("std");

const Self = @This();

start_frame: u64,
end_frame: u64,
frequency: f32,

pub const List = std.ArrayList(Self);
