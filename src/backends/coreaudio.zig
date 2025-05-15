const std = @import("std");
const Phased = @import("../root.zig");
const BackendHandle = @import("backends.zig").BackendHandle;

const c = @cImport({
    @cInclude("CoreAudio/CoreAudio.h");
    @cInclude("AudioToolbox/AudioToolbox.h");
    @cInclude("AudioUnit/AudioUnit.h");
});

const CoreAudioCtx = struct {
    allocator: std.mem.Allocator,
    audio_unit: c.AudioUnit,
    phased: *Phased,

    pub fn init(allocator: std.mem.Allocator, phased: *Phased) !*CoreAudioCtx {
        const ctx = try allocator.create(CoreAudioCtx);
        ctx.phased = phased;
        ctx.allocator = allocator;
        return ctx;
    }

    pub fn deinit(self_ptr: *anyopaque) void {
        const self: *CoreAudioCtx = @alignCast(@ptrCast(self_ptr));
        self.allocator.destroy(self);
    }
};

pub fn connect(phased: *Phased) !BackendHandle {
    const ctx = try CoreAudioCtx.init(phased.allocator, phased);
    errdefer CoreAudioCtx.deinit(ctx);

    var desc = c.AudioComponentDescription{
        .componentType = c.kAudioUnitType_Output,
        .componentSubType = c.kAudioUnitSubType_DefaultOutput,
        .componentManufacturer = c.kAudioUnitManufacturer_Apple,
        .componentFlags = 0,
        .componentFlagsMask = 0,
    };

    const comp = c.AudioComponentFindNext(null, &desc);
    if (comp == null) return error.ComponentNotFound;
    if (c.AudioComponentInstanceNew(comp, &ctx.audio_unit) != 0) return error.FailedToCreateInstance;

    var input = c.AURenderCallbackStruct{
        .inputProc = renderCallback,
        .inputProcRefCon = phased,
    };
    _ = c.AudioUnitSetProperty(
        ctx.audio_unit,
        c.kAudioUnitProperty_SetRenderCallback,
        c.kAudioUnitScope_Input,
        0,
        &input,
        @sizeOf(c.AURenderCallbackStruct),
    );

    var stream_format = c.AudioStreamBasicDescription{
        .mSampleRate = phased.sample_rate,
        .mFormatID = c.kAudioFormatLinearPCM,
        .mFormatFlags = c.kAudioFormatFlagIsFloat | c.kAudioFormatFlagIsPacked,
        .mBytesPerPacket = 4 * 2,
        .mFramesPerPacket = 1,
        .mBytesPerFrame = 4 * 2,
        .mChannelsPerFrame = 2,
        .mBitsPerChannel = 32,
        .mReserved = 0,
    };
    _ = c.AudioUnitSetProperty(
        ctx.audio_unit,
        c.kAudioUnitProperty_StreamFormat,
        c.kAudioUnitScope_Input,
        0,
        &stream_format,
        @sizeOf(c.AudioStreamBasicDescription),
    );

    if (c.AudioUnitInitialize(ctx.audio_unit) != 0) return error.FailedToInitialize;

    return BackendHandle{
        .start = start,
        .stop = stop,
        .ctx = ctx,
        .deinit = CoreAudioCtx.deinit,
    };
}

fn renderCallback(
    inRefCon: ?*anyopaque,
    _: [*c]c_uint,
    _: [*c]const c.struct_AudioTimeStamp,
    _: c_uint,
    inNumberFrames: c_uint,
    ioData: [*c]c.struct_AudioBufferList,
) callconv(.C) c.OSStatus {
    const phased: *Phased = @alignCast(@ptrCast(inRefCon.?));

    const buffer = ioData.*.mBuffers[0];
    const data: [*]f32 = @alignCast(@ptrCast(buffer.mData.?));

    var i: u32 = 0;
    while (i < inNumberFrames) : (i += 1) {
        const sample = phased.computeSample();
        data[i * 2 + 0] = sample;
        data[i * 2 + 1] = sample;
        phased.current_frame += 1;
        if (phased.playback_mode == .loop and phased.current_frame >= phased.getMaxFrame()) {
            phased.current_frame = 0;
        }
    }

    return 0;
}

fn start(phased: *Phased) void {
    const ctx: *CoreAudioCtx = @alignCast(@ptrCast(phased.backend_handle.?.ctx));
    _ = c.AudioOutputUnitStart(ctx.audio_unit);
}

fn stop(phased: *Phased) void {
    const ctx: *CoreAudioCtx = @alignCast(@ptrCast(phased.backend_handle.?.ctx));
    _ = c.AudioOutputUnitStop(ctx.audio_unit);
}
