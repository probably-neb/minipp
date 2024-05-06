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
    try fun.bbs.get(lastBB).addOutgoer(exitBB);

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
            .ConditionalIf, .ConditionalIfElse, .While => utils.todo("gen_function.controlFlow {any}\n", .{stmtNode.kind}),
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
            const allocReg = try fun.getNamedAllocaReg(toName);

            // FIXME: rhs could also be a `read` handle!
            const exprNode = ast.get(assign.rhs).*;
            const exprRef = try gen_expression(ir, ast, fun, bb, exprNode);
            const inst = Inst.store(
                allocReg.type,
                IR.Ref.fromReg(allocReg),
                exprRef.type,
                exprRef,
            );
            try fun.addAnonInst(bb, inst);
        },
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
            const tok = exprNode.token;
            switch (tok.kind) {
                .Not => {
                    const onExpr = ast.get(unary.on).*;
                    const exprReg = try gen_expression(ir, ast, fun, bb, onExpr);
                    // utils.assert(exprReg.type == IR.Type.bool, "Unary `!` on non-bool type {any}\n", .{exprReg.type});
                    const inst = Inst.not(exprReg);
                    const res = try fun.addNamedInst(bb, inst, exprReg.name, .bool);
                    return IR.Ref.fromReg(res);
                },
                .Minus => {
                    const onExpr = ast.get(unary.on).*;
                    const exprReg = try gen_expression(ir, ast, fun, bb, onExpr);
                    // utils.assert(exprReg.type == IR.Type.int, "Unary `-` on non-int type {any}\n", .{exprReg.type});
                    const inst = Inst.neg(exprReg);
                    const res = try fun.addNamedInst(bb, inst, exprReg.name, .int);
                    return IR.Ref.fromReg(res);
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
                .Identifier => {
                    const identID = ir.internToken(ast, atom.token);
                    const reg = try fun.getNamedAllocaReg(identID);
                    const inst = Inst.load(reg.type, IR.Ref.fromReg(reg));
                    const res = try fun.addNamedInst(bb, inst, reg.name, reg.type);
                    return IR.Ref.fromReg(res);
                },
                .False => {
                    return IR.Ref.immFalse();
                },
                else => utils.todo("gen_expression.selector.factor: {any}\n", .{atom.kind}),
            }

            // TODO: gen gep if chain not null
        },
        else => utils.todo("gen_expression: {any}\n", .{exprNode.kind}),
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
        \\  while(i < count){
        \\      i = i + 1;
        \\      base = base + base;
        \\  }
        \\  return base;
        \\ }
    , .{
        "define i32 @main(i64 %count, i64 %base) {",
        "entry:",
        "  %0 = alloca i64",
        "  %i1 = alloca i64",
        "  br label %2",
        "2:",
        "  store i64 0, i64* %i1",
        "  %4 = cmp slt i64 %i1, %count",
        "  br i1 %5, label %3, label %4",
        "3:",
        "  %6 = load i64* %i1",
        "  %7 = add i64 %6, 1",
        "  store i64 %8, i64* %i1",
        "  %9 = load i64* %base",
        "  %10 = add i64 %9, %9",
        "  store i64 %10, i64* %base",
        "  %12 = load i64* %i1",
        "  %13 = cmp slt i64 %12, %count",
        "  br i1 %14, label %3, label %4",
        "4:",
        "  br label %exit",
        "exit:",
        "  %16 = load i64* %base",
        "  ret i64 %16",
        "}",
    });
}
