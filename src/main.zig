const std = @import("std");
const rl = @import("raylib");
const Board = @import("board.zig").Board;

pub fn main() !void {
    var gpa = std.heap.page_allocator;
    var board = try Board.init(&gpa, 50, 50, 15);
    defer board.deinit(&gpa);

    const margin: usize = 10;
    const window_width: i32 = @intCast(board.n_cols * board.cell_size + margin * 2);
    const window_height: i32 = @intCast(board.n_rows * board.cell_size + margin * 2);

    rl.initWindow(window_width, window_height, "Game of Life");
    defer rl.closeWindow();
    rl.setTargetFPS(10);

    var running = false;

    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(rl.KeyboardKey.space)) {
            running = !running;
        }

        if (rl.isMouseButtonDown(rl.MouseButton.left)) {
            const mouse = rl.getMousePosition();
            const c: usize = (@as(usize, @intFromFloat(mouse.x)) - margin) / board.cell_size;
            const r: usize = (@as(usize, @intFromFloat(mouse.y)) - margin) / board.cell_size;
            if (r < board.n_rows and c < board.n_cols) {
                board.set(r, c, 1);
            }
        }
        if (rl.isMouseButtonDown(rl.MouseButton.right)) {
            const mouse = rl.getMousePosition();
            const c = (@as(usize, @intFromFloat(mouse.x)) - margin) / board.cell_size;
            const r = (@as(usize, @intFromFloat(mouse.y)) - margin) / board.cell_size;
            if (r < board.n_rows and c < board.n_cols) {
                board.set(r, c, 0);
            }
        }

        if (running) {
            try board.step(&gpa);
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.ray_white);
        board.draw(margin);
        rl.drawText(if (running) "Running (SPACE to pause)" else "Paused (SPACE to run)", 10, 10, 20, .dark_gray);
    }
}
