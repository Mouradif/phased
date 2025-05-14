const std = @import("std");
pub const Osc = @import("osc.zig");
const Backends = @import("backends/backends.zig");
const Event = @import("event.zig");

const Phased = @This();

allocator: std.mem.Allocator,
backend: Backends.Backend,
backend_handle: ?Backends.BackendHandle,

current_frame: u64 = 0,
scheduler: Event.List,
sample_rate: f32 = 44100,
oscillators: Osc.List,
bpm: f32 = 120.0,

pub fn init(allocator: std.mem.Allocator) Phased {
    return .{
        .allocator = allocator,
        .scheduler = Event.List.init(allocator),
        .oscillators = Osc.List.init(allocator),
        .backend = Backends.Backend.default(),
        .backend_handle = null,
    };
}

pub fn deinit(self: *Phased) void {
    if (self.backend_handle) |handle| {
        handle.stop(self);
        handle.deinit(handle.ctx);
    }
    self.scheduler.deinit();
    self.oscillators.deinit();
}

pub fn setBpm(self: *Phased, bpm: f32) void {
    self.bpm = bpm;
}

pub fn setSampleRate(self: *Phased, sample_rate: f32) void {
    self.sample_rate = sample_rate;
}

pub fn addOscillator(self: *Phased, oscillator: Osc) !void {
    try self.oscillators.append(oscillator);
}

pub fn removeOscillator(self: *Phased, index: usize) void {
    if (index < self.oscillators.items.len) {
        _ = self.oscillators.swapRemove(index);
    }
}

pub fn osc(self: *Phased, index: usize) *Osc {
    return &self.oscillators[index];
}

pub fn connect(self: *Phased) !void {
    const handle = try Backends.connect(self);
    self.backend_handle = handle;
    handle.start(self);
}

pub fn computeSample(self: *Phased) f32 {
    var sample: f32 = 0;

    for (self.scheduler.items) |event| {
        if (event.start_frame > self.current_frame or event.end_frame < self.current_frame) continue;
        var osc_sample: f32 = 0;
        for (self.oscillators.items) |*oscillator| {
            const t = oscillator.phase * event.frequency;
            osc_sample += oscillator.waveform.timeFunction(t) * oscillator.amplitude;
        }
        sample += osc_sample / @as(f32, @floatFromInt(self.oscillators.items.len));
    }

    return sample;
}

pub fn incrementPhases(self: *Phased) void {
    for (self.oscillators.items) |*oscillator| {
        oscillator.phase += 1 / self.sample_rate;
    }
}

pub fn schedule(self: *Phased, freq: f32, starts_in: f32, duration_sec: f32) !void {
    const start_frame = self.current_frame + @as(u64, @intFromFloat(starts_in * self.sample_rate));
    const duration_frames = @as(u64, @intFromFloat(duration_sec * self.sample_rate));
    const event = Event{
        .start_frame = start_frame,
        .end_frame = start_frame + duration_frames,
        .frequency = freq,
    };
    try self.scheduler.append(event);
}

pub fn waitAndStop(self: *Phased) void {
    var max_event_end: u64 = 0;
    for (self.scheduler.items) |event| {
        max_event_end = @max(max_event_end, event.end_frame);
    }
    if (self.current_frame >= max_event_end) return;
    const wait_frames = max_event_end - self.current_frame;
    const wait_sec = @as(f32, @floatFromInt(wait_frames)) / self.sample_rate;
    const wait_ns: u64 = @intFromFloat(wait_sec * 1_000_000_000);
    std.time.sleep(wait_ns);
}
