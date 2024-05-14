// AST (possibly borqed) -> AST (not borqed)

const std = @import("std");

const Ast = @import("ast.zig");
const utils = @import("utils.zig");
const log = @import("log.zig");

const SemaError = error{
    NoMain,
    InvalidReturnPath,
};

const TypeError = error{
    InvalidType,
    InvalidToken,
    InvalidFunctionCall,
    OutOfBounds,
    OutOfMemory,
    ReturnTypeNotVoid,
    InvalidReturnType,
    InvalidAssignmentType,
    InvalidReadExptedTypeInt,
    InvalidAssignmentNoDeclaration,
    StructHasNoMember,
    BinaryOperationTypeMismatch,
    InvalidBinaryOperationType,
    InvalidTypeExptectedInt,
    InvalidTypeExpectedBool,
    InvalidFunctionCallNoDefinedArguments,
    NoSuchFunction,
    FunctionParametersMustNotBeShadowed,
    FunctionParametersMustBeUnique,
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
    errdefer log.err("Function: {s}\n", .{funcName});
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
    errdefer log.err("Function: {s}\n", .{func.getName(ast)});
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

pub fn typeCheck(ast: *const Ast) !void {
    // get all functions out of map
    var funcsKeys = ast.functionMap.keyIterator();
    while (funcsKeys.next()) |key| {
        const func = ast.getFunctionFromName(key.*).?;
        try typeCheckFunction(ast, func.*);
    }
}

// Done
pub fn typeCheckFunction(ast: *const Ast, func: Ast.Node) TypeError!void {
    // errdefer ast.printNodeLine(func);
    var fc = func.kind.Function;
    const functionName = fc.getName(ast);
    const returnType = fc.getReturnType(ast).?;
    const fBody = ast.get(fc.body).*;
    const fstatementsIndex = fBody.kind.FunctionBody.statements;
    if (fstatementsIndex == null) {
        log.trace("wahoo \n", .{});
    }
    if (fstatementsIndex == null) {
        return;
    }
    // ensure that there are no local declarations with the same name as the parameters
    // get the parameters
    const fProto = ast.get(fc.proto).*.kind.FunctionProto.parameters;
    if (fProto != null) {
        const paraMNodes = ast.get(fProto.?).*.kind.Parameters;
        const last = paraMNodes.lastParam orelse paraMNodes.firstParam.? + 1;
        var paramNames = std.StringHashMap(bool).init(ast.allocator);
        var iter: ?usize = paraMNodes.firstParam;
        while (iter != null) {
            const param = ast.get(iter.?).*;
            const ident = ast.get(param.kind.TypedIdentifier.ident).token._range.getSubStrFromStr(ast.input);
            // find if the ident is already in the list
            if (paramNames.contains(ident)) {
                return error.FunctionParametersMustBeUnique;
            }
            const declMe = ast.getFunctionDeclarationTypeFromName(functionName, ident);
            if (declMe != null) {
                return error.FunctionParametersMustNotBeShadowed;
            }
            try paramNames.put(ident, true);
            iter = ast.findIndexWithin(.TypedIdentifier, iter.? + 1, last + 1);
        }
        paramNames.deinit();
        // for each of the parameters check that there is no local declaration with the same name
    }
    try typeCheckStatementList(ast, fstatementsIndex, functionName, returnType);
}

// Done
pub fn typeCheckStatementList(ast: *const Ast, statementListn: ?usize, fName: []const u8, returnType: Ast.Type) TypeError!void {
    // errdefer if (statementListn) |lst| ast.printNodeLine(ast.get(lst).*);
    // log.trace("statementListn: {d}\n", .{statementListn.?});
    const list = try StatemenListgetList(statementListn, ast);
    if (list == null) {
        return;
    }
    for (list.?) |statement| {
        // log.trace("Statement {any}\n", .{statement});
        const statNode = ast.get(statement).*;
        try typeCheckStatement(ast, statNode, fName, returnType);
    }
}

pub fn typeCheckStatement(ast: *const Ast, statement: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!void {
    // errdefer ast.printNodeLine(statement);
    const kind = statement.kind;
    _ = switch (kind) {
        .Block => {
            try typeCheckBlock(ast, statement, fName, returnType);
            return;
        },
        .Assignment => {
            try typeCheckAssignment(ast, statement, fName, returnType);
            return;
        },
        .Print => {
            try typeCheckPrint(ast, statement, fName, returnType);
            return;
        },
        .ConditionalIf => {
            try typeCheckConditional(ast, statement, fName, returnType);
            return;
        },
        .While => {
            try typeCheckWhile(ast, statement, fName, returnType);
            return;
        },
        .Delete => {
            try typeCheckDelete(ast, statement, fName, returnType);
            return;
        },
        .Return => {
            try typeCheckReturn(ast, statement, fName, returnType);
            return;
        },
        .Invocation => {
            _ = try getAndCheckInvocation(ast, statement, fName, returnType);
            return;
        },
        else => {
            utils.todo("Error on statement type checking\n", .{});
            return error.InvalidType;
        },
    };
    return error.InvalidType;
}

// Done
pub fn typeCheckBlock(ast: *const Ast, blockn: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!void {
    // errdefer ast.printNodeLine(blockn);
    // Block to statement list
    const block = blockn.kind.Block;
    const statementIndex = block.statements;
    if (statementIndex == null) {
        return;
    }
    try typeCheckStatementList(ast, statementIndex.?, fName, returnType);
}

// Done
pub fn typeCheckAssignment(ast: *const Ast, assignmentn: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!void {
    // errdefer ast.printNodeLine(assignmentn);
    const assignment = assignmentn.kind.Assignment;
    const left = assignment.lhs;
    const right = assignment.rhs;
    // assignment can't be null silly!
    // if (left == null) {
    //     utils.todo("Error on assignment type checking\n", .{});
    //     return;
    // }
    // if (right == null) {
    //     utils.todo("Error on assignment type checking\n", .{});
    //     return;
    // }
    // check if right is type read
    const leftType = try LValuegetType(left, ast, fName);
    if (leftType == null) {
        utils.todo("Error on assignment type checking\n", .{});
        return;
    }
    const rightNode = ast.get(right).kind;
    if (rightNode == .Read) {
        const readType = Ast.Type.Int;
        // expect lhs to be of type int
        if (!leftType.?.equals(readType)) {
            // TODO: add error
            return error.InvalidReadExptedTypeInt;
        }
        return;
    }

    // right hand side is an expression
    const rightExpr = ast.get(right).*;
    const rightType = try getAndCheckTypeExpression(ast, rightExpr, fName, returnType);
    if (!leftType.?.equals(rightType)) {
        // FIXME: add error
        // chek if left is struct and right is null
        var lType = leftType.?;
        _ = lType;
        var rType = rightType;
        _ = rType;
        return error.InvalidAssignmentType;
    }
}

// Done
pub fn typeCheckPrint(ast: *const Ast, printn: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!void {
    // errdefer ast.printNodeLine(printn);
    const print = printn.kind.Print;
    const expr = print.expr;
    const exprNode = ast.get(expr).*;
    const exprType = try getAndCheckTypeExpression(ast, exprNode, fName, returnType);
    if (!exprType.equals(Ast.Type.Int)) {
        // TODO: add error
        return TypeError.InvalidReadExptedTypeInt;
    }
}

// Done
pub fn typeCheckConditional(ast: *const Ast, conditionaln: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!void {
    // errdefer ast.printNodeLine(conditionaln);
    // first check if conditional is bool
    const conditional = conditionaln.kind.ConditionalIf;
    const cond = conditional.cond;
    const condNode = ast.get(cond).*;
    const condType = try getAndCheckTypeExpression(ast, condNode, fName, returnType);
    if (!condType.equals(Ast.Type.Bool)) {
        utils.todo("Error on conditional type checking\n", .{});
        return error.InvalidType;
    }

    const isIfElse = conditional.isIfElse(ast);
    if (isIfElse) {
        const ifElseNode = ast.get(conditional.block).kind.ConditionalIfElse;
        const ifBlockNode = ast.get(ifElseNode.ifBlock).*;
        const elseBlockNode = ast.get(ifElseNode.elseBlock).*;
        try typeCheckBlock(ast, ifBlockNode, fName, returnType);
        try typeCheckBlock(ast, elseBlockNode, fName, returnType);
    } else {
        const ifBlockNode = ast.get(conditional.block).*;
        try typeCheckBlock(ast, ifBlockNode, fName, returnType);
    }
}

// Done
pub fn typeCheckWhile(ast: *const Ast, while_nN: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!void {
    // errdefer ast.printNodeLine(while_nN);
    // first check if conditional is bool
    const while_n = while_nN.kind.While;
    const cond = while_n.cond;
    const condNode = ast.get(cond).*;
    const condType = try getAndCheckTypeExpression(ast, condNode, fName, returnType);
    if (!condType.equals(Ast.Type.Bool)) {
        utils.todo("Error on while type checking\n", .{});
        return error.InvalidType;
    }

    const blockNode = ast.get(while_n.block).*;
    try typeCheckBlock(ast, blockNode, fName, returnType);
}

// Done
pub fn typeCheckDelete(ast: *const Ast, deleten: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!void {
    // errdefer ast.printNodeLine(deleten);
    const delete = deleten.kind.Delete;
    const expr = delete.expr;
    const exprNode = ast.get(expr).*;
    const exprType = try getAndCheckTypeExpression(ast, exprNode, fName, returnType);
    if (!exprType.equalsNoCont(Ast.Type{ .Struct = "cunny" })) {
        utils.todo("Error on delete type checking\n", .{});
        return error.InvalidType;
    }
}

// Done
pub fn typeCheckReturn(ast: *const Ast, retn: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!void {
    // errdefer ast.printNodeLine(retn);
    const ret = retn.kind.Return;
    const expr = ret.expr;
    if (expr == null) {
        if (!returnType.equals(Ast.Type.Void)) {
            return error.ReturnTypeNotVoid;
        }
        return;
    }
    const exprNode = ast.get(expr.?).*;
    const exprType = try getAndCheckTypeExpression(ast, exprNode, fName, returnType);
    if (!exprType.equals(returnType)) {
        // FIXME: add proper error
        return error.InvalidReturnType;
    }
}

// Done
pub fn getAndCheckInvocation(ast: *const Ast, invocationn: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!Ast.Type {
    // errdefer ast.printNodeLine(invocationn);
    const invocation = invocationn.kind.Invocation;
    const funcName = ast.get(invocation.funcName).token._range.getSubStrFromStr(ast.input);
    const func = ast.getFunctionFromName(funcName);

    if (func == null) {
        utils.todo("Error on invocation type checking\n", .{});
        return error.InvalidFunctionCall;
    }
    // check the arguments
    const args = invocation.args;
    const funcProto = ast.get(func.?.kind.Function.proto).*.kind.FunctionProto.parameters;
    if (args == null) {
        // check the definition of the function
        if (funcProto == null) {
            return ast.getFunctionReturnTypeFromName(funcName).?;
        } else {
            return error.InvalidFunctionCallNoDefinedArguments;
        }
    }

    var argsList = try ArgumentsgetArgumentTypes(args, ast, fName, returnType);
    var funcPList = try ParametergetParamTypes(funcProto, ast);

    if (argsList == null) {
        if (funcPList == null) {
            // return the return type of the function
            const temp = ast.getFunctionReturnTypeFromName(funcName);
            if (temp == null) {
                return error.NoSuchFunction;
            }
            return temp.?;
        }
        // This occurs when the function has no arguments
        // but the function has parameters
        return error.InvalidFunctionCallNoDefinedArguments;
    }

    if (funcPList == null) {
        utils.todo("Error on invocation type checking\n", .{});
        return error.InvalidFunctionCall;
    }

    funcPList = funcPList.?;
    argsList = argsList.?;
    if (argsList.?.len != funcPList.?.len) {
        // print the position of argslist
        return error.InvalidFunctionCall;
    }

    var i: usize = 0;
    while (i < argsList.?.len) {
        const argType = argsList.?[i];
        const paramType = funcPList.?[i];
        if (argType.equals(Ast.Type.Null)) {
            if (!paramType.isStruct()) {
                // print them out
                log.trace("argType: {s}\n", .{@tagName(argType)});
                log.trace("paramType: {s}\n", .{@tagName(paramType)});
                return error.InvalidFunctionCall;
            }
        } else if (!argType.equals(paramType)) {
            log.trace("argType: {s}\n", .{@tagName(argType)});
            log.trace("paramType: {s}\n", .{@tagName(paramType)});
            if (argType.isStruct()) {
                log.trace("argType: {s}\n", .{argType.Struct});
            }
            if (paramType.isStruct()) {
                log.trace("paramType: {s}\n", .{paramType.Struct});
            }
            return error.InvalidFunctionCall;
        }
        i += 1;
    }

    return ast.getFunctionReturnTypeFromName(funcName).?;
}

// Done
pub fn getAndCheckTypeExpression(ast: *const Ast, exprn: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!Ast.Type {
    // errdefer ast.printNodeLine(exprn);
    switch (exprn.kind) {
        .BinaryOperation => {
            return try getAndCheckBinaryOperation(ast, exprn, fName, returnType);
        },
        .UnaryOperation => {
            return try getAndCheckUnaryOperation(ast, exprn, fName, returnType);
        },
        .Selector => {
            return try getAndCheckSelector(ast, exprn, fName, returnType);
        },
        .Expression => {
            const expr = exprn.kind.Expression;
            // get the type of the expression
            const node = ast.get(expr.expr).*;
            const kind = node.kind;
            switch (kind) {
                .BinaryOperation => {
                    return try getAndCheckBinaryOperation(ast, node, fName, returnType);
                },
                .UnaryOperation => {
                    return try getAndCheckUnaryOperation(ast, node, fName, returnType);
                },
                .Selector => {
                    return try getAndCheckSelector(ast, node, fName, returnType);
                },
                else => {
                    utils.todo("Error on expression type checking\n", .{});
                    return error.InvalidType;
                },
            }
        },
        else => {
            log.trace("exprn.kind: {any}\n", .{exprn.kind});
            // print the index into the ast
            utils.todo("Error on expression type checking\n", .{});
            return error.InvalidType;
        },
    }
}

// TODO: fix the errors
pub fn getAndCheckBinaryOperation(ast: *const Ast, binaryOp: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!Ast.Type {
    // errdefer ast.printNodeLine(binaryOp);
    const token = binaryOp.token;
    switch (token.kind) {
        .Lt, .Gt, .GtEq, .LtEq, .DoubleEq, .NotEq => {
            const lhsExpr = ast.get(binaryOp.kind.BinaryOperation.lhs).*;
            const rhsExpr = ast.get(binaryOp.kind.BinaryOperation.rhs).*;
            const lhsType = try getAndCheckTypeExpression(ast, lhsExpr, fName, returnType);
            const rhsType = try getAndCheckTypeExpression(ast, rhsExpr, fName, returnType);
            // log the types
            // log.trace("lhsType: {s}\n", .{@tagName(lhsType)});
            // log.trace("rhsType: {s}\n", .{@tagName(rhsType)});
            if (!lhsType.equals(rhsType)) {
                // check if the types are struct and null
                if (lhsType.equals(Ast.Type.Null) and rhsType.isStruct()) {
                    return Ast.Type.Bool;
                }
                if (lhsType.isStruct() and rhsType.equals(Ast.Type.Null)) {
                    return Ast.Type.Bool;
                }
                return error.BinaryOperationTypeMismatch;
            }
            if (lhsType != .Int and lhsType != .Struct and lhsType != .Null) {
                return error.InvalidBinaryOperationType;
            }
            return Ast.Type.Bool;
        },
        .Or, .And => {
            const lhsExpr = ast.get(binaryOp.kind.BinaryOperation.lhs).*;
            const rhsExpr = ast.get(binaryOp.kind.BinaryOperation.rhs).*;
            const lhsType = try getAndCheckTypeExpression(ast, lhsExpr, fName, returnType);
            const rhsType = try getAndCheckTypeExpression(ast, rhsExpr, fName, returnType);

            if (!lhsType.equals(rhsType)) {
                return error.BinaryOperationTypeMismatch;
            }
            if (!lhsType.equals(Ast.Type.Bool)) {
                return error.InvalidTypeExpectedBool;
            }
            return Ast.Type.Bool;
        },
        .Mul,
        .Minus,
        .Plus,
        .Div,
        => {
            const lhsExpr = ast.get(binaryOp.kind.BinaryOperation.lhs).*;
            const rhsExpr = ast.get(binaryOp.kind.BinaryOperation.rhs).*;
            const lhsType = try getAndCheckTypeExpression(ast, lhsExpr, fName, returnType);
            const rhsType = try getAndCheckTypeExpression(ast, rhsExpr, fName, returnType);
            if (!lhsType.equals(rhsType)) {
                // TODO: add error
                return error.BinaryOperationTypeMismatch;
            }
            if (!lhsType.equals(Ast.Type.Int)) {
                // TODO: add error
                return error.InvalidTypeExptectedInt;
            }
            return lhsType;
        },
        else => {
            log.trace("token.kind: {any}\n", .{token.kind});
            utils.todo("Error on binary operation type checking\n", .{});
            return error.InvalidType;
        },
    }
    unreachable;
}

pub fn getAndCheckUnaryOperation(ast: *const Ast, unaryOp: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!Ast.Type {
    // errdefer ast.printNodeLine(unaryOp);
    const token = unaryOp.token;
    switch (token.kind) {
        .Not => {
            const expr = ast.get(unaryOp.kind.UnaryOperation.on).*;
            const exprType = try getAndCheckTypeExpression(ast, expr, fName, returnType);
            if (!exprType.equals(Ast.Type.Bool)) {
                return error.InvalidTypeExpectedBool;
            }
            return exprType;
        },
        .Minus => {
            const expr = ast.get(unaryOp.kind.UnaryOperation.on).*;
            const exprType = try getAndCheckTypeExpression(ast, expr, fName, returnType);
            if (!exprType.equals(Ast.Type.Int)) {
                return error.InvalidTypeExptectedInt;
            }
            return exprType;
        },
        else => {
            utils.todo("Error on unary operation type checking\n", .{});
            return error.InvalidType;
        },
    }
    unreachable;
}

pub fn getAndCheckSelector(ast: *const Ast, selectorn: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!Ast.Type {
    // errdefer ast.printNodeLine(selectorn);
    const selector = selectorn.kind.Selector;
    const factorNode = ast.get(selector.factor).*;
    const factorType = try getAndCheckFactor(ast, factorNode, fName, returnType);
    const chainType = try SelectorChaingetType(selector.chain, ast, factorType, fName, returnType);
    if (chainType == null) {
        return factorType;
    }
    return chainType.?;
}

pub fn getAndCheckFactor(ast: *const Ast, factorn: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!Ast.Type {
    // errdefer ast.printNodeLine(factorn);
    const factor = factorn.kind.Factor;
    const kind = factor.factor;
    const node = ast.get(kind).*;
    switch (node.kind) {
        .Number => return Ast.Type.Int,
        .True, .False => return Ast.Type.Bool,
        .Null => return Ast.Type.Null,
        .New => return try getAndCheckNew(ast, node),
        .NewIntArray => return getAndCheckNewIntArray(ast, node),
        .Invocation => return try getAndCheckInvocation(ast, node, fName, returnType),
        .Expression => return try getAndCheckTypeExpression(ast, node, fName, returnType),
        .Identifier => return try getAndCheckLocalIdentifier(ast, node, fName),
        else => {
            utils.todo("Error on factor type checking\n", .{});
            return error.InvalidType;
        },
    }
    unreachable;
}

pub fn getAndCheckNew(ast: *const Ast, newn: Ast.Node) TypeError!Ast.Type {
    // errdefer ast.printNodeLine(newn);
    const new = newn.kind.New;
    const name = ast.get(new.ident).token._range.getSubStrFromStr(ast.input);
    const structType = ast.getStructNodeFromName(name);
    if (structType == null) {
        utils.todo("Error on new type checking\n", .{});
        return error.InvalidType;
    }
    return Ast.Type{ .Struct = name };
}

pub fn getAndCheckNewIntArray(ast: *const Ast, newn: Ast.Node) TypeError!Ast.Type {
    // errdefer ast.printNodeLine(newn);
    const new = newn.kind.NewIntArray;
    // check that len is a number node
    const len = ast.get(new.length).kind;
    if (len != .Number) {
        utils.todo("Error on newIntArray type checking\n", .{});
        return error.InvalidType;
    }
    return Ast.Type.IntArray;
}
pub fn getAndCheckLocalIdentifier(ast: *const Ast, localId: Ast.Node, fName: []const u8) TypeError!Ast.Type {
    // errdefer ast.printNodeLine(localId);
    const token = localId.token;
    const name = token._range.getSubStrFromStr(ast.input);
    const func = ast.getFunctionFromName(fName).?.kind.Function.proto;
    const param = ast.get(func).*.kind.FunctionProto.parameters;

    const funcDecl = ast.getFunctionDeclarationTypeFromName(fName, name);
    const funcParam = try ParamatergetParamTypeFromName(param, ast, name);
    const globalDecl = ast.getDeclarationGlobalFromName(name);
    const localDecl = funcParam orelse funcDecl orelse globalDecl;
    if (localDecl == null) {
        return error.InvalidType;
    }
    return localDecl.?;
}

pub fn SelectorChaingetType(this: ?usize, ast: *const Ast, ty: Ast.Type, fName: []const u8, returnType: Ast.Type) !?Ast.Type {
    if (this == null) {
        return null;
    }

    // check if its int array or struct
    switch (ty) {
        .IntArray => {
            const chain = ast.get(this.?).kind.SelectorChain;
            // check if chain.ident is identifier or expression
            const ident = ast.get(chain.ident).kind;
            switch (ident) {
                .Identifier => {
                    return Ast.Type.IntArray;
                },
                .Expression => {
                    const expr = ident.Expression;
                    const exprNode = ast.get(expr.expr).*;
                    return try getAndCheckTypeExpression(ast, exprNode, fName, returnType);
                },
                else => {
                    return error.InvalidType;
                },
            }
        },
        .Struct => {},
        else => {
            return error.InvalidType;
        },
    }

    // get the ident of the struct
    const ident = ty.Struct;

    var result: ?Ast.Type = null;
    var tmpIdent = ident;
    var chaini = this;
    if (chaini == null) {
        return ty;
    }
    tmpIdent = ty.Struct;
    tmpIdent = ast.get(ast.getStructNodeFromName(tmpIdent).?.kind.TypeDeclaration.ident).token._range.getSubStrFromStr(ast.input);

    var chain = ast.get(chaini.?).kind.SelectorChain;
    while (true) {
        const chainIdent2 = ast.get(chain.ident);
        // check if chain.ident is identifier or expression
        switch (chainIdent2.kind) {
            .Identifier => {},
            .Expression => {
                const expr = chainIdent2.kind.Expression;
                const exprNode = ast.get(expr.expr).*;
                return try getAndCheckTypeExpression(ast, exprNode, fName, returnType);
            },
            else => {
                return error.InvalidType;
            },
        }
        const chainIdent = chainIdent2.token._range.getSubStrFromStr(ast.input);
        const field = ast.getStructFieldType(tmpIdent, chainIdent);
        if (field == null) {
            // TODO: add error
            return error.StructHasNoMember;
        }
        if (field.?.isStruct()) {
            tmpIdent = field.?.Struct;
            tmpIdent = ast.get(ast.getStructNodeFromName(tmpIdent).?.kind.TypeDeclaration.ident).token._range.getSubStrFromStr(ast.input);
        }
        result = field;
        if (chain.next == null) {
            return result;
        } else {
            chain = ast.get(chain.next.?).kind.SelectorChain;
        }
    }
}
pub fn ParametergetParamTypes(this: ?usize, ast: *const Ast) !?[]Ast.Type {
    if (this == null) {
        return null;
    }
    const self = ast.get(this.?).kind.Parameters;
    if (self.firstParam == null) {
        return null;
    }
    var last = self.lastParam;
    if (last == null) {
        last = self.firstParam.? + 1;
    }
    var list = std.ArrayList(Ast.Type).init(ast.allocator);
    var iter: ?usize = self.firstParam;
    while (iter != null) {
        const param = ast.get(iter.?).*;
        // find next TypedIdentifier
        iter = ast.findIndexWithin(.TypedIdentifier, iter.? + 1, last.? + 1);
        const ty = try TypedIdentifergetType(param, ast);
        try list.append(ty);
    }
    const res = try list.toOwnedSlice();
    list.deinit();
    return res;
}

pub fn ParamatergetParamTypeFromName(this: ?usize, ast: *const Ast, name: []const u8) !?Ast.Type {
    if (this == null) {
        return null;
    }
    const self = ast.get(this.?).kind.Parameters;
    if (self.firstParam == null) {
        return null;
    }
    var last = self.lastParam;
    if (last == null) {
        last = self.firstParam.? + 1;
    }
    var iter: ?usize = self.firstParam;
    while (iter != null) {
        const param = ast.get(iter.?).*;
        const identNode = ast.get(param.kind.TypedIdentifier.ident);
        const ident = identNode.token._range.getSubStrFromStr(ast.input);
        if (std.mem.eql(u8, ident, name)) {
            return try TypedIdentifergetType(param, ast);
        }
        // find next TypedIdentifier
        iter = ast.findIndexWithin(.TypedIdentifier, iter.? + 1, last.? + 1);
    }
    return null;
}

pub fn TypedIdentifergetType(tid: Ast.Node, ast: *const Ast) !Ast.Type {
    // errdefer ast.printNodeLine(tid);
    const ty = ast.get(tid.kind.TypedIdentifier.type).*.kind.Type;
    const ff = ast.get(ty.kind).*.kind;
    _ = switch (ff) {
        .IntType => return Ast.Type.Int,
        .BoolType => return Ast.Type.Bool,
        .Void => return Ast.Type.Void,
        .StructType => {
            const ident = ast.get(ty.structIdentifier.?).*.token._range.getSubStrFromStr(ast.input);
            // identifier to name
            const name = ident;
            return Ast.Type{ .Struct = name };
        },
        else => {
            utils.todo("this must be defined previously, do error proper", .{});
        },
    };
    return error.InvalidType;
}
pub fn ArgumentsgetArgumentTypes(this: ?usize, ast: *const Ast, fName: []const u8, returnType: Ast.Type) !?[]Ast.Type {
    if (this == null) {
        return null;
    }
    // errdefer ast.printNodeLine(ast.get(this.?).*);
    const self = ast.get(this.?).kind.Arguments;
    var list = std.ArrayList(Ast.Type).init(ast.allocator);
    const last: usize = self.lastArg orelse self.firstArg + 1;
    var iter: ?usize = self.firstArg;

    var depth: usize = 0;

    while (iter != null) {
        const arg = ast.get(iter.?).*;
        const ty = try getAndCheckTypeExpression(ast, arg, fName, returnType);
        try list.append(ty);

        // Move to the next argument, considering nested Arguments and ArgumentEnds
        var cursor = iter.? + 1;
        var flag = true;
        while (flag and cursor <= last) {
            const node = ast.get(cursor).*;
            switch (node.kind) {
                .Arguments => depth += 1,
                .ArgumentEnd => {
                    if (depth == 0) {
                        flag = false;
                    }
                },
                .ArgumentsEnd => {
                    if (depth > 0) {
                        depth -= 1;
                    } else {
                        return error.InvalidFunctionCall;
                    }
                },
                else => {},
            }
            cursor += 1;
        }

        iter = if (flag == false) cursor else null;
    }

    const res = try list.toOwnedSlice();
    list.deinit();
    return res;
}
pub fn LValuegetType(this: ?usize, ast: *const Ast, fName: []const u8) !?Ast.Type {
    if (this == null) {
        // TODO add error
        return null;
    }
    // errdefer ast.printNodeLine(ast.get(this.?).*);
    const self = ast.get(this.?).kind.LValue;
    const identNode = ast.get(self.ident);
    // check if the ident is an identifier or an expression
    switch (identNode.kind) {
        .Identifier => {},
        .Expression => {
            const exp_I_arr = try getAndCheckTypeExpression(ast, ast.get(identNode.kind.Expression.expr).*, fName, Ast.Type.Int);
            if (!exp_I_arr.equals(Ast.Type.Int)) {
                return error.InvalidTypeExptectedInt;
            }
            return Ast.Type.Int;
        },
        else => {
            utils.todo("Error on lvalue type checking\n", .{});
            return error.InvalidType;
        },
    }
    const ident = identNode.token._range.getSubStrFromStr(ast.input);
    // const g_decl = ast.getDeclarationGlobalFromName(ident);
    const f_decl = try getAndCheckLocalIdentifier(ast, identNode.*, fName);
    var decl = f_decl;

    var result: ?Ast.Type = null;
    var tmpIdent = ident;
    var chaini = self.chain;
    if (chaini == null) {
        return decl;
    }
    // check if type is a struct or an intarray
    switch (decl) {
        .Struct => {},
        .IntArray => {
            // check if the chain is an expression
            const chainIdent = ast.get(chaini.?).kind.SelectorChain.ident;
            const chainIdentNode = ast.get(chainIdent).kind;
            switch (chainIdentNode) {
                .Expression => {
                    const exprI_ARR = try getAndCheckTypeExpression(ast, ast.get(chainIdentNode.Expression.expr).*, fName, Ast.Type.Int);
                    if (!exprI_ARR.equals(Ast.Type.Int)) {
                        return error.InvalidTypeExptectedInt;
                    }
                    return Ast.Type.Int;
                },
                else => {
                    utils.todo("Error on lvalue type checking, expexcted xpression\n", .{});
                    return error.InvalidType;
                },
            }
        },
        else => {
            utils.todo("Error on lvalue type checking\n", .{});
            return error.InvalidType;
        },
    }
    tmpIdent = decl.Struct;
    tmpIdent = ast.get(ast.getStructNodeFromName(tmpIdent).?.kind.TypeDeclaration.ident).token._range.getSubStrFromStr(ast.input);

    var chain = ast.get(chaini.?).kind.SelectorChain;
    while (true) {
        var chainIdent_K = ast.get(chain.ident);
        // check if the ident is an identifier or an expression
        switch (chainIdent_K.kind) {
            .Identifier => {},
            .Expression => {
                const exp_type = try getAndCheckTypeExpression(ast, ast.get(chainIdent_K.kind.Expression.expr).*, fName, Ast.Type.Int);
                // assert exp_type.equals(Ast.Type.Int);
                if (!exp_type.equals(Ast.Type.Int)) {
                    return error.InvalidTypeExptectedInt;
                }
                return Ast.Type.Int;
            },
            else => {
                utils.todo("Error on lvalue type checking\n", .{});
                return error.InvalidType;
            },
        }

        const chainIdent = chainIdent_K.token._range.getSubStrFromStr(ast.input);
        const field = ast.getStructFieldType(tmpIdent, chainIdent);
        if (field == null) {
            // TODO: add error
            return error.StructHasNoMember;
        }
        if (field.?.isStruct()) {
            tmpIdent = field.?.Struct;
            tmpIdent = ast.get(ast.getStructNodeFromName(tmpIdent).?.kind.TypeDeclaration.ident).token._range.getSubStrFromStr(ast.input);
        }
        result = field;
        if (chain.next == null) {
            return result;
        } else {
            chain = ast.get(chain.next.?).kind.SelectorChain;
        }
    }
}

pub fn StatemenListgetList(this: ?usize, ast: *const Ast) TypeError!?[]usize {
    if (this == null) {
        return null;
    }
    // errdefer ast.printNodeLine(ast.get(this.?).*);
    const self = ast.get(this.?).kind.StatementList;
    var list = std.ArrayList(usize).init(ast.allocator);
    const last = self.lastStatement orelse self.firstStatement + 1;
    var iter: ?usize = self.firstStatement;
    while (iter != null) {
        if (iter.? > last) {
            break;
        }

        const stmt = ast.get(iter.?).kind.Statement;

        try list.append(stmt.statement);
        iter = stmt.finalIndex;
    }
    const res = try list.toOwnedSlice();
    list.deinit();
    return res;
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

test "sema.get_and_check_invocation" {
    const source = "fun foo () void {} fun main() void {foo();}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("foo");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema.get_and_check_invocation_with_args" {
    const source = "fun foo (int a) void {} fun main() void {foo(1);}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("foo");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema.get_and_check_invocation_with_args_fail" {
    const source = "fun foo (int a) void {} fun main() void {foo(true);}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try ting.expectError(TypeError.InvalidFunctionCall, typeCheckFunction(&ast, funcLit));
}

test "sema_get_and_check_invocations_with_mul_args_pass" {
    const source = "fun foo (int a, bool b) void {} fun main() void {foo(1, true);}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("foo");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema_get_and_check_invocations_with_mul_args_fail" {
    const source = "fun foo (int a, bool b) void {} fun main() void {foo(1, 1);}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try ting.expectError(TypeError.InvalidFunctionCall, typeCheckFunction(&ast, funcLit));
}

test "sema_get_and_check_invocations_with_mul_args_fail2" {
    const source = "fun foo (int a, bool b) void {} fun main() void {foo(true, true);}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try ting.expectError(TypeError.InvalidFunctionCall, typeCheckFunction(&ast, funcLit));
}

test "sema.get_and_check_invocation_with_return" {
    const source = "fun foo () int {return 1;} fun main() void {foo();}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("foo");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema.get_and_check_invocation_with_return_fail" {
    const source = "fun foo () bool {return 1;} fun main() void {foo();}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("foo");
    var funcLit = func.?.*;
    try ting.expectError(TypeError.InvalidReturnType, typeCheckFunction(&ast, funcLit));
}

test "sema.check_assignment_int" {
    const source = "fun main() void {int a; a = 1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema.check_assignment_bool" {
    const source = "fun main() void {bool a; a = true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema.check_assignment_fail" {
    const source = "fun main() void {int a; a = true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try ting.expectError(TypeError.InvalidAssignmentType, typeCheckFunction(&ast, funcLit));
}

test "sema.check_assignment_fail2" {
    const source = "fun main() void {bool a; a = 1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try ting.expectError(TypeError.InvalidAssignmentType, typeCheckFunction(&ast, funcLit));
}

test "sema.check_struct_assignment_member" {
    const source = "struct S {int a;}; fun main() void {struct S s; s.a = 1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema.check_struct_assignment_member_fail" {
    const source = "struct S {int a;}; fun main() void {struct S s; s.a = true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try ting.expectError(TypeError.InvalidAssignmentType, typeCheckFunction(&ast, funcLit));
}

test "sema.check_struct_assignment_member_no_such_member" {
    const source = "struct S {int a;}; fun main() void {struct S s; s.b = 1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try ting.expectError(TypeError.StructHasNoMember, typeCheckFunction(&ast, funcLit));
}

test "sema.check_print_int" {
    const source = "fun main() void {print(1);}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema.check_print_bool" {
    const source = "fun main() void {print(true);}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.InvalidReadExptedTypeInt, typeCheckFunction(&ast, funcLit));
}

test "sema.check_binop_int" {
    const source = "fun main() void {int a; a = 1 + 1 + 1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema.check_binop_int_many" {
    const source = "fun main() void {int a; int b; int c; a =1; b = 2; c = a + b;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}
test "sema.check_binop_int_fail" {
    const source = "fun main() void {int a; a = 1 + true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.BinaryOperationTypeMismatch, typeCheckFunction(&ast, funcLit));
}

test "sema.check_binop_int_function_call" {
    const source = "fun foo() int {return 1;} fun main() void {int a; a = 1 + foo();}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema.check_binop_int_function_call_fail" {
    const source = "fun foo() bool {return true;} fun main() void {int a; a = 1 + foo();}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.BinaryOperationTypeMismatch, typeCheckFunction(&ast, funcLit));
}

test "sema.check_binop_all_ops" {
    const source = "fun main() void {int a; a = 1 + 1 - 1 * 1 / 1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema.check_binop_all_ops_and_logic" {
    const source = "fun main() void {bool a; a = 1 + 1 - 1 * 1 / 1 > 1 && true || false;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema.check_binop_many_ops_fail" {
    const source = "fun main() void {int a; a = 1 + 1 - 1 * 1 / true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.BinaryOperationTypeMismatch, typeCheckFunction(&ast, funcLit));
}

test "sema.check_unop_not" {
    const source = "fun main() void {bool a; a = !true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema.check_unop_not_fail" {
    const source = "fun main() void {int a; a = !1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.InvalidTypeExpectedBool, typeCheckFunction(&ast, funcLit));
}

test "sema.check_unop_minus" {
    const source = "fun main() void {int a; a = -1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema.check_unop_minus_fail" {
    const source = "fun main() void {bool a; a = -true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.InvalidTypeExptectedInt, typeCheckFunction(&ast, funcLit));
}

//FIXME: this seems so wrong lmao
test "sema.check_unop_in_binops" {
    const source = "fun main() void {int a; a = 1 + -1 + 1 - -1 * 1 / -1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema.check_logical_unop_in_binops" {
    const source = "fun main() void {bool a; a = !true && !false || !true && !false && !true || !false && !true || !false && !true && !false;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema.check_logical_unop_in_binops_fail" {
    const source = "fun main() void {bool a; a = !1 && !false || !true && !false && !true || !false && !true || !false && !true && !false;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.InvalidTypeExpectedBool, typeCheckFunction(&ast, funcLit));
}

test "sema.check_deep_struct" {
    const source = "struct S {int a; struct S s;}; fun main() void {struct S s; s.s.s.s.s.s.a = 1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema.check_deep_struct_assignment_fail" {
    const source = "struct S {int a; struct S s;}; fun main() void {struct S s; s.s.s.s.s.s.a = true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.InvalidAssignmentType, typeCheckFunction(&ast, funcLit));
}

test "sema.check_deep_struct_assignment" {
    const source = "struct S {int a; struct S s;}; fun main() void {struct S s; struct S b; s.s.s.s.s.s.a = 1; b.s.s.s.s.s.s.s =s;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}

test "sema.check_mixed.mini" {
    // load source from file
    const source = @embedFile("mixed.mini");
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typeCheckFunction(&ast, funcLit);
}
test "sema.check_mixed_wrong_new.mini" {
    // load source from file
    const source = @embedFile("mixed_wrong_new.mini");
    var ast = try testMe(source);
    // expect error InvalidAssignmentType
    try ting.expectError(TypeError.InvalidAssignmentType, typeCheck(&ast));
}
// test for InvalidFunctionCallNoDefinedArguments
test "sema.check_invocationwithnoargsbutparams" {
    const source = "fun foo(int a) void {} fun main() void {foo();}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error InvalidFunctionCallNoDefinedArguments
    try ting.expectError(TypeError.InvalidFunctionCallNoDefinedArguments, typeCheckFunction(&ast, funcLit));
}

test "sema.check_binop_mul_bools" {
    const source = "fun main() void {bool a; a = true / true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.InvalidTypeExptectedInt, typeCheckFunction(&ast, funcLit));
}
test "sema.checkArrayAccess" {
    const source = "fun main() void {int_array a; a = new int_array[10]; a[0] = 1;}";
    var ast = try testMe(source);
    // var func = ast.getFunctionFromName("main");
    // var funcLit = func.?.*;
    try typeCheck(&ast);
}
test "sema.4mini" {
    // load source from file
    const source = @embedFile("4.mini");
    var ast = try testMe(source);
    // expect error InvalidAssignmentType
    try typeCheck(&ast);
}

test "sema.ia_invalid_access" {
    const source = "fun main() void {int_array a; a = new int_array[10]; a[true] = 1;}";
    var ast = try testMe(source);
    // expect error
    try ting.expectError(TypeError.InvalidTypeExptectedInt, typeCheck(&ast));
}

test "sema.ia_invalid_new" {
    const source = "fun main() void {int_array a; a = new int_array[true];}";
    _ = try ting.expectError(TypeError.InvalidToken, testMe(source));
}

test "sema_ia_lots_of_errors" {
    const source = "fun main() void {int_array a; int b; int c; a = new int_array[0]; c = b + a[100000000]; a = new int_array[2000]; a[0] = c;}";
    _ = try testMe(source);
    // expect error
}

test "sema_ia.structs" {
    const source = "struct S {int a;}; fun main() void {int_array a; struct S b; a = new int_array[10]; b.a = a[0];}";
    var ast = try testMe(source);
    // expect error
    try typeCheck(&ast);
}

test "sema.ia_structs_assign_retrive" {
    const source = "struct S {int a;}; fun main() void {int_array a; struct S b; a = new int_array[10]; b.a = a[0]; a[0] = b.a;}";
    var ast = try testMe(source);
    // expect error
    try typeCheck(&ast);
}

test "sema.ia_int_arryay_member_struct" {
    const source = "struct S {int_array a;}; fun main() void {struct S b; b.a = new int_array[10]; b.a[0] = 1;}";
    var ast = try testMe(source);
    // expect error
    try typeCheck(&ast);
}
test "sema.ia_struct_toself" {
    const source = "struct S {int_array a; int b;}; fun main() void {struct S c; c.a = new int_array[100]; c.b = c.a[20];}";
    var ast = try testMe(source);
    // expect error
    try typeCheck(&ast);
}

test "sema.ia_struct_toself2" {
    const source = "struct S {struct S s; int_array a; int b;}; fun main() void {struct S c; c.s.s.s.s.s.s.s.a = new int_array[100]; c.s.s.s.s.s.s.s.b = c.a[20]; c.s.s.s.s.s.s.s.s.s.a[20] = 2;}";
    var ast = try testMe(source);
    // expect error
    try typeCheck(&ast);
}

test "sema.struct_null" {
    const source = "struct S {int a;}; fun main() void {struct S b; b = null;}";
    var ast = try testMe(source);
    // expect error
    try typeCheck(&ast);
}
