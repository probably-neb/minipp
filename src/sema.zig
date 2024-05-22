// AST (possibly borqed) -> AST (not borqed)

const std = @import("std");

const Ast = @import("ast.zig");
const utils = @import("utils.zig");
const log = @import("log.zig");

const SemaError = error{
    NoMain,
    MissingReturnPath,
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

pub fn ensureSemanticallyValid(ast: *const Ast) !void {
    // get all functions out of map
    try checkHasMain(ast);
    var funcsKeys = ast.functionMap.keyIterator();
    while (funcsKeys.next()) |key| {
        const func = ast.getFunctionFromName(key.*).?.*;
        const fc = func.kind.Function;
        const returnType = fc.getReturnType(ast).?;
        if (returnType != .Void) {
            try checkAllReturnPathsExist(ast, fc);
        }
        try typecheckFunction(ast, func);
    }
}

/// Helper for testing where we only want to type check and don't
/// necessarily care about return value, main, etc checking
fn typecheck(ast: *const Ast) !void {
    // get all functions out of map
    var funcsKeys = ast.functionMap.keyIterator();
    while (funcsKeys.next()) |key| {
        const func = ast.getFunctionFromName(key.*).?;
        try typecheckFunction(ast, func.*);
    }
}

const MAIN: []const u8 = "main";

fn checkHasMain(ast: *const Ast) SemaError!void {
    var funcs = ast.iterFuncs();
    while (funcs.next()) |func| {
        const name = func.getName(ast);
        if (std.mem.eql(u8, name, MAIN)) {
            return;
        }
    }
    return error.NoMain;
}

/// Helper for testing where we only want to check that all functions have a return path
fn checkAllFunctionsHaveValidReturnPaths(ast: *const Ast) !void {
    var funcs = ast.iterFuncs();
    while (funcs.next()) |func| {
        try checkAllReturnPathsExist(ast, func);
    }
    return;
}

fn checkAllReturnPathsExistInner(ast: *const Ast, start: usize, end: usize) bool {
    // TODO:
    // decend the tree if we hit a conditional call a function that checks if the conditional
    // has a return statement, if both sides return then we are good.
    // otherwise continue decending for a fall through.
    // if there is no final return statment throw an error
    var result = false;
    // used for printing the line of the node
    var conditionalNode: ?*const Ast.Node = null;
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
        if (node.kind == .While) {
            const whileNode = node.kind.While;
            const blockRange = ast.get(whileNode.block).kind.Block.range(ast);
            if (blockRange) |range| {
                cursor = range[1] + 1;
            } else {
                cursor = whileNode.block + 1;
            }
            return checkAllReturnPathsExistInner(ast, cursor, end);
        }
        if (node.kind != .ConditionalIf) {
            // we don't care about non conditional nodes
            continue;
        }
        conditionalNode = node;

        var returnsInThenCase = true;
        // defaults to true in case there is no else case
        var returnsInElseCase = true;
        var returnsInTrailing = false;

        const ifNode = node.kind.ConditionalIf;

        _ = returnsInTrailing;

        var trailingNodesStart: usize = undefined;
        const trailingNodesEnd = end;
        var fallthroughRequired = false;

        if (ifNode.isIfElse(ast)) {
            const ifElseNode = ast.get(ifNode.block).kind.ConditionalIfElse;

            returnsInThenCase = checkAllReturnPathsExistInner(ast, ifElseNode.ifBlock, ifElseNode.elseBlock);

            // now default returnsInElse to false because there is an else block
            returnsInElseCase = false;
            const elseBlockRange = ast.get(ifElseNode.elseBlock).kind.Block.range(ast);
            if (elseBlockRange) |range| {
                const elseBlockStart = range[0];
                const elseBlockEnd = range[1] + 1;
                returnsInElseCase = checkAllReturnPathsExistInner(ast, elseBlockStart, elseBlockEnd);
                fallthroughRequired = !returnsInElseCase;

                trailingNodesStart = elseBlockEnd + 1;
            } else {
                trailingNodesStart = ifElseNode.elseBlock + 1;
            }
        } else {
            fallthroughRequired = true;
            const ifNodeBlock = ast.get(ifNode.block).kind.Block;
            const ifNodeBlockRange = ifNodeBlock.range(ast);
            if (ifNodeBlockRange) |range| {
                const ifNodeStart = range[0];
                const ifNodeEnd = range[1] + 1;
                returnsInThenCase = checkAllReturnPathsExistInner(ast, ifNodeStart, ifNodeEnd);

                trailingNodesStart = ifNodeEnd;
            } else {
                returnsInThenCase = false;
                trailingNodesStart = ifNode.block + 1;
            }
        }
        const returnsInTrailingNodes = checkAllReturnPathsExistInner(ast, trailingNodesStart, trailingNodesEnd);
        // print the trailing nodes
        if (fallthroughRequired) {
            result = returnsInTrailingNodes;
        } else {
            result = (returnsInThenCase and returnsInElseCase) or returnsInTrailingNodes;
        }
        ast.printNodeLineTo(conditionalNode.?.*, std.debug.print);
        std.debug.print("returns in:\nthen: {}\nelse: {}\ntrailing: {}\n\n", .{ returnsInThenCase, returnsInElseCase, returnsInTrailingNodes });
        break;
    }
    if (conditionalNode) |condNode| {
        if (!result) {
            ast.printNodeLineTo(condNode.*, log.trace);
        }
    }
    return result;
}

fn checkAllReturnPathsExist(ast: *const Ast, func: Ast.Node.Kind.FunctionType) SemaError!void {
    errdefer log.err("Function: {s}\n", .{func.getName(ast)});
    const returnType = func.getReturnType(ast).?;
    const statementList = func.getBody(ast).getStatementList();
    if (returnType == .Void and statementList == null) {
        return;
    }
    const statList = statementList.?;
    const funcEnd = ast.findIndex(.FunctionEnd, statList).?;

    const ok = checkAllReturnPathsExistInner(ast, statList, funcEnd);
    if (!ok) {
        return SemaError.MissingReturnPath;
    }
}

fn typecheckFunction(ast: *const Ast, func: Ast.Node) TypeError!void {
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
            const ident = ast.getIdentValue(param.kind.TypedIdentifier.ident);
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
    try typecheckStatementList(ast, fstatementsIndex, functionName, returnType);
}

fn typecheckStatementList(ast: *const Ast, statementListn: ?usize, fName: []const u8, returnType: Ast.Type) TypeError!void {
    // errdefer if (statementListn) |lst| ast.printNodeLine(ast.get(lst).*);
    // log.trace("statementListn: {d}\n", .{statementListn.?});
    var iter = ast.get(statementListn.?).kind.StatementList.iter(ast);
    while (iter.next()) |statement| {
        const stmtInner = ast.get(statement.kind.Statement.statement).*;
        try typecheckStatement(ast, stmtInner, fName, returnType);
    }
}

fn typecheckStatement(ast: *const Ast, statement: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!void {
    // errdefer ast.printNodeLine(statement);
    const kind = statement.kind;
    _ = switch (kind) {
        .Block => {
            try typecheckBlock(ast, statement, fName, returnType);
            return;
        },
        .Assignment => {
            try typecheckAssignment(ast, statement, fName, returnType);
            return;
        },
        .Print => {
            try typecheckPrint(ast, statement, fName, returnType);
            return;
        },
        .ConditionalIf => {
            try typecheckConditional(ast, statement, fName, returnType);
            return;
        },
        .While => {
            try typecheckWhile(ast, statement, fName, returnType);
            return;
        },
        .Delete => {
            try typecheckDelete(ast, statement, fName, returnType);
            return;
        },
        .Return => {
            try typecheckReturn(ast, statement, fName, returnType);
            return;
        },
        .Invocation => {
            _ = try typecheckInvocation(ast, statement, fName, returnType);
            return;
        },
        else => {
            utils.todo("Error on statement type checking\n", .{});
            return error.InvalidType;
        },
    };
    return error.InvalidType;
}

fn typecheckBlock(ast: *const Ast, blockn: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!void {
    // errdefer ast.printNodeLine(blockn);
    // Block to statement list
    const block = blockn.kind.Block;
    const statementIndex = block.statements;
    if (statementIndex == null) {
        return;
    }
    try typecheckStatementList(ast, statementIndex.?, fName, returnType);
}

fn typecheckAssignment(ast: *const Ast, assignmentn: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!void {
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
    const leftType = try typecheckLValue(left, ast, fName);
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
    const rightType = try typecheckExpression(ast, rightExpr, fName, returnType);
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

fn typecheckPrint(ast: *const Ast, printn: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!void {
    // errdefer ast.printNodeLine(printn);
    const print = printn.kind.Print;
    const expr = print.expr;
    const exprNode = ast.get(expr).*;
    const exprType = try typecheckExpression(ast, exprNode, fName, returnType);
    if (!exprType.equals(Ast.Type.Int)) {
        // TODO: add error
        return TypeError.InvalidReadExptedTypeInt;
    }
}

fn typecheckConditional(ast: *const Ast, conditionaln: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!void {
    // errdefer ast.printNodeLine(conditionaln);
    // first check if conditional is bool
    const conditional = conditionaln.kind.ConditionalIf;
    const cond = conditional.cond;
    const condNode = ast.get(cond).*;
    const condType = try typecheckExpression(ast, condNode, fName, returnType);
    if (!condType.equals(Ast.Type.Bool)) {
        utils.todo("Error on conditional type checking\n", .{});
        return error.InvalidType;
    }

    const isIfElse = conditional.isIfElse(ast);
    if (isIfElse) {
        const ifElseNode = ast.get(conditional.block).kind.ConditionalIfElse;
        const ifBlockNode = ast.get(ifElseNode.ifBlock).*;
        const elseBlockNode = ast.get(ifElseNode.elseBlock).*;
        try typecheckBlock(ast, ifBlockNode, fName, returnType);
        try typecheckBlock(ast, elseBlockNode, fName, returnType);
    } else {
        const ifBlockNode = ast.get(conditional.block).*;
        try typecheckBlock(ast, ifBlockNode, fName, returnType);
    }
}

fn typecheckWhile(ast: *const Ast, while_nN: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!void {
    // errdefer ast.printNodeLine(while_nN);
    // first check if conditional is bool
    const while_n = while_nN.kind.While;
    const cond = while_n.cond;
    const condNode = ast.get(cond).*;
    const condType = try typecheckExpression(ast, condNode, fName, returnType);
    if (!condType.equals(Ast.Type.Bool)) {
        utils.todo("Error on while type checking\n", .{});
        return error.InvalidType;
    }

    const blockNode = ast.get(while_n.block).*;
    try typecheckBlock(ast, blockNode, fName, returnType);
}

fn typecheckDelete(ast: *const Ast, deleten: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!void {
    // errdefer ast.printNodeLine(deleten);
    const delete = deleten.kind.Delete;
    const expr = delete.expr;
    const exprNode = ast.get(expr).*;
    const exprType = try typecheckExpression(ast, exprNode, fName, returnType);
    if (!exprType.equalsNoCont(Ast.Type{ .Struct = "cunny" })) {
        utils.todo("Error on delete type checking\n", .{});
        return error.InvalidType;
    }
}

fn typecheckReturn(ast: *const Ast, retn: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!void {
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
    const exprType = try typecheckExpression(ast, exprNode, fName, returnType);
    if (!exprType.equals(returnType)) {
        // FIXME: add proper error
        return error.InvalidReturnType;
    }
}

fn typecheckInvocation(ast: *const Ast, invocationn: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!Ast.Type {
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

    var argsList = try typecheckArguments(args, ast, fName, returnType);
    var funcPList = try getParameterTypes(funcProto, ast);

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

fn typecheckExpression(ast: *const Ast, exprn: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!Ast.Type {
    // errdefer ast.printNodeLine(exprn);
    switch (exprn.kind) {
        .BinaryOperation => {
            return try typecheckBinaryOperation(ast, exprn, fName, returnType);
        },
        .UnaryOperation => {
            return try typecheckUnaryOperation(ast, exprn, fName, returnType);
        },
        .Selector => {
            return try typecheckSelector(ast, exprn, fName, returnType);
        },
        .Expression => {
            const expr = exprn.kind.Expression;
            // get the type of the expression
            const node = ast.get(expr.expr).*;
            const kind = node.kind;
            switch (kind) {
                .BinaryOperation => {
                    return try typecheckBinaryOperation(ast, node, fName, returnType);
                },
                .UnaryOperation => {
                    return try typecheckUnaryOperation(ast, node, fName, returnType);
                },
                .Selector => {
                    return try typecheckSelector(ast, node, fName, returnType);
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
fn typecheckBinaryOperation(ast: *const Ast, binaryOp: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!Ast.Type {
    // errdefer ast.printNodeLine(binaryOp);
    const token = binaryOp.token;
    switch (token.kind) {
        .Lt, .Gt, .GtEq, .LtEq, .DoubleEq, .NotEq => {
            const lhsExpr = ast.get(binaryOp.kind.BinaryOperation.lhs).*;
            const rhsExpr = ast.get(binaryOp.kind.BinaryOperation.rhs).*;
            const lhsType = try typecheckExpression(ast, lhsExpr, fName, returnType);
            const rhsType = try typecheckExpression(ast, rhsExpr, fName, returnType);
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
            const lhsType = try typecheckExpression(ast, lhsExpr, fName, returnType);
            const rhsType = try typecheckExpression(ast, rhsExpr, fName, returnType);

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
            const lhsType = try typecheckExpression(ast, lhsExpr, fName, returnType);
            const rhsType = try typecheckExpression(ast, rhsExpr, fName, returnType);
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

fn typecheckUnaryOperation(ast: *const Ast, unaryOp: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!Ast.Type {
    // errdefer ast.printNodeLine(unaryOp);
    const token = unaryOp.token;
    switch (token.kind) {
        .Not => {
            const expr = ast.get(unaryOp.kind.UnaryOperation.on).*;
            const exprType = try typecheckExpression(ast, expr, fName, returnType);
            if (!exprType.equals(Ast.Type.Bool)) {
                return error.InvalidTypeExpectedBool;
            }
            return exprType;
        },
        .Minus => {
            const expr = ast.get(unaryOp.kind.UnaryOperation.on).*;
            const exprType = try typecheckExpression(ast, expr, fName, returnType);
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

fn typecheckSelector(ast: *const Ast, selectorn: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!Ast.Type {
    // errdefer ast.printNodeLine(selectorn);
    const selector = selectorn.kind.Selector;
    const factorNode = ast.get(selector.factor).*;
    const factorType = try typecheckFactor(ast, factorNode, fName, returnType);
    if (selector.chain) |chain| {
        const chainType = try typecheckSelectorChain(chain, ast, factorType, fName, returnType);
        return chainType;
    } else {
        return factorType;
    }
}

fn typecheckFactor(ast: *const Ast, factorn: Ast.Node, fName: []const u8, returnType: Ast.Type) TypeError!Ast.Type {
    // errdefer ast.printNodeLine(factorn);
    const factor = factorn.kind.Factor;
    const kind = factor.factor;
    const node = ast.get(kind).*;
    switch (node.kind) {
        .Number => return Ast.Type.Int,
        .True, .False => return Ast.Type.Bool,
        .Null => return Ast.Type.Null,
        .New => return try typecheckNewStruct(ast, node),
        .NewIntArray => return typecheckNewIntArray(ast, node),
        .Invocation => return try typecheckInvocation(ast, node, fName, returnType),
        .Expression => return try typecheckExpression(ast, node, fName, returnType),
        .Identifier => return try typecheckLocalIdentifier(ast, node, fName),
        else => {
            utils.todo("Error on factor type checking\n", .{});
            return error.InvalidType;
        },
    }
    unreachable;
}

fn typecheckNewStruct(ast: *const Ast, newn: Ast.Node) TypeError!Ast.Type {
    // errdefer ast.printNodeLine(newn);
    const new = newn.kind.New;
    const name = ast.getIdentValue(new.ident);
    const structType = ast.getStructNodeFromName(name);
    if (structType == null) {
        utils.todo("Error on new type checking\n", .{});
        return error.InvalidType;
    }
    return Ast.Type{ .Struct = name };
}

fn typecheckNewIntArray(ast: *const Ast, newn: Ast.Node) TypeError!Ast.Type {
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

fn typecheckLocalIdentifier(ast: *const Ast, localId: Ast.Node, fName: []const u8) TypeError!Ast.Type {
    // errdefer ast.printNodeLine(localId);
    const token = localId.token;
    const name = token._range.getSubStrFromStr(ast.input);
    const func = ast.getFunctionFromName(fName).?.kind.Function.proto;
    const param = ast.get(func).*.kind.FunctionProto.parameters;

    const funcDecl = ast.getFunctionDeclarationTypeFromName(fName, name);
    const funcParam = try getParamTypeByName(param, ast, name);
    const globalDecl = ast.getDeclarationGlobalFromName(name);
    const localDecl = funcParam orelse funcDecl orelse globalDecl;
    if (localDecl == null) {
        return error.InvalidType;
    }
    return localDecl.?;
}

fn typecheckSelectorChain(chainLinkIndex: usize, ast: *const Ast, ty: Ast.Type, fName: []const u8, returnType: Ast.Type) !Ast.Type {
    const chain = ast.get(chainLinkIndex).kind.SelectorChain;
    const selection = ast.get(chain.ident);

    // Verify the type of selection is correct
    switch (selection.kind) {
        .Identifier => if (!ty.isStruct()) {
            log.err("Cannot do struct field access off of type {s} in function {s}\n", .{ @tagName(ty), fName });
            return error.InvalidType;
        },
        .Expression => if (!ty.equals(.IntArray)) {
            log.err("Cannot do array index access off of type {s} in function {s}\n", .{ @tagName(ty), fName });
            return error.InvalidType;
        },
        else => |wtf| {
            log.err("Invalid selector chain type in function {s}. Expected {s} or {s} but got {s}\n", .{ fName, @tagName(.Identifier), @tagName(.Expression), @tagName(wtf) });
            unreachable;
        },
    }

    const selectedType = switch (selection.kind) {
        .Identifier => structFieldAccess: {
            const structName = ty.Struct;
            const fieldName = ast.getIdentValue(chain.ident);
            const maybeFieldType = ast.getStructFieldType(structName, fieldName);

            if (maybeFieldType) |fieldType| {
                break :structFieldAccess fieldType;
            } else {
                log.err("Struct `{s}` has no field named `{s}`. Attempted access in function {s}\n", .{ structName, fieldName, fName });
                return error.StructHasNoMember;
            }
        },
        .Expression => arrayIndexAccess: {
            const exprType = try typecheckExpression(ast, selection.*, fName, returnType);
            if (!exprType.equals(.Int)) {
                log.err("Array index must be of type int, got {s} in function {s}\n", .{ @tagName(exprType), fName });
                return error.InvalidTypeExptectedInt;
            }
            // array indices always return an int
            break :arrayIndexAccess .Int;
        },
        // truly unreachable, this case is covered (has nicer error message) by the switch above
        else => unreachable,
    };

    if (chain.next) |next| {
        // this is a clean way to error if the selectedType is not a struct or int_array
        // as we check the type being selected off of at the top of this function
        return try typecheckSelectorChain(next, ast, selectedType, fName, returnType);
    } else {
        return selectedType;
    }
}

fn getParameterTypes(this: ?usize, ast: *const Ast) !?[]Ast.Type {
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
        const ty = try getTypedIdentiferType(param, ast);
        try list.append(ty);
    }
    const res = try list.toOwnedSlice();
    list.deinit();
    return res;
}

fn getParamTypeByName(this: ?usize, ast: *const Ast, name: []const u8) !?Ast.Type {
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
        const ident = ast.getIdentValue(param.kind.TypedIdentifier.ident);
        if (std.mem.eql(u8, ident, name)) {
            return try getTypedIdentiferType(param, ast);
        }
        // find next TypedIdentifier
        iter = ast.findIndexWithin(.TypedIdentifier, iter.? + 1, last.? + 1);
    }
    return null;
}

fn getTypedIdentiferType(tid: Ast.Node, ast: *const Ast) !Ast.Type {
    // errdefer ast.printNodeLine(tid);
    const ty = ast.get(tid.kind.TypedIdentifier.type).*.kind.Type;
    const ff = ast.get(ty.kind).*.kind;
    _ = switch (ff) {
        .IntType => return Ast.Type.Int,
        .BoolType => return Ast.Type.Bool,
        .IntArrayType => return Ast.Type.IntArray,
        .StructType => {
            const ident = ast.getIdentValue(ty.structIdentifier.?);
            // identifier to name
            const name = ident;
            return Ast.Type{ .Struct = name };
        },
        .Void => return error.InvalidType,
        else => {
            utils.todo("this must be defined previously, do error proper", .{});
        },
    };
    return error.InvalidType;
}

fn typecheckArguments(this: ?usize, ast: *const Ast, fName: []const u8, returnType: Ast.Type) !?[]Ast.Type {
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
        const ty = try typecheckExpression(ast, arg, fName, returnType);
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

fn typecheckLValue(this: ?usize, ast: *const Ast, fName: []const u8) !?Ast.Type {
    if (this == null) {
        // TODO add error
        return null;
    }
    // errdefer ast.printNodeLine(ast.get(this.?).*);
    const self = ast.get(this.?).kind.LValue;

    const identType = try typecheckLocalIdentifier(ast, ast.get(self.ident).*, fName);

    if (self.chain) |chain| {
        const mockReturnType = Ast.Type.Void;
        return try typecheckSelectorChain(chain, ast, identType, fName, mockReturnType);
    } else {
        return identType;
    }
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
    try ting.expectError(SemaError.NoMain, checkHasMain(&ast));
}

test "sema.has_main" {
    defer log.print();
    const source = "fun main() void {return;}";
    const ast = try testMe(source);
    try checkHasMain(&ast);
}

test "sema.not_all_return_paths_void" {
    const source = "fun main() void {if (true) {return;} else {return 1;}}";
    const ast = try testMe(source);
    try ting.expectEqual(ast.numNodes(.Return, 0), 2);
    const result = typecheck(&ast);
    try ting.expectError(TypeError.InvalidReturnType, result);
}

test "sema.all_return_paths_void" {
    const source = "fun main() void {if (true) {return;} else {return;} return;}";
    const ast = try testMe(source);
    try checkAllFunctionsHaveValidReturnPaths(&ast);
}

test "sema.all_return_paths_bool" {
    const source = "fun main() bool {if (true) {return true;} else {return false;}}";
    const ast = try testMe(source);
    try checkAllFunctionsHaveValidReturnPaths(&ast);
}

test "sema.returns_in_both_sides_of_if_else" {
    const source = "fun main() bool {if (true) {return true;} else {return false;}}";
    const ast = try testMe(source);
    try checkAllFunctionsHaveValidReturnPaths(&ast);
}

test "sema.not_all_paths_return" {
    const source = "fun main() bool {if (true) {return true;}}";
    const ast = try testMe(source);
    try ting.expectEqual(ast.numNodes(.Return, 0), 1);
    const result = checkAllFunctionsHaveValidReturnPaths(&ast);
    try ting.expectError(SemaError.MissingReturnPath, result);
}

test "sema.not_all_paths_return_in_nested_if" {
    const source = "fun main() bool {if (true) {if (false) {return true;} else {return false;}}}";
    const ast = try testMe(source);
    try ting.expectEqual(ast.numNodes(.Return, 0), 2);
    const result = checkAllFunctionsHaveValidReturnPaths(&ast);
    try ting.expectError(SemaError.MissingReturnPath, result);
}

test "sema.nested_fallthrough_fail_on_ifelse" {
    const source = "fun main() bool {if (true) {if (false) {if(true){return true;}} else {return false;}}}";
    const ast = try testMe(source);
    try ting.expectEqual(ast.numNodes(.Return, 0), 2);
    const result = checkAllFunctionsHaveValidReturnPaths(&ast);
    try ting.expectError(SemaError.MissingReturnPath, result);
}

test "sema.super_nested_fallthrough_fail_on_ifelse" {
    const source = "fun main() bool {if (true) {if (false) {if(true){if(false){return true;}} else {return false;}}}}";
    const ast = try testMe(source);
    try ting.expectEqual(ast.numNodes(.Return, 0), 2);
    const result = checkAllFunctionsHaveValidReturnPaths(&ast);
    try ting.expectError(SemaError.MissingReturnPath, result);
}

test "sema.get_and_check_invocation" {
    const source = "fun foo () void {} fun main() void {foo();}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("foo");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema.get_and_check_invocation_with_args" {
    const source = "fun foo (int a) void {} fun main() void {foo(1);}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("foo");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema.get_and_check_invocation_with_args_fail" {
    const source = "fun foo (int a) void {} fun main() void {foo(true);}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try ting.expectError(TypeError.InvalidFunctionCall, typecheckFunction(&ast, funcLit));
}

test "sema_get_and_check_invocations_with_mul_args_pass" {
    const source = "fun foo (int a, bool b) void {} fun main() void {foo(1, true);}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("foo");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema_get_and_check_invocations_with_mul_args_fail" {
    const source = "fun foo (int a, bool b) void {} fun main() void {foo(1, 1);}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try ting.expectError(TypeError.InvalidFunctionCall, typecheckFunction(&ast, funcLit));
}

test "sema_get_and_check_invocations_with_mul_args_fail2" {
    const source = "fun foo (int a, bool b) void {} fun main() void {foo(true, true);}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try ting.expectError(TypeError.InvalidFunctionCall, typecheckFunction(&ast, funcLit));
}

test "sema.get_and_check_invocation_with_return" {
    const source = "fun foo () int {return 1;} fun main() void {foo();}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("foo");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema.get_and_check_invocation_with_return_fail" {
    const source = "fun foo () bool {return 1;} fun main() void {foo();}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("foo");
    var funcLit = func.?.*;
    try ting.expectError(TypeError.InvalidReturnType, typecheckFunction(&ast, funcLit));
}

test "sema.check_assignment_int" {
    const source = "fun main() void {int a; a = 1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema.check_assignment_bool" {
    const source = "fun main() void {bool a; a = true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema.check_assignment_fail" {
    const source = "fun main() void {int a; a = true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try ting.expectError(TypeError.InvalidAssignmentType, typecheckFunction(&ast, funcLit));
}

test "sema.check_assignment_fail2" {
    const source = "fun main() void {bool a; a = 1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try ting.expectError(TypeError.InvalidAssignmentType, typecheckFunction(&ast, funcLit));
}

test "sema.check_struct_assignment_member" {
    const source = "struct S {int a;}; fun main() void {struct S s; s.a = 1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema.check_struct_assignment_member_fail" {
    const source = "struct S {int a;}; fun main() void {struct S s; s.a = true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try ting.expectError(TypeError.InvalidAssignmentType, typecheckFunction(&ast, funcLit));
}

test "sema.check_struct_assignment_member_no_such_member" {
    const source = "struct S {int a;}; fun main() void {struct S s; s.b = 1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try ting.expectError(TypeError.StructHasNoMember, typecheckFunction(&ast, funcLit));
}

test "sema.check_print_int" {
    const source = "fun main() void {print(1);}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema.check_print_bool" {
    const source = "fun main() void {print(true);}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.InvalidReadExptedTypeInt, typecheckFunction(&ast, funcLit));
}

test "sema.check_binop_int" {
    const source = "fun main() void {int a; a = 1 + 1 + 1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema.check_binop_int_many" {
    const source = "fun main() void {int a; int b; int c; a =1; b = 2; c = a + b;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}
test "sema.check_binop_int_fail" {
    const source = "fun main() void {int a; a = 1 + true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.BinaryOperationTypeMismatch, typecheckFunction(&ast, funcLit));
}

test "sema.check_binop_int_function_call" {
    const source = "fun foo() int {return 1;} fun main() void {int a; a = 1 + foo();}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema.check_binop_int_function_call_fail" {
    const source = "fun foo() bool {return true;} fun main() void {int a; a = 1 + foo();}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.BinaryOperationTypeMismatch, typecheckFunction(&ast, funcLit));
}

test "sema.check_binop_all_ops" {
    const source = "fun main() void {int a; a = 1 + 1 - 1 * 1 / 1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema.check_binop_all_ops_and_logic" {
    const source = "fun main() void {bool a; a = 1 + 1 - 1 * 1 / 1 > 1 && true || false;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema.check_binop_many_ops_fail" {
    const source = "fun main() void {int a; a = 1 + 1 - 1 * 1 / true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.BinaryOperationTypeMismatch, typecheckFunction(&ast, funcLit));
}

test "sema.check_unop_not" {
    const source = "fun main() void {bool a; a = !true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema.check_unop_not_fail" {
    const source = "fun main() void {int a; a = !1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.InvalidTypeExpectedBool, typecheckFunction(&ast, funcLit));
}

test "sema.check_unop_minus" {
    const source = "fun main() void {int a; a = -1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema.check_unop_minus_fail" {
    const source = "fun main() void {bool a; a = -true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.InvalidTypeExptectedInt, typecheckFunction(&ast, funcLit));
}

//FIXME: this seems so wrong lmao
test "sema.check_unop_in_binops" {
    const source = "fun main() void {int a; a = 1 + -1 + 1 - -1 * 1 / -1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema.check_logical_unop_in_binops" {
    const source = "fun main() void {bool a; a = !true && !false || !true && !false && !true || !false && !true || !false && !true && !false;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema.check_logical_unop_in_binops_fail" {
    const source = "fun main() void {bool a; a = !1 && !false || !true && !false && !true || !false && !true || !false && !true && !false;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.InvalidTypeExpectedBool, typecheckFunction(&ast, funcLit));
}

test "sema.check_deep_struct" {
    const source = "struct S {int a; struct S s;}; fun main() void {struct S s; s.s.s.s.s.s.a = 1;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema.check_deep_struct_assignment_fail" {
    const source = "struct S {int a; struct S s;}; fun main() void {struct S s; s.s.s.s.s.s.a = true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.InvalidAssignmentType, typecheckFunction(&ast, funcLit));
}

test "sema.check_deep_struct_assignment" {
    const source = "struct S {int a; struct S s;}; fun main() void {struct S s; struct S b; s.s.s.s.s.s.a = 1; b.s.s.s.s.s.s.s =s;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}

test "sema.check_mixed.mini" {
    // load source from file
    const source = @embedFile("mixed.mini");
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    try typecheckFunction(&ast, funcLit);
}
test "sema.check_mixed_wrong_new.mini" {
    // load source from file
    const source = @embedFile("mixed_wrong_new.mini");
    var ast = try testMe(source);
    // expect error InvalidAssignmentType
    try ting.expectError(TypeError.InvalidAssignmentType, typecheck(&ast));
}
// test for InvalidFunctionCallNoDefinedArguments
test "sema.check_invocationwithnoargsbutparams" {
    const source = "fun foo(int a) void {} fun main() void {foo();}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error InvalidFunctionCallNoDefinedArguments
    try ting.expectError(TypeError.InvalidFunctionCallNoDefinedArguments, typecheckFunction(&ast, funcLit));
}

test "sema.check_binop_mul_bools" {
    const source = "fun main() void {bool a; a = true / true;}";
    var ast = try testMe(source);
    var func = ast.getFunctionFromName("main");
    var funcLit = func.?.*;
    // expect error
    try ting.expectError(TypeError.InvalidTypeExptectedInt, typecheckFunction(&ast, funcLit));
}
test "sema.checkArrayAccess" {
    const source = "fun main() void {int_array a; a = new int_array[10]; a[0] = 1;}";
    var ast = try testMe(source);
    // var func = ast.getFunctionFromName("main");
    // var funcLit = func.?.*;
    try typecheck(&ast);
}
test "sema.4mini" {
    // load source from file
    const source = @embedFile("4.mini");
    var ast = try testMe(source);
    // expect error InvalidAssignmentType
    try typecheck(&ast);
}

test "sema.ia_invalid_access" {
    log.empty();
    errdefer log.printWithPrefix("sema.ia_invalid_access");
    const source =
        \\fun main() void {
        \\int_array a;
        \\a = new int_array[10];
        \\a[true] = 1;
        \\}
    ;
    var ast = try testMe(source);
    // expect error
    try ting.expectError(TypeError.InvalidTypeExptectedInt, typecheck(&ast));
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
    try typecheck(&ast);
}

test "sema.ia_structs_assign_retrive" {
    const source = "struct S {int a;}; fun main() void {int_array a; struct S b; a = new int_array[10]; b.a = a[0]; a[0] = b.a;}";
    var ast = try testMe(source);
    // expect error
    try typecheck(&ast);
}

test "sema.ia_int_arryay_member_struct" {
    const source = "struct S {int_array a;}; fun main() void {struct S b; b.a = new int_array[10]; b.a[0] = 1;}";
    var ast = try testMe(source);
    // expect error
    try typecheck(&ast);
}
test "sema.ia_struct_toself" {
    const source = "struct S {int_array a; int b;}; fun main() void {struct S c; c.a = new int_array[100]; c.b = c.a[20];}";
    var ast = try testMe(source);
    // expect error
    try typecheck(&ast);
}

test "sema.ia_struct_toself2" {
    const source = "struct S {struct S s; int_array a; int b;}; fun main() void {struct S c; c.s.s.s.s.s.s.s.a = new int_array[100]; c.s.s.s.s.s.s.s.b = c.a[20]; c.s.s.s.s.s.s.s.s.s.a[20] = 2;}";
    var ast = try testMe(source);
    // expect error
    try typecheck(&ast);
}

test "sema.struct_null" {
    const source = "struct S {int a;}; fun main() void {struct S b; b = null;}";
    var ast = try testMe(source);
    // expect error
    try typecheck(&ast);
}
