const std = @import("std");
const os = std.os;
const posix = std.posix;
const io = std.io;
const mem = std.mem;
const fs = std.fs;

// Cライブラリのインポート
const c = @cImport({
    @cInclude("stdlib.h");
    @cInclude("fcntl.h");
    @cInclude("unistd.h");
    @cInclude("util.h"); // macOSの場合はutil.h、Linuxの場合はpty.h
});

// ファイルディスクリプタから読み込む関数
fn readFromFd(fd: std.posix.fd_t) ?[]u8 {
    var buffer = std.heap.page_allocator.alloc(u8, 4096) catch return null;
    errdefer std.heap.page_allocator.free(buffer);

    const bytes_read = posix.read(fd, buffer) catch return null;
    if (bytes_read == 0) {
        // ファイルの終わりに達した場合
        std.heap.page_allocator.free(buffer);
        return null;
    }
    
    // 読み込んだバイト数だけ返す
    return buffer[0..bytes_read];
}

// PTYをフォークしてシェルを実行する関数
fn spawnPtyWithShell(default_shell: []const u8) !std.posix.fd_t {
    var master_fd: c_int = undefined;
    
    // forkptyを使用してPTYを作成し、同時にプロセスをフォーク
    const pid = c.forkpty(&master_fd, null, null, null);
    
    if (pid < 0) {
        // エラー
        return error.ForkFailed;
    } else if (pid == 0) {
        // 子プロセス
        // シェルコマンドを実行

        var process = std.process.Child.init(&[_][]const u8{default_shell}, std.heap.page_allocator);
        process.stdin_behavior = .Inherit;
        process.stdout_behavior = .Inherit;
        process.stderr_behavior = .Inherit;

        _ = process.spawn() catch {
            std.debug.print("Failed to spawn shell process\n", .{});
            posix.exit(1);
        };
       
        std.time.sleep(std.time.ns_per_s * 2); // 5秒待機
        posix.exit(0); // 子プロセスを終了
    }
    
    // 親プロセス - マスターファイルディスクリプタを返す
    return master_fd;
}

pub fn main() !void {
    const default_shell = std.process.getEnvVarOwned(std.heap.page_allocator, "SHELL") catch |err| {
        std.debug.print("Failed to get SHELL env var: {}\n", .{err});
        return err;
    };
    defer std.heap.page_allocator.free(default_shell);
    
    const stdout_fd = try spawnPtyWithShell(default_shell);
    defer posix.close(stdout_fd);
    
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
