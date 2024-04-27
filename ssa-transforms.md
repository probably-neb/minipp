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

