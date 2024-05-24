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

    // add globals to the types map
    for (ir.globals.items.items) |global| {
        const name = global.name;
        const typ = global.type;
        try tmpTypesMap.put(name, typ);
    }

    // add the params to the types map
    for (fun.params.items) |item| {
        const name = item.name;
        // check if ir.funcs contains name
        // if (ir.funcs.contains(name)) {
        //     std.debug.print
        //     return error.CannotNameParamSameAsFunction;
        // }
        const typ = item.type;
        try tmpTypesMap.put(name, typ);

        // also put the param into the registers

        const parRegID = try fun.regs.add(undefined);
        const parInstID = try fun.insts.add(undefined);

        // FIXME: should create a bb that is like 0 or something that just holds the params, that is for later
        const parReg = IR.Register{ .id = parRegID, .name = name, .type = typ, .inst = parInstID, .bb = 0 };
        var parRef = IR.Ref.fromRegLocal(parReg);
        parRef.kind = .param;
        parRef.i = parRegID;
        var inst = IR.Inst.param(parRef, typ);

        // save the register and the inst
        fun.regs.set(parRegID, parReg);
        fun.insts.set(parInstID, inst);
        try fun.paramRegs.put(name, parRegID);
    }

    // generate map of decls to types in the function
    var declsIter = funBody.iterLocalDecls(ast);
    while (declsIter.next()) |declNode| {
        const decl = declNode.kind.TypedIdentifier;
        const declName = ir.internIdent(decl.getName(ast));
        // check if ir.funcs contains declName
        // if (ir.funcs.contains(declName)) {
        //     return error.CannotNameVarSameAsFunction;
        // }
        const declType = ir.astTypeToIRType(decl.getType(ast));
        try tmpTypesMap.put(declName, declType);
        try fun.declaredVars.put(declName, declType);
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
                std.debug.print("could not find type for decl {s}\n", .{ir.getIdent(list.items[0])});
                return error.DeclNotFound;
            }
            // check that the name is not the same as a function
            if (ir.funcs.contains(list.items[0])) {
                return error.CannotNameVarSameAsFunction;
            }
            if (ir.funcs.contains(declNode)) {
                return error.CannotNameVarSameAsFunction;
            }
            try fun.typesMap.put(list.items[0], preType.?);
            try fun.typesMap.put(declNode, preType.?);
            list.deinit();
        } else {
            // check that the name is not the same as a function
            // if (ir.funcs.contains(declNode)) {
            //     return error.CannotNameVarSameAsFunction;
            // }
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
    try fun.mapUsesBBFromCFG(ir);

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
    // generate alloca for the return value if the function returns a value
    // this makes it so ret reg is always `%0`
    if (fun.returnType != .void) {
        // allocate a stack slot for the return value in the entry
        retReg = try fun.addNamedInst(entryBB, Inst.alloca(fun.returnType), retReg.name, fun.returnType);
        // load the stack slot so there is a defualt value
        var loadInst = Inst.load(fun.returnType, IR.Ref.fromRegLocal(retReg));
        retReg = try fun.addInst(entryBB, loadInst, fun.returnType);
        // save it in the function for easy access later
        fun.setReturnReg(retReg.id);
    }
    try fun.typesMap.put(retReg.name, fun.returnType);

    // go through the basic blocks and add the statements for each.
    // update variableMap as we go
    // ast.debugPrintAst();
    for (fun.cfg.postOrder.items) |cfgBlockID| {
        // fun.cfg.printBlockName(cfgBlockID);
        try generateInstsFromCfg(ir, ast, fun, cfgBlockID);
    }
    // // link the entry block to the first block

    // // relink all the phi nodes
    for (fun.bbs.items(), 0..) |bb, bbid| {
        // if not the entry or the exit get the phi
        if (bbid == IR.Function.entryBBID or bbid == fun.exitBBID) {
            continue;
        }
        // std.debug.print("Looking for phi in bb: {s}\n", .{bb.name});
        var phiIter = bb.phiMap.keyIterator();
        while (phiIter.next()) |phiName| {
            // std.debug.print("Looking for phiName: {s}\n", .{ir.getIdent(phiName.*)});
            // get the phi instruction
            var phiInstID = bb.phiMap.get(phiName.*).?;
            var phiInst = fun.insts.get(phiInstID);
            // phiInst.res.debugPrintWithName(ir);

            // convert it to a phi instruction
            var phi = IR.Inst.Phi.get(phiInst.*);

            // get the original entries
            for (phi.entries.items, 0..) |entry, idx| {
                var entryBBID = entry.bb;
                var entryBB_ = fun.bbs.get(entryBBID);

                // phi nodes must come from the predecessor block(s)
                for (entryBB_.incomers.items) |incomerBBID| {
                    if (incomerBBID == bbid) {
                        utils.todo("phi node from the same block\n", .{});
                    }
                    var incomerBB = fun.bbs.get(incomerBBID);
                    // std.debug.print("looking for named ref in block {s}\n", .{incomerBB.name});
                    var ref = incomerBB.versionMap.get(phiName.*);
                    // not in the present block
                    if (ref == null) {
                        ref = try fun.getNamedRef(ir, phiName.*, incomerBBID, false);
                    }
                    // std.debug.print("found named ref from searching upwords\n", .{});
                    // ref.?.debugPrintWithName(ir);
                    // } else {
                    //     // std.debug.print("found named ref from version map\n", .{});
                    //     ref.?.debugPrintWithName(ir);
                    // }
                    var ref_ = ref.?;
                    phi.entries.items[idx].ref = ref_;
                    // std.debug.print("added entry\n", .{});
                }
            }
            // delete any entries that are default
            // FIXME: this is a good place for something to go wrong lol
            // var anyDefault: bool = true;
            //     anyDefault = false;
            //     for (phi.entries.items, 0..) |entry, idx| {
            //         if (entry.ref.name == IR.Ref.default.name) {
            //             _ = phi.entries.orderedRemove(idx);
            //             anyDefault = true;
            //             break;
            //         }
            //     }
            // }

            // convert it back to an instruction
            var back_to_inst = phi.toInst();
            fun.insts.set(phiInstID, back_to_inst);
        }
    }

    // handle return
    if (fun.returnType != .void) {
        // get the exit basic block
        var exitBB = fun.bbs.get(fun.exitBBID);
        if (exitBB.phiInsts.items.len == 0) unreachable;
        if (exitBB.phiInsts.items.len > 1) {
            var anyDefault: bool = true;
            while (anyDefault and exitBB.phiInsts.items.len > 1) {
                anyDefault = false;
                for (exitBB.phiInsts.items, 0..) |entryInstID, idx| {
                    var entryInst = fun.insts.get(entryInstID);
                    if (entryInst.res.name != retReg.name) {
                        _ = exitBB.phiInsts.orderedRemove(idx);
                        anyDefault = true;
                        break;
                    }
                }
            }
        }
        if (exitBB.phiInsts.items.len == 1) {
            const phiInstID = exitBB.phiInsts.items[0];
            const phiInst = fun.insts.get(phiInstID).*;

            var instRet = IR.Inst.ret(fun.returnType, phiInst.res);
            _ = try fun.addInst(fun.exitBBID, instRet, fun.returnType);
        }
    } else {
        var anyDefault: bool = true;
        var exitBB = fun.bbs.get(fun.exitBBID);
        while (anyDefault and exitBB.phiInsts.items.len > 0) {
            anyDefault = false;
            for (exitBB.phiInsts.items, 0..) |entryInstID, idx| {
                var entryInst = fun.insts.get(entryInstID);
                if (entryInst.res.name != retReg.name) {
                    _ = exitBB.phiInsts.orderedRemove(idx);
                    anyDefault = true;
                    break;
                }
            }
        }
        _ = try fun.addInst(fun.exitBBID, Inst.retVoid(), .void);
    }

    if (fun.retRegUsed == false and fun.returnType != .void) {
        _ = fun.bbs.get(IR.Function.entryBBID).insts.orderedRemove(0);
        _ = fun.bbs.get(IR.Function.entryBBID).insts.orderedRemove(0);
        // remove it from the phi in exit if it is there
        // var exitBB = fun.bbs.get(fun.exitBBID);
        // var retInstPhi = exitBB.phiMap.get(retReg.name);
        // if (retInstPhi != null) {
        //     var instForPhi = fun.insts.get(retInstPhi.?);
        //     var instAsPhi = IR.Inst.Phi.get(instForPhi.*);
        //     var newEntries = std.ArrayList(IR.PhiEntry).init(ir.alloc);
        //     for (instAsPhi.entries.items) |entry| {
        //         if (entry.ref.name != retReg.name) {
        //             try newEntries.append(entry);
        //         }
        //     }
        //     instAsPhi.entries.deinit();
        //     instAsPhi.entries = newEntries;
        //     var back_to_inst = instAsPhi.toInst();
        //     fun.insts.set(retInstPhi.?, back_to_inst);
        // }
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
    // for (cfgBlock.statements.items) |stmtNode| {
    //     fun.cfg.printBlockName(cfgBlockID);
    //     ast.printNodeLine(stmtNode);
    // }

    if (cfgBlock.conditional) {
        const statments = cfgBlock.statements;
        // we know that if it is a conditional it is an expression
        if (statments.items.len > 1) unreachable;
        var condRef = try gen_expression(ir, ast, fun, bbID, statments.items[0]);
        // condRef.name = IR.InternPool.NULL;
        if (condRef.kind != .param) {
            condRef = fun.renameRefAnon(ir, condRef);
        }
        //TODO generate the control flow jump
        const brInst = Inst.br(condRef, IR.Ref.label(bb.outgoers[0].?), IR.Ref.label(bb.outgoers[1].?));
        try fun.addCtrlFlowInst(bbID, brInst);

        return;
    } else {
        for (cfgBlock.statements.items) |stmtNode| {
            const isRet = try gen_statement(ir, ast, fun, bbID, stmtNode);
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
//
//
// Algorithm: InsertPhiNodes
// Input: A control flow graph (CFG) of a function
// Output: CFG with phi nodes inserted at necessary locations

// 1. Identify all the variables that are assigned in multiple basic blocks.
// 2. For each variable:
//    2.1 Determine the set of basic blocks (def_blocks) where the variable is defined.
//    2.2 Use a dominance frontier algorithm to find where the phi nodes need to be placed:
//        - Compute the dominance frontier for each block in def_blocks.
//        - The dominance frontier of a block B is the set of all blocks C such that B dominates
//          an immediate predecessor of C, but B does not strictly dominate C.
//    2.3 For each block in the dominance frontier of any block in def_blocks:
//        - Insert a phi node for the variable at the beginning of the block.
//        - The phi node should merge different incoming values of the variable from its predecessors.
// 3. For each phi node:
//    3.1 For each predecessor of the block containing the phi node:
//        - Determine the appropriate value of the variable to be used based on the control flow.
//        - If the predecessor does not define the variable, trace back to find the last definition
//          along the path from the predecessor to the phi node's block.
//        - Set the incoming value from this predecessor in the phi node.
// 4. Optimize the phi nodes by removing any that are unnecessary or redundant.

pub fn place_phi_functions(ir: *IR, ast: *const Ast, fun: *IR.Function, funNode: Ast.Node.Kind.FunctionType) !void {
    _ = funNode;
    _ = ast;
    // 1. Identify all the variables that are assigned in multiple basic blocks.
    // use cfg.assignments = hashmap(strid,hashmap(cfgblockid,bool));
    var assignmentsIter = fun.cfg.assignments.keyIterator();
    while (assignmentsIter.next()) |defStrID_| {
        var defStrID = defStrID_.*;
        var cfgBlockIter = fun.cfg.assignments.get(defStrID).?.keyIterator();
        while (cfgBlockIter.next()) |cfgBlockID_| {
            var cfgBlockID = cfgBlockID_.*;
            var final_string = ir.reduceChainToFirstIdent(defStrID);
            // check if its a global
            if (ir.globals.contains(final_string)) {
                continue;
            }
            if (!fun.defBlocks.contains(final_string)) {
                try fun.defBlocks.put(final_string, std.ArrayList(IR.BasicBlock.ID).init(ir.alloc));
            }
            var bbBlockID = fun.cfgToBBs.get(cfgBlockID).?;
            try fun.defBlocks.getPtr(final_string).?.append(@truncate(bbBlockID));
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
                    var phiInstID = try IR.BasicBlock.addPhiWithPreds(dfBBID, fun, defStr);
                    var phiInst = fun.insts.get(phiInstID);
                    var phiRef = phiInst.res;
                    try fun.bbs.get(dfBBID).versionMap.put(defStr, phiRef);

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
            // std.debug.print("assign to: {s} [{d}]\n", .{ ast.getIdentValue(to.ident), toName });
            var name = toName;

            // FIXME: rhs could also be a `read` handle!
            const exprNode = ast.get(assign.rhs).*;
            // selfRef <- exprRef
            var exprRef = try gen_expression(ir, ast, fun, bb, exprNode);
            var selfRef = try fun.getNamedRef(ir, toName, bb, true);

            if (exprRef.kind == .global) {
                utils.todo("Cannot assign from a global\n", .{});
            }

            // FIXME: handle selector chain
            if (to.chain) |chain| {
                // if it is a global we have to load it to access its fields
                if (selfRef.kind == .global) {
                    // load it first
                    const loadInst = Inst.load(selfRef.type, selfRef);
                    var exprReg = try fun.addInst(bb, loadInst, selfRef.type);
                    selfRef = IR.Ref.fromRegLocal(exprReg);
                }

                var selectorChainRef = try gen_selector_chain(ir, ast, fun, bb, selfRef, chain, toName);
                // need to store the result of the expression into the selector chain
                // if (exprRef.kind == .global) {
                //     // load it first
                //     const loadInst = Inst.load(exprRef.type, exprRef);
                //     var exprReg = try fun.addInst(bb, loadInst, exprRef.type);
                //     exprRef = IR.Ref.fromRegLocal(exprReg);
                // }
                const inst = Inst.store(
                    selectorChainRef, // to
                    exprRef, // from
                );
                try fun.addAnonInst(bb, inst);
                return false;
            }

            // if this is not a chain
            var nullFlag: bool = false;
            _ = nullFlag;
            switch (selfRef.kind) {
                .global => {
                    // if we are assigning to a global then we need to store to it
                    // note that gen expression covers the loading of the other global in that case
                    const storeInst = Inst.store(selfRef, exprRef);
                    try fun.addAnonInst(bb, storeInst);
                },
                .immediate => {
                    // if we are assigning to an immediate then we have a previous assignment that was an immediate
                    switch (exprRef.kind) {
                        .immediate, .local, .param => {
                            // just copy the name over to the new immediate
                            try fun.bbs.get(bb).versionMap.put(name, exprRef);
                        },
                        else => {
                            utils.todo("Cannot assign from an unknown param type {s}\n", .{@tagName(selfRef.kind)});
                        },
                    }
                },
                .param => {
                    switch (exprRef.kind) {
                        .immediate, .local, .param => {
                            // just copy the name over to the new immediate
                            try fun.bbs.get(bb).versionMap.put(name, exprRef);
                        },
                        else => {
                            utils.todo("Cannot assign from an unknown param type {s}\n", .{@tagName(selfRef.kind)});
                        },
                    }
                },
                .local => {
                    switch (exprRef.kind) {
                        .immediate, .param => {
                            try fun.bbs.get(bb).versionMap.put(name, exprRef);
                        },
                        .local => {
                            // just copy the name over to the new immediate
                            _ = fun.renameRef(ir, exprRef, toName);
                            try fun.bbs.get(bb).versionMap.put(name, exprRef);
                        },
                        else => {
                            utils.todo("Cannot assign from an unknown param type {s}\n", .{@tagName(selfRef.kind)});
                        },
                    }
                },
                else => {
                    utils.todo("Cannot assign to an unknown param type {s}\n", .{@tagName(selfRef.kind)});
                },
            }
        }, // end assignment
        .Print => |print| {
            const exprRef = try gen_expression(ir, ast, fun, bb, ast.get(print.expr).*);
            const lenb4 = fun.insts.len;
            try gen_print(ir, fun, bb, exprRef, print.hasEndl);
            const lenAfter = fun.insts.len;
            log.trace("print expr: {any} :: {d} -> {d}\n", .{ exprRef, lenb4, lenAfter });
        },
        // TODO: V5 Revs
        .Delete => |del| {
            const ptrRef = try gen_expression(ir, ast, fun, bb, ast.get(del.expr).*);
            try gen_free_struct(ir, fun, bb, ptrRef);
        },
        // TODO V5 Revs
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
                return error.CannotReturnFromVoidFunction;
            }
            exprRef.type = fun.returnType;
            try fun.typesMap.put(returnRegName, fun.returnType);
            try fun.bbs.get(bb).versionMap.put(exprRef.name, exprRef);
            try fun.bbs.get(bb).versionMap.put(returnRegName, exprRef);
            // exprRef = fun.renameRef(exprRef, returnRegName);
            _ = try IR.BasicBlock.addRefToPhiReturn(fun.exitBBID, fun, exprRef, bb, ir);
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
            const unopName = ir.internIdent("tmp.unop");
            const res = try fun.addNamedInst(bb, inst, unopName, ty);
            return IR.Ref.fromReg(res, fun, ir);
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
            // const name = join_names(lhsRef.name, rhsRef.name);
            const binopName = ir.internIdent("tmp.binop");
            const res = try fun.addNamedInst(bb, inst, binopName, ty);
            return IR.Ref.fromReg(res, fun, ir);
        },
        .Selector => |sel| {
            const factor = ast.get(sel.factor).kind.Factor;
            // I know I know, I just don't know what else to call it
            const atomIndex = factor.factor;
            const atom = ast.get(atomIndex);
            var resultRef = switch (atom.kind) {
                .Identifier => ident: {
                    var identID = ir.internToken(ast, atom.token);
                    var ref = try fun.getNamedRef(ir, identID, bb, false);
                    switch (ref.kind) {
                        .global => {},
                        .param,
                        .local,
                        => {
                            try fun.bbs.get(bb).versionMap.put(identID, ref);
                        },
                        else => {
                            utils.todo("Cannot give reference to an unknown param type\n", .{});
                        },
                    }
                    switch (ref.kind) {
                        .param => {
                            // note that the ref is in the type map under a different name,
                            // but is holding onto its own value so that if it is used it
                            // does not use the wrong name
                        },
                        .local => {
                            // this already happens lol
                            ref.name = identID;
                        },
                        .global => {
                            // load the global
                            const loadInst = Inst.load(ref.type, ref);
                            const name = ir.internIdent("load_global");
                            const reg = try fun.addNamedInst(bb, loadInst, name, ref.type);
                            ref = IR.Ref.fromReg(reg, fun, ir);
                            // we do not want this tracked so we do not add it to the version map
                        },
                        .immediate => {
                            // note that the ref is in the type map under a different name,
                            // but is holding onto its own value so that if it is used it
                            // does not use the wrong name
                        },
                        else => {
                            utils.todo("Cannot assign to an unknown param type\n", .{});
                        },
                    }
                    break :ident ref;
                },
                .False => false: {
                    const trueRef = IR.Ref.immFalse();
                    const falseRef = IR.Ref.immFalse();
                    const orInst = Inst.or_(trueRef, falseRef);
                    const name = ir.internIdent("imm_false");
                    const res = try fun.addNamedInst(bb, orInst, name, .bool);
                    break :false IR.Ref.fromRegLocal(res);
                },
                .True => true: {
                    const trueRef = IR.Ref.immTrue();
                    const falseRef = IR.Ref.immFalse();
                    const orInst = Inst.or_(trueRef, falseRef);
                    const name = ir.internIdent("imm_true");
                    const res = try fun.addNamedInst(bb, orInst, name, .bool);
                    break :true IR.Ref.fromRegLocal(res);
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
                    break :num IR.Ref.fromRegLocal(res);
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
                    const _malloc = ".alloc";
                    const _bitcast = ".bitcast";
                    var allocNameArr = std.ArrayList(u8).init(ir.alloc);
                    var bitcastNameArr = std.ArrayList(u8).init(ir.alloc);
                    for (_malloc) |c| {
                        try allocNameArr.append(c);
                    }
                    for (_bitcast) |c| {
                        try bitcastNameArr.append(c);
                    }
                    for (lenStr) |c| {
                        try allocNameArr.append(c);
                        try bitcastNameArr.append(c);
                    }
                    const allocNameStr = try allocNameArr.toOwnedSlice();
                    const bitcastNameStr = try bitcastNameArr.toOwnedSlice();
                    const allocName = ir.internIdent(allocNameStr);
                    const bitcastName = ir.internIdent(bitcastNameStr);
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
                        const reg = try fun.addNamedInst(bb, inst, allocName, arrType);
                        const ref = IR.Ref.fromRegLocal(reg);
                        break :alloca ref;
                    };
                    const cast = cast: {
                        // bitcast the array to an int* from [int x {len}]*
                        // as int_arrays are passed around and treated as int*
                        // (i.e. unknown length)
                        const inst = Inst.bitcast(alloca, .int_arr);
                        const reg = try fun.addNamedInst(bb, inst, bitcastName, .int_arr);
                        const ref = IR.Ref.fromRegLocal(reg);
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
                .Invocation => IR.Ref.fromReg(try gen_invocation(ir, fun, ast, bb, atom), fun, ir),
                .Expression => try gen_expression(ir, ast, fun, bb, atom.*),
                else => utils.todo("gen_expression.selector.factor: {s}\n", .{@tagName(atom.kind)}),
            };
            if (sel.chain) |chain| {
                var identID = ir.internToken(ast, atom.token);
                resultRef = try gen_selector_chain(ir, ast, fun, bb, resultRef, chain, identID);
                // we need to add a load here
                const loadInst = Inst.load(resultRef.type, resultRef);
                const loadRes = try fun.addInst(bb, loadInst, resultRef.type);
                resultRef = IR.Ref.fromReg(loadRes, fun, ir);
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
                break :blk IR.Ref.fromRegLocal(res);
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
                const resRef = IR.Ref.fromReg(resReg, fun, ir);
                const sextInst = Inst.sext(resRef, .int);
                const sextResReg = try fun.addInst(bb, sextInst, .int);
                break :blk sextResReg;
            };

            // return reference to the sign extended i64 value we read
            return IR.Ref.fromReg(i64ResReg, fun, ir);
        },
        else => utils.todo("gen_expression: {s}\n", .{@tagName(exprNode.kind)}),
    }
    unreachable;
}

fn gen_invocation(ir: *IR, fun: *IR.Function, ast: *const Ast, bb: IR.BasicBlock.ID, node: *const Ast.Node) !IR.Register {
    const invoc = node.*.kind.Invocation;
    const funNameID = ir.internIdentNodeAt(ast, invoc.funcName);
    const funRef = try fun.getNamedRef(ir, funNameID, bb, false);

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
    var newNameArr = std.ArrayList(u8).init(ir.alloc);
    defer newNameArr.deinit();
    const aufrufen = "aufrufen_";
    for (aufrufen) |c| {
        try newNameArr.append(c);
    }
    for (ir.getIdent(funRef.name)) |c| {
        try newNameArr.append(c);
    }
    const newNameStr = try newNameArr.toOwnedSlice();
    const newName = ir.internIdent(newNameStr);
    return try fun.addNamedInst(bb, callInst, newName, funRef.type);
}

// FIXME: allow redefinition of globals
fn gen_malloc_struct(ir: *IR, fun: *IR.Function, bb: IR.BasicBlock.ID, s: IR.StructType) !IR.Ref {
    // the args to malloc are just (i32 sizeof({struct type}))
    const s_name = ir.getIdent(s.name);
    // add .Struct to the name of the struct to avoid conflicts
    const _Struct = ".malloc";
    const _Bitcase = ".bitcast";
    var mallocNameArr = std.ArrayList(u8).init(ir.alloc);
    var bitcastNameArr = std.ArrayList(u8).init(ir.alloc);
    for (s_name) |c| {
        try mallocNameArr.append(c);
        try bitcastNameArr.append(c);
    }
    for (_Struct) |c| {
        try mallocNameArr.append(c);
    }
    for (_Bitcase) |c| {
        try bitcastNameArr.append(c);
    }
    const mallocNameStr = try mallocNameArr.toOwnedSlice();
    const bitcastNameStr = try bitcastNameArr.toOwnedSlice();
    const mallocName = ir.internIdent(mallocNameStr);
    const bitcastName = ir.internIdent(bitcastNameStr);
    const args = blk: {
        var args: []IR.Ref = try ir.alloc.alloc(IR.Ref, 1);
        args[0] = IR.Ref.immu32(s.size, .i32);
        break :blk args;
    };

    // the pointer returned by malloc as an i8*
    const retRef = blk: {
        const mallocRef: IR.Ref = IR.Ref.malloc(ir);
        const mallocInst = Inst.call(.i8, mallocRef, args);
        const memReg = try fun.addNamedInst(bb, mallocInst, mallocName, .i8);
        const memRef = IR.Ref.fromRegLocal(memReg);
        break :blk memRef;
    };

    // the malloced pointer casted from an i8* to a {struct type}*
    const resRef = blk: {
        const cast = Inst.bitcast(retRef, s.getType());
        const castReg = try fun.addNamedInst(bb, cast, bitcastName, s.getType());
        const castRef = IR.Ref.fromRegLocal(castReg);
        break :blk castRef;
    };
    try fun.bbs.get(bb).versionMap.put(s.name, resRef);
    // return the {struct type}* reference
    return resRef;
}

fn gen_free_struct(ir: *IR, fun: *IR.Function, bb: IR.BasicBlock.ID, ptrRef: IR.Ref) !void {
    // the {struct type}* pointer casted to an i8*
    const castRef = blk: {
        const castInst = Inst.bitcast(ptrRef, .i8);
        const castReg = try fun.addInst(bb, castInst, .i8);
        const castRef = IR.Ref.fromReg(castReg, fun, ir);
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
        break :blk IR.Ref.fromRegLocal(res);
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
/// // remove selectorType -> single pointer for all
fn gen_selector_chain(
    ir: *IR,
    ast: *const Ast,
    fun: *IR.Function,
    bb: IR.BasicBlock.ID,
    startRef: IR.Ref,
    chainIndex: usize,
    gen_name: IR.StrID,
) !IR.Ref {
    var chainLink = ast.get(chainIndex).kind.SelectorChain;
    if (startRef.type == .int_arr) {
        // early return if the startRef is an array type as we know
        // that the chainLink is the index into the array and the result will be an
        // int and therefore there will be no more field accesses
        var arrayName = std.ArrayList(u8).init(ir.alloc);
        defer arrayName.deinit();
        const app_str = "_auf";
        for (ir.getIdent(gen_name)) |c| {
            try arrayName.append(c);
        }
        for (app_str) |c| {
            try arrayName.append(c);
        }
        const arrayNameStr = try arrayName.toOwnedSlice();
        const arrayNameID = ir.internIdent(arrayNameStr);
        const exprNode = ast.get(chainLink.ident).*;
        utils.assert(exprNode.kind == .Expression, "chainLink.ident should be expression for chain off of top level int_array", .{});
        const indexRef = try gen_expression(ir, ast, fun, bb, exprNode);
        const inst = Inst.gep(startRef.type, startRef, indexRef);
        var reg = try fun.addNamedInst(bb, inst, arrayNameID, indexRef.type);
        var ref = IR.Ref.fromReg(reg, fun, ir);
        return ref;
    }
    var chainName = std.ArrayList(u8).init(ir.alloc);
    defer chainName.deinit();
    var startNameLit = ir.getIdent(gen_name);
    for (startNameLit) |c| {
        try chainName.append(c);
    }
    try chainName.append('.');
    for (ast.getIdentValue(chainLink.ident)) |c| {
        try chainName.append(c);
    }
    const termStr = "_auf";
    var tmp_nae = try chainName.clone();
    defer tmp_nae.deinit();
    for (termStr) |c| {
        try tmp_nae.append(c);
    }
    if (startRef.type != .strct) {
        return error.CannotChainFromANonStruct;
    }
    var structType = try ir.types.get(startRef.type.strct);
    var fieldNameID = ir.internIdentNodeAt(ast, chainLink.ident);
    var fieldInfo = try structType.getFieldWithName(fieldNameID);
    var fieldIndex = fieldInfo.index;
    var field = fieldInfo.field;
    var inst = IR.Inst.gep(structType.getType(), startRef, IR.Ref.immu32(fieldIndex, .i32));
    var chainLinkNameID = ir.internIdent(try tmp_nae.toOwnedSlice());
    var reg = try fun.addNamedInst(bb, inst, chainLinkNameID, field.type);
    var ref = IR.Ref.fromRegLocal(reg);
    var nextChainLink = chainLink.next;
    var prevField = field;

    while (nextChainLink) |nextIndex| : (nextChainLink = chainLink.next) {
        chainLink = ast.get(nextIndex).kind.SelectorChain;

        try chainName.append('.');
        for (ast.getIdentValue(chainLink.ident)) |c| {
            try chainName.append(c);
        }

        tmp_nae = try chainName.clone();
        defer tmp_nae.deinit();
        for (termStr) |c| {
            try tmp_nae.append(c);
        }
        chainLinkNameID = ir.internIdent(try tmp_nae.toOwnedSlice());
        // fixme
        if (prevField.type == .int_arr) {
            // early return if we reach a field that is an array type as we know
            // that the chainLink is the index into the array and the result will be an
            // int and therefore there will be no more field accesses
            const exprNode = ast.get(chainLink.ident).*;
            utils.assert(exprNode.kind == .Expression, "chainLink.ident should be expression for chain off of int_array field", .{});
            const indexRef = try gen_expression(ir, ast, fun, bb, exprNode);
            inst = Inst.gep(startRef.type, startRef, indexRef);
            reg = try fun.addNamedInst(bb, inst, gen_name, indexRef.type);
            ref = IR.Ref.fromRegLocal(reg);
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
            // maybe also have to change the name of the struct type here
            reg = try fun.addNamedInst(bb, loadInst, structType.name, structType.getType());
            break :blk IR.Ref.fromReg(reg, fun, ir);
        };
        inst = IR.Inst.gep(structType.getType(), loadRef, IR.Ref.immu32(fieldIndex, .i32));

        reg = try fun.addNamedInst(bb, inst, chainLinkNameID, field.type);
        ref = IR.Ref.fromReg(reg, fun, ir);
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

// test "stack.types.none" {
//     const input = "fun main() void {}";
//     const ir = try testMe(input);
//     try ting.expectEqual(@as(usize, 0), ir.types.len());
// }

// test "stack.types.multiple" {
//     errdefer log.print();
//     const input = "struct Foo { int a; bool b; }; struct Bar { int c; int d; int e;}; fun main() void {}";
//     const ir = try testMe(input);
//     try ting.expectEqual(@as(usize, 2), ir.types.len());
//     const foo = ir.types.index(0);
//     const bar = ir.types.index(1);
//     try ting.expectEqualStrings("Foo", ir.getIdent(foo.name));
//     try ting.expectEqual(@as(usize, 2), foo.numFields());
//     try ting.expectEqualStrings("Bar", ir.getIdent(bar.name));
//     try ting.expectEqual(@as(usize, 3), bar.numFields());
// }

// test "stack.globals.multiple" {
//     const input = "struct Foo { int a; bool b; }; int a; bool b; fun main() void {}";
//     const ir = try testMe(input);
//     try ting.expectEqual(@as(usize, 2), ir.globals.len());
//     const a = ir.globals.index(0);
//     const b = ir.globals.index(1);
//     try ting.expectEqualStrings("a", ir.getIdent(a.name));
//     try ting.expectEqual(IR.Type.int, a.type);
//     try ting.expectEqualStrings("b", ir.getIdent(b.name));
//     try ting.expectEqual(IR.Type.bool, b.type);
// }

// test "stack.globals.none" {
//     const input = "struct Foo { int a; bool b; }; fun main() void {}";
//     const ir = try testMe(input);
//     try ting.expectEqual(@as(usize, 0), ir.globals.len());
// }

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
fn inputToIRStringHeader(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    const ir = try testMe(input);
    return try ir.stringifyWithHeader(alloc);
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
// test "phi.print_addition" {
//     errdefer log.print();
//     const in = " fun main() void { int a,b;  a = 5; b = a + 2; a = b + 4;   }";

//     var str = try inputToIRString(in, testAlloc);
//     std.debug.print("{s}\n", .{str});
// }

// test "phi.print_addition2" {
//     errdefer log.print();
//     const in = " fun main() int { int a,b;  a = 5; b = a + 2; a = b + 4; return a;  }";

//     var str = try inputToIRString(in, testAlloc);
//     std.debug.print("{s}\n", .{str});
// }

// test "phi.print_test_if" {
//     errdefer log.print();
//     const in = "fun main() int {\n int a,b,c;\n if(a == 1){\n b =c;\n}\n b = a; return b;\n }";
//     var str = try inputToIRString(in, testAlloc);
//     std.debug.print("{s}\n", .{str});
//     // print out the IR
//     // var arena = std.heap.ArenaAllocator.init(ting.allocator);
//     // var alloc = arena.allocator();
//     // defer arena.deinit();
//     // const ir_str = try inputToIRString(in, alloc);
//     // // check that the IR is correct
//     // std.debug.print("{s}\n", .{ir_str});
// }

// test "phi.print_test_while_nested" {
//     errdefer log.print();
//     const in = "fun main() void { int a,b,c; a = 1;while(a == 2){ b =c;} c=a; print c endl; }";
//     var str = try inputToIRStringHeader(in, testAlloc);
//     std.debug.print("{s}\n", .{str});
// }

// test "phi.print_test_decreasing_num" {
//     errdefer log.print();
//     const in = "fun main() void { int a; a = 10; while(a >= 0){ print a endl; a = a - 1;} }";
//     var str = try inputToIRStringHeader(in, testAlloc);
//     std.debug.print("{s}\n", .{str});
// }

// test "phi.print_first_struct" {
//     errdefer log.print();
//     const in = "struct S {int a; struct S s;}; fun main() void { int a; struct S s; struct S b; s = new S; s.s = new S; s.s.a = 5; b = s.s; a = b.a; print a endl; }";
//     var str = try inputToIRStringHeader(in, testAlloc);
//     std.debug.print("{s}\n", .{str});
// }

// test "phi.functioncalls" {
//     errdefer log.print();
//     const in = "fun test(int a, int b) int { return a + b;} fun main() void { int a; a = test(5, 2); print a endl; }";
//     var str = try inputToIRStringHeader(in, testAlloc);
//     std.debug.print("{s}\n", .{str});
// }
// test "phi.fibonacci" {
//     errdefer log.print();
//     const in = "fun fib(int n) int { if(n <= 1) { return n;} return fib(n-1) + fib(n-2);} fun main() void { int a; a = fib(20); print a endl; }";
//     var str = try inputToIRStringHeader(in, testAlloc);
//     std.debug.print("{s}\n", .{str});
// }
// test "phi.arrays" {
//     errdefer log.print();
//     const in = "fun main() void { int_array a; a = new int_array[20]; a[0] = 5; print a[0] endl; }";
//     var str = try inputToIRStringHeader(in, testAlloc);
//     std.debug.print("{s}\n", .{str});
// }
// test "phi_programBreaker" {
//     errdefer log.print();
//     const name = @embedFile("../../test-suite/tests/milestone2/benchmarks/programBreaker/programBreaker.mini");
//     var str = try inputToIRStringHeader(name, testAlloc);
//     std.debug.print("{s}\n", .{str});
// }

// test "phi_wasteOfCycles" {
//     errdefer log.print();
//     const name = @embedFile("../../test-suite/tests/milestone2/benchmarks/wasteOfCycles/wasteOfCycles.mini");
//     var str = try inputToIRStringHeader(name, testAlloc);
//     std.debug.print("{s}\n", .{str});
// }
// test "phi_killerBubs" {
//     errdefer log.print();
//     const name = @embedFile("../../test-suite/tests/milestone2/benchmarks/killerBubbles/killerBubbles.mini");
//     var str = try inputToIRStringHeader(name, testAlloc);
//     std.debug.print("{s}\n", .{str});
// }

// test "phi.struct_killBubs" {
//     errdefer log.print();
//     const name = "struct Node {struct Node n;}; fun main(struct Node in ) void {struct Node comp; comp = in; if(comp.n != in){ print 1 endl;}  }";
//     var str = try inputToIRStringHeader(name, testAlloc);
//     std.debug.print("{s}\n", .{str});
// }
//
// test "phi.struct_inter_funcs" {
//     errdefer log.print();
//     const name = @embedFile("../inter_fun_structs.mini");
//     var str = try inputToIRStringHeader(name, testAlloc);
//     std.debparamug.print("{s}\n", .{str});
// }
//
test "phi_stats" {
    errdefer log.print();
    const name = @embedFile("../../test-suite/tests/milestone2/benchmarks/stats/stats.mini");
    var str = try inputToIRStringHeader(name, testAlloc);
    std.debug.print("{s}\n", .{str});
}
//
// test "phi_hanoi" {
//     errdefer log.print();
//     const name = @embedFile("../hanoi_local.mini");
//     var str = try inputToIRStringHeader(name, testAlloc);
//     std.debug.print("{s}\n", .{str});
// }
//
// test "phi_stats" {
//     errdefer log.print();
//     const name = @embedFile("../../test-suite/tests/milestone2/benchmarks/bert/bert.mini");
//     var str = try inputToIRStringHeader(name, testAlloc);
//     std.debug.print("{s}\n", .{str});
// }
//
// test "phi_global_bert_prep" {
//     const in = "struct i { int i; }; struct node { int data; struct node next; }; struct tnode { int data; struct tnode left; struct tnode right; }; int a,b; struct i i; fun treeadd(struct tnode root, int toAdd) struct tnode { return root; } fun size(struct node list) int { if (list == null) { return 0; } return 1 + (size(list.next)); } fun buildTree(struct node list) struct tnode { int i; struct tnode root; root = null; i = 0; while (i < size(list)) { root = treeadd(root, get(list, i)); i = i + 1; } return root; }";
//     var str = try inputToIRStringHeader(in, testAlloc);
//     std.debug.print("{s}\n", .{str});
// }
