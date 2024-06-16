declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

define i64 @isqrt(i64 %a) {
entry:
  br label %while.cond11
while.cond11:
  %_12 = icmp sle i64 1, %a
  br i1 %_12, label %while.body2, label %while.exit5
while.body2:
  %a1 = phi i64 [ %a, %while.cond11 ], [ %a1, %while.fillback4 ]
  %square3 = phi i64 [ 1, %while.cond11 ], [ %square14, %while.fillback4 ]
  %delta5 = phi i64 [ 3, %while.cond11 ], [ %delta16, %while.fillback4 ]
  %square14 = add i64 %square3, %delta5
  %delta16 = add i64 %delta5, 2
  br label %while.cond23
while.cond23:
  %_18 = icmp sle i64 %square14, %a1
  br i1 %_18, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %delta6 = phi i64 [ 3, %while.cond11 ], [ %delta16, %while.cond23 ]
  %tmp.binop22 = sdiv i64 %delta6, 2
  %tmp.binop24 = sub i64 %tmp.binop22, 1
  br label %exit
exit:
  ret i64 %tmp.binop24
}

define i1 @prime(i64 %a) {
entry:
  %remainder44 = alloca i64
  %remainder45 = load i64, i64* %remainder44
  br label %if.cond1
if.cond1:
  %_17 = icmp slt i64 %a, 2
  br i1 %_17, label %then.body2, label %else.body3
then.body2:
  br label %exit
else.body3:
  %max22 = call i64 (i64) @isqrt(i64 %a)
  br label %while.cond14
while.cond14:
  %_25 = icmp sle i64 2, %max22
  br i1 %_25, label %while.body5, label %while.exit11
while.body5:
  %max2 = phi i64 [ %max22, %while.cond14 ], [ %max2, %while.fillback10 ]
  %a4 = phi i64 [ %a, %while.cond14 ], [ %a4, %while.fillback10 ]
  %divisor8 = phi i64 [ 2, %while.cond14 ], [ %divisor37, %while.fillback10 ]
  %tmp.binop27 = sdiv i64 %a4, %divisor8
  %tmp.binop28 = mul i64 %tmp.binop27, %divisor8
  %remainder29 = sub i64 %a4, %tmp.binop28
  br label %if.cond6
if.cond6:
  %_32 = icmp eq i64 %remainder29, 0
  br i1 %_32, label %then.body7, label %if.exit8
then.body7:
  br label %exit
if.exit8:
  %divisor37 = add i64 %divisor8, 1
  br label %while.cond29
while.cond29:
  %_39 = icmp sle i64 %divisor37, %max2
  br i1 %_39, label %while.fillback10, label %while.exit11
while.fillback10:
  br label %while.body5
while.exit11:
  br label %exit
exit:
  %return_reg20 = phi i1 [ 0, %then.body2 ], [ 0, %then.body7 ], [ 1, %while.exit11 ]
  ret i1 %return_reg20
}

define i64 @main() {
entry:
  br label %body0
body0:
  %_6 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_7 = call i32 (i8*, ...) @scanf(i8* %_6, i32* @.read_scratch)
  %_8 = load i32, i32* @.read_scratch
  %limit9 = sext i32 %_8 to i64
  br label %while.cond11
while.cond11:
  %_12 = icmp sle i64 0, %limit9
  br i1 %_12, label %while.body2, label %while.exit9
while.body2:
  %limit0 = phi i64 [ %limit9, %while.cond11 ], [ %limit0, %while.fillback8 ]
  %a2 = phi i64 [ 0, %while.cond11 ], [ %a22, %while.fillback8 ]
  br label %if.cond3
if.cond3:
  %_15 = call i1 (i64) @prime(i64 %a2)
  br i1 %_15, label %then.body4, label %if.exit6
then.body4:
  %_17 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_18 = call i32 (i8*, ...) @printf(i8* %_17, i64 %a2)
  br label %if.exit6
if.exit6:
  %a22 = add i64 %a2, 1
  br label %while.cond27
while.cond27:
  %_24 = icmp sle i64 %a22, %limit0
  br i1 %_24, label %while.fillback8, label %while.exit9
while.fillback8:
  br label %while.body2
while.exit9:
  br label %exit
exit:
  ret i64 0
}

