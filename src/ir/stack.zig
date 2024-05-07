const std = @import("std");

const IR = @import("ir.zig");
const Inst = IR.Inst;

const Ast = @import("../ast.zig");
const log = @import("../log.zig");
const utils = @import("../utils.zig");

pub const StackGen = @This();
const Ctx = StackGen;

/// An arena allocator used for temporary allocations. Any
/// memory that persists in the IR should be allocated using
/// the IR's allocator
arena: std.heap.ArenaAllocator,

pub fn generate(alloc: std.mem.Allocator, ast: *const Ast) !IR {
    const arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    const this = StackGen{ .arena = arena };
    _ = this;

    var ir = IR.init(alloc);

    const globals = try gen_globals(&ir, ast);
    ir.globals.fill(globals);

    const types = try gen_types(&ir, ast);
    ir.types.fill(types);

    const funcs = try gen_functions(&ir, ast);
    ir.funcs.fill(funcs);

    return ir;
}

pub const MemError = std.mem.Allocator.Error;

pub fn gen_globals(ir: *IR, ast: *const Ast) MemError![]IR.GlobalsList.Item {
    const Global = IR.GlobalsList.Item;
    const programDecls = ast.find(.ProgramDeclarations, 0) orelse unreachable;
    const globalDeclsIndex = programDecls.kind.ProgramDeclarations.declarations;
    if (globalDeclsIndex == null) {
        // wierd I know but it coerces to empty list because
        // zig has reasonable defaults
        // there is a test that checks for this do not worry
        return &[_]IR.GlobalsList.Item{};
    }
    var globalDeclsIter = ast.get(globalDeclsIndex.?).kind.LocalDeclarations.iter(ast);

    const numDecls = globalDeclsIter.calculateLen();
    const globalDecls: []Global = try ir.alloc.alloc(Global, numDecls);

    var gi: usize = 0;
    while (globalDeclsIter.next()) |globalNode| : (gi += 1) {
        const global = globalNode.kind.TypedIdentifier;

        const ident = ir.internIdent(global.getName(ast));
        const irType = ir.astTypeToIRType(global.getType(ast));

        globalDecls[gi] = Global.init(ident, irType);
    }

    return globalDecls;
}

pub fn gen_types(ir: *IR, ast: *const Ast) MemError![]IR.TypeList.Item {
    const Struct = IR.TypeList.Item;
    const Field = Struct.Field;

    var iter = ast.structMap.valueIterator();

    // WARN: read the comment at the call to realloc at the end of this function
    const numDecls = iter.len;
    log.trace("numDecls: {}\n", .{numDecls});
    const types: []Struct = try ir.alloc.alloc(Struct, numDecls);

    var ti: usize = 0;

    while (iter.next()) |declIndex| : (ti += 1) {
        // Just a safeguard in case iter.len is lower than the number of declarations
        // see comments before the return
        utils.assert(ti <= numDecls, "ti <= numDecls in `gen_types`. There's a comment about this. I'm Sorry\n", .{});

        const decl = ast.get(declIndex.*).kind.TypeDeclaration;
        const structNameID = ir.internIdentNodeAt(ast, decl.ident);

        var fieldIter = ast.get(decl.declarations).kind.StructFieldDeclarations.iter(ast);

        // pre-iter all fields so no realloc
        const numFields = fieldIter.calculateLen();
        const fields: []Field = try ir.alloc.alloc(Field, numFields);

        var fi: usize = 0;

        while (fieldIter.next()) |fieldNode| : (fi += 1) {
            const field = fieldNode.kind.TypedIdentifier;
            const fieldNameID = ir.internIdent(field.getName(ast));

            const fieldAstType = field.getType(ast);
            const fieldType = ir.astTypeToIRType(fieldAstType);

            fields[fi] = Field.init(fieldNameID, fieldType);
        }
        types[ti] = Struct.init(structNameID, fields);
    }

    // So.... the structMap iter.len is not accurate, only bigger as far as I can tell,
    // so i'm doing the easy thing and just resizing the array here instead of figuring out
    // how to get the correct size. I apologize in advance if `.len` is ever too small
    // and there's an out of bounds error
    const types_sized = try ir.alloc.realloc(types, ti);
    return types_sized;
}

pub fn gen_functions(ir: *IR, ast: *const Ast) ![]IR.Function {
    const Fun = IR.Function;

    // NOTE: not using the `iterFuncs` method because we wan't to use the
    // `calculateLen` helper and I'm too lazy rn to port it
    var funcIter = Ast.NodeIter(.Function).init(ast, 0, ast.nodes.items.len);
    const numFuncs = funcIter.calculateLen();
    log.trace("num funcs := {}\n", .{numFuncs});
    var funcs: []Fun = try ir.alloc.alloc(Fun, numFuncs);
    var fi: usize = 0;

    while (funcIter.next()) |funcNode| : (fi += 1) {
        funcs[fi] = try gen_function(ir, ast, funcNode.kind.Function);
    }
    return funcs;
}

pub fn gen_function(ir: *IR, ast: *const Ast, funNode: Ast.Node.Kind.FunctionType) !IR.Function {
    const funName = ir.internIdent(funNode.getName(ast));
    const funReturnType = ir.astTypeToIRType(funNode.getReturnType(ast).?);
    const params = try gen_function_params(ir, ast, funNode);

    var fun = IR.Function.init(ir.alloc, funName, funReturnType, params);
    // TODO: exit/entry blocks should probably be stored separately
    // i.e. entry = bb[0], exit = bb[1], rest = bb[2..exit)
    // possibly as fields in `struct Function` with a helper on `Function`
    // that checks `i < 2 ? [self.entry, self.exit][i] : self.bbs[i - 2]`

    // entry block is the one that holds `alloca`s
    // separated to make it easier to just append `alloca`s
    // to the start and maintain hoisting (all allocas are in order at start of function)
    const entryBB = try fun.newBB();
    // Exit is like entryBB in that it is intentionally bare, containing only
    // the return instruction
    const exitBB = try fun.newBB();

    const funBody = funNode.getBody(ast);

    // (should) only used if the function returns a value
    var retReg = IR.Register.default;

    // generate alloca for the return value if the function returns a value
    // this makes it so ret reg is always `%0`
    if (funReturnType != .void) {
        // allocate a stack slot for the return value in the entry
        retReg = try fun.addInst(entryBB, Inst.alloca(funReturnType), funReturnType);
        // save it in the function for easy access later
        fun.setReturnReg(retReg.id);
    }

    // add allocas for all local variables
    var declsIter = funBody.iterLocalDecls(ast);
    while (declsIter.next()) |declNode| {
        const decl = declNode.kind.TypedIdentifier;
        const declName = ir.internIdent(decl.getName(ast));
        const declType = ir.astTypeToIRType(decl.getType(ast));

        const alloca = Inst.alloca(declType);
        _ = try fun.addNamedInst(entryBB, alloca, declName, declType);
    }

    const bodyBB = try fun.newBBWithParent(entryBB);
    try fun.addCtrlFlowInst(entryBB, Inst.jmp(IR.Ref.label(bodyBB)));

    // generate IR for the function body
    const lastBB = try gen_block(ir, ast, &fun, bodyBB, ast.get(funNode.body).*);
    try fun.addCtrlFlowInst(lastBB, IR.Inst.jmp(IR.Ref.label(exitBB)));

    // generate return instruction in exit block
    if (funReturnType != .void) {
        // load it in the exit block
        const retValReg = try fun.addInst(exitBB, Inst.load(funReturnType, IR.Ref.fromReg(retReg)), funReturnType);
        // return the loaded return value
        // using addAnonInst so ctrl flow cfg construction is skipped
        // as we'll hook everything up manually as we go
        try fun.addAnonInst(exitBB, Inst.ret(funReturnType, IR.Ref.fromReg(retValReg)));
    } else {
        // void return
        _ = try fun.addInst(exitBB, Inst.retVoid(), .void);
    }

    return fun;
}

fn gen_function_params(ir: *IR, ast: *const Ast, funNode: Ast.Node.Kind.FunctionType) ![]IR.Function.Param {
    var params: []IR.Function.Param = undefined;
    const parametersIndex = funNode.getProto(ast).parameters;
    if (parametersIndex == null) {
        return &[_]IR.Function.Param{};
    }
    const paramsIndex = parametersIndex.?;

    var paramsIt = ast.get(paramsIndex).kind.Parameters.iter(ast);

    const numParams = paramsIt.calculateLen();
    params = try ir.alloc.alloc(IR.Function.Param, numParams);

    var pi: usize = 0;
    while (paramsIt.next()) |paramNode| : (pi += 1) {
        const param = paramNode.kind.TypedIdentifier;
        const ident = param.getName(ast);
        const name = ir.internIdent(ident);
        const astType = param.getType(ast);
        const ty = ir.astTypeToIRType(astType);
        params[pi] = .{
            .name = name,
            .type = ty,
        };
    }
    return params;
}

// generates the IR for a block of statements, i.e. a function body or Block node
// returns the ID of the final basic block it generated instructions for
fn gen_block(ir: *IR, ast: *const Ast, fun: *IR.Function, initialBB: IR.BasicBlock.ID, node: Ast.Node) !IR.BasicBlock.ID {
    var curBB = initialBB;

    var statementsIter = switch (node.kind) {
        .FunctionBody => |funBody| funBody.iterStatements(ast),
        .Block => |block| block.iterStatements(ast),
        else => unreachable,
    };

    while (statementsIter.next()) |stmtNode| {
        const innerNode = ast.get(stmtNode.kind.Statement.statement);
        const kind = innerNode.kind;
        // FIXME: check for control flow
        switch (kind) {
            .ConditionalIf, .ConditionalIfElse => utils.todo("gen_function.controlFlow {any}\n", .{stmtNode.kind}),
            .While => |whil| {
                const startBB = curBB;
                const condExpr = ast.get(whil.cond).*;
                const initialCondRef = try gen_expression(ir, ast, fun, curBB, condExpr);

                const bodyBB = try fun.newBBWithParent(curBB);
                const endBodyBB = try gen_block(ir, ast, fun, bodyBB, ast.get(whil.block).*);
                const endCondRef = try gen_expression(ir, ast, fun, bodyBB, condExpr);

                const endBB = try fun.newBB();

                const startBr = Inst.br(initialCondRef, IR.Ref.label(bodyBB), IR.Ref.label(endBB));
                try fun.addCtrlFlowInst(startBB, startBr);

                const endBr = Inst.br(endCondRef, IR.Ref.label(bodyBB), IR.Ref.label(endBB));
                try fun.addCtrlFlowInst(endBodyBB, endBr);

                curBB = endBB;
            },
            .Return => |ret| {
                if (ret.expr) |retExpr| {
                    const retExprReg = try gen_expression(ir, ast, fun, curBB, ast.get(retExpr).*);
                    const returnRegID = fun.returnReg.?;
                    const inst = Inst.store(
                        fun.returnType,
                        IR.Ref.fromReg(fun.regs.get(returnRegID)),
                        retExprReg.type,
                        retExprReg,
                    );
                    try fun.addAnonInst(curBB, inst);
                } else {
                    utils.todo("gen_block.return.void\n", .{});
                }
                try fun.addCtrlFlowInst(curBB, Inst.jmp(IR.Ref.label(IR.Function.exitBBID)));
                return curBB;
            },
            else => try gen_statement(ir, ast, fun, curBB, stmtNode),
        }
    }

    return curBB;
}

/// Generates the IR for a statement. NOTE: not supposed to handle control flow
fn gen_statement(ir: *IR, ast: *const Ast, fun: *IR.Function, bb: IR.BasicBlock.ID, statementNode: Ast.Node) !void {
    const node = ast.get(statementNode.kind.Statement.statement);
    const kind = node.kind;

    switch (kind) {
        .Assignment => |assign| {
            const to = ast.get(assign.lhs).kind.LValue;
            const toName = ir.internIdentNodeAt(ast, to.ident);
            log.trace("assign to: {s} [{d}]\n", .{ ast.getIdentValue(to.ident), toName });
            // FIXME: handle selector chain
            const allocRef = try fun.getNamedRef(ir, toName);

            // FIXME: rhs could also be a `read` handle!
            const exprNode = ast.get(assign.rhs).*;
            const exprRef = try gen_expression(ir, ast, fun, bb, exprNode);
            const inst = Inst.store(
                allocRef.type,
                allocRef,
                exprRef.type,
                exprRef,
            );
            try fun.addAnonInst(bb, inst);
        },
        .Print => |print| {
            const exprRef = try gen_expression(ir, ast, fun, bb, ast.get(print.expr).*);
            const lenb4 = fun.insts.len;
            try gen_print(ir, fun, bb, exprRef, print.hasEndl);
            const lenAfter = fun.insts.len;
            log.trace("print expr: {any} :: {d} -> {d}\n", .{ exprRef, lenb4, lenAfter });
        },
        .Delete => |del| {
            const ptrRef = try gen_expression(ir, ast, fun, bb, ast.get(del.expr).*);
            try gen_free_struct(ir, fun, bb, ptrRef);
        },
        // control flow should be handled by the caller
        .ConditionalIf => unreachable,
        .ConditionalIfElse => unreachable,
        .While => unreachable,
        else => utils.todo("gen_statement {any}\n", .{kind}),
    }
}

fn gen_expression(ir: *IR, ast: *const Ast, fun: *IR.Function, bb: IR.BasicBlock.ID, exprNode: Ast.Node) !IR.Ref {
    switch (exprNode.kind) {
        .Expression => |expr| {
            return gen_expression(ir, ast, fun, bb, ast.get(expr.expr).*);
        },
        .UnaryOperation => |unary| {
            const onExpr = ast.get(unary.on).*;
            const exprReg = try gen_expression(ir, ast, fun, bb, onExpr);
            const tok = exprNode.token;
            const inst = switch (tok.kind) {
                .Not => Inst.not(exprReg),
                .Minus => Inst.neg(exprReg),
                else => unreachable,
            };
            const res = try fun.addNamedInst(bb, inst, exprReg.name, .bool);
            return IR.Ref.fromReg(res);
        },
        .BinaryOperation => |binary| {
            const lhsExpr = ast.get(binary.lhs).*;
            const lhsRef = try gen_expression(ir, ast, fun, bb, lhsExpr);

            const rhsExpr = ast.get(binary.rhs).*;
            const rhsRef = try gen_expression(ir, ast, fun, bb, rhsExpr);

            const tok = exprNode.token;
            const inst = switch (tok.kind) {
                .Plus => Inst.add(lhsRef, rhsRef),
                .Minus => Inst.sub(lhsRef, rhsRef),
                .Mul => Inst.mul(lhsRef, rhsRef),
                .Div => Inst.div(lhsRef, rhsRef),
                .And => Inst.and_(lhsRef, rhsRef),
                .Or => Inst.or_(lhsRef, rhsRef),
                .Eq => Inst.cmp(.Eq, lhsRef, rhsRef),
                .NotEq => Inst.cmp(.NEq, lhsRef, rhsRef),
                .Lt => Inst.cmp(.Lt, lhsRef, rhsRef),
                .LtEq => Inst.cmp(.LtEq, lhsRef, rhsRef),
                .Gt => Inst.cmp(.Gt, lhsRef, rhsRef),
                .GtEq => Inst.cmp(.GtEq, lhsRef, rhsRef),
                else => unreachable,
            };
            const ty: IR.Type = switch (tok.kind) {
                .Plus, .Minus, .Mul, .Div => .int,
                .Eq, .NotEq, .Lt, .LtEq, .Gt, .GtEq, .And, .Or => .bool,
                else => unreachable,
            };
            const name = switch (lhsRef.name) {
                IR.InternPool.NULL => rhsRef.name,
                else => lhsRef.name,
            };
            const res = try fun.addNamedInst(bb, inst, name, ty);
            return IR.Ref.fromReg(res);
        },
        .Selector => |sel| {
            const factor = ast.get(sel.factor).kind.Factor;
            // I know I know, I just don't know what else to call it
            const atomIndex = factor.factor;
            const atom = ast.get(atomIndex);
            switch (atom.kind) {
                .Identifier => {
                    const identID = ir.internToken(ast, atom.token);
                    const ref = try fun.getNamedRef(ir, identID);
                    const inst = Inst.load(ref.type, ref);
                    const res = try fun.addNamedInst(bb, inst, ref.name, ref.type);
                    return IR.Ref.fromReg(res);
                },
                .False => {
                    return IR.Ref.immFalse();
                },
                .True => {
                    return IR.Ref.immTrue();
                },
                .Number => {
                    const tok = atom.token;
                    const num = ir.internToken(ast, tok);
                    return IR.Ref.immediate(num, .int);
                },
                .New => |new| {
                    const structName = ir.internIdentNodeAt(ast, new.ident);
                    const structType = ir.types.get(structName);
                    const s = structType;

                    const memRef = try gen_malloc_struct(ir, fun, bb, s);
                    return memRef;
                },
                else => utils.todo("gen_expression.selector.factor: {s}\n", .{@tagName(atom.kind)}),
            }

            // TODO: gen gep if selector chain not null
        },
        else => utils.todo("gen_expression: {any}\n", .{exprNode.kind}),
    }
    unreachable;
}

// FIXME: allow redefinition of globals
fn gen_malloc_struct(ir: *IR, fun: *IR.Function, bb: IR.BasicBlock.ID, s: IR.StructType) !IR.Ref {
    const mallocRef: IR.Ref = IR.Ref.malloc(ir);

    var args: []IR.Ref = try ir.alloc.alloc(IR.Ref, 1);
    args[0] = IR.Ref.immu32(s.size, .i32);

    const mallocInst = Inst.call(.i8, mallocRef, args);
    const memReg = try fun.addNamedInst(bb, mallocInst, s.name, .i8);
    const memRef = IR.Ref.fromReg(memReg);

    const cast = Inst.bitcast(.i8, memRef, s.getType());
    const castReg = try fun.addNamedInst(bb, cast, s.name, s.getType());
    const castRef = IR.Ref.fromReg(castReg);

    return castRef;
}

fn gen_free_struct(ir: *IR, fun: *IR.Function, bb: IR.BasicBlock.ID, ptrRef: IR.Ref) !void {
    const castInst = Inst.bitcast(ptrRef.type, ptrRef, .i8);
    const castReg = try fun.addInst(bb, castInst, .i8);
    const castRef = IR.Ref.fromReg(castReg);

    const args = blk: {
        var args = try ir.alloc.alloc(IR.Ref, 1);
        args[0] = castRef;
        break :blk args;
    };

    const freeRef = IR.Ref.free(ir);
    const free = Inst.call(.void, freeRef, args);
    _ = try fun.addInst(bb, free, .void);
    return;
}

fn gen_print(ir: *IR, fun: *IR.Function, bb: IR.BasicBlock.ID, expr: IR.Ref, nl: bool) !void {
    // either a pointer to the printf format string
    // with a trailing newline or a trailing space
    const fmtRef = if (nl) IR.Ref.print_ln_fmt(ir) else IR.Ref.print_fmt(ir);

    // the pointer to format string as an i8* instead of an array
    const fmti8PtrRef = blk: {
        // use gep to get the fmt string as an i8*
        // (ptr to first element) instead of an array
        const zeroIndex = IR.Ref.immediate(0, .i32);
        const gepFmtPtr = Inst.gep(fmtRef.type, fmtRef.type, fmtRef, zeroIndex);
        const res = try fun.addInst(bb, gepFmtPtr, .i8);
        break :blk IR.Ref.fromReg(res);
    };
    const printRef = IR.Ref.printf(ir);
    // the args are (i8* fmt, i64 num)
    const args = blk: {
        var args = try ir.alloc.alloc(IR.Ref, 2);
        args[0] = fmti8PtrRef;
        args[1] = expr;
        break :blk args;
    };
    const print = Inst.call(.void, printRef, args);
    _ = try fun.addInst(bb, print, .void);
    return;
}

/////////////
// TESTING //
/////////////

const ting = std.testing;
const testAlloc = std.heap.page_allocator;

fn testMe(input: []const u8) !IR {
    const tokens = try @import("../lexer.zig").Lexer.tokenizeFromStr(input, testAlloc);
    const parser = try @import("../parser.zig").Parser.parseTokens(tokens, input, testAlloc);
    const ast = try Ast.initFromParser(parser);
    const ir = try generate(testAlloc, &ast);
    return ir;
}

test "stack.types.none" {
    const input = "fun main() void {}";
    const ir = try testMe(input);
    try ting.expectEqual(@as(usize, 0), ir.types.len());
}

test "stack.types.multiple" {
    errdefer log.print();
    const input = "struct Foo { int a; bool b; }; struct Bar { int c; int d; int e;}; fun main() void {}";
    const ir = try testMe(input);
    try ting.expectEqual(@as(usize, 2), ir.types.len());
    const foo = ir.types.index(0);
    const bar = ir.types.index(1);
    try ting.expectEqualStrings("Foo", ir.getIdent(foo.name));
    try ting.expectEqual(@as(usize, 2), foo.numFields());
    try ting.expectEqualStrings("Bar", ir.getIdent(bar.name));
    try ting.expectEqual(@as(usize, 3), bar.numFields());
}

test "stack.globals.multiple" {
    const input = "struct Foo { int a; bool b; }; int a; bool b; fun main() void {}";
    const ir = try testMe(input);
    try ting.expectEqual(@as(usize, 2), ir.globals.len());
    const a = ir.globals.index(0);
    const b = ir.globals.index(1);
    try ting.expectEqualStrings("a", ir.getIdent(a.name));
    try ting.expectEqual(IR.Type.int, a.type);
    try ting.expectEqualStrings("b", ir.getIdent(b.name));
    try ting.expectEqual(IR.Type.bool, b.type);
}

test "stack.globals.none" {
    const input = "struct Foo { int a; bool b; }; fun main() void {}";
    const ir = try testMe(input);
    try ting.expectEqual(@as(usize, 0), ir.globals.len());
}

const ExpectedInst = struct {
    inst: IR.Inst,
    // TODO:
    // name: []const u8,
};

// TODO: consider making `IR.Function.withInsts(insts: []inst)` or similar
// that takes an array of insts and creates the function with them
// then we can compare in much more detail
fn expectIRMatches(fun: IR.Function, expected: []const Inst) !void {
    const got = try fun.getOrderedInsts(ting.allocator);
    defer ting.allocator.free(got);
    for (expected, 0..) |expectedInst, i| {
        if (i >= got.len) {
            // bro what was copilot thinking with this one
            // `try ting.expectEqualStrings("expected more insts", "got fewer insts")`;
            log.err("expected more insts. Missing:\n{any}\n", .{expected[i..]});
            // TODO: if op == Binop check extra.op on both
            return error.NotEnoughInstructions;
        }
        var gotInst = got[i];
        // NOTE: when expanding, must make sure the `res` field on the
        // expected insts are set as they won't be by the helper creator
        // functions
        ting.expectEqual(expectedInst.op, gotInst.op) catch {
            log.err("expected op: {s}, got: {s}\n", .{ @tagName(expectedInst.op), @tagName(gotInst.op) });
            log.err("expected insts:\n\n{any}\n", .{expected});
            log.err("got insts:\n\n{any}\n", .{got});
            return error.InvalidInstruction;
        };
    }
}

fn expectResultsInIR(input: []const u8, expected: anytype) !void {
    var arena = std.heap.ArenaAllocator.init(ting.allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    const ir = try testMe(input);
    const gotIRstr = try ir.stringify(alloc);

    // putting all lines in newline separated buf
    // required because as far as I can tell, writing
    // multiline strings in zig is a pain in the
    // metaphorical ass
    comptime var expectedLen: usize = 1;
    inline for (expected) |e| {
        expectedLen += e.len + 1;
    }
    var expectedStr = try alloc.alloc(u8, expectedLen);
    comptime var i: usize = 0;
    inline for (expected) |e| {
        const end = i + e.len;
        @memcpy(expectedStr[i..end], e);
        expectedStr[end] = '\n';
        i = end + 1;
    }
    // the stringify outputs an extra newline at the end.
    // this is the easier fix sue me
    expectedStr[i] = '\n';

    try ting.expectEqualStrings(expectedStr, gotIRstr);
}

test "stack.fun.empty" {
    errdefer log.print();
    const ir = try testMe("fun main() void {}");
    try ting.expectEqual(@as(usize, 1), ir.funcs.items.len);
}

test "stack.str.fun.unary-ret" {
    errdefer log.print();
    try expectResultsInIR(
        \\fun main() bool {
        \\  bool a;
        \\  a = !false;
        \\  return a;
        \\}
    ,
        .{
            "define i1 @main() {",
            "entry:",
            "  %0 = alloca i1",
            "  %a1 = alloca i1",
            "  br label %2",
            // FIXME: need way to say hey callee, this should be an immediate, I
            // didn't make a register for it, glhf!
            "2:",
            "  %3 = xor i1 0, 1",
            "  store i1 %3, i1* %a1",
            "  %a5 = load i1* %a1",
            "  store i1 %a5, i1* %0",
            "  br label %exit",
            "exit:",
            "  %8 = load i1* %0",
            "  ret i1 %8",
            "}",
        },
    );
}

test "stack.str.do-math" {
    errdefer log.print();
    try expectResultsInIR(
    // what the hell is this syntax. Lots of feelings
        \\ fun main(int count, int base) int {
        \\  int i;
        \\  i = 0;
        \\  while(i < count) {
        \\      i = i + 1;
        \\      base = base + base;
        \\  }
        \\  return base;
        \\ }
    , .{
        "define i64 @main(i64 %count, i64 %base) {",
        "entry:",
        "  %0 = alloca i64",
        "  %i1 = alloca i64",
        "  br label %2",
        "  store i64 0, i64* %i1",
        "2:",
        "  %i4 = load i64* %i1",
        "  %count5 = load i64* %count",
        "  %i6 = icmp lt i1 %i4, %count5",
        "  br i1 %i6, label %3, label %4",
        "3:",
        "  %i7 = load i64* %i1",
        "  %i8 = add i64 %i7, 1",
        "  store i64 %i8, i64* %i1",
        "  %base10 = load i64* %base",
        "  %base11 = load i64* %base",
        "  %base12 = add i64 %base10, %base11",
        "  store i64 %base12, i64* %base",
        "  %i14 = load i64* %i1",
        "  %count15 = load i64* %count",
        "  %i16 = icmp lt i1 %i14, %count15",
        "  br i1 %i16, label %3, label %4",
        "4:",
        "  %i19 = load i64* %i1",
        "  %i20 = add i64 %i19, 1",
        "  store i64 %i20, i64* %i1",
        "  %base22 = load i64* %base",
        "  %base23 = load i64* %base",
        "  %base24 = add i64 %base22, %base23",
        "  store i64 %base24, i64* %base",
        "  %base26 = load i64* %base",
        "  store i64 %base26, i64* %0",
        "  br label %exit",
        "exit:",
        "  %29 = load i64* %0",
        "  ret i64 %29",
        "}",
    });
}

// FIXME: stringify types
// FIXME: calculate struct sizes in genTypes (after getting complete list of types)
test "stack.str.new" {
    try expectResultsInIR(
        \\struct S {
        \\  int x;
        \\};
        \\
        \\fun main() void {
        \\  struct S s;
        \\  s = new S;
        \\  delete s;
        \\}
    , .{
        "%struct.S = type { i64 }",
        "",
        "define void @main() {",
        "entry:",
        "  %s0 = alloca %struct.S*",
        "  br label %2",
        "2:",
        "  %S2 = call i8* @malloc(i32 8)",
        "  %S3 = bitcast i8* %3 to %struct.S*",
        "  store %struct.S* %3, %struct.S** %s0",
        "  %s4 = load %struct.S** %s0",
        "  %5 = bitcast %struct.S* %s4 to i8*",
        "  %6 = call void @free(i8* %5)",
        "  br label %exit",
        "exit:",
        "}",
    });
}

// test "stack.str.nested-assign" {
//     errdefer log.print();
//     try expectResultsInIR(
//         \\struct S {
//         \\  int x;
//         \\  int y;
//         \\  struct S s;
//         \\};
//         \\
//         \\fun main() void {
//         \\  struct S s;
//         \\  int a;
//         \\  s = new S;
//         \\  a = s.s.s.x + s.s.y;
//         \\  print a endl;
//         \\  delete s;
//         \\}
//     , .{
//         "%struct.S = type { i64, i64, %struct.S* }",
//         "",
//         "define void @main() {",
//         "entry:",
//         "  %s0 = alloca %struct.S*",
//         "  %a1 = alloca i64",
//         "  store %struct.S* null, %struct.S** %s0",
//         "  br label %2",
//         "2:",
//         "  %4 = call i8* @malloc(i32 24)",
//         "  %4 = bitcast i8* %4 to %struct.S*",
//         "  store %struct.S* %4, %struct.S** %s0",
//         // get x
//         "  %s5 = load %struct.S** %s0",
//         // TODO: move this comment to where gep is actually constructed
//         // NOTE: i'm pretty sure we have to do it this way, not all together
//         // as "subsequent types being indexed into can never be pointers, since that would require loading the pointer before continuing calculation"
//         // i.e. for a dynamically allocated element, you can't know apriori what the ptr to it is, and by extension
//         // cannot know what the ptr to the field is
//         // This is because gep only does ptr arithmetic, not loading
//         // https://llvm.org/docs/LangRef.html#id236
//         "  %s6 = getelementptr %struct.S, %struct.S* %s5, i1 0, i32 2", // get first .s
//         "  %s7 = getelementptr %struct.S, %struct.S* %s6, i1 0, i32 2", // get second .s
//         "  %x8 = getelementptr %struct.S, %struct.S* %s8, i1 0, i32 0", // get .x*
//         "  %x9 = load i64, i64* %x8", // load .x*
//         // get y
//         "  %s10 = load %struct.S** %s0",
//         "  %s11 = getelementptr %struct.S, %struct.S* %s10, i1 0, i32 2",
//         "  %y12 = getelementptr %struct.S, %struct.S* %s11, i1 0, i32 1",
//         "  %y13 = load i64, i64* %y12",
//         // add x and y
//         "  %a14 = add i64 %x9, %y13",
//         "  store i64 %a14, i64* %a1",
//         // print a endl
//         "  %a16 = load i64* %a1",
//         "  %17 = call void @printf(@.println, %a16)",
//         // delete s
//         "  %s18 = load %struct.S** %s0",
//         "  %19 = bitcast %struct.S* %s18 to i8*",
//         "  %20 = call void @free(i8* %19)",
//         "exit:",
//         "}",
//     });
// }

// TODO:
// if/else
// types
// - is_ptr in IR.Type
// more statement kinds I think?
// function calls
// gep
// globals
//
