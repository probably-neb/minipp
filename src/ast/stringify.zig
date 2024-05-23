const std = @import("std");
const Ast = @import("../ast.zig");
const utils = @import("../utils.zig");
const log = @import("../log.zig");

pub fn print_tree(ast: *const Ast) !void {
    const tree = try into_tree(ast);
    // for (tree.children.items, 0..) |child, i| {
    //     const is_last = i == tree.children.items.len - 1;
    //     _ = is_last;
    //     std.debug.print("{s}", .{try child.print()});
    // }
    std.debug.print("\n{s}\n", .{try tree.print()});
}

fn into_tree(ast: *const Ast) !TreeNode {
    // var baseAlloc = ast.allocator;
    // var baseAlloc = std.heap.page_allocator;
    // var arena = std.heap.ArenaAllocator.init(baseAlloc);
    // defer arena.deinit();
    // var alloc = arena.allocator();
    var alloc = ast.allocator;

    const root = try expr_into_treenode(alloc, ast, ast.get(0).*);

    return root;
}

pub const TreeNode = struct {
    data: []const u8,
    children: std.ArrayList(TreeNode),
    alloc: std.mem.Allocator,

    const Self = @This();

    // Create a new tree node
    fn init(alloc: std.mem.Allocator, data: []const u8) Self {
        return TreeNode{
            .data = data,
            .children = std.ArrayList(TreeNode).init(alloc),
            .alloc = alloc,
        };
    }

    // Add a child node directly to this node
    fn add_node(self: *Self, data: TreeNode) !void {
        try self.children.append(data);
    }

    const Str = std.ArrayList(u8);

    const Writer = std.ArrayList(u8).Writer;
    // Print the tree
    // TODO: take writer so we can swap between stdout and stderr
    fn print(self: *const Self) ![]const u8 {
        var str = Str.init(self.alloc);
        var writer = str.writer();

        _ = try writer.write(self.data);
        _ = try writer.write("\n");

        const children = self.children;

        var last_index: usize = children.items.len;
        if (last_index > 0) {
            last_index -= 1;
        }

        for (self.children.items, 0..) |child, index| {
            try child.print_child(
                &writer,
                "",
                index == last_index,
            );
        }

        return str.items;
    }

    fn print_child(self: *const Self, str: *Writer, prefix: []const u8, is_last: bool) !void {
        _ = try str.write(prefix);
        _ = try str.write(if (is_last) "└─ " else "├─ ");
        _ = try str.write(self.data);
        _ = try str.write("\n");
        const new_prefix = try std.fmt.allocPrint(self.alloc, "{s}{s}", .{ prefix, if (is_last) "    " else "│   " });
        defer self.alloc.free(new_prefix);

        const children = self.children;

        var last_index: usize = children.items.len;
        if (last_index > 0) {
            last_index -= 1;
        }

        for (self.children.items, 0..) |child, index| {
            try child.print_child(
                str,
                new_prefix,
                index == last_index,
            );
        }
    }
};

fn expr_into_treenode(alloc: std.mem.Allocator, ast: *const Ast, node: Ast.Node) !TreeNode {
    const data = try repr_node(alloc, ast, node);
    var node_t = TreeNode.init(alloc, data);

    switch (node.kind) {
        .Program => |prog| {
            const progDecls_t = try expr_into_treenode(alloc, ast, ast.get(prog.declarations).*);
            try node_t.add_node(progDecls_t);
            const funcs_t = try expr_into_treenode(alloc, ast, ast.get(prog.functions).*);
            try node_t.add_node(funcs_t);
        },
        .ProgramDeclarations => |progDecls| {
            if (progDecls.types) |types| {
                const types_t = try expr_into_treenode(alloc, ast, ast.get(types).*);
                try node_t.add_node(types_t);
            }
            if (progDecls.declarations) |decls| {
                var decls_t = try expr_into_treenode(alloc, ast, ast.get(decls).*);
                decls_t.data = "Globals";
                try node_t.add_node(decls_t);
            }
        },
        .Types => |types| {
            var iter = Ast.NodeIter(.TypeDeclaration).init(ast, types.firstType, types.lastType);
            while (iter.next()) |typeDecl| {
                const typeDecl_t = try expr_into_treenode(alloc, ast, typeDecl);
                try node_t.add_node(typeDecl_t);
            }
        },
        .TypeDeclaration => |tDecl| {
            const fieldDecls = ast.get(tDecl.declarations).*.kind.StructFieldDeclarations;
            var iter = fieldDecls.iter(ast);
            while (iter.next()) |fieldDecl| {
                const fieldDecl_t = try expr_into_treenode(alloc, ast, fieldDecl);
                try node_t.add_node(fieldDecl_t);
            }
        },
        .LocalDeclarations => |localDecls| {
            var iter = localDecls.iter(ast);
            log.trace("num locals - {d}\n", .{iter.calculateLen()});
            while (iter.next()) |tIdent| {
                const tIdent_t = try expr_into_treenode(alloc, ast, tIdent);
                try node_t.add_node(tIdent_t);
            }
        },
        .Functions => |funcs| {
            var iter = Ast.NodeIter(.Function).init(ast, funcs.firstFunc, funcs.lastFunc);
            while (iter.next()) |funDef| {
                const funDef_t = try expr_into_treenode(alloc, ast, funDef);
                try node_t.add_node(funDef_t);
            }
        },
        .Function => |func| {
            const proto = ast.get(func.proto).*;
            const proto_t = try expr_into_treenode(alloc, ast, proto);
            try node_t.add_node(proto_t);
            const body_t = try expr_into_treenode(alloc, ast, ast.get(func.body).*);
            try node_t.add_node(body_t);
        },
        .FunctionBody => |body| {
            if (body.declarations) |decls| {
                const decls_t = try expr_into_treenode(alloc, ast, ast.get(decls).*);
                try node_t.add_node(decls_t);
            }
            if (body.statements) |stmts| {
                const stmts_t = try expr_into_treenode(alloc, ast, ast.get(stmts).*);
                try node_t.add_node(stmts_t);
            }
        },
        .FunctionProto => |proto| {
            if (proto.parameters) |params| {
                const params_t = try expr_into_treenode(alloc, ast, ast.get(params).*);
                try node_t.add_node(params_t);
            }
        },
        .Parameters => |params| {
            var iter = params.iter(ast);
            while (iter.next()) |param| {
                const param_t = try expr_into_treenode(alloc, ast, param);
                try node_t.add_node(param_t);
            }
        },
        .Invocation => |funCall| {
            if (funCall.args) |args| {
                const arg_node = ast.get(args).*.kind.Arguments;
                var argsIter = arg_node.iter(ast);
                while (argsIter.next()) |arg| {
                    const arg_t = try expr_into_treenode(alloc, ast, arg);
                    try node_t.add_node(arg_t);
                }
            }
        },
        .StatementList => |stmtList| {
            var iter = Ast.NodeIter(.Statement).init(ast, stmtList.firstStatement, stmtList.lastStatement);
            while (iter.next()) |stmt| {
                const stmt_t = try expr_into_treenode(alloc, ast, stmt);
                iter.skipTo(stmt.kind.Statement.finalIndex);
                try node_t.add_node(stmt_t);
            }
        },
        .Statement => |stmt| {
            var stmt_t = try expr_into_treenode(alloc, ast, ast.get(stmt.statement).*);
            try node_t.add_node(stmt_t);
        },
        .Assignment => |assign| {
            const lhs = ast.get(assign.lhs).*;
            const lhs_t = try expr_into_treenode(alloc, ast, lhs);
            try node_t.add_node(lhs_t);
            const rhs = ast.get(assign.rhs).*;
            const rhs_t = try expr_into_treenode(alloc, ast, rhs);
            try node_t.add_node(rhs_t);
        },
        .LValue => |lval| {
            if (lval.chain) |chain| {
                const chain_t = try expr_into_treenode(alloc, ast, ast.get(chain).*);
                try node_t.add_node(chain_t);
            }
        },
        .Expression => |expr| {
            const expr_t = try expr_into_treenode(alloc, ast, ast.get(expr.expr).*);
            try node_t.add_node(expr_t);
        },
        .BinaryOperation => |binop| {
            const lhs = ast.get(binop.lhs).*;
            const lhs_t = try expr_into_treenode(alloc, ast, lhs);
            try node_t.add_node(lhs_t);
            const rhs = ast.get(binop.rhs).*;
            const rhs_t = try expr_into_treenode(alloc, ast, rhs);
            try node_t.add_node(rhs_t);
        },
        .UnaryOperation => |unop| {
            const expr = ast.get(unop.on).*;
            const expr_t = try expr_into_treenode(alloc, ast, expr);
            try node_t.add_node(expr_t);
        },
        .Selector => |sel| {
            const expr = ast.get(sel.factor).*;
            var expr_t = try expr_into_treenode(alloc, ast, expr);
            if (sel.chain) |chain| {
                const chain_t = try expr_into_treenode(alloc, ast, ast.get(chain).*);
                try expr_t.add_node(chain_t);
            }
            try node_t.add_node(expr_t);
        },
        .Factor => |factor| {
            const expr = ast.get(factor.factor).*;
            const expr_t = try expr_into_treenode(alloc, ast, expr);
            try node_t.add_node(expr_t);
        },
        .SelectorChain => |chain| {
            if (chain.next) |next| {
                const chain_t = try expr_into_treenode(alloc, ast, ast.get(next).*);
                try node_t.add_node(chain_t);
            }
        },
        .While => |whileNode| {
            const cond = ast.get(whileNode.cond).*;
            const cond_t = try expr_into_treenode(alloc, ast, cond);
            try node_t.add_node(cond_t);
            const body = ast.get(whileNode.block).*;
            const body_t = try expr_into_treenode(alloc, ast, body);
            try node_t.add_node(body_t);
        },
        .Block => |block| {
            if (block.statements) |stmts| {
                const stmts_t = try expr_into_treenode(alloc, ast, ast.get(stmts).*);
                try node_t.add_node(stmts_t);
            }
        },
        .ConditionalIf => |ifNode| {
            const cond = ast.get(ifNode.cond).*;
            const cond_t = try expr_into_treenode(alloc, ast, cond);
            try node_t.add_node(cond_t);
            const body = ast.get(ifNode.block).*;
            const body_t = try expr_into_treenode(alloc, ast, body);
            try node_t.add_node(body_t);
        },
        .ConditionalIfElse => |elseNode| {
            const then_t = try expr_into_treenode(alloc, ast, ast.get(elseNode.ifBlock).*);
            try node_t.add_node(then_t);
            const else_t = try expr_into_treenode(alloc, ast, ast.get(elseNode.elseBlock).*);
            try node_t.add_node(else_t);
        },
        .Return => |ret| {
            if (ret.expr) |expr| {
                const expr_t = try expr_into_treenode(alloc, ast, ast.get(expr).*);
                try node_t.add_node(expr_t);
            }
        },
        .NewIntArray => |newIntArray| {
            const expr_t = try expr_into_treenode(alloc, ast, ast.get(newIntArray.length).*);
            try node_t.add_node(expr_t);
        },
        .Print => |print| {
            const expr_t = try expr_into_treenode(alloc, ast, ast.get(print.expr).*);
            try node_t.add_node(expr_t);
            if (print.hasEndl) {
                const endl_t = TreeNode.init(alloc, "endl");
                try node_t.add_node(endl_t);
            }
        },
        // base nodes with no children
        // typed Identifier has children but we display it as `{type} {name}`
        // for simplicity's sake
        .TypedIdentifier, .Number, .Identifier, .True, .False, .Read => {},
        else => utils.todo("expr_into_treenode: {s}", .{@tagName(node.kind)}),
    }
    return node_t;
}

fn repr_node(alloc: std.mem.Allocator, ast: *const Ast, node: Ast.Node) ![]const u8 {
    return switch (node.kind) {
        // just print tag name
        .LocalDeclarations,
        .Types,
        .Program,
        .ProgramDeclarations,
        .FunctionBody,
        .Functions,
        .StatementList,
        .Statement,
        .Assignment,
        .Factor,
        .Selector,
        .Expression,
        .Block,
        .True,
        .False,
        .ConditionalIf,
        .ConditionalIfElse,
        .While,
        .Return,
        => @tagName(node.kind),
        // print tag name and token tag name
        .UnaryOperation, .BinaryOperation => std.fmt.allocPrint(alloc, "{s} {s}", .{ @tagName(node.kind), tok_name(node) }),
        // print tag name and token value
        .LValue, .Identifier, .Number => std.fmt.allocPrint(alloc, "{s} {s}", .{ @tagName(node.kind), tok_str(ast, node) }),
        .SelectorChain => |chain| std.fmt.allocPrint(alloc, "{s} .{s}", .{ @tagName(node.kind), ast.getIdentValue(chain.ident) }),
        .TypeDeclaration => |tDecls| std.fmt.allocPrint(alloc, "Struct {s}", .{ast.getIdentValue(tDecls.ident)}),
        .TypedIdentifier => |tIdent| std.fmt.allocPrint(alloc, "{s} {s}", .{ @tagName(tIdent.getType(ast)), tIdent.getName(ast) }),
        .Function => |funDef| std.fmt.allocPrint(alloc, "Fun {s}", .{ast.getIdentValue(ast.get(funDef.proto).*.kind.FunctionProto.name)}),
        .FunctionProto => |proto| std.fmt.allocPrint(alloc, "{s} -> {s}", .{ proto.getName(ast), @tagName(if (proto.getReturnType(ast)) |ty| ty else .Void) }),
        .Invocation => |funCall| std.fmt.allocPrint(alloc, "Call {s}", .{ast.getIdentValue(funCall.funcName)}),
        else => {
            log.warn("unhandled repr_node: {s}\n", .{@tagName(node.kind)});
            return @tagName(node.kind);
        },
    };
}

fn dbg(label: []const u8, str: []const u8) []const u8 {
    std.debug.print("{s}: {s}\n", .{ label, str });
    return str;
}

fn tok_str(ast: *const Ast, node: Ast.Node) []const u8 {
    return node.token._range.getSubStrFromStr(ast.input);
}

fn tok_name(node: Ast.Node) []const u8 {
    return @tagName(node.token.kind);
}

test "ast/stringify.make-sure-this-shit-compiles" {
    defer log.print();
    // TODO: comment out the `else` arms in the repr and treenode
    // switch statements and handle unhandled nodes
    // i.e.
    //  - Delete
    //  - New
    //  - Read
    //  - Print
    //  - Print endl
    //  - BackfillReserve -> unreachable
    // FIXME:
    // figure out why it is printing the local a in main
    // as a global
    const input =
        \\ struct foo {
        \\   int a;
        \\   bool b;
        \\   struct foo foo;
        \\ };
        \\ 
        \\ int globalA;
        \\ bool globalB;
        \\ struct foo globalFoo;
        \\
        \\ fun main() void {
        \\      int a;
        \\      bool b;
        \\      struct foo foo;
        \\      a = -1 / 2 * 3 + 4 - 5;
        \\      b = !true == false && a < a && a > a || a <= 10 || a >= 15 || a != 12;
        \\      foo.foo.foo.a = a;
        \\      while (b) {
        \\          if (false) {
        \\              return;
        \\          } else {
        \\              a = -0;
        \\          }
        \\      }
        \\ }
    ;
    const tokens = try @import("../lexer.zig").Lexer.tokenizeFromStr(input, std.heap.page_allocator);
    const parser = try @import("../parser.zig").Parser.parseTokens(tokens, input, std.heap.page_allocator);
    const ast = try Ast.initFromParser(parser);
    try print_tree(&ast);
}
