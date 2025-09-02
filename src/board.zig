const std = @import("std");
const rl = @import("raylib");
const Pos = @import("pos.zig").Pos;

pub const Board = struct {
    cell_size: isize,
    alive: std.HashMap(Pos, void, Pos.HashContext, std.hash_map.default_max_load_percentage),
    temp: std.HashMap(Pos, void, Pos.HashContext, std.hash_map.default_max_load_percentage),
    neighbour_count: std.HashMap(Pos, u8, Pos.HashContext, std.hash_map.default_max_load_percentage),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, s: isize) !Board {
        return Board{
            .cell_size = s,
            .alive = std.HashMap(Pos, void, Pos.HashContext, std.hash_map.default_max_load_percentage).init(allocator),
            .temp = std.HashMap(Pos, void, Pos.HashContext, std.hash_map.default_max_load_percentage).init(allocator),
            .neighbour_count = std.HashMap(Pos, u8, Pos.HashContext, std.hash_map.default_max_load_percentage).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Board) void {
        self.alive.deinit();
        self.temp.deinit();
        self.neighbour_count.deinit();
    }

    pub fn isAlive(self: *Board, r: usize, c: usize) bool {
        return self.alive.contains(Pos{ .row = r, .col = c });
    }

    pub fn set(self: *Board, r: isize, c: isize, val: u8) !void {
        const pos = Pos{ .row = r, .col = c };
        if (val == 1) {
            try self.alive.put(pos, {});
        } else {
            _ = self.alive.remove(pos);
        }
    }

    pub fn draw(self: *Board, margin: isize) void {
        var iter = self.alive.iterator();
        while (iter.next()) |cell| {
            const pos = cell.key_ptr.*;
            const x: i32 = @intCast(margin + pos.col * self.cell_size);
            const y: i32 = @intCast(margin + pos.row * self.cell_size);
            rl.drawRectangle(x, y, @intCast(self.cell_size), @intCast(self.cell_size), .black);
        }
    }

    pub fn drawGrid(self: *Board, camera: rl.Camera2D, margin: isize, screen_width: i32, screen_height: i32) void {
        const top_left = rl.getScreenToWorld2D(.{ .x = 0, .y = 0 }, camera);
        const bottom_right = rl.getScreenToWorld2D(.{ .x = @floatFromInt(screen_width), .y = @floatFromInt(screen_height) }, camera);

        const cell_size = self.cell_size;

        // TODO: find a better way of writing this kind of stuff
        const start_x = @divFloor(
            @as(isize, @intFromFloat(top_left.x - @as(f64, @floatFromInt(margin)))),
            cell_size,
        ) * cell_size + margin;

        const end_x = @divFloor(
            @as(isize, @intFromFloat(bottom_right.x - @as(f64, @floatFromInt(margin)))),
            cell_size,
        ) * cell_size + margin;

        const start_y = @divFloor(
            @as(isize, @intFromFloat(top_left.y - @as(f64, @floatFromInt(margin)))),
            cell_size,
        ) * cell_size + margin;

        const end_y = @divFloor(
            @as(isize, @intFromFloat(bottom_right.y - @as(f64, @floatFromInt(margin)))),
            cell_size,
        ) * cell_size + margin;

        var x = start_x;
        while (x <= end_x) : (x += cell_size) {
            rl.drawLine(@intCast(x), @intCast(start_y), @intCast(x), @intCast(end_y), .light_gray);
        }

        var y = start_y;
        while (y <= end_y) : (y += cell_size) {
            rl.drawLine(@intCast(start_x), @intCast(y), @intCast(end_x), @intCast(y), .light_gray);
        }
    }
    pub fn step(self: *Board) !void {
        self.neighbour_count.clearRetainingCapacity();
        self.temp.clearRetainingCapacity();

        var iter = self.alive.iterator();
        while (iter.next()) |cell| {
            const pos = cell.key_ptr.*;
            const offsets = [_]i2{ -1, 0, 1 };
            for (offsets) |dr| {
                for (offsets) |dc| {
                    if (dr == 0 and dc == 0) continue;
                    const nr = @as(isize, @intCast(pos.row)) + dr;
                    const nc = @as(isize, @intCast(pos.col)) + dc;

                    const neighbour_pos = Pos{ .row = @intCast(nr), .col = @intCast(nc) };
                    const curr_count = self.neighbour_count.get(neighbour_pos) orelse 0;
                    try self.neighbour_count.put(neighbour_pos, curr_count + 1);
                }
            }
        }

        var n_iter = self.neighbour_count.iterator();
        while (n_iter.next()) |cell| {
            const pos = cell.key_ptr.*;
            const neighbour_count = cell.value_ptr.*;
            const is_black = self.alive.contains(pos);

            var should_be_black = false;
            if (is_black and (neighbour_count == 2 or neighbour_count == 3)) {
                should_be_black = true;
            } else if (!is_black and neighbour_count == 3) {
                should_be_black = true;
            }

            if (should_be_black) {
                try self.temp.put(pos, {});
            }
        }

        const temp = self.alive;
        self.alive = self.temp;
        self.temp = temp;
    }
};
