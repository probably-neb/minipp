[HELPFUL LINK](https://blog.yossarian.net/2020/10/23/Understanding-static-single-assignment-forms)
# OPTIMIZATIONS

# dead code elimination

### liveness analysis

Mark side effects (mutations, io) and return variables as live, work backwards from what is needed to create their operands

#### steps
- find side effects
- search for side effect operands
- identify non-live instructions & eliminate

#### notes

Should have it's own data structure for saving live nodes
and remaining unalive instructions, possibly a set of all instructions where instructions get removed when recusively marking as live

#### operations

- search for specific set of instruction kinds (side effects + returns)
```
nodes := function.find_one_of(.Ret, .Store, .Call(.Read), .Call(.Print))

```
- get register (getting operands of live inst/s)
- remove set of insts


#### reachability

Using constants determined in constant propogation, folding, etc (all constant stuff) evaluates compile time known conditionals and removes not-taken branches


# constant folding

Evaluate compile time known expressions. ex. `int x = 1 + 2` -> remove addition and just have `store %x 3`

### steps
- identify operation where all inputs are constant
- evalutate the operation
- replace inst/s with result

### operations
- identifying constants
- locating 'operations' (add, mul, etc) where operands are constant
- replacing inst/s & possibly removing (if an add assigned to `r1` doesn't need to happen and just becomes loading a constant, the downstream usages of `r1` could just load the constant/use as immediate as well although this is likely the job of constant propogation)


    
# constant propogation

Replaces load-then-use instances with just use referencing the original assignent when there is no possible assignment between the two uses. Also involves replacing integer constants with immediates, ex. `int x` declared and only assigned once -> replace references to x with the use of an immediate instead of a load and use

Relies on dominance (cfg parents/control flow analysis i.e. if this bb is running these other bbs must have ran and the rest can't have)





----
```{wawa}
struct S {
    int x;
    int y;
    struct s;
};

fun main()void{
    struct S s;
    int a;
    a = s.s.s.s.s.s.s.x + s.s.s.s.s.s.s.s.s.s.y;
    print a endl;
};
```


```{field access}

```


# IDEAS
Basic block:
 - List of instructions
 - List of predecessors
 - List of successors
 - List of live variables in both start and end of block
   - Note: this will have to be updated after each optimization, and/or in a serperate pass 
 - List/Map of variables to their last assignment
 - List of phi functions (should be at top of block and only have one assignment)
   - Note that this does not have to be at the top of the block.
For optimization:
 - List of Dominators
 - Immediate Dominator

Register References (Ref.id):
- [block_id, offset in block]
  - pros:
    - makes propogating inner-bb mutations (relatively) trivial as you just need to search for refs with the block id you mutated
      and update the relative pos. For removing blocks the refs to that block /should/ all be unalive so should be removed in the same
      step that removed the block
      ```{example}
        for (current_function.getRefsToBlock(block_id)) |ref| { 
            if ref.offset > removed_inst_offset {
                 ref.offset -= num_insts_removed 
            }
        }
      ```
- incrementing id within function
  - blocks would store a range/their max reg id so you could do 
    ```
    while (block.next()) |bb| { if (bb.max_id > needle) {break :blk bb.id;}}
    ```
    without having to store all instructions in one big list

Reference Register LUT:
- Look up table that houses the registers in the Block/function
- You pass in an index, it returns the register. If the index does not exist, the lut puts it at the first zero
- When you remove a register, the lut stops tracking the index, and sets the location that housed it previously to zero.


```{REGLUT}
getNew(to: ):
    let id = self.len()
```

``` c
fun do_math(int count, int base) int {
  int i = 0;
  while(i < count){
      i++;
      base += base;
  }
  return base;
}
```

Block 1:
```{llvm}
define i64 @do_math(i64 %count, i64 %base) {
    entry:
        %igt0 = icmp sgt i64 %count, 0
        br i1 %igt0, /* true  */ label %body, /* false  */ label %exit
    body:
        %i = phi i64 [%entry -> 0], [%body -> %inc]
        %inc = addi i64 %i, 1
        %base.old = phi i64 [%entry -> %base], [%body -> %base.new]
        %base.new = add i64 %base.old, %base.old
        %shouldexit = icmp eq i64 %inc, %count
        br i1 %shouldexit, /* true */ label %exit, /* false */ label %body
    exit:
        %base.final = phi i64 [%entry -> %base], [%body -> %base.new]
        ret i64 %base.final
}
```
Block{
  instructions[]
  pre[]
  succ[]
  phi[]
  last_assign[][]
}



```{c}
int main(void) {
  int x = 100;

  if (rand() % 2) {
     x = 200;
  } else if (rand() % 2) {
     x = 300;
  } else {
     x = 400;
  }

  return x;
}
```

Pass 1:
Blocks{
    1: {
        instructions: [r0 <- 100, r1 <- call rand, r2 <- r1 % 2, brez r2, b2, b3]
        pre: []
        succ: [b2,b3]
        phi: []
        last_assign: [x: r0]
    }
    2: {
        instructions: [r3 <- 200, j b4]
        pre: [b1]
        zucc: [b4]
        phi: []
        last_assign: [x: r3]
    }
    3: {
        instructions: [r4 <- call rand, r5 <- r4 % 2, brez r5, 5 6]
        pre: [b1]
        succ: [b5,b6]
        phi: []
        last_assign: []
    }
    5: {
        instructions: [r6 <- 300, j 7]
        pre: [3]
        succ: [7]
        phi: []
        last_assign: [x: r6]
    }
    6: {
        instructions: [r7 <- 400, j 7]
        pre: [3]
        succ: [7]
        phi: []
        last_assign: [x: r7]
    }

}





```
define i32 @main() {
entry:
    %x = alloca i64
    store %x 100
    %rand1 = call i64 @rand()
    %rand1mod2 = mod i64 %rand1, 2
    %rand1even = icmp eq i64 %rand1mod2, 0
    br i1 %rand1even, label %rand1_is_even, label %rand1_is_odd
rand1_is_even:
    store %x, 200
    br label %exit
rand1_is_odd:
    %rand2 = call i64 @rand()
    %rand2mod2 = mod i64 %rand2, 2
    %rand2even = icmp eq i64 %rand2mod2, 0
    br i1 %rand2even, label %rand2_is_even, label %rand2_is_odd    
rand2_is_even:
    store %x, 300
    br label %exit
rand2_is_odd:
    store %x, 400
    br label %exit
exit:
    %x_end = load i64 %x
    ret %x_end
}
```