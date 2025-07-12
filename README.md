# zwc

A simple and fast reimplementation of the `wc` (word count) command-line utility, written in Zig.

## Description

`zwc` is a clone of the Unix `wc` command. It reads either standard input or a list of files and, by default, outputs the number of newlines, words, and bytes contained in each.

## Building

To build the project, you'll need the Zig compiler installed on your system.

Clone the repository and navigate to the project directory. Then, run the following command:

```sh
zig build
```

The compiled binary will be located at `./zig-out/bin/zwc`.

## Usage

You can use `zwc` in a similar way to the standard `wc` command. To see all available options and their descriptions, you can use the `--help` flag.

```sh
$ ./zig-out/bin/zwc --help
A blazingly fast wc clone

Usage: zwc [OPTION]... [FILE]...
Print newline, word, and byte counts for each FILE, and a total line if
more than one FILE is specified.

With no FILE, or when FILE is -, read standard input.

The options below may be used to select which counts are printed, always in
the following order: newline, word, character, byte.
  -c, --bytes            print the byte counts
  -m, --chars            print the character counts
  -l, --lines            print the newline counts
  -w, --words            print the word counts

      --help             display this help and exit
      --version          output version information and exit
```
