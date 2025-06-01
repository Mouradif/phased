const Effect = @This();

pub const VTable = struct {
    process: *const fn (self: *anyopaque, input: f32) f32,
    deinit: *const fn (self: *anyopaque) void,
};

ctx: *anyopaque,
vtable: *const VTable,

pub fn process(self: Effect, input: f32) f32 {
    return self.vtable.process(self.ctx, input);
}

pub fn deinit(self: Effect) void {
    self.vtable.deinit(self.ctx);
}
