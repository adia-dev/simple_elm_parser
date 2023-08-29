const std = @import("std");
const Self = @This();

const TokenType = union(enum) {
    Keyword: []const u8,
    Identifier: []const u8,

    // Literals
    IntegerLiteral: i32,
    StringLiteral: []const u8,

    // Operators and Punctuation
    Assign,
    Ampersand,
    Equals,
    Plus,
    Minus,
    Pipe,
    Pipeline,
    Arrow,
    OpenBrace,
    CloseBrace,
    LParen,
    RParen,
    LBrack,
    RBrack,
    LBrace,
    RBrace,
    LChevron,
    RChevron,
    Comma,
    Colon,
    SemiColon,
    Dot,
    Tilde,

    // Comments
    InlineComment: []const u8,
    BlockComment: []const u8,

    // Whitespace (usually ignored except as a separator)
    Space,

    // Special
    EndOfFile,
    Illegal,
};

t: TokenType,
literal: []const u8,
line: usize,
column: usize,
file: ?[]const u8,

pub fn new(t: TokenType, literal: []const u8, line: usize, column: usize, file: ?[]const u8) Self {
    return Self{
        .t = t,
        .literal = literal,
        .line = line,
        .column = column,
        .file = file,
    };
}

pub fn print(self: *const Self) void {
    std.debug.print(
        \\ type: {s}
        \\ literal: "{s}"
        \\ line: {d}
        \\ column: {d}
        \\ file: {?s}
        \\
        \\
    , .{ @tagName(self.t), self.literal, self.line, self.column, self.file });
}
