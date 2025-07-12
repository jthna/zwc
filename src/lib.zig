const std = @import("std");
const cli = @import("cli.zig");

pub const EntrySummary = struct {
    lines: usize = 0,
    words: usize = 0,
    chars: usize = 0,
    bytes: usize = 0,
    name: ?[]const u8,

    pub fn read_data(reader: anytype, allocator: std.mem.Allocator) !EntrySummary {
        const buffer = try allocator.alloc(u8, 4096);
        defer allocator.free(buffer);

        var lines: usize = 0;
        var words: usize = 0;
        var bytes: usize = 0;
        var chars: usize = 0;

        while (try reader.readUntilDelimiterOrEof(buffer, '\n')) |line| {
            lines += 1;
            chars += 1;
            bytes += line.len + 1;

            var tokenizer = std.mem.tokenizeAny(u8, line, " \t\r\n");
            while (tokenizer.next()) |_| {
                words += 1;
            }

            var code_point_iterator = (try std.unicode.Utf8View.init(line)).iterator();
            while (code_point_iterator.nextCodepoint()) |_| {
                chars += 1;
            }
        }

        return EntrySummary{
            .lines = lines,
            .words = words,
            .bytes = bytes,
            .chars = chars,
            .name = null,
        };
    }

    pub fn read_from_filename(filename: []const u8, allocator: std.mem.Allocator) !EntrySummary {
        const file = try std.fs.cwd().openFile(filename, .{});
        defer file.close();

        var filedata = try EntrySummary.read_data(file.reader(), allocator);
        filedata.name = filename;
        return filedata;
    }

    pub fn print(self: EntrySummary, writer: anytype, flags: cli.Flags, format_width: usize) !void {
        if (flags.lines)
            try writer.print("{[lines]:>[width]}", .{ .lines = self.lines, .width = format_width });
        if (flags.words)
            try writer.print(" {[words]:>[width]}", .{ .words = self.words, .width = format_width });
        if (flags.chars)
            try writer.print(" {[chars]:>[width]}", .{ .chars = self.chars, .width = format_width });
        if (flags.bytes)
            try writer.print(" {[bytes]:>[width]}", .{ .bytes = self.bytes, .width = format_width });

        if (self.name) |name| {
            try writer.print(" {s}", .{name});
        }
        try writer.print("\n", .{});
    }

    pub fn accumulate(self: *EntrySummary, other: EntrySummary) void {
        self.lines += other.lines;
        self.words += other.words;
        self.chars += other.chars;
        self.bytes += other.bytes;
    }

    pub fn calculate_format_width(self: EntrySummary, mode: PrintMode) usize {
        if (mode == .StdIn) return 7;

        const max_num_digits = @max(num_digits(self.lines), num_digits(self.words), num_digits(self.chars), num_digits(self.bytes));
        if (mode == .Short) return max_num_digits - 1;

        return max_num_digits;
    }
};

pub const PrintMode = enum {
    Short,
    Normal,
    StdIn,
};

pub fn num_digits(n: usize) usize {
    var digits: usize = 1;
    var value = n;
    while (value >= 10) : (value /= 10) {
        digits += 1;
    }

    return digits;
}
