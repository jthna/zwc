const std = @import("std");
const version = "0.1.0";

fn print_help(writer: anytype) !void {
    try writer.print(
        \\A blazingly fast wc clone
        \\
        \\Usage: zwc [OPTION]... [FILE]...
        \\Print newline, word, and byte counts for each FILE, and a total line if
        \\more than one FILE is specified.
        \\
        \\With no FILE, or when FILE is -, read standard input.
        \\
        \\The options below may be used to select which counts are printed, always in
        \\the following order: newline, word, character, byte.
        \\  -c, --bytes            print the byte counts
        \\  -m, --chars            print the character counts
        \\  -l, --lines            print the newline counts
        \\  -w, --words            print the word counts
        \\
        \\      --help             display this help and exit
        \\      --version          output version information and exit
        \\
    , .{});
    std.process.exit(0);
}

fn print_version(writer: anytype) !void {
    try writer.print("zwc {s}", .{version});
    std.process.exit(0);
}

pub const Flags = struct {
    lines: bool = false,
    words: bool = false,
    chars: bool = false,
    bytes: bool = false,

    pub fn num_active(self: Flags) usize {
        var num: usize = 0;

        if (self.lines) num += 1;
        if (self.words) num += 1;
        if (self.chars) num += 1;
        if (self.bytes) num += 1;

        return num;
    }
};

pub const Cli = struct {
    flags: Flags,
    filenames: std.ArrayList([]const u8),

    pub fn process(writer: anytype, allocator: std.mem.Allocator) !Cli {
        var args = try std.process.argsWithAllocator(allocator);
        defer args.deinit();

        var flags = Flags{};
        var filenames = std.ArrayList([]const u8).init(allocator);

        // Process arguments. We skip the first arguments (binary name).
        _ = args.next();

        while (args.next()) |arg| {
            if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
                try print_help(writer);
            } else if (std.mem.startsWith(u8, arg, "--")) {
                if (std.mem.eql(u8, arg, "--version")) {
                    try print_version(writer);
                } else if (std.mem.eql(u8, arg, "--bytes")) {
                    flags.bytes = true;
                } else if (std.mem.eql(u8, arg, "--chars")) {
                    flags.chars = true;
                } else if (std.mem.eql(u8, arg, "--lines")) {
                    flags.lines = true;
                } else if (std.mem.eql(u8, arg, "--words")) {
                    flags.words = true;
                } else {
                    try writer.print("Unknown flag: {s}\n", .{arg});
                }
            } else if (std.mem.startsWith(u8, arg, "-")) {
                for (arg[1..]) |flag| {
                    switch (flag) {
                        'c' => flags.bytes = true,
                        'm' => flags.chars = true,
                        'l' => flags.lines = true,
                        'w' => flags.words = true,
                        else => {
                            try writer.print("Unknown flag: -{c}\n", .{flag});
                        },
                    }
                }
            } else {
                try filenames.append(arg);
            }
        }

        // Show lines, words, and chars if no flag is specified.
        if (!flags.lines and !flags.words and !flags.bytes and !flags.chars) {
            flags = .{ .lines = true, .words = true, .bytes = true };
        }

        return Cli{ .flags = flags, .filenames = filenames };
    }

    pub fn deinit(self: Cli) void {
        defer self.filenames.deinit();
    }
};
