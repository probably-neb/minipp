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

fn allReturnPathsExistInner(ast: *const Ast, start: usize, end: usize) bool {
    // TODO:
    // decend the tree if we hit a conditional call a function that checks if the conditional
    // has a return statement, if both sides return then we are good.
    // otherwise continue decending for a fall through.
    // if there is no final return statment throw an error
    var result = false;
    var cursor = start;
    while (cursor < end) {
        const i = cursor;
        cursor += 1;

        const node = ast.get(i);
        if (node.kind == .Return) {
            // found return, can ignore rest of block
            result = true;
            break;
        }
        if (node.kind != .ConditionalIf) {
            // we don't care about non conditional nodes
            continue;
        }

        var returnsInThenCase = true;
        // defaults to true in case there is no else case
        var returnsInElseCase = true;
        var returnsInTrailing = false;

        const ifNode = node.kind.ConditionalIf;

        _ = returnsInTrailing;

        var trailingNodesStart: usize = undefined;
        const trailingNodesEnd = end;
        var fallthroughReq = false;

        if (ifNode.isIfElse(ast)) {
            const ifElseNode = ast.get(ifNode.block).kind.ConditionalIfElse;

            returnsInThenCase = allReturnPathsExistInner(ast, ifElseNode.ifBlock, ifElseNode.elseBlock);

            // now default returnsInElse to false because there is an else block
            returnsInElseCase = false;
            const elseBlockRange = ast.get(ifElseNode.elseBlock).kind.Block.range(ast);
            if (elseBlockRange) |range| {
                const elseBlockStart = range[0];
                const elseBlockEnd = range[1] + 1;
                returnsInElseCase = allReturnPathsExistInner(ast, elseBlockStart, elseBlockEnd);
                fallthroughReq = !returnsInElseCase;

                trailingNodesStart = elseBlockEnd + 1;
            } else {
                trailingNodesStart = ifElseNode.elseBlock + 1;
            }
        } else {
            fallthroughReq = true;
            const ifNodeBlock = ast.get(ifNode.block).kind.Block;
            const ifNodeBlockRange = ifNodeBlock.range(ast);
            if (ifNodeBlockRange) |range| {
                const ifNodeStart = range[0];
                const ifNodeEnd = range[1] + 1;
                returnsInThenCase = allReturnPathsExistInner(ast, ifNodeStart, ifNodeEnd);

                trailingNodesStart = ifNodeEnd;
            } else {
                returnsInThenCase = false;
                trailingNodesStart = ifNode.block + 1;
            }
        }
        const returnsInTrailingNodes = allReturnPathsExistInner(ast, trailingNodesStart, trailingNodesEnd);
        // print the trailing nodes
        if (fallthroughReq) {
            result = returnsInTrailingNodes;
        } else {
            result = (returnsInThenCase and returnsInElseCase);
        }
        break;
    }
    return result;
}

fn allReturnPathsExist(ast: *const Ast, func: Ast.Node.Kind.FunctionType) SemaError!void {
    const returnType = func.getReturnType(ast).?;
    const statementList = func.getBody(ast).getStatementList();
    if (returnType == .Void and statementList == null) {
        return;
    }
    const statList = statementList.?;
    const funcEnd = ast.findIndex(.FunctionEnd, statList).?;

    const ok = allReturnPathsExistInner(ast, statList, funcEnd);
    if (!ok) {
        return SemaError.InvalidReturnPath;
    }
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

test "sema.returns_in_both_sides_of_if_else" {
    const source = "fun main() bool {if (true) {return true;} else {return false;}}";
    const ast = try testMe(source);
    try allFunctionsHaveValidReturnPaths(&ast);
}

test "sema.not_all_paths_return" {
    const source = "fun main() bool {if (true) {return true;}}";
    const ast = try testMe(source);
    try ting.expectEqual(ast.numNodes(.Return, 0), 1);
    const result = allFunctionsHaveValidReturnPaths(&ast);
    try ting.expectError(SemaError.InvalidReturnPath, result);
}

test "sema.not_all_paths_return_in_nested_if" {
    const source = "fun main() bool {if (true) {if (false) {return true;} else {return false;}}}";
    const ast = try testMe(source);
    try ting.expectEqual(ast.numNodes(.Return, 0), 2);
    const result = allFunctionsHaveValidReturnPaths(&ast);
    try ting.expectError(SemaError.InvalidReturnPath, result);
}

test "sema.nested_fallthrough_fail_on_ifelse" {
    const source = "fun main() bool {if (true) {if (false) {if(true){return true;}} else {return false;}}}";
    const ast = try testMe(source);
    try ting.expectEqual(ast.numNodes(.Return, 0), 2);
    const result = allFunctionsHaveValidReturnPaths(&ast);
    try ting.expectError(SemaError.InvalidReturnPath, result);
}

test "sema.super_nested_fallthrough_fail_on_ifelse" {
    const source = "fun main() bool {if (true) {if (false) {if(true){if(false){return true;}} else {return false;}}}}";
    const ast = try testMe(source);
    try ting.expectEqual(ast.numNodes(.Return, 0), 2);
    const result = allFunctionsHaveValidReturnPaths(&ast);
    try ting.expectError(SemaError.InvalidReturnPath, result);
}
