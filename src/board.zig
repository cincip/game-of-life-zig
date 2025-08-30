const std = @import("std");
const rl = @import("raylib");
const Pos = @import("pos.zig").Pos;

pub const Board = struct {
    n_rows: usize,
    n_cols: usize,
    cell_size: usize,
    alive: std.HashMap(Pos, void, Pos.HashContext, std.hash_map.default_max_load_percentage),
    temp: std.HashMap(Pos, void, Pos.HashContext, std.hash_map.default_max_load_percentage),
    neighbour_count: std.HashMap(Pos, u8, Pos.HashContext, std.hash_map.default_max_load_percentage),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, r: usize, c: usize, s: usize) !Board {
        return Board{
            .n_rows = r,
            .n_cols = c,
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

    pub fn set(self: *Board, r: usize, c: usize, val: u8) !void {
        const pos = Pos{ .row = r, .col = c };
        if (val == 1) {
            try self.alive.put(pos, {});
        } else {
            _ = self.alive.remove(pos);
        }
    }

    pub fn draw(self: *Board, margin: usize) void {
        for (0..self.n_rows) |r| {
            for (0..self.n_cols) |c| {
                const x: i32 = @intCast(margin + c * self.cell_size);
                const y: i32 = @intCast(margin + r * self.cell_size);
                rl.drawRectangle(x, y, @intCast(self.cell_size), @intCast(self.cell_size), .ray_white);
                rl.drawRectangleLines(x, y, @intCast(self.cell_size), @intCast(self.cell_size), .light_gray);
            }
        }

        var iter = self.alive.iterator();
        while(iter.next()) |cell| {
            const pos = cell.key_ptr.*;
            const x: i32 = @intCast(margin + pos.col * self.cell_size);
            const y: i32 = @intCast(margin + pos.row * self.cell_size);
            rl.drawRectangle(x, y, @intCast(self.cell_size), @intCast(self.cell_size), .black);
        }
    }

    pub fn step(self: *Board) !void {
        self.neighbour_count.clearRetainingCapacity();
        self.temp.clearRetainingCapacity();

        var iter = self.alive.iterator();
        while (iter.next()) |cell| {
            const pos = cell.key_ptr.*;
            const offsets = [_]i2{-1, 0, 1};
            for (offsets) |dr| {
                for (offsets) |dc| {
                    if (dr == 0 and dc == 0) continue;
                    const nr = @as(isize, @intCast(pos.row)) + dr;
                    const nc = @as(isize, @intCast(pos.col)) + dc;

                    if (nr >= 0 and nr < @as(isize, @intCast(self.n_rows)) and
                            nc >= 0 and nc < @as(isize, @intCast(self.n_cols)))
                    {
                        const neighbour_pos = Pos{ .row = @intCast(nr), .col = @intCast(nc) };
                        const curr_count = self.neighbour_count.get(neighbour_pos) orelse 0;
                        try self.neighbour_count.put(neighbour_pos, curr_count + 1);
                    }
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
