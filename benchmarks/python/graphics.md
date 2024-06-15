---
title: "Compiles Final Paper"
date: today
geometry: margin=1in
format:
   html:
       code-fold: true
jupyter: python3
---

## Parsing
For our compiler, we decided not to use ANTLR or any other parser generator. Instead, we wrote our own tokenizer and parser.

## Static Semantics:

### Type Checking

### Return path checking

## Intermediate Representation

Our compiler stores the IR as a list of functions.
Each function then stores a list of all the registers,
instructions, and basic blocks. Each basic block stores and ordered list of references to instructions. Each instruction stores references to the registers it uses as well as the register it writes to and any other instruction specific data.

The IR is used as a control flow graph as well through the references which the basic blocks hold. This is esspecialy usefull for



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


## BenchMarkishTopics

![BenchMarkishTopics Timings](./media/BenchMarkishTopics-time.svg)

```{.include}
./media/BenchMarkishTopics-stats.md
```

![BenchMarkishTopics Instructions](./media/BenchMarkishTopics-instr.svg)

## Fibonacci

![Fibonacci Timings](./media/Fibonacci-time.svg)

```{.include}
./media/Fibonacci-stats.md
```

![Fibonacci Instructions](./media/Fibonacci-instr.svg)

## GeneralFunctAndOptimize

![GeneralFunctAndOptimize Timings](./media/GeneralFunctAndOptimize-time.svg)

```{.include}
./media/GeneralFunctAndOptimize-stats.md
```

![GeneralFunctAndOptimize Instructions](./media/GeneralFunctAndOptimize-instr.svg)

## OptimizationBenchmark

![OptimizationBenchmark Timings](./media/OptimizationBenchmark-time.svg)

```{.include}
./media/OptimizationBenchmark-stats.md
```

![OptimizationBenchmark Instructions](./media/OptimizationBenchmark-instr.svg)

## TicTac

![TicTac Timings](./media/TicTac-time.svg)

```{.include}
./media/TicTac-stats.md
```

![TicTac Instructions](./media/TicTac-instr.svg)

## array_sort

![array_sort Timings](./media/array_sort-time.svg)

```{.include}
./media/array_sort-stats.md
```

![array_sort Instructions](./media/array_sort-instr.svg)

## array_sum

![array_sum Timings](./media/array_sum-time.svg)

```{.include}
./media/array_sum-stats.md
```

![array_sum Instructions](./media/array_sum-instr.svg)

## bert

![bert Timings](./media/bert-time.svg)

```{.include}
./media/bert-stats.md
```

![bert Instructions](./media/bert-instr.svg)

## biggest

![biggest Timings](./media/biggest-time.svg)

```{.include}
./media/biggest-stats.md
```

![biggest Instructions](./media/biggest-instr.svg)

## binaryConverter

![binaryConverter Timings](./media/binaryConverter-time.svg)

```{.include}
./media/binaryConverter-stats.md
```

![binaryConverter Instructions](./media/binaryConverter-instr.svg)

## brett

![brett Timings](./media/brett-time.svg)

```{.include}
./media/brett-stats.md
```

![brett Instructions](./media/brett-instr.svg)

## creativeBenchMarkName

![creativeBenchMarkName Timings](./media/creativeBenchMarkName-time.svg)

```{.include}
./media/creativeBenchMarkName-stats.md
```

![creativeBenchMarkName Instructions](./media/creativeBenchMarkName-instr.svg)

## fact_sum

![fact_sum Timings](./media/fact_sum-time.svg)

```{.include}
./media/fact_sum-stats.md
```

![fact_sum Instructions](./media/fact_sum-instr.svg)

## hailstone

![hailstone Timings](./media/hailstone-time.svg)

```{.include}
./media/hailstone-stats.md
```

![hailstone Instructions](./media/hailstone-instr.svg)

## hanoi_benchmark

![hanoi_benchmark Timings](./media/hanoi_benchmark-time.svg)

```{.include}
./media/hanoi_benchmark-stats.md
```

![hanoi_benchmark Instructions](./media/hanoi_benchmark-instr.svg)

## killerBubbles

![killerBubbles Timings](./media/killerBubbles-time.svg)

```{.include}
./media/killerBubbles-stats.md
```

![killerBubbles Instructions](./media/killerBubbles-instr.svg)

## mile1

![mile1 Timings](./media/mile1-time.svg)

```{.include}
./media/mile1-stats.md
```

![mile1 Instructions](./media/mile1-instr.svg)

## mixed

![mixed Timings](./media/mixed-time.svg)

```{.include}
./media/mixed-stats.md
```

![mixed Instructions](./media/mixed-instr.svg)

## primes

![primes Timings](./media/primes-time.svg)

```{.include}
./media/primes-stats.md
```

![primes Instructions](./media/primes-instr.svg)

## programBreaker

![programBreaker Timings](./media/programBreaker-time.svg)

```{.include}
./media/programBreaker-stats.md
```

![programBreaker Instructions](./media/programBreaker-instr.svg)

## stats

![stats Timings](./media/stats-time.svg)

```{.include}
./media/stats-stats.md
```

![stats Instructions](./media/stats-instr.svg)

## wasteOfCycles

![wasteOfCycles Timings](./media/wasteOfCycles-time.svg)

```{.include}
./media/wasteOfCycles-stats.md
```

![wasteOfCycles Instructions](./media/wasteOfCycles-instr.svg)

