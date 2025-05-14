const std = @import("std");
const builtin = @import("builtin");
const Phased = @import("../root.zig");
const coreaudio = @import("coreaudio.zig");

pub const Backend = enum {
    coreaudio,
    // alsa,
    // wasapi,
    // pulseaudio,
    // jack,
    // dummy,

    pub fn default() Backend {
        return switch (builtin.os.tag) {
            .macos => .coreaudio,
            // .linux => .alsa,
            // .windows => .wasapi,
            else => @compileError("No default backend available for this platform."),
        };
    }

    pub fn name(self: Backend) []const u8 {
        return switch (self) {
            .coreaudio => "coreaudio",
            // .alsa => "alsa",
            // .wasapi => "wasapi",
            // ...
        };
    }

    pub fn handle(self: Backend) *const fn (*Phased) anyerror!BackendHandle {
        return switch (self) {
            .coreaudio => coreaudio.connect,
        };
    }
};

pub const BackendHandle = struct {
    start: *const fn (*Phased) void,
    stop: *const fn (*Phased) void,
    ctx: *anyopaque,
    deinit: *const fn (*anyopaque) void,
};

pub fn connect(phased: *Phased) !BackendHandle {
    const handle = phased.backend.handle();
    return handle(phased);
}
