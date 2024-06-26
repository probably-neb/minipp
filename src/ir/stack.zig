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

    const types = try gen_types(&ir, ast);
    ir.types.fill(types);

    const globals = try gen_globals(&ir, ast);
    ir.globals.fill(globals);

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
    // log.trace("numDecls: {}\n", .{numDecls});
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

        var size: u32 = 0;
        var fi: usize = 0;

        while (fieldIter.next()) |fieldNode| : (fi += 1) {
            const field = fieldNode.kind.TypedIdentifier;
            const fieldNameID = ir.internIdent(field.getName(ast));

            const fieldAstType = field.getType(ast);
            const fieldType = ir.astTypeToIRType(fieldAstType);
            size += IR.Type.aligned_sizeof(IR.ALIGN, fieldType);

            fields[fi] = Field.init(fieldNameID, fieldType);
        }
        types[ti] = Struct.init(structNameID, size, fields);
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

    // create a copy of funcIter we will use to generate proto definitions
    // of the functions before generating the ir for each function body
    // this ensures when generating the function body ir, that when
    // we encounter a function call it will be able to find the
    // name + return type to reference
    var funcProtoIter = funcIter;

    const numFuncs = funcIter.calculateLen();

    // log.trace("num funcs := {}\n", .{numFuncs});
    var funcs: []Fun = try ir.alloc.alloc(Fun, numFuncs);
    var fi: usize = 0;

    while (funcProtoIter.next()) |node| : (fi += 1) {
        const funNode = node.kind.Function;
        const funName = ir.internIdent(funNode.getName(ast));
        const funReturnType = ir.astTypeToIRType(funNode.getReturnType(ast).?);

        // we don't neeeeed to generate the params before the function bodies
        // are generated, as we assume all that jazz has been checked by sema
        // but I wrote the Function.init to take them, and they are
        // logically part of the function proto definition so I've
        // kept them here
        const params = try gen_function_params(ir, ast, funNode);
        var fun = IR.Function.init(ir.alloc, funName, funReturnType, params);
        funcs[fi] = fun;
    }

    // NOTE: identical to phi above this point

    ir.funcs.fill(funcs);
    fi = 0;

    while (funcIter.next()) |funcNode| : (fi += 1) {
        var fun = &funcs[fi];
        fun.* = (try gen_function(ir, ast, fun, funcNode.kind.Function)).*;
    }
    return funcs;
}

/// @param fun: takes a function that has already been initialized
/// with the bare minimum name + params + return type information (proto)
pub fn gen_function(
    ir: *IR,
    ast: *const Ast,
    fun: *IR.Function,
    funNode: Ast.Node.Kind.FunctionType,
) !*const IR.Function {
    // TODO: exit/entry blocks should probably be stored separately
    // i.e. entry = bb[0], exit = bb[1], rest = bb[2..exit)
    // possibly as fields in `struct Function` with a helper on `Function`
    // that checks `i < 2 ? [self.entry, self.exit][i] : self.bbs[i - 2]`

    // entry block is the one that holds `alloca`s
    // separated to make it easier to just append `alloca`s
    // to the start and maintain hoisting (all allocas are in order at start of function)
    const entryBB = try fun.newBB("entry");

    // Exit is like entryBB in that it is intentionally bare, containing only
    // the return instruction
    const exitBB = try fun.newBB("exit");

    const funBody = funNode.getBody(ast);

    // (should) only used if the function returns a value
    var retReg = IR.Register.default;

    // generate alloca for the return value if the function returns a value
    // this makes it so ret reg is always `%0`
    if (fun.returnType != .void) {
        // allocate a stack slot for the return value in the entry
        retReg = try fun.addInst(entryBB, Inst.alloca(fun.returnType), fun.returnType);
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

    // add allocas for all function parameters
    // and store the params into them
    // this is necessary to allow for mutating params
    // PERF: identify params that are stored to and gen alloca/store
    // for them only
    for (fun.params.items, 0..) |item, ID| {
        const name = item.name;
        const typ = item.type;
        const alloca = Inst.alloca(typ);
        const allocaReg = try fun.addNamedInst(entryBB, alloca, name, typ);
        const storeInst = Inst.store(IR.Ref.fromReg(allocaReg), IR.Ref.param(@intCast(ID), name, typ));
        _ = try fun.addAnonInst(entryBB, storeInst);
    }

    const bodyBB = try fun.newBBWithParent(entryBB, "body");
    try fun.addCtrlFlowInst(entryBB, Inst.jmp(IR.Ref.label(bodyBB)));

    // generate IR for the function body
    const lastBB = try gen_block(ir, ast, fun, bodyBB, ast.get(funNode.body).*);
    try fun.addCtrlFlowInst(lastBB, IR.Inst.jmp(IR.Ref.label(exitBB)));

    // generate return instruction in exit block
    if (fun.returnType != .void) {
        // load it in the exit block
        // NOTE: could use a name like anon_return or something, but that would have to go into the intern pool
        const retValReg = try fun.addInst(exitBB, Inst.load(fun.returnType, IR.Ref.fromReg(retReg)), fun.returnType);
        // return the loaded return value
        // using addAnonInst so ctrl flow cfg construction is skipped
        // as we'll hook everything up manually as we go
        try fun.addAnonInst(exitBB, Inst.ret(fun.returnType, IR.Ref.fromReg(retValReg)));
    } else {
        // void return
        _ = try fun.addInst(exitBB, Inst.retVoid(), .void);
    }

    return fun;
}

fn gen_function_params(
    ir: *IR,
    ast: *const Ast,
    funNode: Ast.Node.Kind.FunctionType,
) ![]IR.Function.Param {
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

/// generates the IR for a block of statements, i.e. a function body or Block node
/// returns the ID of the final basic block it generated instructions for
/// @param initialBB: the ID of the basic block to begin generating instructions in
/// @param node: either a FunctionBody or Block node
/// @param parentStatementIter: the statement iterator of the parent node
///                             this is a wierd hacky way to get around the
///                             fact the `iterStatements` method is primitive
///                             minded and does not skip nested statements
///                             the simplest solution was just to pass the
///                             parent statement iter to the child block as
///                             needed and step it for every statement in
///                             the child block
fn gen_block(
    ir: *IR,
    ast: *const Ast,
    fun: *IR.Function,
    initialBB: IR.BasicBlock.ID,
    node: Ast.Node,
) !IR.BasicBlock.ID {
    var curBB = initialBB;

    var statementsIter = switch (node.kind) {
        .FunctionBody => |funBody| funBody.iterStatements(ast),
        .Block => |block| block.iterStatements(ast),
        else => unreachable,
    };

    while (statementsIter.next()) |stmtNode| {
        const statementIndex = stmtNode.kind.Statement.statement;
        const innerNode = ast.get(statementIndex);
        const kind = innerNode.kind;
        // FIXME: check for control flow
        switch (kind) {
            .ConditionalIf => |_if| {
                const condBB = curBB;
                const condRef = try gen_expression(ir, ast, fun, condBB, ast.get(_if.cond).*);

                const isIfElse = _if.isIfElse(ast);
                var ifBlockNode = ast.get(_if.block).*;
                var elseBlockNode: ?Ast.Node = null;

                if (isIfElse) {
                    const condIfElse = ifBlockNode.kind.ConditionalIfElse;
                    elseBlockNode = ast.get(condIfElse.elseBlock).*;
                    ifBlockNode = ast.get(condIfElse.ifBlock).*;
                }

                const ifBB = try fun.newBBWithParent(condBB, "if.then");
                const ifEndBB = try gen_block(ir, ast, fun, ifBB, ifBlockNode);
                if (ifBlockNode.kind.Block.range(ast)) |range| {
                    statementsIter.skipTo(range[1]);
                }

                var elseBB: IR.BasicBlock.ID = undefined;
                var endBB: IR.BasicBlock.ID = undefined;

                if (elseBlockNode) |elseBlock| {
                    elseBB = try fun.newBBWithParent(condBB, "if.else");
                    const elseEndBB = try gen_block(ir, ast, fun, elseBB, elseBlock);
                    if (elseBlock.kind.Block.range(ast)) |range| {
                        statementsIter.skipTo(range[1]);
                    }
                    // now that we've created elseBB we can create
                    // endBB while maintaining order
                    endBB = try fun.newBB("if.end");
                    // need to handle this inside here because
                    // this scope is the only one that knows the else
                    // block exists and where it ended
                    const jmpEndInst = Inst.jmp(IR.Ref.label(endBB));
                    fun.addCtrlFlowInst(elseEndBB, jmpEndInst) catch |err| {
                        if (err != error.ConflictingControlFlowInstructions) {
                            return err;
                        }
                        // assume the conflicting control flow is a jmp to ret
                        // and ignore it
                    };
                } else {
                    endBB = try fun.newBBWithParent(condBB, "if.end");
                    // this makes it so we can make the branch outside
                    // of this (zig not mini) if/else block
                    // and point it to ifBB and elseBB
                    // and have it pointing to the endBB if
                    // there was no else
                    // pretty nifty if you ask me
                    elseBB = endBB;
                }
                // there will always be a jmp from the end of the
                // if to the end
                const ifJmpEndInst = Inst.jmp(IR.Ref.label(endBB));
                fun.addCtrlFlowInst(ifEndBB, ifJmpEndInst) catch |err| {
                    if (err != error.ConflictingControlFlowInstructions) {
                        return err;
                    }
                    // assume the conflicting control flow is a jmp to ret
                    // and ignore it
                };

                const brInst = Inst.br(condRef, IR.Ref.label(ifBB), IR.Ref.label(elseBB));
                try fun.addCtrlFlowInst(condBB, brInst);
                curBB = endBB;
            },
            .ConditionalIfElse => unreachable,
            .While => |whil| {
                const startBB = curBB;
                const condExpr = ast.get(whil.cond).*;
                const initialCondRef = try gen_expression(ir, ast, fun, curBB, condExpr);

                const bodyBB = try fun.newBBWithParent(curBB, "while.body");
                const whileBlockNode = ast.get(whil.block).*;
                const endBodyBB = try gen_block(ir, ast, fun, bodyBB, whileBlockNode);
                if (whileBlockNode.kind.Block.range(ast)) |range| {
                    statementsIter.skipTo(range[1]);
                }
                const endCondRef = try gen_expression(ir, ast, fun, endBodyBB, condExpr);

                const endBB = try fun.newBB("while.end");

                const startBr = Inst.br(initialCondRef, IR.Ref.label(bodyBB), IR.Ref.label(endBB));
                try fun.addCtrlFlowInst(startBB, startBr);

                const endBr = Inst.br(endCondRef, IR.Ref.label(bodyBB), IR.Ref.label(endBB));
                try fun.addCtrlFlowInst(endBodyBB, endBr);

                curBB = endBB;
            },
            .Return => |ret| {
                if (ret.expr) |retExpr| {
                    const retExprRef = try gen_expression(ir, ast, fun, curBB, ast.get(retExpr).*);
                    const returnRegID = fun.returnReg.?;
                    const returnReg = fun.regs.get(returnRegID);
                    const returnRef = IR.Ref.fromReg(returnReg);
                    utils.assert(returnReg.type.eq(fun.returnType), "returnReg.type == fun.returnType", .{});
                    const inst = Inst.store(
                        returnRef,
                        retExprRef,
                    );
                    try fun.addAnonInst(curBB, inst);
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
fn gen_statement(
    ir: *IR,
    ast: *const Ast,
    fun: *IR.Function,
    bb: IR.BasicBlock.ID,
    statementNode: Ast.Node,
) !void {
    const node = ast.get(statementNode.kind.Statement.statement);
    const kind = node.kind;

    switch (kind) {
        .Assignment => |assign| {
            const to = ast.get(assign.lhs).kind.LValue;
            const toName = ir.internIdentNodeAt(ast, to.ident);
            // log.trace("assign to: {s} [{d}]\n", .{ ast.getIdentValue(to.ident), toName });
            // FIXME: handle selector chain
            var assignRef = try fun.getNamedRef(ir, toName);
            if (to.chain) |chain| {
                const structRef = blk: {
                    // it's a chain, so the assign must be a struct, we're in the load/store ir,
                    // so it's got to be a %struct.{name}** (i.e. a pointer struct pointer on the stack)
                    // so we have to load it first because gep can't do shit in this situation
                    const loadStructInst = Inst.load(assignRef.type, assignRef);
                    const loadReg = try fun.addNamedInst(bb, loadStructInst, assignRef.name, assignRef.type);
                    break :blk IR.Ref.fromReg(loadReg);
                };
                assignRef = try gen_selector_chain(ir, ast, fun, bb, structRef, chain, .Assignment);
            }

            // FIXME: rhs could also be a `read` handle!
            const exprNode = ast.get(assign.rhs).*;
            const exprRef = try gen_expression(ir, ast, fun, bb, exprNode);
            const inst = Inst.store(
                assignRef,
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
        .Invocation => {
            _ = try gen_invocation(ir, fun, ast, bb, node);
        },
        // control flow should be handled by the caller
        .ConditionalIf, .ConditionalIfElse, .While => unreachable,
        else => utils.todo("gen_statement {any}\n", .{kind}),
    }
}

fn gen_expression(
    ir: *IR,
    ast: *const Ast,
    fun: *IR.Function,
    bb: IR.BasicBlock.ID,
    exprNode: Ast.Node,
) anyerror!IR.Ref {
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
            const ty: IR.Type = switch (tok.kind) {
                .Not => .bool,
                .Minus => .int,
                else => unreachable,
            };
            const res = try fun.addNamedInst(bb, inst, exprReg.name, ty);
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
                .DoubleEq => Inst.cmp(.Eq, lhsRef, rhsRef),
                .NotEq => Inst.cmp(.NEq, lhsRef, rhsRef),
                .Lt => Inst.cmp(.Lt, lhsRef, rhsRef),
                .LtEq => Inst.cmp(.LtEq, lhsRef, rhsRef),
                .Gt => Inst.cmp(.Gt, lhsRef, rhsRef),
                .GtEq => Inst.cmp(.GtEq, lhsRef, rhsRef),
                else => std.debug.panic("gen_expression.binary_operation: {s}\n", .{@tagName(tok.kind)}),
            };
            const ty: IR.Type = switch (tok.kind) {
                .Plus, .Minus, .Mul, .Div => .int,
                .DoubleEq, .NotEq, .Lt, .LtEq, .Gt, .GtEq, .And, .Or => .bool,
                else => unreachable,
            };
            const name = join_names(lhsRef.name, rhsRef.name);
            const res = try fun.addNamedInst(bb, inst, name, ty);
            return IR.Ref.fromReg(res);
        },
        .Selector => |sel| {
            const factor = ast.get(sel.factor).kind.Factor;
            // I know I know, I just don't know what else to call it
            const atomIndex = factor.factor;
            const atom = ast.get(atomIndex);
            var resultRef = switch (atom.kind) {
                .Identifier => ident: {
                    const identID = ir.internToken(ast, atom.token);
                    const ref = try fun.getNamedRef(ir, identID);
                    if (ref.kind == .param) {
                        break :ident ref;
                    }
                    const inst = Inst.load(ref.type, ref);
                    const res = try fun.addNamedInst(bb, inst, ref.name, ref.type);
                    break :ident IR.Ref.fromReg(res);
                },
                .False => false: {
                    break :false IR.Ref.immFalse();
                },
                .True => true: {
                    break :true IR.Ref.immTrue();
                },
                .Number => num: {
                    const tok = atom.token;
                    const num = ir.internToken(ast, tok);
                    break :num IR.Ref.immediate(num, .int);
                },
                .New => |new| new: {
                    const structName = ir.internIdentNodeAt(ast, new.ident);
                    const structType = try ir.types.get(structName);
                    const s = structType;

                    const memRef = try gen_malloc_struct(ir, fun, bb, s);
                    break :new memRef;
                },
                .NewIntArray => |newArr| newArr: {
                    const lenStr = ast.getIdentValue(newArr.length);
                    const len = try std.fmt.parseInt(u32, lenStr, 10);
                    const arrType = IR.Type{
                        .arr = .{
                            .type = .int,
                            .len = len,
                        },
                    };
                    const alloca = alloca: {
                        // allocate the array on the stack
                        // yielding reference to the *array* (i.e. [int x {len}]*)
                        const inst = Inst.alloca(arrType);
                        const reg = try fun.addInst(bb, inst, arrType);
                        const ref = IR.Ref.fromReg(reg);
                        break :alloca ref;
                    };
                    const cast = cast: {
                        // bitcast the array to an int* from [int x {len}]*
                        // as int_arrays are passed around and treated as int*
                        // (i.e. unknown length)
                        const inst = Inst.bitcast(alloca, .int_arr);
                        const reg = try fun.addInst(bb, inst, .int_arr);
                        const ref = IR.Ref.fromReg(reg);
                        break :cast ref;
                    };
                    break :newArr cast;
                },
                .Null => null: {
                    // TODO: if llvm doesn't like this, or I want to make the code pretty
                    // whichever comes first...
                    // the way to not have i8* null is to have a `null_` type in IR.Type
                    // and have it replaced with the destination type in stores (which are
                    // the only valid place to have null)
                    //
                    // FIXME: this is mad broken yo
                    // I think that we should implment a structID named null,
                    // since it is a keyword the user could never do so,
                    // and this would add no new abstractions to the IR
                    break :null IR.Ref.immnull();
                },
                .Invocation => IR.Ref.fromReg(try gen_invocation(ir, fun, ast, bb, atom)),
                .Expression => try gen_expression(ir, ast, fun, bb, atom.*),
                else => utils.todo("gen_expression.selector.factor: {s}\n", .{@tagName(atom.kind)}),
            };
            if (sel.chain) |chain| {
                resultRef = try gen_selector_chain(ir, ast, fun, bb, resultRef, chain, .Usage);
                switch (resultRef.type) {
                    .strct, .arr, .int_arr => {},
                    // Whenever we are accessing a field of a struct,
                    // if it isn't a struct or an array, it should be derefed
                    // so it isn't a pointer
                    else => {
                        const loadInst = Inst.load(resultRef.type, resultRef);
                        const resultReg = try fun.addNamedInst(bb, loadInst, resultRef.name, resultRef.type);
                        resultRef = IR.Ref.fromReg(resultReg);
                    },
                }
            }
            return resultRef;
        },
        .Read => {
            const scanfRef = IR.Ref.scanf(ir);

            const fmtRef = blk: {
                // the format as an array of i8
                const fmtRef = IR.Ref.read_fmt(ir);
                // use gep to get the fmt string as an i8*
                // (ptr to first element) instead of an array
                // i.e. `i8* ptr = &fmt[0];`
                const zeroIndex = IR.Ref.immediate(0, .i32);
                const gepFmtPtr = Inst.gep(fmtRef.type, fmtRef, zeroIndex);
                const res = try fun.addInst(bb, gepFmtPtr, .i8);
                break :blk IR.Ref.fromReg(res);
            };

            // the reference to the scratch global whose pointer
            // we pass to scanf to read into
            // it is of type i32, which we will sign extend to i64
            // after reading
            const readScratchRef = IR.Ref.read_scratch(ir);

            const args = blk: {
                var args = try ir.alloc.alloc(IR.Ref, 2);
                args[0] = fmtRef;
                args[1] = readScratchRef;
                break :blk args;
            };
            // we don't care about the return value of scanf
            // because who needs error handling
            _ = try fun.addInst(bb, Inst.call(.i32, scanfRef, args), .void);

            // load @.read_scratch into a register before sign extending
            const resReg = blk: {
                const loadResInst = Inst.load(.i32, readScratchRef);
                const resReg = try fun.addInst(bb, loadResInst, .i32);
                break :blk resReg;
            };

            const i64ResReg = blk: {
                // sign extend the i32 put into the @.read_scratch
                // global to an i64
                const resRef = IR.Ref.fromReg(resReg);
                const sextInst = Inst.sext(resRef, .int);
                const sextResReg = try fun.addInst(bb, sextInst, .int);
                break :blk sextResReg;
            };

            // return reference to the sign extended i64 value we read
            return IR.Ref.fromReg(i64ResReg);
        },
        else => utils.todo("gen_expression: {s}\n", .{@tagName(exprNode.kind)}),
    }
    unreachable;
}

fn gen_invocation(ir: *IR, fun: *IR.Function, ast: *const Ast, bb: IR.BasicBlock.ID, node: *const Ast.Node) !IR.Register {
    const invoc = node.*.kind.Invocation;
    const funNameID = ir.internIdentNodeAt(ast, invoc.funcName);
    const funRef = try fun.getNamedRef(ir, funNameID);

    var args: []IR.Ref = undefined;
    if (invoc.args) |argsIndex| {
        var argsIter = ast.get(argsIndex).*.kind.Arguments.iter(ast);
        const numArgs = argsIter.calculateLen();
        args = try ir.alloc.alloc(IR.Ref, numArgs);
        var ai: usize = 0;
        while (argsIter.next()) |arg| : (ai += 1) {
            const argRef = try gen_expression(ir, ast, fun, bb, arg);
            args[ai] = argRef;
        }
    } else {
        args = &[_]IR.Ref{};
    }

    const callInst = Inst.call(funRef.type, funRef, args);
    return try fun.addNamedInst(bb, callInst, funRef.name, funRef.type);
}

// FIXME: allow redefinition of globals
fn gen_malloc_struct(ir: *IR, fun: *IR.Function, bb: IR.BasicBlock.ID, s: IR.StructType) !IR.Ref {
    // the args to malloc are just (i32 sizeof({struct type}))
    const args = blk: {
        var args: []IR.Ref = try ir.alloc.alloc(IR.Ref, 1);
        args[0] = IR.Ref.immu32(s.size, .i32);
        break :blk args;
    };

    // the pointer returned by malloc as an i8*
    const retRef = blk: {
        const mallocRef: IR.Ref = IR.Ref.malloc(ir);
        const mallocInst = Inst.call(.i8, mallocRef, args);
        const memReg = try fun.addNamedInst(bb, mallocInst, s.name, .i8);
        const memRef = IR.Ref.fromReg(memReg);
        break :blk memRef;
    };

    // the malloced pointer casted from an i8* to a {struct type}*
    const resRef = blk: {
        const cast = Inst.bitcast(retRef, s.getType());
        const castReg = try fun.addNamedInst(bb, cast, s.name, s.getType());
        const castRef = IR.Ref.fromReg(castReg);
        break :blk castRef;
    };
    // return the {struct type}* reference
    return resRef;
}

fn gen_free_struct(ir: *IR, fun: *IR.Function, bb: IR.BasicBlock.ID, ptrRef: IR.Ref) !void {
    // the {struct type}* pointer casted to an i8*
    const castRef = blk: {
        const castInst = Inst.bitcast(ptrRef, .i8);
        const castReg = try fun.addInst(bb, castInst, .i8);
        const castRef = IR.Ref.fromReg(castReg);
        break :blk castRef;
    };

    // the args to free are just (i8* {casted ptr})
    const args = blk: {
        var args = try ir.alloc.alloc(IR.Ref, 1);
        args[0] = castRef;
        break :blk args;
    };

    const freeRef = IR.Ref.free(ir);
    const free = Inst.call(.void, freeRef, args);
    // call free, we don't care about return types as
    // the grammar does not specify a return value from delete
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
        // i.e. `i8* ptr = &fmt[0];`
        const zeroIndex = IR.Ref.immediate(0, .i32);
        const gepFmtPtr = Inst.gep(fmtRef.type, fmtRef, zeroIndex);
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
    const print = Inst.call(printRef.type, printRef, args);
    _ = try fun.addInst(bb, print, printRef.type);
    return;
}

const SelectorType = enum {
    Usage,
    Assignment,
};
/// @param chainIndex: the `chain` field in `LValue` or `Selector`
///               i.e. the pointer to the `SelectorChain` node
/// @returns the reference to the last instruction in the chain
fn gen_selector_chain(
    ir: *IR,
    ast: *const Ast,
    fun: *IR.Function,
    bb: IR.BasicBlock.ID,
    startRef: IR.Ref,
    chainIndex: usize,
    selectorType: SelectorType,
) !IR.Ref {
    var chainLink = ast.get(chainIndex).kind.SelectorChain;
    if (startRef.type == .int_arr) {
        // early return if the startRef is an array type as we know
        // that the chainLink is the index into the array and the result will be an
        // int and therefore there will be no more field accesses
        const exprNode = ast.get(chainLink.ident).*;
        utils.assert(exprNode.kind == .Expression, "chainLink.ident should be expression for chain off of top level int_array", .{});
        const indexRef = try gen_expression(ir, ast, fun, bb, exprNode);
        const inst = Inst.gep(startRef.type, startRef, indexRef);
        var reg = try fun.addNamedInst(bb, inst, startRef.name, indexRef.type);
        var ref = IR.Ref.fromReg(reg);
        // if (selectorType == .Usage) {
        //     const loadInst = Inst.load(ref.type, ref);
        //     reg = try fun.addNamedInst(bb, loadInst, ref.name, ref.type);
        //     ref = IR.Ref.fromReg(reg);
        // }
        return ref;
    }
    var structType = try ir.types.get(startRef.type.strct);
    var fieldNameID = ir.internIdentNodeAt(ast, chainLink.ident);
    var fieldInfo = try structType.getFieldWithName(fieldNameID);
    var fieldIndex = fieldInfo.index;
    var field = fieldInfo.field;
    var inst = IR.Inst.gep(structType.getType(), startRef, IR.Ref.immu32(fieldIndex, .i32));

    var reg = try fun.addNamedInst(bb, inst, field.name, field.type);
    var ref = IR.Ref.fromReg(reg);
    var nextChainLink = chainLink.next;
    var prevField = field;

    while (nextChainLink) |nextIndex| : (nextChainLink = chainLink.next) {
        chainLink = ast.get(nextIndex).kind.SelectorChain;

        if (prevField.type == .int_arr) {
            // early return if we reach a field that is an array type as we know
            // that the chainLink is the index into the array and the result will be an
            // int and therefore there will be no more field accesses
            const exprNode = ast.get(chainLink.ident).*;
            utils.assert(exprNode.kind == .Expression, "chainLink.ident should be expression for chain off of int_array field", .{});
            const indexRef = try gen_expression(ir, ast, fun, bb, exprNode);
            inst = Inst.gep(startRef.type, startRef, indexRef);
            reg = try fun.addNamedInst(bb, inst, startRef.name, indexRef.type);
            ref = IR.Ref.fromReg(reg);
            // if (selectorType == .Usage) {
            //     const loadInst = Inst.load(ref.type, ref);
            //     reg = try fun.addNamedInst(bb, loadInst, ref.name, ref.type);
            //     ref = IR.Ref.fromReg(reg);
            // }
            return ref;
        }
        utils.assert(prevField.type == .strct, "prevField.type.isStruct in `gen_selector_chain`", .{});
        structType = try ir.types.get(prevField.type.strct);
        fieldNameID = ir.internIdentNodeAt(ast, chainLink.ident);
        fieldInfo = try structType.getFieldWithName(fieldNameID);
        fieldIndex = fieldInfo.index;
        field = fieldInfo.field;
        const loadRef = blk: {
            // need to load the secondary struct because rn we have a struct**
            const loadInst = Inst.load(structType.getType(), ref);
            reg = try fun.addNamedInst(bb, loadInst, structType.name, structType.getType());
            break :blk IR.Ref.fromReg(reg);
        };
        inst = IR.Inst.gep(structType.getType(), loadRef, IR.Ref.immu32(fieldIndex, .i32));

        reg = try fun.addNamedInst(bb, inst, field.name, field.type);
        ref = IR.Ref.fromReg(reg);
    }
    if (ref.type == .strct and selectorType == .Usage) {
        // if the final field being accessed in the struct, we are polite
        // and return a pointer to the struct instead of the pointer to the pointer to the struct
        // because that is (certainly?) what the consumer expects
        const loadInst = Inst.load(ref.type, ref);
        reg = try fun.addNamedInst(bb, loadInst, ref.name, ref.type);
        ref = IR.Ref.fromReg(reg);
    }
    return ref;
}

// Returns a or b if the other is null and they aren't,
// NULL if they are both non null
fn join_names(a: IR.StrID, b: IR.StrID) IR.StrID {
    if (a == IR.InternPool.NULL) {
        return b;
    }
    if (b == IR.InternPool.NULL) {
        return a;
    }
    return IR.InternPool.NULL;
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
    // NOTE: testing on the strings is really nice except when you
    // add or remove an instruction and then all the registers are off
    // this can be fixed by doing the following
    // vim command with the lines selected:
    // ```
    // :'<,'>s/[\( i\d*\) ]\@<!\(\d\+\)/\=submatch(1)+1/g
    // ```
    // replacing the `+1` after the `submatch` with `-1` if
    // you removed an instruction
    // after that all of the alloca registers will be wrong
    // (actually all references to registers defined before the new/removed line)
    // but that's probably easier to fix
    // the `[\( i\d*\) ]\@<!` part makes it so it doesn't change
    // numbers prefixed with `i` or ` ` i.e. number types
    // and indices respectively
    var arena = std.heap.ArenaAllocator.init(ting.allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    const ir = try testMe(input);
    const gotIRstr = try ir.stringify(alloc);

    // NOTE: could use multiline strings for the
    // expected value but, that makes it so you can't put
    // comments inbetween the lines
    // idk rough tradeoff

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
            "  %_0 = alloca i1",
            "  %a1 = alloca i1",
            "  br label %body1",
            "body1:",
            "  %_3 = xor i1 0, 1",
            "  store i1 %_3, i1* %a1",
            "  %a5 = load i1, i1* %a1",
            "  store i1 %a5, i1* %_0",
            "  br label %exit",
            "exit:",
            "  %_8 = load i1, i1* %_0",
            "  ret i1 %_8",
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
        "  %_0 = alloca i64",
        "  %i1 = alloca i64",
        "  %count2 = alloca i64",
        "  store i64 %count, i64* %count2",
        "  %base4 = alloca i64",
        "  store i64 %base, i64* %base4",
        "  br label %body1",
        "body1:",
        "  store i64 0, i64* %i1",
        "  %i8 = load i64, i64* %i1",
        "  %count9 = load i64, i64* %count2",
        "  %_10 = icmp slt i64 %i8, %count9",
        "  br i1 %_10, label %while.body2, label %while.end3",
        "while.body2:",
        "  %i11 = load i64, i64* %i1",
        "  %i12 = add i64 %i11, 1",
        "  store i64 %i12, i64* %i1",
        "  %base14 = load i64, i64* %base4",
        "  %base15 = load i64, i64* %base4",
        "  %_16 = add i64 %base14, %base15",
        "  store i64 %_16, i64* %base4",
        "  %i18 = load i64, i64* %i1",
        "  %count19 = load i64, i64* %count2",
        "  %_20 = icmp slt i64 %i18, %count19",
        "  br i1 %_20, label %while.body2, label %while.end3",
        "while.end3:",
        "  %base23 = load i64, i64* %base4",
        "  store i64 %base23, i64* %_0",
        "  br label %exit",
        "exit:",
        "  %_26 = load i64, i64* %_0",
        "  ret i64 %_26",
        "}",
    });
}

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
        "  br label %body1",
        "body1:",
        "  %S2 = call i8* (i32) @malloc(i32 8)",
        "  %S3 = bitcast i8* %S2 to %struct.S*",
        "  store %struct.S* %S3, %struct.S** %s0",
        "  %s5 = load %struct.S*, %struct.S** %s0",
        "  %_6 = bitcast %struct.S* %s5 to i8*",
        "  call void (i8*) @free(i8* %_6)",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
    });
}

test "stack.str.new.with-bool-align" {
    try expectResultsInIR(
        \\struct S {
        \\  int x;
        \\  bool y;
        \\};
        \\
        \\fun main() void {
        \\  struct S s;
        \\  s = new S;
        \\}
    , .{
        "%struct.S = type { i64, i1 }",
        "",
        "define void @main() {",
        "entry:",
        "  %s0 = alloca %struct.S*",
        "  br label %body1",
        "body1:",
        "  %S2 = call i8* (i32) @malloc(i32 16)",
        "  %S3 = bitcast i8* %S2 to %struct.S*",
        "  store %struct.S* %S3, %struct.S** %s0",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
    });
}

test "stack.str.nested-assign" {
    errdefer log.print();
    try expectResultsInIR(
        \\struct S {
        \\  int x;
        \\  int y;
        \\  struct S s;
        \\};
        \\
        \\fun main() void {
        \\  struct S s;
        \\  int a;
        \\  s = new S;
        \\  a = s.s.s.x + s.s.y;
        \\  print a endl;
        \\  delete s;
        \\}
    , .{
        "%struct.S = type { i64, i64, %struct.S* }",
        "",
        "define void @main() {",
        "entry:",
        "  %s0 = alloca %struct.S*",
        "  %a1 = alloca i64",
        "  br label %body1",
        "body1:",
        // new (malloc)
        "  %S3 = call i8* (i32) @malloc(i32 24)",
        "  %S4 = bitcast i8* %S3 to %struct.S*",
        "  store %struct.S* %S4, %struct.S** %s0",
        // get x
        "  %s6 = load %struct.S*, %struct.S** %s0",
        "  %s7 = getelementptr %struct.S, %struct.S* %s6, i1 0, i32 2",
        "  %S8 = load %struct.S*, %struct.S** %s7",
        "  %s9 = getelementptr %struct.S, %struct.S* %S8, i1 0, i32 2",
        "  %S10 = load %struct.S*, %struct.S** %s9",
        "  %x11 = getelementptr %struct.S, %struct.S* %S10, i1 0, i32 0",
        "  %x12 = load i64, i64* %x11",
        // get y
        "  %s13 = load %struct.S*, %struct.S** %s0",
        "  %s14 = getelementptr %struct.S, %struct.S* %s13, i1 0, i32 2",
        "  %S15 = load %struct.S*, %struct.S** %s14",
        "  %y16 = getelementptr %struct.S, %struct.S* %S15, i1 0, i32 1",
        "  %y17 = load i64, i64* %y16",
        "  %_18 = add i64 %x12, %y17",
        "  store i64 %_18, i64* %a1",
        // print
        "  %a20 = load i64, i64* %a1",
        "  %_21 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0",
        "  %_22 = call i32 (i8*, ...) @printf(i8* %_21, i64 %a20)",
        // delete (free)
        "  %s23 = load %struct.S*, %struct.S** %s0",
        "  %_24 = bitcast %struct.S* %s23 to i8*",
        "  call void (i8*) @free(i8* %_24)",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
    });
}

test "stack.str.gep-assign" {
    try expectResultsInIR(
        \\struct S {
        \\  int x;
        \\  int y;
        \\  struct S s;
        \\};
        \\
        \\fun main() void {
        \\  struct S s;
        \\  s.s.y = 0;
        \\}
    , .{
        "%struct.S = type { i64, i64, %struct.S* }",
        "",
        "define void @main() {",
        "entry:",
        "  %s0 = alloca %struct.S*",
        "  br label %body1",
        "body1:",
        "  %s2 = load %struct.S*, %struct.S** %s0",
        "  %s3 = getelementptr %struct.S, %struct.S* %s2, i1 0, i32 2",
        "  %S4 = load %struct.S*, %struct.S** %s3",
        "  %y5 = getelementptr %struct.S, %struct.S* %S4, i1 0, i32 1",
        "  store i64 0, i64* %y5",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
    });
}

test "stack.str.assign-null" {
    try expectResultsInIR(
        \\struct S {
        \\  struct S s;
        \\};
        \\
        \\fun main() void {
        \\  struct S s;
        \\  s.s = null;
        \\}
    , .{
        "%struct.S = type { %struct.S* }",
        "",
        "define void @main() {",
        "entry:",
        "  %s0 = alloca %struct.S*",
        "  br label %body1",
        "body1:",
        "  %s2 = load %struct.S*, %struct.S** %s0",
        "  %s3 = getelementptr %struct.S, %struct.S* %s2, i1 0, i32 0",
        "  store %struct.S* null, %struct.S** %s3",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
    });
}

test "stack.if-else" {
    try expectResultsInIR(
        \\fun main() void {
        \\  int a;
        \\  if (true) {
        \\    a = 1;
        \\  } else {
        \\    a = 2;
        \\  }
        \\}
    , .{
        "define void @main() {",
        "entry:",
        "  %a0 = alloca i64",
        "  br label %body1",
        "body1:",
        "  br i1 1, label %if.then2, label %if.else3",
        "if.then2:",
        "  store i64 1, i64* %a0",
        "  br label %if.end4",
        "if.else3:",
        "  store i64 2, i64* %a0",
        "  br label %if.end4",
        "if.end4:",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
    });
}

test "stack.if-no-else" {
    errdefer log.print();
    try expectResultsInIR(
        \\fun main() void {
        \\  int a;
        \\  if (true) {
        \\    a = 1;
        \\  }
        \\  a = 2;
        \\}
    , .{
        "define void @main() {",
        "entry:",
        "  %a0 = alloca i64",
        "  br label %body1",
        "body1:",
        "  br i1 1, label %if.then2, label %if.end3",
        "if.then2:",
        "  store i64 1, i64* %a0",
        "  br label %if.end3",
        "if.end3:",
        "  store i64 2, i64* %a0",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
    });
}

test "stack.nested-if-no-else" {
    try expectResultsInIR(
        \\fun main() void {
        \\  int a;
        \\  if (true) {
        \\    if (false) {
        \\      a = 1;
        \\    }
        \\  }
        \\  a = 2;
        \\}
    , .{
        "define void @main() {",
        "entry:",
        "  %a0 = alloca i64",
        "  br label %body1",
        "body1:",
        "  br i1 1, label %if.then2, label %if.end5",
        "if.then2:",
        "  br i1 0, label %if.then3, label %if.end4",
        "if.then3:",
        "  store i64 1, i64* %a0",
        "  br label %if.end4",
        "if.end4:",
        "  br label %if.end5",
        "if.end5:",
        "  store i64 2, i64* %a0",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
    });
}

test "stack.nested-if-else" {
    try expectResultsInIR(
        \\fun main() void {
        \\  int a;
        \\  if (true) {
        \\    if (false) {
        \\      a = 1;
        \\    } else {
        \\      a = 3;
        \\    }
        \\  }
        \\  a = 2;
        \\}
    , .{
        "define void @main() {",
        "entry:",
        "  %a0 = alloca i64",
        "  br label %body1",
        "body1:",
        "  br i1 1, label %if.then2, label %if.end6",
        "if.then2:",
        "  br i1 0, label %if.then3, label %if.else4",
        "if.then3:",
        "  store i64 1, i64* %a0",
        "  br label %if.end5",
        "if.else4:",
        "  store i64 3, i64* %a0",
        "  br label %if.end5",
        "if.end5:",
        "  br label %if.end6",
        "if.end6:",
        "  store i64 2, i64* %a0",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
    });
}

test "stack.while-nested-if" {
    try expectResultsInIR(
        \\fun main() void {
        \\  int a;
        \\  if (true) {
        \\    while (false) {
        \\      a = 1;
        \\      a = 3;
        \\    }
        \\  }
        \\  a = 2;
        \\}
    , .{
        "define void @main() {",
        "entry:",
        "  %a0 = alloca i64",
        "  br label %body1",
        "body1:",
        "  br i1 1, label %if.then2, label %if.end5",
        "if.then2:",
        "  br i1 0, label %while.body3, label %while.end4",
        "while.body3:",
        "  store i64 1, i64* %a0",
        "  store i64 3, i64* %a0",
        "  br i1 0, label %while.body3, label %while.end4",
        "while.end4:",
        "  br label %if.end5",
        "if.end5:",
        "  store i64 2, i64* %a0",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
    });
}

test "stack.global-access" {
    try expectResultsInIR(
        \\int a;
        \\fun main() void {
        \\  a = 1;
        \\}
    , .{
        "@a = global i64 undef, align 8",
        "",
        "define void @main() {",
        "entry:",
        "  br label %body1",
        "body1:",
        "  store i64 1, i64* @a",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
    });
}

test "stack.fun-call.no-args-no-ret" {
    errdefer log.print();

    try expectResultsInIR(
        \\fun foo() void {}
        \\
        \\fun main() void {
        \\  foo();
        \\}
    , .{
        "define void @foo() {",
        "entry:",
        "  br label %body1",
        "body1:",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
        "",
        "define void @main() {",
        "entry:",
        "  br label %body1",
        "body1:",
        "  call void () @foo()",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
    });
}

test "stack.fun-call.args+ret" {
    errdefer log.print();

    try expectResultsInIR(
        \\struct S {
        \\  int x;
        \\  bool y;
        \\  struct S s;
        \\};
        \\fun foo(int a, bool b, struct S s) int {
        \\  if (a <= 1) {
        \\      return a;
        \\  }
        \\  return s.x * a;
        \\}
        \\
        \\fun main() void {
        \\  struct S s;
        \\  int res;
        \\  res = foo(5, true, s);
        \\}
    , .{
        "%struct.S = type { i64, i1, %struct.S* }",
        "",
        "define i64 @foo(i64 %a, i1 %b, %struct.S* %s) {",
        "entry:",
        "  %_0 = alloca i64",
        "  %a1 = alloca i64",
        "  store i64 %a, i64* %a1",
        "  %b3 = alloca i1",
        "  store i1 %b, i1* %b3",
        "  %s5 = alloca %struct.S*",
        "  store %struct.S* %s, %struct.S** %s5",
        "  br label %body1",
        "body1:",
        "  %a8 = load i64, i64* %a1",
        "  %a9 = icmp sle i64 %a8, 1",
        "  br i1 %a9, label %if.then2, label %if.end3",
        "if.then2:",
        "  %a10 = load i64, i64* %a1",
        "  store i64 %a10, i64* %_0",
        "  br label %exit",
        "if.end3:",
        "  %s14 = load %struct.S*, %struct.S** %s5",
        "  %x15 = getelementptr %struct.S, %struct.S* %s14, i1 0, i32 0",
        "  %x16 = load i64, i64* %x15",
        "  %a17 = load i64, i64* %a1",
        "  %_18 = mul i64 %x16, %a17",
        "  store i64 %_18, i64* %_0",
        "  br label %exit",
        "exit:",
        "  %_21 = load i64, i64* %_0",
        "  ret i64 %_21",
        "}",
        "",
        "define void @main() {",
        "entry:",
        "  %s0 = alloca %struct.S*",
        "  %res1 = alloca i64",
        "  br label %body1",
        "body1:",
        "  %s3 = load %struct.S*, %struct.S** %s0",
        "  %foo4 = call i64 (i64, i1, %struct.S*) @foo(i64 5, i1 1, %struct.S* %s3)",
        "  store i64 %foo4, i64* %res1",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
    });
}

test "stack.str.read" {
    try expectResultsInIR(
        \\fun main() void {
        \\  int a;
        \\  a = read;
        \\}
    , .{
        "define void @main() {",
        "entry:",
        "  %a0 = alloca i64",
        "  br label %body1",
        "body1:",
        "  %_2 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0",
        "  %_3 = call i32 (i8*, ...) @scanf(i8* %_2, i32* @.read_scratch)",
        "  %_4 = load i32, i32* @.read_scratch",
        "  %_5 = sext i32 %_4 to i64",
        "  store i64 %_5, i64* %a0",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
    });
}
