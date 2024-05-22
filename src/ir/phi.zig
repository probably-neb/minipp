// v0: Dylan Leifer-Ives 6/24
//     Directly ripped from ben's stack code
// PHI ssa
// v1: Dylan Leifer-Ives 6/24
//

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
    const funBody = funNode.getBody(ast);

    fun.cfg = try IR.CfgFunction.generate(fun, ast, funNode, ir);

    var tmpTypesMap = std.AutoHashMap(IR.StrID, IR.Type).init(ir.alloc);
    // generate map of decls to types in the function
    var declsIter = funBody.iterLocalDecls(ast);
    while (declsIter.next()) |declNode| {
        const decl = declNode.kind.TypedIdentifier;
        const declName = ir.internIdent(decl.getName(ast));
        const declType = ir.astTypeToIRType(decl.getType(ast));
        try tmpTypesMap.put(declName, declType);
    }

    for (fun.params.items) |item| {
        const name = item.name;
        const typ = item.type;
        try tmpTypesMap.put(name, typ);
    }

    // convert the used decls into types
    // iterate over the decls iside the cfg
    var cfgDeclsIter = fun.cfg.declsUsed.keyIterator();
    while (cfgDeclsIter.next()) |declNode_| {
        var declNode = declNode_.*;
        var preType = tmpTypesMap.get(declNode);
        if (preType == null) {
            // var str_name = ir.getIdent(declNode);
            var list = try ir.chainToStrIdList(declNode);
            if (list.items.len == 0) {
                return error.DeclNotFound;
            }
            preType = tmpTypesMap.get(list.items[0]);
            if (preType == null) {
                return error.DeclNotFound;
            }
            try fun.typesMap.put(list.items[0], preType.?);
            list.deinit();
        } else {
            try fun.typesMap.put(declNode, preType.?);
        }
    }
    //
    var entryBB = try fun.newBB("entry");
    // generate all of the basic blocks
    for (fun.cfg.postOrder.items) |cfgBlockID| {
        const cfgBlock = fun.cfg.blocks.items[cfgBlockID];
        // check if the block is the exit block
        var bb = try fun.newBB(cfgBlock.name);
        try fun.bbsToCFG.put(bb, cfgBlockID);
        try fun.cfgToBBs.put(cfgBlockID, bb);
        // assing the exit block if we are there
        if (cfgBlockID == fun.cfg.exitID) {
            fun.exitBBID = bb;
        }
    }

    // link them all together
    try fun.linkBBsFromCFG();

    // fill in the entry block with all used decls
    var defined = std.AutoHashMap(IR.StrID, bool).init(ir.alloc);
    var declsKeyIter = fun.cfg.declsUsed.keyIterator();
    while (declsKeyIter.next()) |declNode| {
        const declName = ir.reduceChainToFirstIdent(declNode.*);
        if (defined.contains(declName)) {
            continue;
        }
        if (!fun.defBlocks.contains(declName)) {
            try fun.defBlocks.put(declName, std.ArrayList(IR.BasicBlock.ID).init(ir.alloc));
        }
        try fun.defBlocks.getPtr(declName).?.append(entryBB);
        try defined.put(declName, true);
    }

    // put in the phi functions
    try place_phi_functions(ir, ast, fun, funNode);

    // (should) only used if the function returns a value
    var retReg = IR.Register.default;
    retReg.name = ir.internIdent("return_reg");
    std.debug.print("return reg: {d}\n", .{retReg.name});
    // generate alloca for the return value if the function returns a value
    // this makes it so ret reg is always `%0`
    if (fun.returnType != .void) {
        // allocate a stack slot for the return value in the entry
        retReg = try fun.addNamedInst(entryBB, Inst.alloca(fun.returnType), retReg.name, fun.returnType);
        // save it in the function for easy access later
        fun.setReturnReg(retReg.id);
    }
    try fun.typesMap.put(retReg.name, fun.returnType);

    // go through the basic blocks and add the statements for each.
    // update variableMap as we go
    // ast.debugPrintAst();
    for (fun.cfg.postOrder.items) |cfgBlockID| {
        fun.cfg.printBlockName(cfgBlockID);
        try generateInstsFromCfg(ir, ast, fun, cfgBlockID);
    }
    // link the entry block to the first block

    // relink all the phi nodes
    for (fun.bbs.items()) |bb| {
        var phiIter = bb.phiMap.keyIterator();
        while (phiIter.next()) |phiName| {
            const phiInstID = bb.phiMap.get(phiName.*).?;
            const phiInst = fun.insts.get(phiInstID);
            var asPhi = IR.Inst.Phi.get(phiInst.*);
            for (asPhi.entries.items, 0..) |asPhiEntry, idx| {
                const currentBBID = asPhiEntry.bb;
                const phiNameRef = asPhiEntry.ref.name;
                std.debug.print("phiNameRef: {d}\n", .{phiNameRef});
                std.debug.print("currentBBID: {d}\n", .{currentBBID});
                asPhi.entries.items[idx].ref = try fun.getNamedRef(ir, phiNameRef, currentBBID);
            }
            const toInst = asPhi.toInst();
            fun.insts.set(phiInstID, toInst);
        }
    }

    // handle return
    if (fun.returnType != .void) {
        // get the exit basic block
        const exitBB = fun.bbs.get(fun.exitBBID).*;
        if (exitBB.phiInsts.items.len == 0) unreachable;
        if (exitBB.phiInsts.items.len == 1) {
            const phiInstID = exitBB.phiInsts.items[0];
            const phiInst = fun.insts.get(phiInstID).*;
            std.debug.print("phiInstEntries: {any}\n", .{IR.Inst.Phi.get(phiInst).entries.items});

            var instRet = IR.Inst.ret(fun.returnType, phiInst.res);
            _ = try fun.addInst(fun.exitBBID, instRet, fun.returnType);
        }
    } else {
        _ = try fun.addInst(fun.exitBBID, Inst.retVoid(), .void);
    }

    try fun.addCtrlFlowInst(entryBB, Inst.jmp(IR.Ref.label(fun.cfgToBBs.get(0).?)));
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

pub fn generateInstsFromCfg(ir: *IR, ast: *const Ast, fun: *IR.Function, cfgBlockID: IR.CfgBlock.ID_t) !void {
    const bbID = fun.cfgToBBs.get(cfgBlockID).?;
    const cfgBlock = fun.cfg.blocks.items[cfgBlockID];
    const bb = fun.bbs.get(bbID);
    for (cfgBlock.statements.items) |stmtNode| {
        fun.cfg.printBlockName(cfgBlockID);
        ast.printNodeLine(stmtNode);
    }

    if (cfgBlock.conditional) {
        const statments = cfgBlock.statements;
        // we know that if it is a conditional it is an expression
        if (statments.items.len > 1) unreachable;
        var condRef = try gen_expression(ir, ast, fun, bbID, statments.items[0]);
        //TODO generate the control flow jump
        const brInst = Inst.br(condRef, IR.Ref.label(bb.outgoers[0].?), IR.Ref.label(bb.outgoers[1].?));
        try fun.addCtrlFlowInst(bbID, brInst);
        try fun.bbs.get(bbID).versionMap.put(condRef.name, condRef);

        return;
    } else {
        for (cfgBlock.statements.items) |stmtNode| {
            const isRet = try gen_statement(ir, ast, fun, bbID, stmtNode);
            std.debug.print("isRet: {any}\n", .{stmtNode});
            if (isRet == true) {
                return; // we can just skip the rest
            }
        }
        if (bbID == fun.exitBBID) {
            return;
        }
        const nextBBID = bb.outgoers[0].?;
        const jmpInst = Inst.jmp(IR.Ref.label(nextBBID));
        try fun.addCtrlFlowInst(bbID, jmpInst);
    }
}
//place_phi_functions[]:
//for each node n:
//  for each variable a that is a member of A(orig)[n]:
//	defsites[a] = defsites[a] U [n]
//for each variable a:
//  W = defsites[a]
//      while W != empty list
//          remove some node n from W
//          for each y in DF[n]
// 	        if a does not belong to the set A(phi)[y]
// 		    insert-phi(y,a)
// 		    A(phi)[y] = A(phi)[y] U {a}
// 		    if a does not belong to the set A(orig)[y]
//                      W = W U {y}
//A(orig)[n] = the set of variables defined at node n
//A(phi)[y]  = the set of variables that have phi-functions at node y
//
//insert-phi(y,a):
// insert the statement a = phi (a,a,...) at the top of the block y
// where the phi function has as many arguments as y has predecessors
pub fn place_phi_functions(ir: *IR, ast: *const Ast, fun: *IR.Function, funNode: Ast.Node.Kind.FunctionType) !void {
    _ = funNode;
    _ = ast;
    // for each node n:
    for (fun.cfg.postOrder.items) |cfgBlockID| {
        // for each variable a that is a member of A(orig)[n]:
        for (fun.cfg.blocks.items[cfgBlockID].assignments.items) |defStrID| {
            // create a set of defsites for each variable
            // check if defblocks contains bb's id
            const bbID = fun.cfgToBBs.get(cfgBlockID).?;
            var reducdStr = ir.reduceChainToFirstIdent(defStrID);
            std.debug.print("full {s}, reduced {s}\n", .{ ir.getIdent(defStrID), ir.getIdent(reducdStr) });
            if (!fun.defBlocks.contains(reducdStr)) {
                try fun.defBlocks.put(reducdStr, std.ArrayList(IR.BasicBlock.ID).init(ir.alloc));
            }
            // check if the bb is in the defsites
            var inDefSites = false;
            for (fun.defBlocks.getPtr(reducdStr).?.items) |bb| {
                if (bb == bbID) {
                    inDefSites = true;
                    break;
                }
            }

            if (inDefSites) {
                continue;
            }
            try fun.defBlocks.getPtr(reducdStr).?.append(bbID);
        }
    }
    // for each variable a:
    var defBlocksIter = fun.defBlocks.keyIterator();
    while (defBlocksIter.next()) |defStrID| {
        const defStr = defStrID.*;
        // W = defsites[a]
        var W = try fun.defBlocks.get(defStr).?.clone();
        // while W != empty list
        while (W.items.len != 0) {
            // remove some node n from W
            var bbBlockID = W.pop();
            if (bbBlockID == IR.Function.entryBBID) {
                bbBlockID = fun.cfgToBBs.get(0).?;
            }
            const cfgBlockID = fun.bbsToCFG.get(bbBlockID).?;
            // for each y in DF[n]
            for (fun.cfg.domFront.get(cfgBlockID).?.items) |dfCfgBlockID| {
                // get bbid
                const dfBBID = fun.cfgToBBs.get(dfCfgBlockID).?;
                // if y is not in A(phi)[y]
                const assInBBPhi = fun.bbs.get(dfBBID).phiMap.contains(defStr);
                if (!assInBBPhi) {
                    // 		    insert-phi(y,a)
                    // 		    A(phi)[y] = A(phi)[y] U {a}
                    _ = try IR.BasicBlock.addPhiWithPreds(dfBBID, fun, defStr);

                    // 		    if a does not belong to the set A(orig)[y]
                    // iterate through the cfgBlock's assignments and see if any of them are the same as defStr
                    var isDef: bool = false;
                    for (fun.cfg.blocks.items[dfCfgBlockID].assignments.items) |yIdent| {
                        if (ir.reduceChainToFirstIdent(yIdent) == defStr) {
                            isDef = true;
                            break;
                        }
                    }
                    if (!isDef) {
                        //                      W = W U {y}
                        try W.append(dfBBID);
                    }
                }
            }
        }
        W.deinit();
    }
}

/// Generates the IR for a statement. NOTE: not supposed to handle control flow
fn gen_statement(
    ir: *IR,
    ast: *const Ast,
    fun: *IR.Function,
    bb: IR.BasicBlock.ID,
    statementNode: Ast.Node,
) !bool {
    const node = ast.get(statementNode.kind.Statement.statement);
    const kind = node.kind;

    switch (kind) {
        .Assignment => |assign| {
            const to = ast.get(assign.lhs).kind.LValue;
            const toName = ir.internIdentNodeAt(ast, to.ident);
            std.debug.print("assign to: {s} [{d}]\n", .{ ast.getIdentValue(to.ident), toName });
            var name = toName;

            // FIXME: handle selector chain
            if (to.chain) |chain| {
                var assignRef = try fun.getNamedRef(ir, toName, bb);
                const structRef = blk: {
                    // it's a chain, so the assign must be a struct, we're in the load/store ir,
                    // so it's got to be a %struct.{name}** (i.e. a pointer struct pointer on the stack)
                    // so we have to load it first because gep can't do shit in this situation
                    const loadStructInst = Inst.load(assignRef.type, assignRef);
                    const loadReg = try fun.addNamedInst(bb, loadStructInst, assignRef.name, assignRef.type);
                    break :blk IR.Ref.fromReg(loadReg);
                };
                assignRef = try gen_selector_chain(ir, ast, fun, bb, structRef, chain, .Assignment);
                name = assignRef.name;
            }

            // FIXME: rhs could also be a `read` handle!
            const exprNode = ast.get(assign.rhs).*;
            const exprRef = try gen_expression(ir, ast, fun, bb, exprNode);
            // _ = fun.renameRef(exprRef, toName);
            if (exprRef.name != IR.InternPool.NULL) {
                std.debug.print("exprRef name {s}\n", .{ir.getIdent(exprRef.name)});
            }
            try fun.bbs.get(bb).versionMap.put(exprRef.name, exprRef);
            try fun.bbs.get(bb).versionMap.put(name, exprRef);
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
        .Return => |ret| {
            if (ret.expr == null) {
                try fun.addCtrlFlowInst(bb, Inst.jmp(IR.Ref.label(fun.exitBBID)));
                return true;
            }
            var exprRef = try gen_expression(ir, ast, fun, bb, ast.get(ret.expr.?).*);
            var returnRegName = ir.internIdent("return_reg");
            if (fun.returnReg == null) {
                std.debug.print("returnReg is null\n", .{});
                unreachable;
            }
            exprRef.type = fun.returnType;
            exprRef.name = returnRegName;
            try fun.typesMap.put(returnRegName, fun.returnType);
            try fun.bbs.get(bb).versionMap.put(exprRef.name, exprRef);
            std.debug.print("returnRegName: {d}\n", .{returnRegName});
            std.debug.print("bb {d} exitBB {d}\n", .{ bb, fun.exitBBID });
            _ = try IR.BasicBlock.addRefToPhi(fun.exitBBID, fun, exprRef, bb, returnRegName);
            // add jmp to exitBB
            try fun.addCtrlFlowInst(bb, Inst.jmp(IR.Ref.label(fun.exitBBID)));
        },
        // control flow should be handled by the caller
        .ConditionalIf, .ConditionalIfElse, .While => unreachable,
        else => utils.todo("gen_statement {any}\n", .{kind}),
    }
    return false;
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
            std.debug.print("res id: {d}\n", .{res.id});
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
                    try fun.bbs.get(bb).versionMap.put(identID, ref);
                    break :ident ref;
                },
                .False => false: {
                    const trueRef = IR.Ref.immFalse();
                    const falseRef = IR.Ref.immFalse();
                    const orInst = Inst.or_(trueRef, falseRef);
                    const name = ir.internIdent("imm_false");
                    const res = try fun.addNamedInst(bb, orInst, name, .bool);
                    break :false IR.Ref.fromReg(res);
                },
                .True => true: {
                    const trueRef = IR.Ref.immTrue();
                    const falseRef = IR.Ref.immFalse();
                    const orInst = Inst.or_(trueRef, falseRef);
                    const name = ir.internIdent("imm_true");
                    const res = try fun.addNamedInst(bb, orInst, name, .bool);
                    break :true IR.Ref.fromReg(res);
                },
                .Number => num: {
                    const tok = atom.token;
                    const num = ir.internToken(ast, tok);
                    const immRef = IR.Ref.immediate(num, .int);
                    // number must be an int
                    const immRef2 = IR.Ref.immediate(0, .int);
                    // do add instruction
                    const inst = Inst.add(immRef, immRef2);
                    const name = ir.internIdent("imm_store");
                    const res = try fun.addNamedInst(bb, inst, name, .int);
                    break :num IR.Ref.fromReg(res);
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

fn inputToIRString(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    const ir = try testMe(input);
    return try ir.stringify(alloc);
}

// test "stack.fun.empty" {
//     errdefer log.print();
//     const ir = try testMe("fun main() void {}");
//     try ting.expectEqual(@as(usize, 1), ir.funcs.items.len);
// }
// test "stack.str.read" {
//     try expectResultsInIR(
//         \\fun main() void {
//         \\  int a;
//         \\  a = read;
//         \\}
//     , .{
//         "define void @main() {",
//         "entry:",
//         "  %a0 = alloca i64",
//         "  br label %body1",
//         "body1:",
//         "  %_2 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0",
//         "  %_3 = call i32 (i8*, ...) @scanf(i8* %_2, i32* @.read_scratch)",
//         "  %_4 = load i32, i32* @.read_scratch",
//         "  %_5 = sext i32 %_4 to i64",
//         "  store i64 %_5, i64* %a0",
//         "  br label %exit",
//         "exit:",
//         "  ret void",
//         "}",
//     });
// }

test "phi.print_test" {
    errdefer log.print();
    const in = "fun main() void { int a,b,c; a = 1; b = 2; c = 3; }";
    // print out the IR
    const ir = try testMe(in);
    _ = ir;
    // var arena = std.heap.ArenaAllocator.init(ting.allocator);
    // var alloc = arena.allocator();
    // defer arena.deinit();
    // const ir_str = try inputToIRString(in, alloc);
    // // check that the IR is correct
    // std.debug.print("{s}\n", .{ir_str});
}

// test "phi.print_test_while_nested" {
//     errdefer log.print();
//     const in = "fun main() void { int a,b,c; while(a){ b =c;} c=a; }";
//     // print out the IR
//     const ir = try testMe(in);
//     _ = ir;
// }

// test "phi.print_test_while" {
//     errdefer log.print();
//     const in = "fun test() int {int a; a =5; return a;} fun main() void { int a,b,c,d,e;a = 5+2; while(a != 2){ b =c; if (c < test()){while(b >2 ) {d =55;}}} c=a+e; }";
//     // print out the IR
//     const ir = try testMe(in);
//     _ = ir;
// }

// test "phi.print_test_while_if_else_params" {
//     errdefer log.print();
//     const in = "fun test(int c, int d) int {int a,b; a =5; if(c > 5) { while(a > 0){ a = a -1;} return a;} else { a = 20; if(a < 20){return d;}}  return a;} fun main() void { int a; a = test(); }";
//     const ir = try testMe(in);
//     _ = ir;
// }

// test "phi.print_struct_tests" {
//     errdefer log.print();
//     const in = "struct S {int a; struct S s;}; fun main() void { int a; struct S s; a =s.s.s.s.s.s.a; if(s.s.s.s.a > 2) { s.s.s.s.s.a = 3;} return s.s.s.a; }";

//     var str = try inputToIRString(in, testAlloc);
//     std.debug.print("{s}\n", .{str});
// }

// test "phi.print_struct_tests2" {
//     errdefer log.print();
//     const in = "struct S {int a; struct S s;}; fun main() void { int a; struct S s; a = 5; if(a > 2) { a =2; s.s.a = a; if (s.s.a == 1) {a = 2; s.s.a = 1;} else {a = 5;}} s.s.a = 2; return;  }";

//     var str = try inputToIRString(in, testAlloc);
//     std.debug.print("{s}\n", .{str});
// }
test "phi.print_addition" {
    errdefer log.print();
    const in = " fun main() void { int a,b;  a = 5; b = a + 2; a = b + 4;   }";

    var str = try inputToIRString(in, testAlloc);
    std.debug.print("{s}\n", .{str});
}

test "phi.print_addition2" {
    errdefer log.print();
    const in = " fun main() int { int a,b;  a = 5; b = a + 2; a = b + 4; return a;  }";

    var str = try inputToIRString(in, testAlloc);
    std.debug.print("{s}\n", .{str});
}

test "phi.print_test_if" {
    errdefer log.print();
    const in = "fun main() int {\n int a,b,c;\n if(a == 1){\n b =c;\n}\n b = a; return b;\n }";
    var str = try inputToIRString(in, testAlloc);
    std.debug.print("{s}\n", .{str});
    // print out the IR
    // var arena = std.heap.ArenaAllocator.init(ting.allocator);
    // var alloc = arena.allocator();
    // defer arena.deinit();
    // const ir_str = try inputToIRString(in, alloc);
    // // check that the IR is correct
    // std.debug.print("{s}\n", .{ir_str});
}
