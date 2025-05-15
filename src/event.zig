const std = @import("std");

const Event = @This();

start_frame: u64,
end_frame: u64,
current_frame: u64 = 0,
frequency: f32,
track_index: usize,

pub fn startTime(self: Event, sample_rate: f32) f32 {
    return @as(f32, @floatFromInt(self.start_frame)) / sample_rate;
}

pub fn endTime(self: Event, sample_rate: f32) f32 {
    return @as(f32, @floatFromInt(self.end_frame)) / sample_rate;
}

pub fn time(self: Event, sample_rate: f32) f32 {
    return @as(f32, @floatFromInt(self.current_frame)) / sample_rate;
}

pub fn start(self: *Event) void {
    self.current_frame = 0;
}

pub fn advance(self: *Event) void {
    self.current_frame += 1;
}

pub const List = std.ArrayList(Event);
