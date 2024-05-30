pub const std = @import("std");

const Ast = @import("../ast.zig");
const utils = @import("../utils.zig");
const log = @import("../log.zig");
const Set = @import("../array_hash_set.zig");
const IR = @import("ir_phi.zig");
const Phi = @import("phi.zig");

const Function = IR.Function;
const Block = IR.BasicBlock;

pub const BSet = Set.Set(Block.ID);
pub const BitSet = std.bit_set.DynamicBitSet;

pub const Dominance = struct {
    // TODO: replace with bitsets
    dominators: std.ArrayList(BitSet),
    idoms: std.AutoHashMap(Block.ID, Block.ID),
    domChildren: std.AutoHashMap(Block.ID, std.ArrayList(Block.ID)),
    domFront: std.AutoHashMap(Block.ID, std.ArrayList(Block.ID)),
    fun: *Function,
    alloc: std.mem.Allocator,
    numBlocks: u32,

    pub fn init(ir: *IR, fun: *Function) Dominance {
        return .{
            .idoms = std.AutoHashMap(Block.ID, Block.ID).init(ir.alloc),
            .domChildren = std.AutoHashMap(Block.ID, std.ArrayList(Block.ID)).init(ir.alloc),
            .domFront = std.AutoHashMap(Block.ID, std.ArrayList(Block.ID)).init(ir.alloc),
            .dominators = std.ArrayList(BitSet).init(ir.alloc),
            .alloc = ir.alloc,
            .fun = fun,
            .numBlocks = fun.bbs.len + fun.bbs.removed,
        };
    }

    ////////////////////////////////////////////////////////////////////////////
    /// START FUNCTIONS
    ////////////////////////////////////////////////////////////////////////////

    // // dominator of the start node is the start itself
    // Dom(n0) = {n0}
    // // for all other nodes, set all nodes as dominators
    // for each n in N - {n0}
    //     Dom(n) = N;
    // // iteratively eliminate nodes that are not dominators
    // while changes in any Dom(n)
    //     for each n in N - {n0}:
    //         Dom(n) = {n} union with intersection over Dom(p) for all p in pred(n)
    // return Dom
    pub fn generateDominators(self: *Dominance) !void {
        var result = try std.ArrayList(BitSet).initCapacity(self.alloc, self.numBlocks);
        // // fill all the dominators with empty
        for (self.fun.bbs.ids()) |_| {
            try result.append(undefined);
        }

        // // dominator of the start node is the start itself
        // Dom(n0) = {n0}
        // // for all other nodes, set all nodes as dominators
        // for each n in N - {n0}
        //     Dom(n) = N;
        // initialize the dominator sets
        for (self.fun.bbs.ids()) |block| {
            if (block == Function.entryBBID) {
                result.items[block] = try BitSet.initEmpty(self.alloc, self.numBlocks);
                result.items[block].set(block);
                continue;
            }

            result.items[block] = try BitSet.initFull(self.alloc, self.numBlocks);
        }

        // // std.debug.print("after init Dominators\n", .{});
        // for (self.postOrder.items) |block| {
        //     std.debug.print("block = {any}, ", .{block});
        //     result.items[block].print();
        //     std.debug.print("\n", .{});
        // }
        // while changes in any Dom(n)
        //     for each n in N - {n0}:
        //         Dom(n) = {n} union with intersection over Dom(p) for all p in pred(n)
        // return Dom
        var changes = true;
        while (changes) {
            changes = false;
            for (self.fun.bbs.ids()) |block| {
                if (block == Function.entryBBID) continue;

                // get the predecessors for this block
                const preds = try self.getBlockIncomerIDs(block);
                for (preds.items) |pred| {
                    // get the intersection of the dominators of the predecessors
                    // get Dom(p)
                    var predDom = result.items[pred];
                    var blockDom = result.items[block];
                    var intersection = try blockDom.clone(self.alloc);
                    intersection.setIntersection(predDom);
                    intersection.set(block);
                    var changedInter = intersection.eql(blockDom);
                    if (!changedInter) {
                        result.items[block].deinit();
                        result.items[block] = try intersection.clone(self.alloc);
                        changes = true;
                    } else {}
                    intersection.deinit();
                }
                preds.deinit();
            }
        }
        self.dominators = result;
    }

    // // Initialize the immediate dominators map to be empty
    // idom = {}

    // // For each node n in the set of all nodes N
    // for each n in N:
    //     // Exclude the node itself from its set of dominators to find possible idoms
    //     PossibleIdoms = Dom(n) - {n}

    //     // The idom of node n is the unique dominator d in PossibleIdoms such that
    //     // every other dominator in PossibleIdoms is also dominated by d
    //     for each d in PossibleIdoms:
    //         if ∀d' ∈ PossibleIdoms - {d} : d' ∈ Dom(d)
    //             idom[n] = d
    //             break
    // // Return the map of immediate dominators
    // return idom
    pub fn computeIdoms(self: *Dominance) !void {
        // for each n in N;
        for (self.fun.bbs.ids()) |block| {
            // Exclude the node itself from its set of dominators to find possible idoms
            var blockDom = self.dominators.items[block];
            var possibleIdoms = try blockDom.clone(self.alloc);
            _ = possibleIdoms.unset(block);

            // The idom of node n is the unique dominator d in PossibleIdoms such that
            // every other dominator in PossibleIdoms is also dominated by d
            var posIter = possibleIdoms.iterator(.{});
            while (posIter.next()) |d| {
                var doms_all = true;
                // // Check if d dominates all other elements in PossibleIdoms
                // for each d' in PossibleIdoms:
                //     if d != d' and d' not in Dom(d):
                //         dominates_all = false
                //         break
                var posIter2 = possibleIdoms.iterator(.{});
                while (posIter2.next()) |d2| {
                    if (d == d2) {
                        continue;
                    }
                    if (!self.dominators.items[d].isSet(d2)) {
                        // std.debug.print("block = {any}, d = {any}, d2 = {any}\n", .{ self.fun.bbsToCFG.get(block), self.fun.bbsToCFG.get(d.key_ptr.*), self.fun.bbsToCFG.get(d2.key_ptr.*) });
                        doms_all = false;
                        break;
                    }
                }

                if (doms_all) {
                    // std.debug.print("idom adding block = {any}, d = {any}\n", .{ self.fun.bbsToCFG.get(block), self.fun.bbsToCFG.get(d.key_ptr.*) });

                    _ = try self.idoms.put(block, @intCast(d));
                    break;
                }
            }
            possibleIdoms.deinit();
        }
    }

    // finds the children for a node
    // function find_children(idom, all_nodes, target_node):
    //     children = []

    //     // Iterate over all nodes in the graph
    //     for each node in all_nodes:
    //         // Check if the immediate dominator of the current node is the target_node
    //         if idom[node] == target_node:
    //             // If so, add the node to the children list
    //             children.append(node)

    //     // Return the list of children nodes
    //     return children
    pub fn findChildren(self: *Dominance, target_node: Block.ID) !std.ArrayList(Block.ID) {
        var children = std.ArrayList(Block.ID).init(self.alloc);
        for (self.fun.bbs.ids()) |node| {
            if (self.idoms.get(node) == target_node) {
                try children.append(node);
            }
        }
        return children;
    }

    pub fn getBlockIncomerIDs(self: *Dominance, blockID: Block.ID) !std.ArrayList(Block.ID) {
        const block = self.fun.bbs.get(blockID);
        var result = std.ArrayList(Block.ID).init(self.alloc);
        for (block.incomers.items) |incomer| {
            try result.append(incomer);
        }
        return result;
    }

    pub fn printAsDot(self: *Dominance) void {
        std.debug.print("digraph G {{\n", .{});
        for (self.fun.bbs.ids()) |block| {
            // print out the predecessors
            for (self.fun.bbs.get(block).incomers.items) |incomer| {
                INDENT();
                self.printBlockName(incomer);
                std.debug.print(" -> ", .{});
                self.printBlockName(block);
                std.debug.print("\n", .{});
            }
            // print ouf the successors
            for (self.fun.bbs.get(block).outgoers) |outgoer| {
                INDENT();
                if (outgoer == null) {
                    continue;
                }
                self.printBlockName(block);
                std.debug.print(" -> ", .{});
                self.printBlockName(outgoer.?);
                std.debug.print("\n", .{});
            }
        }
        std.debug.print("}}\n", .{});
    }

    pub fn printChildren(self: *Dominance, node: Block.ID) void {
        // print block name
        self.printBlockName(node);
        const children = self.domChildren.get(node);
        if (children == null) {
            return;
        }
        for (children.?.items) |child| {
            std.debug.print("{d} ", .{child});
        }
        std.debug.print("\n", .{});
    }

    pub fn printBlockName(self: *Dominance, block: Block.ID) void {
        const blockName = self.fun.bbs.get(block).name;
        std.debug.print("\"{s}{d}\"", .{ blockName, block });
    }

    pub fn printallChildren(self: *Dominance) void {
        for (self.fun.bbs.ids()) |node| {
            INDENT();
            self.printChildren(node);
        }
    }

    pub fn generateDomChildren(self: *Dominance) !void {
        for (self.fun.bbs.ids()) |node| {
            INDENT();
            try self.domChildren.put(node, try self.findChildren(node));
        }
    }

    // pub fn printDominators(self: *Dominance) void {
    //     for (self.fun.bbs.ids()) |block| {
    //         INDENT();
    //         self.printBlockName(block);
    //         self.dominators.items[block].print();
    //         std.debug.print("\n", .{});
    //     }
    // }

    pub fn printIdoms(self: *Dominance) void {
        var iter = self.idoms.keyIterator();
        while (iter.next()) |key| {
            INDENT();
            self.printBlockName(key.*);
            std.debug.print(" -> ", .{});
            self.printBlockName(self.idoms.get(key.*).?);
            std.debug.print("\n", .{});
        }
    }

    pub fn INDENT() void {
        std.debug.print("   ", .{});
    }

    pub fn printDomFront(self: *Dominance) void {
        var iter = self.domFront.iterator();
        while (iter.next()) |entry| {
            INDENT();
            self.printBlockName(entry.key_ptr.*);
            std.debug.print(" -> ", .{});
            for (entry.value_ptr.items) |block| {
                self.printBlockName(block);
                std.debug.print(" ", .{});
            }
            std.debug.print("\n", .{});
        }
    }

    //computeDF[n]:
    //    S = {}
    //    for each node y in succ[n]:
    //      if idom(y) != n:
    //         S = S U {y}
    //    for each child c of n in the dom-tree:
    //      computeDF[c]
    //      for each w that is in the set DF[c]
    //         if n does not dom w, or n = w:
    //            S = S U {w}
    //    DF[n] = S
    pub fn computeDomFront(self: *Dominance, nodeID: Block.ID) !void {
        const node = self.fun.bbs.get(nodeID);
        var S = std.ArrayList(Block.ID).init(self.alloc);
        // for each node y in succ[n]:
        for (node.outgoers) |outgoer| {
            if (outgoer == null) {
                continue;
            }

            if (self.idoms.get(outgoer.?) != nodeID) {
                // std.debug.print("edge.dest = {d}, nodeID = {d}\n", .{ edge.dest, nodeID });

                try S.append(outgoer.?);
            }
        }
        // for each child c of n in the dom-tree:
        var children = self.domChildren.get(nodeID);
        if (children == null) {
            return;
        }
        for (self.domChildren.get(nodeID).?.items) |child| {
            try self.computeDomFront(child);
            const DF = self.domFront.get(child);
            if (DF == null) continue;
            for (DF.?.items) |w| {
                if (!self.dominators.items[w].isSet(nodeID) or nodeID == w) {
                    try S.append(w);
                }
            }
        }
        try self.domFront.put(nodeID, S);
    }

    /// just do it for all of them
    pub fn computeAllDomFronts(self: *Dominance) !void {
        for (self.fun.bbs.ids()) |node| {
            try self.computeDomFront(node);
        }
    }

    pub fn genDominance(self: *Dominance) !void {
        try self.generateDominators();
        try self.computeIdoms();
        try self.generateDomChildren();
        try self.computeAllDomFronts();
    }

    ////////////////////////////////////////////////////////////////////////////
    // TESTING
    ////////////////////////////////////////////////////////////////////////////

    pub fn compareCFgDomFront(self: *Dominance) !void {
        const cfgFun = self.fun.cfg;
        const cfgDomFront = cfgFun.domFront;
        // go through all of the keys in the dominance front convert to Block.ID see if the values are the same
        var cfgIter = cfgDomFront.iterator();
        while (cfgIter.next()) |entry| {
            const cfgKey = entry.key_ptr;
            const cfgValue = entry.value_ptr;
            const blockID = self.fun.cfgToBBs.get(cfgKey.*).?;
            const domFront = self.domFront.get(blockID);
            // check that the block is in the domFront
            if (domFront == null) {
                utils.impossible("blockID = {d} block = {d} not in domFront\n", .{ blockID, cfgKey });
                continue;
            }

            // check that the values are the same
            const domList = domFront.?;
            var cfgList = std.ArrayList(?Block.ID).init(self.alloc);
            for (cfgValue.items) |cfgBlock| {
                const blockIDAAAA = self.fun.cfgToBBs.get(cfgBlock);
                try cfgList.append(blockIDAAAA);
            }
            var cfgListAsBlockID = cfgList.items;
            for (cfgListAsBlockID) |blockID_| {
                var blockIDFinding = blockID_.?;

                var found: bool = false;
                for (domList.items) |domBlock| {
                    if (domBlock == blockIDFinding) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    utils.impossible("blockID = {d} block = {d} not in domFront\n", .{ blockIDFinding, cfgKey });
                }
            }

            // and then the other way
            for (domList.items) |domBlock| {
                var blockIDFinding = domBlock;
                var found: bool = false;
                for (cfgListAsBlockID) |blockID_| {
                    if (blockID_ == blockIDFinding) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    utils.impossible("blockID = {d} block = {d} not in domFront\n", .{ blockIDFinding, cfgKey });
                }
            }
        }
    }

    pub fn compareToCfgDominator(self: *Dominance) !void {
        // print everything
        // std.debug.print("Dominators\n", .{});
        // self.printDominators();
        // std.debug.print("Idoms\n", .{});
        // self.printIdoms();
        // std.debug.print("Children\n", .{});
        // self.printallChildren();
        // std.debug.print("DomFront\n", .{});
        // self.printDomFront();
        // std.debug.print("\n\n Dot:\n", .{});
        // self.printAsDot();

        try self.compareCFgDomFront();
    }
};

const ting = std.testing;
const testAlloc = std.heap.page_allocator;

fn testMe(input: []const u8) !IR {
    const tokens = try @import("../lexer.zig").Lexer.tokenizeFromStr(input, testAlloc);
    const parser = try @import("../parser.zig").Parser.parseTokens(tokens, input, testAlloc);
    const ast = try Ast.initFromParser(parser);
    const ir = try Phi.generate(testAlloc, &ast);
    return ir;
}

test "dominance.if_test" {
    errdefer log.print();
    const in = "fun main() int {\n int a,b,c;\n if(a == 1){\n b =c;\n}\n b = a; return b;\n }";
    var ir = try testMe(in);
    var funNameID = ir.internIdent("main");
    var fun = ir.getFun(funNameID) catch {
        utils.impossible("fun not found\n", .{});
    };
    var dom = Dominance.init(&ir, fun);
    try dom.genDominance();
    try dom.compareToCfgDominator();
}
