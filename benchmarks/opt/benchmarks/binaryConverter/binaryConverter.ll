declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

define i64 @wait(i64 %waitTime) {
entry:
  br label %while.cond11
while.cond11:
  %_7 = icmp sgt i64 %waitTime, 0
  br i1 %_7, label %while.body2, label %while.exit5
while.body2:
  %waitTime2 = phi i64 [ %waitTime, %while.cond11 ], [ %waitTime10, %while.fillback4 ]
  %waitTime10 = sub i64 %waitTime2, 1
  br label %while.cond23
while.cond23:
  %_13 = icmp sgt i64 %waitTime10, 0
  br i1 %_13, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  br label %exit
exit:
  ret i64 0
}

define i64 @power(i64 %base, i64 %exponent) {
entry:
  br label %while.cond11
while.cond11:
  %_13 = icmp sgt i64 %exponent, 0
  br i1 %_13, label %while.body2, label %while.exit5
while.body2:
  %product2 = phi i64 [ 1, %while.cond11 ], [ %product15, %while.fillback4 ]
  %exponent5 = phi i64 [ %exponent, %while.cond11 ], [ %exponent17, %while.fillback4 ]
  %base6 = phi i64 [ %base, %while.cond11 ], [ %base6, %while.fillback4 ]
  %product15 = mul i64 %product2, %base6
  %exponent17 = sub i64 %exponent5, 1
  br label %while.cond23
while.cond23:
  %_20 = icmp sgt i64 %exponent17, 0
  br i1 %_20, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %product3 = phi i64 [ 1, %while.cond11 ], [ %product15, %while.cond23 ]
  br label %exit
exit:
  ret i64 %product3
}

define i64 @recursiveDecimalSum(i64 %binaryNum, i64 %decimalSum, i64 %recursiveDepth) {
entry:
  br label %if.cond1
if.cond1:
  %_11 = icmp sgt i64 %binaryNum, 0
  br i1 %_11, label %then.body2, label %if.exit7
then.body2:
  %tempNum15 = sdiv i64 %binaryNum, 10
  %tempNum17 = mul i64 %tempNum15, 10
  %tempNum18 = sub i64 %binaryNum, %tempNum17
  br label %if.cond3
if.cond3:
  %_21 = icmp eq i64 %tempNum18, 1
  br i1 %_21, label %then.body4, label %if.exit6
then.body4:
  %aufrufen_power23 = call i64 (i64, i64) @power(i64 2, i64 %recursiveDepth)
  %tmp.binop24 = add i64 %decimalSum, %aufrufen_power23
  br label %then.exit5
then.exit5:
  br label %if.exit6
if.exit6:
  %decimalSum4 = phi i64 [ %decimalSum, %if.cond3 ], [ %tmp.binop24, %then.exit5 ]
  %tmp.binop28 = sdiv i64 %binaryNum, 10
  %tmp.binop30 = add i64 %recursiveDepth, 1
  %aufrufen_recursiveDecimalSum31 = call i64 (i64, i64, i64) @recursiveDecimalSum(i64 %tmp.binop28, i64 %decimalSum4, i64 %tmp.binop30)
  br label %exit
if.exit7:
  br label %exit
exit:
  %return_reg32 = phi i64 [ %aufrufen_recursiveDecimalSum31, %if.exit6 ], [ %decimalSum, %if.exit7 ]
  ret i64 %return_reg32
}

define i64 @convertToDecimal(i64 %binaryNum) {
entry:
  %return_reg1 = alloca i64
  %_2 = load i64, i64* %return_reg1
  br label %body0
body0:
  %aufrufen_recursiveDecimalSum5 = call i64 (i64, i64, i64) @recursiveDecimalSum(i64 %binaryNum, i64 0, i64 0)
  br label %exit
exit:
  ret i64 %aufrufen_recursiveDecimalSum5
}

define i64 @main() {
entry:
  %return_reg2 = alloca i64
  %_3 = load i64, i64* %return_reg2
  br label %body0
body0:
  %_4 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_5 = call i32 (i8*, ...) @scanf(i8* %_4, i32* @.read_scratch)
  %_6 = load i32, i32* @.read_scratch
  %number7 = sext i32 %_6 to i64
  %number8 = call i64 (i64) @convertToDecimal(i64 %number7)
  %waitTime9 = mul i64 %number8, %number8
  br label %while.cond11
while.cond11:
  %_12 = icmp sgt i64 %waitTime9, 0
  br i1 %_12, label %while.body2, label %while.exit5
while.body2:
  %waitTime0 = phi i64 [ %waitTime9, %while.cond11 ], [ %waitTime16, %while.fillback4 ]
  %aufrufen_wait14 = call i64 (i64) @wait(i64 %waitTime0)
  %waitTime16 = sub i64 %waitTime0, 1
  br label %while.cond23
while.cond23:
  %_19 = icmp sgt i64 %waitTime16, 0
  br i1 %_19, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %_22 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_23 = call i32 (i8*, ...) @printf(i8* %_22, i64 %number8)
  br label %exit
exit:
  ret i64 0
}

