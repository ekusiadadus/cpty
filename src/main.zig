const std = @import("std");
const posix = std.posix;
const io = std.io;
const time = std.time;
const terminal = @import("terminal.zig");
const ui = @import("ui.zig");

// シグナル処理用のCライブラリインポート
const c = @cImport({
    @cInclude("signal.h");
});

// UI操作用のグローバルアロケータ
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

fn signalHandler(sig: c_int) callconv(.C) void {
    const allocator = gpa.allocator();
    
    if (sig == c.SIGWINCH) {
        // ウィンドウサイズ変更シグナルの場合、UIを再描画
        ui.drawUi(allocator) catch {};
    } else if (sig == c.SIGTERM or sig == c.SIGINT or sig == c.SIGQUIT or sig == c.SIGHUP) {
        // 終了シグナルの場合、ターミナル状態を復元して終了
        const stdout = std.io.getStdOut().writer();
        stdout.writeAll("\x1b[H\x1b[J") catch {}; // 画面クリア
        stdout.writeAll("\x1b[?25h") catch {}; // カーソル表示
        std.process.exit(0);
    }
}

pub fn main() !void {
    const allocator = gpa.allocator();

    defer {
        // Zig 0.14.0では、gpa.deinit()はheap.Checkを返す
        const leaked = gpa.deinit();
        if (leaked == .leak) std.debug.print("Memory leak detected.\n", .{});
    }

    // シグナルハンドラのセットアップ
    var sa = std.mem.zeroes(posix.Sigaction);
    sa.handler.handler = signalHandler;
    
    // Zig 0.14.0ではsigactionはvoidを返すので、単純に呼び出す
    posix.sigaction(posix.SIG.WINCH, &sa, null);
    posix.sigaction(posix.SIG.TERM, &sa, null);
    posix.sigaction(posix.SIG.INT, &sa, null);
    posix.sigaction(posix.SIG.QUIT, &sa, null);
    posix.sigaction(posix.SIG.HUP, &sa, null);
    
    // 初期UI描画
    try ui.drawUi(allocator);
    
    // シグナルを無期限に待つ
    while (true) {
        time.sleep(time.ns_per_s);
    }
}
