# Phased

**Phased** is a small audio backend library written in [Zig](https://ziglang.org).  
It wraps platform-specific audio APIs (CoreAudio for now) and lets you play simple tones built from layered oscillators.

It's meant as a building block for synth experiments, music tools, or just messing around with sound from code.

---

## 🔧 What it does

- Provides access to CoreAudio through a Zig-friendly interface
- Lets you define one or more oscillators (`sine`, `saw`, `square`, `triangle`)
- Plays a frequency for a duration using those oscillators
- Runs synchronously (no threads, no event loop yet)

---

## 📦 Using Phased in Your Zig Project

You can add Phased as a dependency using zig fetch:

```sh
zig fetch --save git+https://github.com/Mouradif/phased#main
```

Update your build.zig to include Phased:

```
const phased_dep = b.dependency("phased", .{
    .target = target,
    .optimize = optimize,
});

const exe_mod = b.createModule(.{
    // ...
    .imports = &.{
        .{ .name = "phased", .module = phased_dep.module("phased") },
    },
});
```

## 🧱 Example

```zig
const Phased = @import("phased");
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var phased = Phased.init(allocator);
    try phased.addOscillator(Phased.Osc.init(.{}));
    try phased.connect();
    try phased.play(440, 1); // Play A4 for 1 second
}

```

## 📦 Building

```
zig build
```

Should produce the static library at `zig-out/lib/libphased.a`

## ⚠️ Not implemented (yet?)

- Multiple voices / polyphony
- Event loop or scheduling
- Other backends (only CoreAudio works right now)
- MIDI or any real input

## 🧪 Why?

Mostly for fun. Partially to learn Zig’s audio and FFI capabilities. Maybe useful down the line for algorithmic music, livecoding, or small synth tools.

## 📜 License

MIT
