---
title: Final Paper
subtitle: CSC 431
date: Friday June 14th, 2024
author:
    - Benjamin Kunkle
    - Dylan Liefer-Ives
    - Spencer Perley
geometry: margin=1in
---

# Overview 

## Parsing

For our compiler, we decided not to use ANTLR or any other parser generator. Instead, we wrote our own tokenizer and parser.

![INSERT FIGURE DESCRIPTION HERE](./media/node.png){width=300px}

![INSERT FIGURE DESCRIPTION HERE](./media/parser.png){width=300px}

![INSERT FIGURE DESCRIPTION HERE](./media/range.png){width=300px}

![INSERT FIGURE DESCRIPTION HERE](./media/token.png){width=300px}

![INSERT FIGURE DESCRIPTION HERE](./media/while.png){width=300px}

## Static Semantics:

### Type Checking

### Return path checking

## Intermediate Representation

Our compiler stores the IR as a list of functions.
Each function then stores a list of all the registers,
instructions, and basic blocks. Each basic block stores and ordered list of references to instructions. Each instruction stores references to the registers it uses as well as the register it writes to and any other instruction specific data.

The IR is used as a control flow graph as well through the references which the basic blocks hold. This is especially useful for


## Optimizations:
For our compiler, we implemented the following optimizations:

### Sparse Conditional Constant Propagation
First, we implemented SCCP which propogates constant values. If while propogating a constant value, a conditional branch is reached, and the condition is known, we only continue propogating down that branch. Once we are finished any unreachable basic blocks are removed, and references to things in the blocks like phi nodes are replaced with the constant value.

### Comparison Propagation
On top of SCCP, we implemented comparison propagation. This is an extention of SCCP that evalueates comparisons and removes redundant ones. For example, if we check that a value is less than some number and then check again if it is biger than some larger number, we can remove the child comparison as it is impossible to be true. We also can create constants from direct comparisons. For example, if we compare a value to 0, we can do constant propogation on the value in the branch where it is the case where the value is 0.

### Dead Code Elimination
Finaly, we implemented mark and sweep dead code elimination. This was fairly straightforward to implement. For each function in the IR, we first marked all the side effects like calls as well as the return value. Then we marked everything that the marked values relied on. Finally we removed anything not marked.

### Empty Block Removal
Somewhat related to dead code elimination, we also implemented empty block removal which removes any basic blocks with only a single jump instruction.

# Analysis

## BenchMarkishTopics

![](./media/BenchMarkishTopics-time.svg)

```{.include}
./media/BenchMarkishTopics-stats.md
```

![](./media/BenchMarkishTopics-instr.svg)

## Fibonacci

![](./media/Fibonacci-time.svg)

```{.include}
./media/Fibonacci-stats.md
```

![](./media/Fibonacci-instr.svg)

## GeneralFunctAndOptimize

![](./media/GeneralFunctAndOptimize-time.svg)

```{.include}
./media/GeneralFunctAndOptimize-stats.md
```

![](./media/GeneralFunctAndOptimize-instr.svg)

## OptimizationBenchmark

![](./media/OptimizationBenchmark-time.svg)

```{.include}
./media/OptimizationBenchmark-stats.md
```

![](./media/OptimizationBenchmark-instr.svg)

## TicTac

![](./media/TicTac-time.svg)

```{.include}
./media/TicTac-stats.md
```

![](./media/TicTac-instr.svg)

## array_sort

![](./media/array_sort-time.svg)

```{.include}
./media/array_sort-stats.md
```

![](./media/array_sort-instr.svg)

## array_sum

![](./media/array_sum-time.svg)

```{.include}
./media/array_sum-stats.md
```

![](./media/array_sum-instr.svg)

## bert

![](./media/bert-time.svg)

```{.include}
./media/bert-stats.md
```

![](./media/bert-instr.svg)

## biggest

![](./media/biggest-time.svg)

```{.include}
./media/biggest-stats.md
```

![](./media/biggest-instr.svg)

## binaryConverter

![](./media/binaryConverter-time.svg)

```{.include}
./media/binaryConverter-stats.md
```

![](./media/binaryConverter-instr.svg)

## brett

![](./media/brett-time.svg)

```{.include}
./media/brett-stats.md
```

![](./media/brett-instr.svg)

## creativeBenchMarkName

![](./media/creativeBenchMarkName-time.svg)

```{.include}
./media/creativeBenchMarkName-stats.md
```

![](./media/creativeBenchMarkName-instr.svg)

## fact_sum

![](./media/fact_sum-time.svg)

```{.include}
./media/fact_sum-stats.md
```

![](./media/fact_sum-instr.svg)

## hailstone

![](./media/hailstone-time.svg)

```{.include}
./media/hailstone-stats.md
```

![](./media/hailstone-instr.svg)

## hanoi_benchmark

![](./media/hanoi_benchmark-time.svg)

```{.include}
./media/hanoi_benchmark-stats.md
```

![](./media/hanoi_benchmark-instr.svg)

## killerBubbles

![](./media/killerBubbles-time.svg)

```{.include}
./media/killerBubbles-stats.md
```

![](./media/killerBubbles-instr.svg)

## mile1

![](./media/mile1-time.svg)

```{.include}
./media/mile1-stats.md
```

![](./media/mile1-instr.svg)

## mixed

![](./media/mixed-time.svg)

```{.include}
./media/mixed-stats.md
```

![](./media/mixed-instr.svg)

## primes

![](./media/primes-time.svg)

```{.include}
./media/primes-stats.md
```

![](./media/primes-instr.svg)

## programBreaker

![](./media/programBreaker-time.svg)

```{.include}
./media/programBreaker-stats.md
```

![](./media/programBreaker-instr.svg)

## stats

![](./media/stats-time.svg)

```{.include}
./media/stats-stats.md
```

![](./media/stats-instr.svg)

## wasteOfCycles

![](./media/wasteOfCycles-time.svg)

```{.include}
./media/wasteOfCycles-stats.md
```

![](./media/wasteOfCycles-instr.svg)

