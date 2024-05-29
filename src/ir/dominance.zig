pub const std = @import("std");

const Ast = @import("../ast.zig");
const utils = @import("../utils.zig");
const log = @import("../log.zig");
const Set = @import("../array_hash_set.zig");
const IR = @import("ir_phi.zig");

const Function = IR.Function;
const Block = IR.BasicBlock;

pub const BSet = Set.Set(Block.ID);

pub const Dominance = struct {
    // TODO: replace with bitsets
    dominators: std.ArrayList(Set.Set(Block.ID)),
    idoms: std.AutoHashMap(Block.ID, Block.ID),
    domChildren: std.AutoHashMap(Block.ID, std.ArrayList(Block.ID)),
    domFront: std.AutoHashMap(Block.ID, std.ArrayList(Block.ID)),
};


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
pub fn generateDominators(self: *CfgFunction) !void {
    var result = try std.ArrayList(Set.Set(Block.ID)).initCapacity(self.alloc, self.blocks.items.len);
    // fill all the dominators with empty
    for (self.blocks.items) |_| {
        try result.append(BSet.init());
    }

    // // dominator of the start node is the start itself
    // Dom(n0) = {n0}
    // // for all other nodes, set all nodes as dominators
    // for each n in N - {n0}
    //     Dom(n) = N;
    // initialize the dominator sets
    for (self.postOrder.items, 0..) |block, i| {
        if (i == 0) {
            _ = try result.items[block].add(self.alloc, block);
            continue;
        }

        for (self.postOrder.items) |block2| {
            _ = try result.items[block].add(self.alloc, block2);
        }
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
        for (self.postOrder.items, 0..) |block, i| {
            if (i == 0) continue;

            // get the predecessors for this block
            const preds = try self.getBlockIncomerIDs(block);
            for (preds.items) |pred| {
                // get the intersection of the dominators of the predecessors
                // get Dom(p)
                var predDom = result.items[pred];
                var blockDom = result.items[block];
                var intersection = try blockDom.intersectionOf(self.alloc, predDom);
                _ = try intersection.add(self.alloc, block);
                // std.debug.print("\nblock = {any}, pred = {any}\n", .{ block, pred });
                // std.debug.print("predDom\n", .{});
                // predDom.print();
                // std.debug.print("blockDm\n", .{});
                // blockDom.print();
                // std.debug.print("intersection\n", .{});
                // intersection.print();
                // std.debug.print("\n", .{});
                var changedInter = intersection.eql(blockDom);
                if (!changedInter) {
                    result.items[block].deinit(self.alloc);
                    result.items[block] = try intersection.clone(self.alloc);
                    changes = true;
                } else {}
                intersection.deinit(self.alloc);
            }
            preds.deinit();
        }
    }
    self.dominators = result;
    // // std.debug.print("Dominators\n", .{});
    // for (self.postOrder.items) |block| {
    //     std.debug.print("block = {any}, ", .{block});
    //     self.dominators.items[block].print();
    //     std.debug.print("\n", .{});
    // }
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
pub fn computeIdoms(self: *CfgFunction) !void {
    // for each n in N;
    for (self.postOrder.items) |block| {
        // Exclude the node itself from its set of dominators to find possible idoms
        var blockDom = self.dominators.items[block];
        var possibleIdoms = try blockDom.clone(self.alloc);
        _ = possibleIdoms.remove(block);

        // The idom of node n is the unique dominator d in PossibleIdoms such that
        // every other dominator in PossibleIdoms is also dominated by d
        var posIter = possibleIdoms.iterator();
        while (posIter.next()) |d| {
            var doms_all = true;
            // // Check if d dominates all other elements in PossibleIdoms
            // for each d' in PossibleIdoms:
            //     if d != d' and d' not in Dom(d):
            //         dominates_all = false
            //         break
            var posIter2 = possibleIdoms.iterator();
            while (posIter2.next()) |d2| {
                if (d.key_ptr.* == d2.key_ptr.*) {
                    continue;
                }
                if (!self.dominators.items[d.key_ptr.*].contains(d2.key_ptr.*)) {
                    // std.debug.print("block = {d}, d = {d}, d2 = {d}\n", .{ block, d.key_ptr.*, d2.key_ptr.* });
                    doms_all = false;
                    break;
                }
            }

            if (doms_all) {
                // std.debug.print("idom adding block = {d}, idom = {d}\n", .{ block, d.key_ptr.* });

                _ = try self.idoms.put(block, d.key_ptr.*);
                break;
            }
        }
        possibleIdoms.deinit(self.alloc);
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
pub fn findChildren(self: *CfgFunction, target_node: Block.ID) !std.ArrayList(Block.ID) {
    var children = std.ArrayList(Block.ID).init(self.alloc);
    for (self.postOrder.items) |node| {
        if (self.idoms.get(node) == target_node) {
            try children.append(node);
        }
    }
    return children;
}

pub fn printChildren(self: *CfgFunction, node: Block.ID) void {
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

pub fn printallChildren(self: *CfgFunction) void {
    for (self.postOrder.items) |node| {
        self.printChildren(node);
    }
}

pub fn generateDomChildren(self: *CfgFunction) !void {
    for (self.postOrder.items) |node| {
        try self.domChildren.put(node, try self.findChildren(node));
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
pub fn computeDomFront(self: *CfgFunction, nodeID: Block.ID) !void {
    const node = self.blocks.items[nodeID];
    var S = std.ArrayList(Block.ID).init(self.alloc);
    // for each node y in succ[n]:
    for (node.outgoers) |outgoer| {
        if (outgoer == null) {
            continue;
        }
        const edge = self.edges.items[outgoer.?];
        if (self.idoms.get(edge.dest) != nodeID) {
            // std.debug.print("edge.dest = {d}, nodeID = {d}\n", .{ edge.dest, nodeID });

            try S.append(edge.dest);
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
            if (!self.dominators.items[w].contains(nodeID) or nodeID == w) {
                try S.append(w);
            }
        }
    }
    try self.domFront.put(nodeID, S);
}

/// just do it for all of them
pub fn computeAllDomFronts(self: *CfgFunction) !void {
    for (self.postOrder.items) |node| {
        try self.computeDomFront(node);
    }
}

pub fn genDominance(self: *CfgFunction) !void {
    try self.generateDominators();
    try self.computeIdoms();
    try self.generateDomChildren();
    try self.computeAllDomFronts();
}
