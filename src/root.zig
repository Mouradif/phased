const std = @import("std");
const Backends = @import("backends/backends.zig");
const Event = @import("event.zig");
const PlaybackMode = @import("playback_mode.zig").PlaybackMode;
pub const Osc = @import("osc.zig");
pub const Track = @import("track.zig");
pub const Generator = @import("generator.zig");
pub const Effect = @import("effect.zig");
pub const Send = @import("send.zig");

const MAX_SIMULTANEOUS_EVENTS = 32;
const MAX_FX_BUSES = 8;

const Phased = @This();

allocator: std.mem.Allocator,
backend: Backends.Backend,
backend_handle: ?Backends.BackendHandle,
playback_mode: PlaybackMode = .once,
current_frame: u64 = 0,
scheduler: Event.List,
sample_rate: f32 = 44100,
tracks: Track.List,
current_events: [MAX_SIMULTANEOUS_EVENTS]?*Event = undefined,
current_events_index: usize = 0,
fx_buses: [MAX_FX_BUSES]?Effect = [_]?Effect{null} ** MAX_FX_BUSES,
fx_inputs: [MAX_FX_BUSES]f32 = [_]f32{0} ** MAX_FX_BUSES,

pub fn init(allocator: std.mem.Allocator) Phased {
    return .{
        .allocator = allocator,
        .scheduler = Event.List.init(allocator),
        .tracks = Track.List.init(allocator),
        .backend = Backends.Backend.default(),
        .backend_handle = null,
    };
}

pub fn deinit(self: *Phased) void {
    if (self.backend_handle) |handle| {
        handle.stop(self);
        handle.deinit(handle.ctx);
    }
    for (self.tracks.items) |*track| {
        track.deinit();
    }
    self.tracks.deinit();
    self.scheduler.deinit();
}

pub fn time(self: Phased) f32 {
    return @as(f32, @floatFromInt(self.current_frame)) / self.sample_rate;
}

pub fn setSampleRate(self: *Phased, sample_rate: f32) void {
    self.sample_rate = sample_rate;
}

pub fn addTrack(self: *Phased) !void {
    try self.tracks.append(Track.init(self.allocator));
}

pub fn processEvent(self: *Phased, event: *Event) void {
    event.start();
    if (self.current_events_index == MAX_SIMULTANEOUS_EVENTS) return;
    self.current_events[self.current_events_index] = event;
    self.current_events_index += 1;
}

pub fn isProcessingEvent(self: *Phased, event: *Event) bool {
    for (0..self.current_events_index) |i| {
        if (self.current_events[i] == event) {
            return true;
        }
    }
    return false;
}

fn stopProcessingEvent(self: *Phased, index: usize) void {
    if (index >= self.current_events_index) return;
    self.current_events[index] = null;
}

pub fn squashProcessedEvents(self: *Phased) void {
    var holes: [MAX_SIMULTANEOUS_EVENTS]usize = undefined;
    var hole_index: usize = 0;
    var next_hole_index: usize = 0;
    var i: usize = 0;
    while (i < self.current_events_index) : (i += 1) {
        if (self.current_events[i] == null) {
            holes[hole_index] = i;
            hole_index += 1;
            continue;
        }
        if (next_hole_index < hole_index) {
            self.current_events[holes[next_hole_index]] = self.current_events[i];
            self.current_events[i] = null;
            holes[hole_index] = i;
            hole_index += 1;
            next_hole_index += 1;
        }
    }
    self.current_events_index -= hole_index - next_hole_index;
}

fn shouldRunEvent(self: *Phased, event: Event) bool {
    return event.start_frame <= self.current_frame and event.end_frame > self.current_frame;
}

pub fn assignTrack(self: *Phased, track: usize, generator: Generator) !void {
    if (track >= self.tracks.items.len) {
        return error.TrackNotFound;
    }
    self.tracks.items[track].setGenerator(generator);
}

pub fn assignEffect(self: *Phased, bus: usize, fx: Effect) void {
    if (bus >= MAX_FX_BUSES) return;
    self.fx_buses[bus] = fx;
}

pub fn setTrackVolume(self: *Phased, track: usize, volume: f32) void {
    if (track >= self.tracks.items.len) return;
    self.tracks.items[track].volume = volume;
}

pub fn deleteTrack(self: *Phased, index: usize) void {
    if (index < self.tracks.items.len) {
        var t = self.tracks.swapRemove(index);
        t.deinit();
    }
}

pub fn connect(self: *Phased) !void {
    const handle = try Backends.connect(self);
    self.backend_handle = handle;
    handle.start(self);
}

pub fn computeSample(self: *Phased) f32 {
    @memset(&self.fx_inputs, 0);
    var sample: f32 = 0;

    for (self.scheduler.items) |*event| {
        if (self.shouldRunEvent(event.*) and !self.isProcessingEvent(event)) {
            self.processEvent(event);
        }
    }

    for (0..self.current_events_index) |i| {
        if (self.current_events[i] == null) {
            continue;
        }
        const event = self.current_events[i].?;
        const track = self.tracks.items[event.track_index];
        if (track.generator == null) {
            continue;
        }
        const gen = track.generator.?;
        const dry = gen.render(event.*, self.sample_rate) * track.volume;
        if (!self.shouldRunEvent(event.*) and dry == 0) {
            self.stopProcessingEvent(i);
        }
        event.advance();
        sample += dry;
        for (track.sends.items) |send| {
            self.fx_inputs[send.bus] += dry * send.level;
        }
    }
    self.squashProcessedEvents();

    for (0..MAX_FX_BUSES) |bus_index| {
        if (self.fx_buses[bus_index] == null) continue;
        const fx = self.fx_buses[bus_index].?;
        const wet = fx.process(self.fx_inputs[bus_index]);
        sample += wet;
    }
    return sample;
}

pub fn getMaxFrame(self: *Phased) u64 {
    var max_event_end: u64 = 0;
    for (self.scheduler.items) |event| {
        max_event_end = @max(max_event_end, event.end_frame);
    }
    return max_event_end;
}

fn getLongestRelease(self: *Phased) f32 {
    var max_release: f32 = 0;
    for (self.tracks.items) |track| {
        if (track.generator) |gen| {
            max_release = @max(max_release, gen.releaseTime());
        }
    }
    return max_release;
}

pub fn schedule(self: *Phased, track_index: usize, freq: f32, starts_in: f32, duration_sec: f32) !void {
    if (track_index >= self.tracks.items.len) return;
    const start_frame = self.current_frame + @as(u64, @intFromFloat(starts_in * self.sample_rate));
    const duration_frames = @as(u64, @intFromFloat(duration_sec * self.sample_rate));
    const event = Event{
        .start_frame = start_frame,
        .end_frame = start_frame + duration_frames,
        .frequency = freq,
        .track_index = track_index,
    };
    try self.scheduler.append(event);
}

pub fn loop(self: *Phased, is_loop: bool) void {
    self.playback_mode = if (is_loop) .loop else .once;
}

pub fn waitAndStop(self: *Phased) void {
    if (self.backend_handle == null) return;
    const max_event_end = self.getMaxFrame();
    if (self.current_frame >= max_event_end) return;
    const wait_frames = max_event_end - self.current_frame;
    const wait_sec = @as(f32, @floatFromInt(wait_frames)) / self.sample_rate + self.getLongestRelease();
    const wait_ns: u64 = @intFromFloat(wait_sec * 1_000_000_000);
    if (wait_ns < 1_000_000) return;
    std.time.sleep(wait_ns);
}

pub fn play(self: *Phased) !void {
    if (self.backend_handle == null) {
        try self.connect();
    }
    if (self.playback_mode == .loop) {
        while (true) std.time.sleep(1_000_000_000);
    } else {
        self.waitAndStop();
    }
}
