const std = @import("std");
const terminal = @import("terminal.zig");

pub fn drawRect(allocator: std.mem.Allocator, rows: u16, columns: u16, x: u16, y: u16, middle_text: []const u8) !void {
    const stdout = std.io.getStdOut().writer();

    const top_edge = try allocator.alloc(u8, columns - 2);
    defer allocator.free(top_edge);
    @memset(top_edge, 'q');

    const blank_middle = try allocator.alloc(u8, columns - 2);
    defer allocator.free(blank_middle);
    @memset(blank_middle, ' ');

    var y_index: u16 = 0;
    while (y_index < rows) : (y_index += 1) {
        if (y_index == 0) {
            // 上辺
            try stdout.print("\x1b[{d};{d}H\x1b(0l{s}k\x1b(B", .{ y + y_index + 1, x, top_edge });
        } else if (y_index == rows - 1) {
            // 下辺
            try stdout.print("\x1b[{d};{d}H\x1b(0m{s}j\x1b(B", .{ y + y_index + 1, x, top_edge });
        } else {
            // 側辺
            try stdout.print("\x1b[{d};{d}H\x1b(0x{s}x\x1b(B", .{ y + y_index + 1, x, blank_middle });
        }
    }

    // 中央のテキスト
    const text_len = @as(u16, @intCast(middle_text.len));
    const text_x = x + (columns - text_len) / 2;
    const text_y = y + rows / 2;
    try stdout.print("\x1b[{d};{d}H{s}", .{ text_y + 1, text_x, middle_text });
}

pub fn sideBySideUi(allocator: std.mem.Allocator, rows: u16, columns: u16, left_text: []const u8, right_text: []const u8) !void {
    const left_rect_rows = rows;
    const left_rect_columns = columns / 2;
    const left_rect_x: u16 = 1;
    const left_rect_y: u16 = 0;

    const right_rect_rows = rows;
    const right_rect_columns = columns / 2;
    const right_rect_x = (columns / 2) + 1;
    const right_rect_y: u16 = 0;

    try drawRect(
        allocator,
        left_rect_rows,
        left_rect_columns,
        left_rect_x,
        left_rect_y,
        left_text,
    );
    try drawRect(
        allocator,
        right_rect_rows,
        right_rect_columns,
        right_rect_x,
        right_rect_y,
        right_text,
    );
}

pub fn topAndBottomUi(allocator: std.mem.Allocator, rows: u16, columns: u16, top_text: []const u8, bottom_text: []const u8) !void {
    const top_rect_rows = rows / 2;
    const top_rect_columns = columns;
    const top_rect_x: u16 = 1;
    const top_rect_y: u16 = 0;

    const bottom_rect_rows = rows / 2 + 1;
    const bottom_rect_columns = columns;
    const bottom_rect_x: u16 = 1;
    const bottom_rect_y = rows / 2;

    try drawRect(
        allocator,
        top_rect_rows,
        top_rect_columns,
        top_rect_x,
        top_rect_y,
        top_text,
    );
    try drawRect(
        allocator,
        bottom_rect_rows,
        bottom_rect_columns,
        bottom_rect_x,
        bottom_rect_y,
        bottom_text,
    );
}

pub fn drawUi(allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();

    // 画面クリア
    try stdout.writeAll("\x1b[H\x1b[J");
    // カーソル非表示
    try stdout.writeAll("\x1b[?25l");

    const primary_text = "I am some arbitrary text";
    const secondary_text = "Me too! Here's a shrug emoticon: ¯\\_(ツ)_/¯";
    
    const min_side_width = @max(
        primary_text.len,
        secondary_text.len
    ) + 2; // 矩形の境界線分を追加

    const term_size = terminal.getTerminalSize();
    const rows = term_size.rows;
    const columns = term_size.columns;

    if (columns / 2 > min_side_width) {
        try sideBySideUi(allocator, rows, columns, primary_text, secondary_text);
    } else if (columns > min_side_width) {
        try topAndBottomUi(allocator, rows, columns, primary_text, secondary_text);
    } else {
        try stdout.writeAll("Sorry, terminal is too small!\n");
    }

    // flush()の代わりに、flushStdOutを使用
    try flushStdOut();
}

// 標準出力をフラッシュするヘルパー関数
fn flushStdOut() !void {
    // Zig 0.14.0ではfs.Fileにflushメソッドがないため、ioライブラリを使用
    var writer = std.io.getStdOut().writer();
    try writer.context.writeAll("");
}
