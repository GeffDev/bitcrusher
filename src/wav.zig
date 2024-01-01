const std = @import("std");

pub const WavWriter = struct {
    file: std.fs.File,
    before_audio: u64,
    after_audio: u64,

    pub fn init(file_name: []const u8, bit_depth: i32, channels: i16, sample_rate: i32) !WavWriter {
        var wav: WavWriter = .{
            .file = try std.fs.cwd().createFile(file_name, .{}),
            .before_audio = 0,
            .after_audio = 0,
        };

        _ = try wav.file.write("RIFF");
        _ = try wav.file.write("aaaa"); // placeholder
        _ = try wav.file.write("WAVE");

        _ = try wav.file.write("fmt ");
        _ = try wav.file.writer().writeInt(i32, bit_depth, .little);
        _ = try wav.file.writer().writeInt(i16, 1, .little); // raw pcm data, no compression
        _ = try wav.file.writer().writeInt(i16, channels, .little);
        _ = try wav.file.writer().writeInt(i32, sample_rate, .little);
        _ = try wav.file.writer().writeInt(i32, @divTrunc(sample_rate * bit_depth * channels, 8), .little); // bitrate
        _ = try wav.file.writer().writeInt(i16, @as(i16, @as(i16, @intCast(bit_depth * channels))), .little);
        _ = try wav.file.writer().writeInt(i16, @as(i16, @as(i16, @intCast(bit_depth))), .little);

        _ = try wav.file.write("data");
        _ = try wav.file.write(">:) "); // placeholder

        wav.before_audio = try wav.file.getPos();
        return wav;
    }

    pub fn deinit(self: *WavWriter) void {
        self.file.close();
    }

    pub fn write8(self: *WavWriter, sample: u8) !void {
        try self.file.writer().writeByte(sample);
    }

    pub fn writeSize(self: *WavWriter) !void {
        try self.file.seekTo(self.before_audio - 4);
        _ = try self.file.writer().writeInt(i32, @as(i32, @as(i32, @intCast(self.after_audio - self.before_audio))), .little);

        try self.file.seekTo(4);
        _ = try self.file.writer().writeInt(i32, @as(i32, @as(i32, @intCast(self.after_audio - 4))), .little);
    }
};

pub const WavReader = struct {
    file: std.fs.File,
    sample: []u8,
    // in bytes
    sample_size: i32,
    bit_depth: i32,
    channels: i16,
    sample_rate: i32,
    bitrate: i32,
    // btw, this is the number of bytes for one sample including all channels
    block_align: i16,
    bits_per_sample: i16,

    pub fn init(file_name: []const u8, allocator: std.mem.Allocator) !WavReader {
        var wav: WavReader = .{
            .file = try std.fs.cwd().openFile(file_name, .{}),
            .sample = undefined,
            .sample_size = 0,
            .bit_depth = 0,
            .channels = 0,
            .sample_rate = 0,
            .bitrate = 0,
            .block_align = 0,
            .bits_per_sample = 0,
        };

        try wav.file.seekTo(16);
        wav.bit_depth = try wav.file.reader().readInt(i32, .little);
        if (try wav.file.reader().readInt(i16, .little) != 1) {
            std.debug.print("bitcrush only supports raw pcm frames with no compression!", .{});
            return error.FailedToOpen;
        }
        wav.channels = try wav.file.reader().readInt(i16, .little);
        wav.sample_rate = try wav.file.reader().readInt(i32, .little);
        wav.bitrate = try wav.file.reader().readInt(i32, .little);
        wav.block_align = try wav.file.reader().readInt(i16, .little);
        wav.bits_per_sample = try wav.file.reader().readInt(i16, .little);
        try wav.file.seekTo(try wav.file.getPos() + 4);
        wav.sample_size = try wav.file.reader().readInt(i32, .little);

        wav.sample = try wav.file.readToEndAlloc(allocator, std.math.maxInt(usize));
        return wav;
    }

    pub fn deinit(self: *WavReader, allocator: std.mem.Allocator) void {
        allocator.free(self.sample);

        self.file.close();
    }
};
