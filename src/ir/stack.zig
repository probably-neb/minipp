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
        return undefined;
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

    var fun = IR.Function.init(ir.alloc, funName, funReturnType);
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
    // TODO: fun.addLocal(name, type) instead of the `Inst.alloca` below
    // for consistency with exit and so we isolate how entry/exit blocks are stored
    // / managed
    const exitBB = try fun.newBB();
    // TODO: fun.addReturnReg(...regInfo);
    // for easy
    _ = exitBB;

    const funBody = funNode.getBody(ast);

    var declsIter = funBody.iterLocalDecls(ast);
    while (declsIter.next()) |declNode| {
        const decl = declNode.kind.TypedIdentifier;
        const declName = ir.internIdent(decl.getName(ast));
        const declType = ir.astTypeToIRType(decl.getType(ast));

        const alloca = Inst.alloca(declType);
        _ = try fun.addNamedInst(entryBB, alloca, declName, declType);
    }

    var statementsIter = funBody.iterStatements(ast);
    while (statementsIter.next()) |stmtNode| {
        // FIXME: check for control flow
        try gen_statement(ir, ast, &fun, entryBB, stmtNode);
    }

    return fun;
}

/// Generates the IR for a statement. NOTE: not supposed to handle control flow
fn gen_statement(ir: *IR, ast: *const Ast, fun: *IR.Function, bb: IR.BasicBlock.ID, statementNode: Ast.Node) !void {
    const kind = statementNode.kind;

    switch (kind) {
        .Assignment => |assign| {
            const to = ast.get(assign.lhs).kind.LValue;
            const toName = ir.internIdentNodeAt(ast, to.ident);
            // FIXME: handle selector chain
            const allocReg = try fun.getNamedAllocaReg(toName);
            _ = allocReg;

            // FIXME: rhs could also be a `read` handle!
            const exprNode = ast.get(assign.rhs).kind.Expression;
            const exprReg = try gen_expression(ir, ast, fun, bb, exprNode);
            _ = exprReg;
        },
        .ConditionalIf => unreachable,
        .ConditionalIfElse => unreachable,
        .While => unreachable,
        else => utils.todo("gen_statement {any}\n", .{kind}),
    }
}

fn gen_expression(ir: *IR, ast: *const Ast, fun: *IR.Function, bb: IR.BasicBlock.ID, exprNode: Ast.Node.Kind.ExpressionType) !IR.Register {
    const expr = ast.get(exprNode.expr);
    const kind = expr.kind;
    switch (kind) {
        .UnaryOperation => |unary| {
            const tok = expr.token;
            switch (tok.kind) {
                .Not => {
                    const onExpr = ast.get(unary.on).*.kind.Expression;
                    const exprReg = try gen_expression(ir, ast, fun, bb, onExpr);
                    utils.assert(exprReg.type == IR.Type.bool, "Unary `!` on non-bool type {any}\n", .{exprReg.type});
                    const inst = Inst.not(IR.Ref.local(exprReg.id, exprReg.name));
                    const res = try fun.addNamedInst(bb, inst, exprReg.name, IR.Type.bool);
                    return res;
                },
                .Minus => {
                    const onExpr = ast.get(unary.on).*.kind.Expression;
                    const exprReg = try gen_expression(ir, ast, fun, bb, onExpr);
                    utils.assert(exprReg.type == IR.Type.int, "Unary `-` on non-int type {any}\n", .{exprReg.type});
                    const inst = Inst.neg(IR.Ref.local(exprReg.id, exprReg.name));
                    const res = try fun.addNamedInst(bb, inst, exprReg.name, IR.Type.int);
                    return res;
                },
                else => unreachable,
            }
        },
        .Selector => |sel| {
            const factor = ast.get(sel.factor).kind.Factor;
            // I know I know, I just don't know what else to call it
            const atomIndex = factor.factor;
            const atom = ast.get(atomIndex);
            switch (atom.kind) {
                .Identifier => |ident| {
                    _ = ident;
                    const identID = ir.internToken(ast, atom.token);
                    const reg = try fun.getNamedAllocaReg(identID);
                    const inst = Inst.load(reg.type, IR.Ref.local(reg.id, reg.name));
                    return try fun.addNamedInst(bb, inst, reg.name, reg.type);
                },
                else => utils.todo("gen_expression.selector.factor: {any}\n", .{atom.kind}),
            }

            // TODO: gen gep if chain not null
        },
        else => utils.todo("gen_expression: {any}\n", .{kind}),
    }
    unreachable;
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
    const got = fun.insts.array();
    for (expected, 0..) |expectedInst, i| {
        if (i >= got.len) {
            // bro what was copilot thinking with this one
            // try ting.expectEqualStrings("expected more insts", "got fewer insts");
            log.err("expected more insts. Missing:\n{any}\n", .{expected[i..]});
            return error.NotEnoughInstructions;
        }
        var gotInst = got[i];
        // NOTE: when expanding, must make sure the `res` field on the
        // expected insts are set as they won't be by the helper creator
        // functions
        try ting.expectEqual(@intFromEnum(expectedInst.op), @intFromEnum(gotInst.op));
    }
}

test "stack.fun.empty" {
    errdefer log.print();
    const ir = try testMe("fun main() void {}");
    try ting.expectEqual(@as(usize, 1), ir.funcs.items.len);
}

test "stack.fun.unary-ret" {
    errdefer log.print();
    const ir = try testMe("fun main() bool { bool a; a = !false; return a; }");
    const mainName = try ir.getIdentID("main");
    const main = try ir.getFun(mainName);
    const a = try ir.getIdentID("a");
    const expected = [_]Inst{
        Inst.alloca(IR.Type.bool),
        Inst.not(IR.Ref.immediate(IR.InternPool.FALSE)),
        Inst.load(IR.Type.bool, IR.Ref.local(0, a)),
        Inst.ret(IR.Type.bool, IR.Ref.local(1, a)),
    };
    try expectIRMatches(main, &expected);
}
