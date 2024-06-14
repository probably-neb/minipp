declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

@global1 = global i64 undef, align 8
@global2 = global i64 undef, align 8
@global3 = global i64 undef, align 8

define i64 @constantFolding() {
entry:
  br label %exit
exit:
  ret i64 226
}

define i64 @constantPropagation() {
entry:
  br label %exit
exit:
  ret i64 -25457889
}

define i64 @deadCodeElimination() {
entry:
  br label %body0
body0:
  store i64 11, i64* @global1
  store i64 5, i64* @global1
  store i64 9, i64* @global1
  br label %exit
exit:
  ret i64 38
}

define i64 @sum(i64 %number) {
entry:
  br label %while.cond11
while.cond11:
  %_10 = icmp sgt i64 %number, 0
  br i1 %_10, label %while.body2, label %while.exit5
while.body2:
  %number2 = phi i64 [ %number, %while.cond11 ], [ %number14, %while.fillback4 ]
  %total3 = phi i64 [ 0, %while.cond11 ], [ %total12, %while.fillback4 ]
  %total12 = add i64 %total3, %number2
  %number14 = sub i64 %number2, 1
  br label %while.cond23
while.cond23:
  %_17 = icmp sgt i64 %number14, 0
  br i1 %_17, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %total4 = phi i64 [ 0, %while.cond11 ], [ %total12, %while.cond23 ]
  br label %exit
exit:
  ret i64 %total4
}

define i64 @doesntModifyGlobals() {
entry:
  br label %exit
exit:
  ret i64 3
}

define i64 @interProceduralOptimization() {
entry:
  br label %body0
body0:
  store i64 1, i64* @global1
  store i64 0, i64* @global2
  store i64 0, i64* @global3
  %a12 = call i64 (i64) @sum(i64 100)
  br label %if.cond1
if.cond1:
  %load_global14 = load i64, i64* @global1
  %_16 = icmp eq i64 %load_global14, 1
  br i1 %_16, label %then.body2, label %if.cond5
then.body2:
  %a19 = call i64 (i64) @sum(i64 10000)
  br label %then.exit3
then.exit3:
  br label %if.exit14
if.cond5:
  %load_global23 = load i64, i64* @global2
  %_25 = icmp eq i64 %load_global23, 2
  br i1 %_25, label %then.body6, label %if.exit8
then.body6:
  %a28 = call i64 (i64) @sum(i64 20000)
  br label %then.exit7
then.exit7:
  br label %if.exit8
if.exit8:
  %a1 = phi i64 [ %a12, %if.cond5 ], [ %a28, %then.exit7 ]
  br label %if.cond9
if.cond9:
  %load_global32 = load i64, i64* @global3
  %_34 = icmp eq i64 %load_global32, 3
  br i1 %_34, label %then.body10, label %if.exit12
then.body10:
  %a37 = call i64 (i64) @sum(i64 30000)
  br label %then.exit11
then.exit11:
  br label %if.exit12
if.exit12:
  %a2 = phi i64 [ %a1, %if.cond9 ], [ %a37, %then.exit11 ]
  br label %else.exit13
else.exit13:
  br label %if.exit14
if.exit14:
  %a0 = phi i64 [ %a19, %then.exit3 ], [ %a2, %else.exit13 ]
  br label %exit
exit:
  ret i64 %a0
}

define i64 @commonSubexpressionElimination() {
entry:
  br label %exit
exit:
  ret i64 -48796
}

define i64 @hoisting() {
entry:
  %h41 = alloca i64
  %h42 = load i64, i64* %h41
  %g43 = alloca i64
  %g44 = load i64, i64* %g43
  %e45 = alloca i64
  %e46 = load i64, i64* %e45
  br label %while.cond11
while.cond11:
  br label %while.body2
while.body2:
  %b0 = phi i64 [ 2, %while.cond11 ], [ %b0, %while.fillback4 ]
  %i2 = phi i64 [ 0, %while.cond11 ], [ %i33, %while.fillback4 ]
  %i33 = add i64 %i2, 1
  br label %while.cond23
while.cond23:
  %_36 = icmp slt i64 %i33, 1000000
  br i1 %_36, label %while.fillback4, label %exit
while.fillback4:
  br label %while.body2
exit:
  ret i64 %b0
}

define i64 @doubleIf() {
entry:
  br label %exit
exit:
  ret i64 50
}

define i64 @integerDivide() {
entry:
  br label %exit
exit:
  ret i64 736
}

define i64 @association() {
entry:
  br label %exit
exit:
  ret i64 10
}

define i64 @tailRecursionHelper(i64 %value, i64 %sum) {
entry:
  br label %if.cond1
if.cond1:
  %_6 = icmp eq i64 %value, 0
  br i1 %_6, label %then.body2, label %else.body3
then.body2:
  br label %exit
else.body3:
  %tmp.binop11 = sub i64 %value, 1
  %tmp.binop12 = add i64 %sum, %value
  %aufrufen_tailRecursionHelper13 = call i64 (i64, i64) @tailRecursionHelper(i64 %tmp.binop11, i64 %tmp.binop12)
  br label %exit
exit:
  %return_reg8 = phi i64 [ %sum, %then.body2 ], [ %aufrufen_tailRecursionHelper13, %else.body3 ]
  ret i64 %return_reg8
}

define i64 @tailRecursion(i64 %value) {
entry:
  br label %body0
body0:
  %aufrufen_tailRecursionHelper4 = call i64 (i64, i64) @tailRecursionHelper(i64 %value, i64 0)
  br label %exit
exit:
  ret i64 %aufrufen_tailRecursionHelper4
}

define i64 @unswitching() {
entry:
  br label %while.cond11
while.cond11:
  br label %while.body2
while.body2:
  %b0 = phi i64 [ 2, %while.cond11 ], [ %b0, %while.fillback10 ]
  %a4 = phi i64 [ 1, %while.cond11 ], [ %a2, %while.fillback10 ]
  br label %if.cond3
if.cond3:
  %_15 = icmp eq i64 %b0, 2
  br i1 %_15, label %then.body4, label %else.body6
then.body4:
  %a18 = add i64 %a4, 1
  br label %then.exit5
then.exit5:
  br label %if.exit8
else.body6:
  %a22 = add i64 %a4, 2
  br label %else.exit7
else.exit7:
  br label %if.exit8
if.exit8:
  %a2 = phi i64 [ %a18, %then.exit5 ], [ %a22, %else.exit7 ]
  br label %while.cond29
while.cond29:
  %_27 = icmp slt i64 %a2, 1000000
  br i1 %_27, label %while.fillback10, label %exit
while.fillback10:
  br label %while.body2
exit:
  ret i64 %a2
}

define i64 @randomCalculation(i64 %number) {
entry:
  %b50 = alloca i64
  %b51 = load i64, i64* %b50
  %a52 = alloca i64
  %a53 = load i64, i64* %a52
  %c54 = alloca i64
  %c55 = load i64, i64* %c54
  %d56 = alloca i64
  %d57 = load i64, i64* %d56
  %e58 = alloca i64
  %e59 = load i64, i64* %e58
  br label %while.cond11
while.cond11:
  %_22 = icmp slt i64 0, %number
  br i1 %_22, label %while.body2, label %while.exit5
while.body2:
  %i3 = phi i64 [ 0, %while.cond11 ], [ %i43, %while.fillback4 ]
  %sum5 = phi i64 [ 0, %while.cond11 ], [ %sum29, %while.fillback4 ]
  %number7 = phi i64 [ %number, %while.cond11 ], [ %number7, %while.fillback4 ]
  %sum29 = add i64 %sum5, 19
  %i31 = mul i64 %i3, 2
  %i33 = sdiv i64 %i31, 2
  %i35 = mul i64 3, %i33
  %i37 = sdiv i64 %i35, 3
  %i39 = mul i64 %i37, 4
  %i41 = sdiv i64 %i39, 4
  %i43 = add i64 %i41, 1
  br label %while.cond23
while.cond23:
  %_45 = icmp slt i64 %i43, %number7
  br i1 %_45, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %sum6 = phi i64 [ 0, %while.cond11 ], [ %sum29, %while.cond23 ]
  br label %exit
exit:
  ret i64 %sum6
}

define i64 @iterativeFibonacci(i64 %number) {
entry:
  %sum29 = alloca i64
  %sum30 = load i64, i64* %sum29
  br label %while.cond11
while.cond11:
  %_18 = icmp slt i64 0, %number
  br i1 %_18, label %while.body2, label %while.exit5
while.body2:
  %previous1 = phi i64 [ 1, %while.cond11 ], [ %result20, %while.fillback4 ]
  %number3 = phi i64 [ %number, %while.cond11 ], [ %number3, %while.fillback4 ]
  %i5 = phi i64 [ 0, %while.cond11 ], [ %i22, %while.fillback4 ]
  %previous7 = phi i64 [ -1, %while.cond11 ], [ %previous1, %while.fillback4 ]
  %result20 = add i64 %previous1, %previous7
  %i22 = add i64 %i5, 1
  br label %while.cond23
while.cond23:
  %_24 = icmp slt i64 %i22, %number3
  br i1 %_24, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %result2 = phi i64 [ 1, %while.cond11 ], [ %result20, %while.cond23 ]
  br label %exit
exit:
  ret i64 %result2
}

define i64 @recursiveFibonacci(i64 %number) {
entry:
  br label %if.cond1
if.cond1:
  %tmp.binop5 = icmp sle i64 %number, 0
  %tmp.binop7 = icmp eq i64 %number, 1
  %_8 = or i1 %tmp.binop5, %tmp.binop7
  br i1 %_8, label %then.body2, label %else.body3
then.body2:
  br label %exit
else.body3:
  %tmp.binop13 = sub i64 %number, 1
  %aufrufen_recursiveFibonacci14 = call i64 (i64) @recursiveFibonacci(i64 %tmp.binop13)
  %tmp.binop16 = sub i64 %number, 2
  %aufrufen_recursiveFibonacci17 = call i64 (i64) @recursiveFibonacci(i64 %tmp.binop16)
  %tmp.binop18 = add i64 %aufrufen_recursiveFibonacci14, %aufrufen_recursiveFibonacci17
  br label %exit
exit:
  %return_reg10 = phi i64 [ %number, %then.body2 ], [ %tmp.binop18, %else.body3 ]
  ret i64 %return_reg10
}

define i64 @main() {
entry:
  %return_reg6 = alloca i64
  %_7 = load i64, i64* %return_reg6
  %result76 = alloca i64
  %result77 = load i64, i64* %result76
  br label %body0
body0:
  %_8 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_9 = call i32 (i8*, ...) @scanf(i8* %_8, i32* @.read_scratch)
  %_10 = load i32, i32* @.read_scratch
  %input11 = sext i32 %_10 to i64
  br label %while.cond11
while.cond11:
  %_14 = icmp slt i64 1, %input11
  br i1 %_14, label %while.body2, label %while.exit5
while.body2:
  %input2 = phi i64 [ %input11, %while.cond11 ], [ %input2, %while.fillback4 ]
  %i4 = phi i64 [ 1, %while.cond11 ], [ %i65, %while.fillback4 ]
  %result16 = call i64 () @constantFolding()
  %_17 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_18 = call i32 (i8*, ...) @printf(i8* %_17, i64 %result16)
  %result19 = call i64 () @constantPropagation()
  %_20 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_21 = call i32 (i8*, ...) @printf(i8* %_20, i64 %result19)
  %result22 = call i64 () @deadCodeElimination()
  %_23 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_24 = call i32 (i8*, ...) @printf(i8* %_23, i64 %result22)
  %result25 = call i64 () @interProceduralOptimization()
  %_26 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_27 = call i32 (i8*, ...) @printf(i8* %_26, i64 %result25)
  %result28 = call i64 () @commonSubexpressionElimination()
  %_29 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_30 = call i32 (i8*, ...) @printf(i8* %_29, i64 %result28)
  %result31 = call i64 () @hoisting()
  %_32 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_33 = call i32 (i8*, ...) @printf(i8* %_32, i64 %result31)
  %result34 = call i64 () @doubleIf()
  %_35 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_36 = call i32 (i8*, ...) @printf(i8* %_35, i64 %result34)
  %result37 = call i64 () @integerDivide()
  %_38 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_39 = call i32 (i8*, ...) @printf(i8* %_38, i64 %result37)
  %result40 = call i64 () @association()
  %_41 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_42 = call i32 (i8*, ...) @printf(i8* %_41, i64 %result40)
  %tmp.binop44 = sdiv i64 %input2, 1000
  %result45 = call i64 (i64) @tailRecursion(i64 %tmp.binop44)
  %_46 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_47 = call i32 (i8*, ...) @printf(i8* %_46, i64 %result45)
  %result48 = call i64 () @unswitching()
  %_49 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_50 = call i32 (i8*, ...) @printf(i8* %_49, i64 %result48)
  %result51 = call i64 (i64) @randomCalculation(i64 %input2)
  %_52 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_53 = call i32 (i8*, ...) @printf(i8* %_52, i64 %result51)
  %tmp.binop55 = sdiv i64 %input2, 5
  %result56 = call i64 (i64) @iterativeFibonacci(i64 %tmp.binop55)
  %_57 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_58 = call i32 (i8*, ...) @printf(i8* %_57, i64 %result56)
  %tmp.binop60 = sdiv i64 %input2, 1000
  %result61 = call i64 (i64) @recursiveFibonacci(i64 %tmp.binop60)
  %_62 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_63 = call i32 (i8*, ...) @printf(i8* %_62, i64 %result61)
  %i65 = add i64 %i4, 1
  br label %while.cond23
while.cond23:
  %_67 = icmp slt i64 %i65, %input2
  br i1 %_67, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %_71 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_72 = call i32 (i8*, ...) @printf(i8* %_71, i64 9999)
  br label %exit
exit:
  ret i64 0
}

