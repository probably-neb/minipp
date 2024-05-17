// v0: Dylan Leifer-Ives 6/24
//     Directly ripped from ben's stack code
// PHI ssa
// v1: Dylan Leifer-Ives 6/24
//
//  ACTIVE{
//  - do a pre pass to create the full bb heirarchy before its filled. I think this will be fundementally easier to reason about
//  -- while loops should work in the manner
//  --- cond
//  --- body
//  --- cond2
//  ---- back edge
//  --- exit
//  -- in this pass add in the phi nodes for the entry blocks
//  - create the phi noes for the entry block
//  // on creation of every new block, push down all of the values that were defined from the parent.
//  // so this means for every single block after entry, they should have all of the values, both the params and the
//  // declarations
//  -- possibly split out the phi nodes into their own part of the basic block
//
//  - On iteration through the statements, there will always be a parent block's value to phi off of (after entry)
//  this means that there will always be a reference.
//  -- therefore on the branching back to things is where the important updates to the phi values will occur
//
//
//  define dso_local i32 @if3_square(i32 %num) {
//  entry:
//          %num0 = phi i32 [%num, %entry]
//          %b0 = phi i32 [0, %entry]
//          ; cmp to see if num is > 0
//          %cmp0 = icmp sgt i32 %num0, 0
//          br i1 %cmp0, label %if.then, label %if.end
//  if.then:
//          %b1 = phi i32 [%b0, %entry]
//          %num1 = phi i32 [%num0, %entry]
//          br label %while.cond

//  if.end:
//          %b2 = phi i32 [%b0, %entry], [%b6, %while.end]
//          %num2 = phi i32 [%num0, %entry]
//          br label %exit

//  while.cond:
//          %b3 = phi i32 [%b1, %if.then], [%b5, %while.body]
//          %num3 = phi i32 [%num1, %if.then], [%num5, %while.body]
//          ; while num < 4
//          %cmp1 = icmp slt i32 %num3, 4
//          br i1 %cmp1, label %while.body, label %while.end

//  exit:
//          %b4 = phi i32 [%b2, %if.end]
//          ret i32 %b4

//  while.body:
//          %b5 = phi i32 [%b3, %while.cond]
//          %num4 = phi i32 [%num3, %while.cond]
//          ;num += b
//          %num5 = add i32 %num4, %b5
//          br label %while.cond ;-> update while cond's phi nodes

//  while.end:
//          %b6 = phi i32 [%b5, %while.cond]
//          %num6 = phi i32 [%num3, %while.cond]
//          br label %if.end

//  }
// }
//  BROKEN{
//          gen_stateent
//          searchCFGforREG -> should wait a bit longer on this
//  }
//  HOLD{
//          PHI -> CFG upsearch
//          - searchCFGforREG fixme on the cfg upsearch, this will create a loop I recon, so i need to be careful with how I write this
//          - make sure that the phi that will be created (if needed), has a reference to this block just in case
//          Done{
//                  - check that vars can be the same name of different types
//                  - be able to get the type of an ast node
//                  - update the search BB for reg so that it is the proper type
//          } we do not need to check the type we are not allowed to name multiple vals the same name in the same scope
//  } Need to implement the phi creation for every block foremost,

const std = @import("std");

const IR = @import("ir_phi.zig");
const Inst = IR.Inst;

const Ast = @import("../ast.zig");
const log = @import("../log.zig");
const utils = @import("../utils.zig");

pub const MemError = std.mem.Allocator.Error;

pub const PhiGen = @This();
const Context = PhiGen;
arena: std.heap.ArenaAllocator,

/// An arena allocator used for temporary allocations. Any
/// memory that persists in the IR should be allocated using
/// the IR's allocator
pub fn generate(alloc: std.mem.Allocator, ast: *const Ast) !IR {
    const arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    const this = PhiGen{ .arena = arena };
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

    // TODO: rv1 implement the walking of the functinos to generate all of the
    //       desired BasicBlocks before they are needed
    // FIXME: make them not allocas but rather phi accesses
    // add allocas for all local variables
    var declsIter = funBody.iterLocalDecls(ast);
    while (declsIter.next()) |declNode| {
        const decl = declNode.kind.TypedIdentifier;
        const declName = ir.internIdent(decl.getName(ast));
        const declType = ir.astTypeToIRType(decl.getType(ast));
        // add a phi instruction to the entryBB, then edit it afterwords
        var phiEntries = std.ArrayList(IR.PhiEntry).init(fun.alloc);
        const selfEntry = IR.PhiEntry{ .bb = entryBB, .ref = IR.Ref.default };
        try phiEntries.append(selfEntry);
        const phi = Inst.phi(IR.Ref.default, declType, phiEntries);

        const phiID = try fun.addNamedInst(entryBB, phi, declName, declType);
        const phiInstID = phiID.inst;
        const phiInst = fun.insts.get(phiInstID);
        phiInst.extra.phi.items[0] = IR.PhiEntry{ .bb = entryBB, .ref = IR.Ref.fromReg(phiID) };
    }

    // FIXME: also do this as phis instead of allocas, allocas should only be used for structs and the like
    // add allocas for all function parameters
    // and store the params into them
    // this is necessary to allow for mutating params
    // PERF: identify params that are stored to and gen alloca/store
    // for them only
    for (fun.params.items, 0..) |item, ID| {
        const name = item.name;
        const typ = item.type;
        const parRef = IR.Ref.param(@intCast(ID), name, typ);
        var phiEntries = std.ArrayList(IR.PhiEntry).init(fun.alloc);
        const selfEntry = IR.PhiEntry{ .bb = entryBB, .ref = parRef };
        try phiEntries.append(selfEntry);
        const phi = Inst.phi(IR.Ref.default, typ, phiEntries);

        _ = try fun.addNamedInst(entryBB, phi, name, typ);
    }

    const bodyBB = try fun.newBBWithParent(entryBB, "body");
    try fun.addCtrlFlowInst(entryBB, Inst.jmp(IR.Ref.label(bodyBB)));

    // pre generate the IR for the body

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
            var assignRef = try fun.getNamedRef(ir, toName, bb);

            if (to.chain) |chain| {
                const structRef = blk: {
                    // it's a chain, so the assign must be a struct, we're in the load/store ir,
                    // so it's got to be a %struct.{name}** (i.e. a pointer struct pointer on the stack)
                    // so we have to load it first because gep can't do shit in this situation
                    const loadStructInst = Inst.load(assignRef.type, assignRef);
                    const loadReg = try fun.addNamedInst(bb, loadStructInst, assignRef.name, assignRef.type);
                    break :blk IR.Ref.fromReg(loadReg);
                };
                assignRef = try gen_selector_chain(ir, ast, fun, bb, structRef, chain, true);
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
                    const ref = try fun.getNamedRef(ir, identID, bb);
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
                resultRef = try gen_selector_chain(ir, ast, fun, bb, resultRef, chain, null);
                switch (resultRef.type) {
                    .strct, .arr => {},
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
    const funRef = try fun.getNamedRef(ir, funNameID, bb);

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
    optionallyNoDerefFinal: ?bool,
) !IR.Ref {
    var structType = try ir.types.get(startRef.type.strct);
    var chainLink = ast.get(chainIndex).kind.SelectorChain;
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
    const okToDerefFinal = !(optionallyNoDerefFinal orelse false);
    if (ref.type == .strct and okToDerefFinal) {
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

fn inputToIRString(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    const ir = try testMe(input);
    return try ir.stringify(alloc);
}

test "stack.fun.empty" {
    errdefer log.print();
    const ir = try testMe("fun main() void {}");
    try ting.expectEqual(@as(usize, 1), ir.funcs.items.len);
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

test "phi.print_test" {
    errdefer log.print();
    const in = "fun main() void { int a,b,c; a = 1; b = 2; c = 3; }";
    // print out the IR
    var arena = std.heap.ArenaAllocator.init(ting.allocator);
    var alloc = arena.allocator();
    defer arena.deinit();
    const ir_str = try inputToIRString(in, alloc);
    // check that the IR is correct
    std.debug.print("{s}\n", .{ir_str});
}
