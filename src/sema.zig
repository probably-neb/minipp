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

// Done
pub fn typeCheckFunction(ast: *Ast, func: Ast.Node.Kind.FunctionType) !void {
    const functionName = func.getName(ast);
    const returnType = func.getReturnType(ast).?;

    var statementList = func.getBody(ast).getStatementList();
    if (statementList == null) {
        return;
    }
    try typeCheckStatementList(ast, statementList, functionName, returnType);
}

// Done
pub fn typeCheckStatementList(ast: *Ast, statementList: Ast.Node.Kind.StatementList, fName: []const u8, returnType: Ast.Type) !void {
    const list = statementList.getList();
    for (list) |statement| {
        try typeCheckStatement(ast, statement, fName, returnType);
    }
}

pub fn typeCheckStatement(ast: *Ast, statement: Ast.Node, fName: []const u8, returnType: Ast.Type) !void {
    _ = returnType;
    _ = fName;
    _ = ast;
    const node = statement.kind.Statement;
    _ = node;
}

// Done
pub fn typeCheckBlock(ast: *Ast, block: Ast.Node.Kind.Block, fName: []const u8, returnType: Ast.Type) !void {
    // Block to statement list
    const statementIndex = block.statements;
    if (statementIndex == null) {
        return;
    }
    const statementList = ast.get(statementIndex).kind.StatementList;
    try typeCheckStatementList(ast, statementList, fName, returnType);
}

// Done
pub fn typeCheckAssignment(ast: *Ast, assignment: Ast.Node.Kind.Assignment, fName: []const u8, returnType: Ast.Type) !void {
    const left = assignment.left;
    const right = assignment.right;
    if (left == null) {
        utils.todo("Error on assignment type checking\n", .{});
        return;
    }
    if (right == null) {
        utils.todo("Error on assignment type checking\n", .{});
        return;
    }
    // check if right is type read
    const leftType = Ast.Node.Kind.LValue.getType(left, ast, fName);
    if (leftType == null) {
        utils.todo("Error on assignment type checking\n", .{});
        return;
    }
    const rightNode = ast.get(right.?).kind;
    if (rightNode == .Read) {
        const readType = Ast.Type{.Int};
        // expect lhs to be of type int
        if (!leftType.equals(readType)) {
            std.debug.print("Error on assignment type checking\n");
            std.debug.print("must read to an int type\n");
            return error.InvalidType;
        }
    }

    // right hand side is an expression
    const rightExpr = ast.get(right.?).kind.Expression;
    const rightType = try getAndCheckTypeExpression(ast, rightExpr, fName, returnType);
    if (rightType == null) {
        utils.todo("Error on assignment type checking\n", .{});
        return error.InvalidType;
    }
    if (!leftType.equals(rightType)) {
        utils.todo("Error on assignment type checking\n", .{});
        return error.InvalidType;
    }
}

// Done
pub fn typeCheckPrint(ast: *Ast, print: Ast.Node.Kind.Print, fName: []const u8, returnType: Ast.Type) !void {
    const expr = print.expr;
    const exprType = try getAndCheckTypeExpression(ast, expr, fName, returnType);
    if (exprType == null) {
        utils.todo("Error on print type checking\n", .{});
        return error.InvalidType;
    }
    if (!exprType.equals(Ast.Type{.Int})) {
        utils.todo("Error on print type checking\n", .{});
        return error.InvalidType;
    }
}

// Done
pub fn typeCheckConditional(ast: *Ast, conditional: Ast.Node.Kind.ConditionalIfType, fName: []const u8, returnType: Ast.Type) !void {
    // first check if conditional is bool
    const cond = conditional.cond;
    const condNode = ast.get(cond).kind.Expression;
    const condType = try getAndCheckTypeExpression(ast, condNode, fName, returnType);
    if (condType == null) {
        utils.todo("Error on conditional type checking\n", .{});
        return error.InvalidType;
    }
    if (!condType.equals(Ast.Type{.Bool})) {
        utils.todo("Error on conditional type checking\n", .{});
        return error.InvalidType;
    }

    const isIfElse = conditional.isIfElse(ast);
    if (isIfElse) {
        const ifElseNode = ast.get(conditional.block).kind.ConditionalIfElse;
        const ifBlockNode = ast.get(ifElseNode.ifBlock).kind.Block;
        const elseBlockNode = ast.get(ifElseNode.elseBlock).kind.Block;
        try typeCheckBlock(ast, ifBlockNode, fName, returnType);
        try typeCheckBlock(ast, elseBlockNode, fName, returnType);
    } else {
        const ifBlockNode = ast.get(conditional.block).kind.Block;
        try typeCheckBlock(ast, ifBlockNode, fName, returnType);
    }
}

// Done
pub fn typeCheckWhile(ast: *Ast, while_n: Ast.Node.Kind.While, fName: []const u8, returnType: Ast.Type) !void {
    // first check if conditional is bool
    const cond = while_n.cond;
    const condNode = ast.get(cond).kind.Expression;
    const condType = try getAndCheckTypeExpression(ast, condNode, fName, returnType);
    if (condType == null) {
        utils.todo("Error on while type checking\n", .{});
        return error.InvalidType;
    }
    if (!condType.equals(Ast.Type{.Bool})) {
        utils.todo("Error on while type checking\n", .{});
        return error.InvalidType;
    }

    const blockNode = ast.get(while_n.block).kind.Block;
    try typeCheckBlock(ast, blockNode, fName, returnType);
}

// Done
pub fn typeCheckDelete(ast: *Ast, delete: Ast.Node.Kind.Delete, fName: []const u8, returnType: Ast.Type) !void {
    const expr = delete.expr;
    const exprNode = ast.get(expr).kind.Expression;
    const exprType = try getAndCheckTypeExpression(ast, exprNode, fName, returnType);
    if (exprType == null) {
        utils.todo("Error on delete type checking\n", .{});
        return error.InvalidType;
    }
    // expect a struct of some form
    // FIXME:
    if (exprType.kind != .Struct) {
        utils.todo("Error on delete type checking\n", .{});
        return error.InvalidType;
    }
}

// Done
pub fn typeCheckReturn(ast: *Ast, ret: Ast.Node.Kind.Return, fName: []const u8, returnType: Ast.Type) !void {
    const expr = ret.expr;
    if (expr == null) {
        if (!returnType.equals(Ast.Type{.Void})) {
            utils.todo("Error on return type checking\n", .{});
            return error.InvalidType;
        }
        return;
    }
    const exprNode = ast.get(expr).kind.Expression;
    const exprType = try getAndCheckTypeExpression(ast, exprNode, fName, returnType);
    if (exprType == null) {
        utils.todo("Error on return type checking\n", .{});
        return error.InvalidType;
    }
    if (!exprType.equals(returnType)) {
        utils.todo("Error on return type checking\n", .{});
        return error.InvalidType;
    }
}

// Done
pub fn getAndCheckInvocation(ast: *Ast, invocation: Ast.Node.Kind.Invocation, fName: []const u8, returnType: Ast.Type) !Ast.Type {
    _ = returnType;
    _ = fName;
    const funcName = ast.get(invocation.funcName).token._range.getSubStrFromStr(ast.input);
    const func = ast.getFunctionFromName(funcName);
    if (func == null) {
        utils.todo("Error on invocation type checking\n", .{});
        return;
    }
    // check the arguments
    const args = invocation.args;
    const funcProto = ast.get(func.?.proto).kind.FunctionProto.parameters;
    if (args == null) {
        // check the definition of the function
        if (funcProto == null) {
            return Ast.Type{.Void};
        } else {
            utils.todo("Error on invocation type checking\n", .{});
            return error.InvalidFunctionCall;
        }
    }

    var argsList = Ast.Node.Kind.Argument.getArgumentTypes(args, ast);
    var funcPList = Ast.Node.Kind.Parameter.getParamTypes(funcProto, ast);

    if (argsList == null) {
        if (funcPList == null) {
            // return the return type of the function
            return ast.getFunctionReturnTypeFromName(funcName);
        }
        utils.todo("Error on invocation type checking\n", .{});
        return error.InvalidFunctionCall;
    }

    if (funcPList == null) {
        utils.todo("Error on invocation type checking\n", .{});
        return error.InvalidFunctionCall;
    }

    funcPList = funcPList.?;
    argsList = argsList.?;
    if (argsList.len != funcPList.len) {
        utils.todo("Error on invocation type checking\n", .{});
        return error.InvalidFunctionCall;
    }

    var i: usize = 0;
    while (i < argsList.len) {
        const argType = argsList[i];
        const paramType = funcPList[i];
        if (!argType.equals(paramType)) {
            utils.todo("Error on invocation type checking\n", .{});
            return error.InvalidFunctionCall;
        }
        i += 1;
    }

    return try ast.getFunctionReturnTypeFromName(funcName);
}

// Done
pub fn getAndCheckTypeExpression(ast: *Ast, expr: Ast.Node.Kind.Expression, fName: []const u8, returnType: Ast.Type) !Ast.Type {
    // get the type of the expression
    const node = ast.get(expr.expr);
    const kind = node.kind;
    switch (kind) {
        .BinaryOperation => {
            return try ast.getAndCheckBinaryOperation(ast, node, fName, returnType);
        },
        .UnaryOperation => {
            return try ast.getAndCheckUnaryOperation(ast, node, fName, returnType);
        },
        .Factor => {
            return try ast.getAndCheckFactor(ast, kind.Factor, fName, returnType);
        },
        else => {
            utils.todo("Error on expression type checking\n", .{});
            return error.InvalidType;
        },
    }
}

pub fn getAndCheckBinaryOperation(ast: *Ast, binaryOp: Ast.Node, fName: []const u8, returnType: Ast.Type) !Ast.Type {
    const token = binaryOp.token;
    FIXME: this is where I am working right now!
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
