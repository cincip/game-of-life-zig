const std = @import("std");
const rl = @import("raylib");
const Board = @import("board.zig").Board;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var board = try Board.init(allocator, 50, 50, 15);
    defer board.deinit();

    const margin: usize = 10;
    const window_width: i32 = @intCast(board.n_cols * board.cell_size + margin * 2);
    const window_height: i32 = @intCast(board.n_rows * board.cell_size + margin * 2);

    rl.initWindow(window_width, window_height, "Game of Life");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var running = false;
    var speed: f64 = 15;
    var last_time: f64 = 0;

    while (!rl.windowShouldClose()) {
        const time = rl.getTime();
        const inv_speed = 1 / speed;

        if (rl.isKeyPressed(rl.KeyboardKey.space)) {
            running = !running;
        }

        if (rl.isKeyPressed(rl.KeyboardKey.up)) {
            speed += 1;
        }

        if (rl.isKeyPressed(rl.KeyboardKey.down)) {
            speed -= 1;
        }

        if (rl.isKeyPressed(rl.KeyboardKey.r)) {
            speed = 15;
        }

        if (rl.isMouseButtonDown(rl.MouseButton.left)) {
            const mouse = rl.getMousePosition();
            const c: usize = (@as(usize, @intFromFloat(mouse.x)) - margin) / board.cell_size;
            const r: usize = (@as(usize, @intFromFloat(mouse.y)) - margin) / board.cell_size;
            if (r < board.n_rows and c < board.n_cols) {
                try board.set(r, c, 1);
            }
        }
        if (rl.isMouseButtonDown(rl.MouseButton.right)) {
            const mouse = rl.getMousePosition();
            const c = (@as(usize, @intFromFloat(mouse.x)) - margin) / board.cell_size;
            const r = (@as(usize, @intFromFloat(mouse.y)) - margin) / board.cell_size;
            if (r < board.n_rows and c < board.n_cols) {
                try board.set(r, c, 0);
            }
        }

        if (running and (time - last_time) >= inv_speed) {
            try board.step();
            last_time = time;
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.ray_white);
        board.draw(margin);
        rl.drawText(if (running) "Running (SPACE to pause)" else "Paused (SPACE to run)", 10, 10, 20, .dark_gray);

        var speed_buffer: [64]u8 = undefined;
        const speed_text = try std.fmt.bufPrintZ(&speed_buffer, "Speed: {d:.1} steps/sec (UP and DOWN to adjust, R to reset)", .{speed}); // LOL ChatGPT is the GOAT for this one
        rl.drawText(@ptrCast(speed_text), 10, 35, 16, .dark_gray);
    }
}
