const std = @import("std");
const os = std.os;
const posix = std.posix;
const io = std.io;
const mem = std.mem;
const fs = std.fs;

fn readFromFd(fd: std.posix.fd_t) ?[]u8 {
    _ = fd;
    @panic("readFromFd not implemented");
}

fn spawnPtyWithShell(default_shell: []const u8) !std.posix.fd_t {
    _ = default_shell;
    @panic("spawnPtyWithShell not implemented");
}


pub fn main() !void {
    const default_shell = std.process.getEnvVarOwned(std.heap.page_allocator, "SHELL") catch |err| {
        std.debug.print("Failed to get SHELL env var: {}\n", .{err});
        return err;
    };
    defer std.heap.page_allocator.free(default_shell);

    const stdout_fd = spawnPtyWithShell(default_shell) catch |err| {
        std.debug.print("Failed to spawn pty: {}\n", .{err});
        return err;
    };

    var read_buffer = std.ArrayList(u8).init(std.heap.page_allocator);
    defer read_buffer.deinit();

    while (true) {
        if (readFromFd(stdout_fd)) |read_bytes| {
            try read_buffer.appendSlice(read_bytes);
            std.heap.page_allocator.free(read_bytes);
        } else {
            std.debug.print("Output: {s}\n", .{read_buffer.items});
            break;
        }
    }
}


