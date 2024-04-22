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
        try allReturnPathsExist(ast, func);
    }
    return;
}

/// note that the ast must be sliced to start at some function for this function
/// to work
fn allReturnPathsHaveReturnType(ast: *const Ast, func: Ast.Node.Kind.FunctionType) SemaError!void {

    // Get the name
    const funcName = func.getName(ast);
    // Get the return type
    const returnType = func.getReturnType(ast).?;
    // std.debug.print("ast = {any}\n", .{ast.*});

    // Get all return expressions
    // This is in the form of there being the first and last expression within the statment list of the functio
    var returnExprs = func.getBody(ast).iterReturns(ast);
    var checked: usize = 0;
    while (returnExprs.next()) |returnExpr| {
        checked += 1;
        if (returnExpr.expr == null and returnType == .Void) {
            // void return valid for void function
            continue;
        }
        // FIXME: this may or may not be invalid.
        if (returnExpr.expr != null and returnType == .Void) {
            // void return invalid for non-void function
            // FIXME: determine if this an error or a warning that the returned value will not be used?
            log.err("Expected function {s} to return `void`, but found Return expression: {any}\n", .{ funcName, returnExpr });
            return SemaError.InvalidReturnPath;
        }

        if (returnExpr.expr == null and returnType != .Void) {
            log.err("Expected function {s} to return {any}, but found Return type: {any}\n", .{ funcName, returnExpr, returnType });
            return SemaError.InvalidReturnPath;
        }

        // TODO: FIXME
        // if (returnExpr.expr) |expr| {
        //     if (returnType) |retTy| {
        //         _ = expr;
        //         _ = retTy;
        //         utils.todo("Checking expression types not implemented\n", .{});
        //     } else unreachable;
        // } else unreachable;
    }
    return;
}

fn allReturnPathsExist(ast: *const Ast, func: Ast.Node.Kind.FunctionType) SemaError!void {
    const returnType = func.getReturnType(ast).?;
    const statementList = func.getBody(ast).getStatementList();
    if (returnType == .Void and statementList == null) {
        return;
    }
    const statList = statementList.?;
    const funcEnd = ast.findIndex(.FunctionEnd, statList).?;
    // TODO:
    // decend the tree if we hit a conditional call a function that checks if the conditional
    // has a return statement, if both sides return then we are good.
    // otherwise continue decending for a fall through.
    // if there is no final return statment throw an error
    _ = funcEnd;

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

test "sema.not_all_return_paths_void" {
    const source = "fun main() void {if (true) {return;} else {return 1;}}";
    const ast = try testMe(source);
    try ting.expectEqual(ast.numNodes(.Return, 0), 2);
    const result = allFunctionsHaveValidReturnPaths(&ast);
    try ting.expectError(SemaError.InvalidReturnPath, result);
}

test "sema.all_return_paths_void" {
    const source = "fun main() void {if (true) {return;} else {return;} return;}";
    const ast = try testMe(source);
    try allFunctionsHaveValidReturnPaths(&ast);
}

test "sema.all_return_paths_bool" {
    const source = "fun main() bool {if (true) {return true;} else {return false;}}";
    const ast = try testMe(source);
    try allFunctionsHaveValidReturnPaths(&ast);
}
