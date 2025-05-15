const Generator = @This();
const Event = @import("event.zig");

pub const VTable = struct {
    render: *const fn (self: *anyopaque, event: Event, sample_rate: f32) f32,
    releaseTime: *const fn(self: *anyopaque) f32,
    deinit: *const fn (self: *anyopaque) void,
};


ctx: *anyopaque,
vtable: *const VTable,

pub fn render(self: Generator, event: Event, sample_rate: f32) f32 {
    return self.vtable.render(self.ctx, event, sample_rate);
}

pub fn releaseTime(self: Generator) f32 {
    return self.vtable.releaseTime(self.ctx);
}

pub fn deinit(self: Generator) void {
    self.vtable.deinit(self.ctx);
}
