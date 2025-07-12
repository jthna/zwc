const std = @import("std");
const lib = @import("lib.zig");
const cli = @import("cli.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const stdout = std.io.getStdOut().writer();

    const args = try cli.Cli.process(stdout, allocator);
    defer args.deinit();

    if (args.filenames.items.len == 0) {
        try from_stdin(args, stdout, allocator);
    } else if (args.filenames.items.len > 1) {
        try with_total(args, stdout, allocator);
    } else {
        try without_total(args, stdout, allocator);
    }
}

fn from_stdin(args: cli.Cli, writer: anytype, allocator: std.mem.Allocator) !void {
    const stdin = std.io.getStdIn().reader();
    const summary = try lib.EntrySummary.read_data(stdin, allocator);

    const format_width = summary.calculate_format_width(lib.PrintMode.StdIn);
    try summary.print(writer, args.flags, format_width);
}

fn with_total(args: cli.Cli, writer: anytype, allocator: std.mem.Allocator) !void {
    var summaries = try allocator.alloc(lib.EntrySummary, args.filenames.items.len);
    defer allocator.free(summaries);

    var total = lib.EntrySummary{ .name = "total" };
    for (args.filenames.items, 0..) |filename, i| {
        const summary = try lib.EntrySummary.read_from_filename(filename, allocator);
        total.accumulate(summary);

        summaries[i] = summary;
    }

    const format_width = total.calculate_format_width(lib.PrintMode.Normal);
    for (summaries) |summary| {
        try summary.print(writer, args.flags, format_width);
    }

    try total.print(writer, args.flags, format_width);
}

fn without_total(args: cli.Cli, writer: anytype, allocator: std.mem.Allocator) !void {
    const summary = try lib.EntrySummary.read_from_filename(args.filenames.items[0], allocator);

    const print_mode = if (args.flags.num_active() == 1) lib.PrintMode.Short else lib.PrintMode.Normal;
    const format_width = summary.calculate_format_width(print_mode);
    try summary.print(writer, args.flags, format_width);
}
