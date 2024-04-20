// AST (possibly borqed) -> AST (not borqed)

const std = @import("std");

const Ast = @import("ast.zig");
const utils = @import("utils.zig");
const log = @import("log.zig");

const SemaError = error{
    NoMain,
    InvalidReturnPath,
};

const MAIN: []const u8 = "main";

fn ensureHasMain(ast: *const Ast) SemaError!void {
    var funcs = ast.iterFuncs();
    while (funcs.next()) |func| {
        const name = func.getName(ast);
        if (std.mem.eql(u8, name, MAIN)) {
            return;
        }
    }
    return error.NoMain;
}

fn allFunctionsHaveValidReturnPaths(ast: *const Ast) !void {
    var funcs = ast.iterFuncs();
    while (funcs.next()) |func| {
        try allReturnPathsHaveReturnType(ast, func);
    }
    return;
}

fn allReturnPathsHaveReturnType(ast: *const Ast, func: Ast.Node.Kind.FunctionType) SemaError!void {
    const funcName = func.getName(ast);
    const returnType = func.getReturnType(ast);
    // std.debug.print("ast = {any}\n", .{ast.*});
    var returnExprs = func.getBody(ast).iterReturns(ast);
    var checked: usize = 0;
    while (returnExprs.next()) |returnExpr| {
        checked += 1;
        if (returnExpr.expr == null and returnType == null) {
            // void return valid for void function
            continue;
        }
        if (returnExpr.expr != null and returnType == null) {
            // void return invalid for non-void function
            // FIXME: determine if this an error or a warning that the returned value will not be used?
            log.err("Expected function {s} to return `void`, but found Return expression: {any}\n", .{ funcName, returnExpr });
            return SemaError.InvalidReturnPath;
        }
        if (returnExpr.expr == null and returnType != null) {
            log.err("Expected function {s} to return {any}, but found Return type: {any}\n", .{ funcName, returnExpr, returnType });
            return SemaError.InvalidReturnPath;
        }
        if (returnExpr.expr) |expr| {
            if (returnType) |retTy| {
                _ = expr;
                _ = retTy;
                utils.todo("Checking expression types not implemented\n", .{});
            }
        }
    }
    return;
}

fn getExpressionType(ast: *const Ast, exprNode: Ast.Node.Kind) !Ast.Type {
    _ = ast;
    const expr = exprNode.Expression;
    const token = exprNode.token;
    _ = token;
    switch (expr) {}
}

///////////
// TESTS //
///////////

const ting = std.testing;
const debugAlloc = std.heap.page_allocator;

fn testMe(input: []const u8) !Ast {
    const tokens = try @import("lexer.zig").Lexer.tokenizeFromStr(input, debugAlloc);
    const parser = try @import("parser.zig").Parser.parseTokens(tokens, input, debugAlloc);
    const ast = Ast.initFromParser(parser);
    return ast;
}

test "sema.no_main" {
    const source = "fun foo() void {return;}";
    const ast = try testMe(source);
    try ting.expectError(SemaError.NoMain, ensureHasMain(&ast));
}

test "sema.has_main" {
    defer log.print();
    const source = "fun main() void {return;}";
    const ast = try testMe(source);
    try ensureHasMain(&ast);
}

test "sema.not_all_return_paths_same_type" {
    const source = "fun main() void {if (true) {return;} else {return 1;}}";
    const ast = try testMe(source);
    try ting.expectEqual(ast.numNodes(.Return, 0), 2);
    const result = allFunctionsHaveValidReturnPaths(&ast);
    try ting.expectError(SemaError.InvalidReturnPath, result);
}

test "sema.all_return_paths_same_type" {
    const source = "fun main() void {if (true) {return;} else {return;} return;}";
    const ast = try testMe(source);
    try allFunctionsHaveValidReturnPaths(&ast);
}
