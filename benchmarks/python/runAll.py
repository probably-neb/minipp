import os
import sys
import time
import json
import subprocess
from llvmlite import ir
from llvmlite import binding as llvm
tests = {
        "BenchMarkishTopics" : 100,
        "Fibonacci" :10,
        "GeneralFunctAndOptimize" :10,
        "OptimizationBenchmark" :100,
        "TicTac" :100,
        "array_sort" :100,
        "array_sum" :100,
        "bert" :100,
        "biggest" :100,
        "binaryConverter" :10,
        "brett" :100,
        "creativeBenchMarkName" :10,
        "fact_sum" :100,
        "hailstone" :100,
        "hanoi_benchmark" :10,
        "killerBubbles" :10,
        "mile1" :100,
        "mixed" :10,
        "primes" :10,
        "programBreaker" :100,
        "stats" :100,
        "wasteOfCycles" :100,
         }

types = [("cNoOpt", "Clang -O0"),
         ("cOpt", "Clang -O3"),
         ("stack", "Stack"),
         ("phi", "Phi"),
         ("opt", "Optimized")]

wdir = "/home/spenc/calPoly/class/Csc341/minipp/benchmarks/"

def compeleCfiles():
    for key in tests.keys():
        os.system(f"clang -O0 -o {wdir}cNoOpt/benchmarks/{key}/{key} {wdir}cNoOpt/benchmarks/{key}/{key}.c")
    for key in tests.keys():
        os.system(f"clang -O3 -o {wdir}cOpt/benchmarks/{key}/{key} {wdir}cOpt/benchmarks/{key}/{key}.c")
        
def runTests():
    times = {}
    for key in tests.keys():
        individualTimes = {}
        for tp in types:
            dir = f"{wdir}{tp[0]}/benchmarks/{key}/"
            perRunTimes = []
            for i in range(tests[key]):
                start = time.time()
                os.system(f"{dir}{key} < {dir}input")
                end = time.time()
                perRunTimes.append(end - start)
            individualTimes[tp[1]] = perRunTimes
        times[key] = individualTimes
    return times

def count_instructions(filename):
    with open(filename, 'r') as f:
        llvm_ir = f.read()

    # Initialize LLVM
    llvm.initialize()
    llvm.initialize_native_target()
    llvm.initialize_native_asmprinter()

    # Create a LLVM module
    module = llvm.parse_assembly(llvm_ir)

    total_instructions = 0
    for func in module.functions:
        for block in func.blocks:
            # Iterate over instructions and count them
            for _ in block.instructions:
                total_instructions += 1

    return total_instructions

def calculateInstructionCount():
    instrCounts = {}
    for key in tests.keys():
        programInstrCounts = {}
        for tp in types[2:]:
            file = f"{wdir}{tp[0]}/benchmarks/{key}/{key}.ll"
            count = count_instructions(file)
            programInstrCounts[tp[1]] = [count]
        instrCounts[key] = programInstrCounts
    return instrCounts

if __name__ == "__main__":
    # compeleCfiles()
    times = runTests()
    # print the times to times.json
    with open("times.json", "w") as f:
        json.dump(times, f, indent=4)
    instrCounts = calculateInstructionCount()
    with open("instrCounts.json", "w") as f:
        json.dump(instrCounts, f, indent=4)

