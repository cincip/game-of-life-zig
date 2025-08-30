const std = @import("std");

pub const Pos = struct {
    row: usize,
    col: usize,

    pub const HashContext = struct {
        pub fn eql(_: @This(), a: Pos, b: Pos) bool {
            return a.row == b.row and a.col == b.col;
        }
        
        pub fn hash(_: @This(), pos: Pos) u64 {
            var h = std.hash.Wyhash.init(0);
            h.update(std.mem.asBytes(&pos.row));
            h.update(std.mem.asBytes(&pos.col));
            return h.final();
        }
    };
};
