const std = @import("std");
const StringHashMap = std.StringHashMap;
const Self = @This();
const Token = @import("token.zig");

input: []const u8,
position: usize,
next_position: usize,
last_line_position: usize,
line: usize,
file: ?[]const u8 = null,
c: u8,
keywords: StringHashMap(void),

pub fn init(input: []const u8, allocator: std.mem.Allocator, file: ?[]const u8) !Self {
    var lexer = Self{ .input = input, .position = 0, .last_line_position = 0, .next_position = 0, .line = 1, .c = 0, .keywords = StringHashMap(void).init(allocator), .file = file };

    _ = try lexer.read();

    try lexer.keywords.put("module", {});
    try lexer.keywords.put("exposing", {});
    try lexer.keywords.put("import", {});
    try lexer.keywords.put("type", {});
    try lexer.keywords.put("alias", {});
    try lexer.keywords.put("case", {});
    try lexer.keywords.put("of", {});
    try lexer.keywords.put("init", {});
    try lexer.keywords.put("update", {});
    try lexer.keywords.put("view", {});
    try lexer.keywords.put("main", {});
    try lexer.keywords.put("program", {});

    return lexer;
}

pub fn deinit(self: *Self) void {
    self.keywords.deinit();
}

pub fn read(self: *Self) !Token {
    self.eat_whitespace();

    var token = Token.new(.Illegal, "", self.line, self.position - self.last_line_position, self.file);

    switch (self.c) {
        ' ' => {
            token.t = .Space;
            token.literal = " ";
        },
        'a'...'z', 'A'...'Z' => {
            const identifier = self.read_identifier();
            token.literal = identifier;

            if (self.keywords.contains(identifier)) {
                token.t = .{ .Keyword = identifier };
                return token;
            }

            token.t = .{ .Identifier = token.literal };
            return token;
        },
        '0'...'9' => {
            token.literal = self.read_integer_literal();
            token.t = .{ .IntegerLiteral = try std.fmt.parseInt(i32, token.literal, 10) };

            return token;
        },
        '(' => {
            token.literal = "(";
            token.t = .LParen;
        },
        ')' => {
            token.literal = ")";
            token.t = .RParen;
        },
        '{' => {
            if (self.peek_char() == '-') {
                token.literal = self.read_block_comment();
                token.t = .{ .BlockComment = token.literal };
                return token;
            }
            token.literal = "{";
            token.t = .LBrace;
        },
        '}' => {
            token.literal = "}";
            token.t = .RBrace;
        },
        '[' => {
            token.literal = "[";
            token.t = .LBrack;
        },
        ']' => {
            token.literal = "]";
            token.t = .RBrack;
        },
        ',' => {
            token.literal = ",";
            token.t = .Comma;
        },
        ';' => {
            token.literal = ";";
            token.t = .SemiColon;
        },
        ':' => {
            token.literal = ":";
            token.t = .Colon;
        },
        '+' => {
            token.literal = "+";
            token.t = .Plus;
        },
        '.' => {
            token.literal = ".";
            token.t = .Dot;
        },
        '-' => {
            if (self.peek_char() == '-') {
                token.literal = self.read_inline_comment();
                token.t = .{ .InlineComment = token.literal };
                return token;
            } else if (self.peek_char() == '>') {
                token.literal = "->";
                token.t = .Arrow;
            } else {
                token.literal = "-";
                token.t = .Minus;
            }
        },
        '|' => {
            if (self.peek_char() == '>') {
                token.t = .Pipeline;
                token.literal = "|>";
                self.advance();
            } else {
                token.literal = "|";
                token.t = .Pipe;
            }
        },
        '&' => {
            token.literal = "&";
            token.t = .Ampersand;
        },
        '~' => {
            token.literal = "~";
            token.t = .Tilde;
        },
        '=' => {
            token.literal = "=";
            token.t = .Assign;
        },
        '>' => {
            token.literal = ">";
            token.t = .RChevron;
        },
        '<' => {
            token.literal = "<";
            token.t = .LChevron;
        },
        '"' => {
            token.literal = self.read_string_literal();
            token.t = .{ .StringLiteral = token.literal };

            return token;
        },
        0 => {
            token.literal = "";
            token.t = .EndOfFile;
        },
        else => {},
    }

    self.advance();

    return token;
}

fn read_identifier(self: *Self) []const u8 {
    const position = self.position;

    while (std.ascii.isAlphanumeric(self.c) or self.c == '_') : (self.advance()) {}

    return self.input[position..self.position];
}

fn read_inline_comment(self: *Self) []const u8 {
    const position = self.position;

    while (self.c != '\n' and self.c != '\r' and self.c != 0) : (self.advance()) {}

    return self.input[position..self.position];
}

fn read_block_comment(self: *Self) []const u8 {
    const position = self.position;

    while (!(self.c == '-' and self.peek_char() == '}')) : (self.advance()) {}

    self.advance();
    self.advance();

    return self.input[position..self.position];
}

fn read_string_literal(self: *Self) []const u8 {
    const position = self.position;

    self.advance();
    while (self.c != '"' and self.c != 0) : (self.advance()) {}
    self.advance();

    return self.input[position..self.position];
}

fn read_integer_literal(self: *Self) []const u8 {
    const position = self.position;

    while (std.ascii.isDigit(self.c) or self.c == '_') : (self.advance()) {}

    return self.input[position..self.position];
}

fn eat_whitespace(self: *Self) void {
    // Don't eat up spaces as they are valid tokens in ELM
    while (self.c == ' ' or self.c == '\t' or self.c == '\n' or self.c == '\r') : (self.advance()) {
        if (self.c == '\n' or self.c == 'r') {
            self.*.line += 1;
            self.*.last_line_position = self.position;
        }
    }
}

fn peek_char(self: *Self) u8 {
    if (self.next_position + 1 >= self.input.len) {
        return 0;
    } else {
        return self.input[self.next_position];
    }
}

fn advance(self: *Self) void {
    if (self.next_position + 1 >= self.input.len) {
        self.*.c = 0;
    } else {
        self.*.c = self.input[self.next_position];
    }

    self.*.position = self.next_position;
    self.*.next_position += 1;
}
