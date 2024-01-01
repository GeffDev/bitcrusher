const std = @import("std");

const wav = @import("wav.zig");

// worst code ever written

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var args = try std.process.ArgIterator.initWithAllocator(alloc);
    _ = args.next();

    const file_name = args.next();
    if (file_name == null) {
        std.debug.print("no valid file name argument provided!\n", .{});
        return error.NoFileName;
    }

    const file_name_output = args.next();
    if (file_name == null) {
        std.debug.print("no valid output file name argument provided!\n", .{});
        return error.NoFileName;
    }

    const bit_reducer_str = args.next();
    if (bit_reducer_str == null) {
        std.debug.print("no valid bit reducer value provided!\n", .{});
        return error.NoBitReducer;
    }

    const bit_reducer = try std.fmt.parseInt(u3, bit_reducer_str.?, 0);
    if (bit_reducer > 7) {
        std.debug.print("bit reducer value must be lower than 8!\n", .{});
        return error.HighBitReducer;
    }

    var wav_file = try wav.WavReader.init(file_name.?, alloc);
    var wav_file_crush = try wav.WavWriter.init(file_name_output.?, wav_file.bit_depth, wav_file.channels, wav_file.sample_rate);

    for (wav_file.sample) |*sample| {
        sample.* >>= bit_reducer;
        try wav_file_crush.write8(sample.*);
    }
    wav_file_crush.after_audio = try wav_file_crush.file.getPos();
    try wav_file_crush.writeSize();

    wav_file_crush.deinit();
    wav_file.deinit(alloc);

    _ = gpa.deinit();
}
