const std = @import("std");
const Lexer = @import("lexer.zig");
const Token = @import("token.zig");

const CODE = @embedFile("./data/slime.elm");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var lexer = try Lexer.init(CODE, arena.allocator(), "src/main.zig");
    var token = try lexer.read();
    token.print();

    while (token.t != .Illegal and token.t != .EndOfFile) : (token = try lexer.read()) {
        token.print();
    }
}
