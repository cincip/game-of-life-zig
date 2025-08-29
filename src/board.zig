const std = @import("std");
const rl = @import("raylib");

pub const Board = struct {
    n_rows: usize,
    n_cols: usize,
    cell_size: usize,
    table: []u8,

    pub fn init(allocator: *std.mem.Allocator, r: usize, c: usize, s: usize) !Board {
        const tbl = try allocator.alloc(u8, r * c);
        @memset(tbl, 0);
        return Board{
            .n_rows = r,
            .n_cols = c,
            .cell_size = s,
            .table = tbl,
        };
    }

    pub fn deinit(self: *Board, allocator: *std.mem.Allocator) void {
        allocator.free(self.table);
    }

    inline fn index(self: *Board, r: usize, c: usize) usize {
        return r * self.n_cols + c;
    }

    pub fn get(self: *Board, r: usize, c: usize) u8 {
        return self.table[self.index(r, c)];
    }

    pub fn set(self: *Board, r: usize, c: usize, val: u8) void {
        self.table[self.index(r, c)] = val;
    }

    pub fn draw(self: *Board, margin: usize) void {
        for (0..self.n_rows) |r| {
            for (0..self.n_cols) |c| {
                const x: i32 = @intCast(margin + c * self.cell_size);
                const y: i32 = @intCast(margin + r * self.cell_size);
                const color: rl.Color = if (self.get(r, c) == 1) .black else .ray_white;
                rl.drawRectangle(x, y, @intCast(self.cell_size), @intCast(self.cell_size), color);
                rl.drawRectangleLines(x, y, @intCast(self.cell_size), @intCast(self.cell_size), .light_gray);
            }
        }
    }

    pub fn step(self: *Board, allocator: *std.mem.Allocator) !void {
        var new_table = try allocator.alloc(u8, self.n_rows * self.n_cols);
        defer allocator.free(new_table);

        for (0..self.n_rows) |r| {
            for (0..self.n_cols) |c| {
                var neighbors: usize = 0;

                const offsets = [_]i2{ -1, 0, 1 };
                for (offsets) |dr| {
                    for (offsets) |dc| {
                        if (dr == 0 and dc == 0) continue;
                        const nr = @as(isize, @intCast(r)) + dr;
                        const nc = @as(isize, @intCast(c)) + dc;
                        if (nr >= 0 and nr < @as(isize, @intCast(self.n_rows)) and
                            nc >= 0 and nc < @as(isize, @intCast(self.n_cols)))
                        {
                            if (self.get(@intCast(nr), @intCast(nc)) == 1) {
                                neighbors += 1;
                            }
                        }
                    }
                }

                const alive = self.get(r, c) == 1;
                var next: u8 = 0;
                if (alive and (neighbors == 2 or neighbors == 3)) next = 1;
                if (!alive and neighbors == 3) next = 1;

                new_table[self.index(r, c)] = next;
            }
        }

        @memcpy(self.table, new_table);
    }
};


