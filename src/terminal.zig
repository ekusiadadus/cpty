const std = @import("std");
const posix = std.posix;

// C ライブラリのインポート
const c = @cImport({
    @cInclude("sys/ioctl.h");
    @cInclude("unistd.h");
});

pub const Winsize = extern struct {
    ws_row: u16,
    ws_col: u16,
    ws_xpixel: u16,
    ws_ypixel: u16,
};

pub fn getTerminalSize() struct { rows: u16, columns: u16 } {
    var winsize = Winsize{
        .ws_row = 0,
        .ws_col = 0,
        .ws_xpixel = 0,
        .ws_ypixel = 0,
    };

    const stdout_fd = posix.STDOUT_FILENO;
    _ = c.ioctl(stdout_fd, c.TIOCGWINSZ, &winsize);

    return .{
        .rows = winsize.ws_row,
        .columns = winsize.ws_col,
    };
}
