const std = @import("std");
const rl = @import("raylib");
const Board = @import("board.zig").Board;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var board = try Board.init(allocator, 20);
    defer board.deinit();

    const margin: isize = 10;
    const window_width: i32 = 1000;
    const window_height: i32 = 1000;

    rl.initWindow(window_width, window_height, "Game of Life");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var running = false;
    var speed: f64 = 15;
    var last_time: f64 = 0;

    var camera = rl.Camera2D{
        .target = .{ .x = 0, .y = 0 },
        .offset = .{ .x = 0, .y = 0 },
        .zoom = 1,
        .rotation = 0,
    };

    var dragging = false;
    var drag_start = rl.Vector2{ .x = 0, .y = 0 };
    var show_grid = true;

    while (!rl.windowShouldClose()) {
        const time = rl.getTime();
        const inv_speed = 1 / speed;

        if (rl.isKeyPressed(rl.KeyboardKey.space)) {
            running = !running;
        }

        if (rl.isKeyDown(rl.KeyboardKey.up)) {
            speed += 0.1;
        }

        if (rl.isKeyDown(rl.KeyboardKey.down)) {
            speed -= 0.1;
        }

        if (rl.isKeyPressed(rl.KeyboardKey.r)) {
            speed = 15;
        }

        if (rl.isKeyPressed(rl.KeyboardKey.g)) {
            show_grid = !show_grid;
        }

        if (rl.isMouseButtonDown(rl.MouseButton.left)) {
            const mouse_world = rl.getScreenToWorld2D(rl.getMousePosition(), camera);
            const c = @divTrunc(@as(isize, @intFromFloat(mouse_world.x - margin)), @as(isize, @intCast(board.cell_size))); // Did not know divTrunc could work like this
            const r = @divTrunc(@as(isize, @intFromFloat(mouse_world.y - margin)), @as(isize, @intCast(board.cell_size)));
            if (rl.isKeyDown(rl.KeyboardKey.left_control) or rl.isKeyDown(rl.KeyboardKey.right_control)) {
                try board.set(@intCast(r), @intCast(c), 0);
            } else {
                try board.set(@intCast(r), @intCast(c), 1);
            }
        }

        if (rl.isMouseButtonPressed(rl.MouseButton.right)) {
            dragging = true;
            drag_start = rl.getMousePosition();
        }

        if (rl.isMouseButtonReleased(rl.MouseButton.right)) {
            dragging = false;
        }

        if (dragging) {
            const mouse = rl.getMousePosition();

            const prev_world = rl.getScreenToWorld2D(drag_start, camera);
            const curr_world = rl.getScreenToWorld2D(mouse, camera);

            camera.target.x += (prev_world.x - curr_world.x);
            camera.target.y += (prev_world.y - curr_world.y);

            drag_start = mouse;
        }

        if (running and (time - last_time) >= inv_speed) {
            try board.step();
            last_time = time;
        }

        {
            const wheel = rl.getMouseWheelMove();
            if (wheel != 0) {
                const screenToWorld = rl.getScreenToWorld2D(rl.getMousePosition(), camera);

                camera.offset = rl.getMousePosition();
                camera.target = screenToWorld;

                var scaleFactor = 1 + (0.5 * @abs(wheel));
                if (wheel < 0) {
                    scaleFactor = 1 / scaleFactor;
                }

                camera.zoom = rl.math.clamp(camera.zoom * scaleFactor, 0.125, 64);
            }
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.ray_white);

        {
            camera.begin();
            defer camera.end();

            if (show_grid) {
                board.drawGrid(camera, margin, window_width, window_height);
            }

            board.draw(margin);
        }

        const line_height = 26;
        var y: i32 = 10;

        rl.drawText(
            if (running) "Running (SPACE to pause)" else "Paused (SPACE to run)",
            10,
            y,
            24,
            .dark_gray,
        );

        y += line_height;
        rl.drawText(
            if (show_grid) "Showing grid (G to stop showing grid)" else "Not showing the grid (G to show the grid)",
            10,
            y,
            24,
            .dark_gray,
        );

        y += line_height;
        var speed_buffer: [64]u8 = undefined;
        const speed_text = try std.fmt.bufPrintZ(
            &speed_buffer,
            "Speed: {d:.1} steps/sec (UP/DOWN to adjust, R to reset)",
            .{speed},
        );
        rl.drawText(@ptrCast(speed_text), 10, y, 24, .dark_gray);

        y += line_height;
        rl.drawText(
            "Left click to select, Ctrl+Click to unselect",
            10,
            y,
            24,
            .dark_gray,
        );
    }
}
