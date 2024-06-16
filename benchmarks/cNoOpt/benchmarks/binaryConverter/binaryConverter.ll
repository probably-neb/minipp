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
  %_0 = alloca i64
  %waitTime1 = alloca i64
  store i64 %waitTime, i64* %waitTime1
  br label %body1
body1:
  %waitTime4 = load i64, i64* %waitTime1
  %waitTime5 = icmp sgt i64 %waitTime4, 0
  br i1 %waitTime5, label %while.body2, label %while.end3
while.body2:
  %waitTime6 = load i64, i64* %waitTime1
  %waitTime7 = sub i64 %waitTime6, 1
  store i64 %waitTime7, i64* %waitTime1
  %waitTime9 = load i64, i64* %waitTime1
  %waitTime10 = icmp sgt i64 %waitTime9, 0
  br i1 %waitTime10, label %while.body2, label %while.end3
while.end3:
  store i64 0, i64* %_0
  br label %exit
exit:
  %_15 = load i64, i64* %_0
  ret i64 %_15
}

define i64 @power(i64 %base, i64 %exponent) {
entry:
  %_0 = alloca i64
  %product1 = alloca i64
  %base2 = alloca i64
  store i64 %base, i64* %base2
  %exponent4 = alloca i64
  store i64 %exponent, i64* %exponent4
  br label %body1
body1:
  store i64 1, i64* %product1
  %exponent8 = load i64, i64* %exponent4
  %exponent9 = icmp sgt i64 %exponent8, 0
  br i1 %exponent9, label %while.body2, label %while.end3
while.body2:
  %product10 = load i64, i64* %product1
  %base11 = load i64, i64* %base2
  %_12 = mul i64 %product10, %base11
  store i64 %_12, i64* %product1
  %exponent14 = load i64, i64* %exponent4
  %exponent15 = sub i64 %exponent14, 1
  store i64 %exponent15, i64* %exponent4
  %exponent17 = load i64, i64* %exponent4
  %exponent18 = icmp sgt i64 %exponent17, 0
  br i1 %exponent18, label %while.body2, label %while.end3
while.end3:
  %product21 = load i64, i64* %product1
  store i64 %product21, i64* %_0
  br label %exit
exit:
  %_24 = load i64, i64* %_0
  ret i64 %_24
}

define i64 @recursiveDecimalSum(i64 %binaryNum, i64 %decimalSum, i64 %recursiveDepth) {
entry:
  %_0 = alloca i64
  %tempNum1 = alloca i64
  %base2 = alloca i64
  %remainder3 = alloca i64
  %binaryNum4 = alloca i64
  store i64 %binaryNum, i64* %binaryNum4
  %decimalSum6 = alloca i64
  store i64 %decimalSum, i64* %decimalSum6
  %recursiveDepth8 = alloca i64
  store i64 %recursiveDepth, i64* %recursiveDepth8
  br label %body1
body1:
  %binaryNum11 = load i64, i64* %binaryNum4
  %binaryNum12 = icmp sgt i64 %binaryNum11, 0
  br i1 %binaryNum12, label %if.then2, label %if.end5
if.then2:
  store i64 2, i64* %base2
  %binaryNum14 = load i64, i64* %binaryNum4
  %binaryNum15 = sdiv i64 %binaryNum14, 10
  store i64 %binaryNum15, i64* %tempNum1
  %tempNum17 = load i64, i64* %tempNum1
  %tempNum18 = mul i64 %tempNum17, 10
  store i64 %tempNum18, i64* %tempNum1
  %binaryNum20 = load i64, i64* %binaryNum4
  %tempNum21 = load i64, i64* %tempNum1
  %_22 = sub i64 %binaryNum20, %tempNum21
  store i64 %_22, i64* %tempNum1
  %tempNum24 = load i64, i64* %tempNum1
  %tempNum25 = icmp eq i64 %tempNum24, 1
  br i1 %tempNum25, label %if.then3, label %if.end4
if.then3:
  %decimalSum26 = load i64, i64* %decimalSum6
  %base27 = load i64, i64* %base2
  %recursiveDepth28 = load i64, i64* %recursiveDepth8
  %power29 = call i64 (i64, i64) @power(i64 %base27, i64 %recursiveDepth28)
  %_30 = add i64 %decimalSum26, %power29
  store i64 %_30, i64* %decimalSum6
  br label %if.end4
if.end4:
  %binaryNum34 = load i64, i64* %binaryNum4
  %binaryNum35 = sdiv i64 %binaryNum34, 10
  %decimalSum36 = load i64, i64* %decimalSum6
  %recursiveDepth37 = load i64, i64* %recursiveDepth8
  %recursiveDepth38 = add i64 %recursiveDepth37, 1
  %recursiveDecimalSum39 = call i64 (i64, i64, i64) @recursiveDecimalSum(i64 %binaryNum35, i64 %decimalSum36, i64 %recursiveDepth38)
  store i64 %recursiveDecimalSum39, i64* %_0
  br label %exit
if.end5:
  %decimalSum43 = load i64, i64* %decimalSum6
  store i64 %decimalSum43, i64* %_0
  br label %exit
exit:
  %_46 = load i64, i64* %_0
  ret i64 %_46
}

define i64 @convertToDecimal(i64 %binaryNum) {
entry:
  %_0 = alloca i64
  %recursiveDepth1 = alloca i64
  %decimalSum2 = alloca i64
  %binaryNum3 = alloca i64
  store i64 %binaryNum, i64* %binaryNum3
  br label %body1
body1:
  store i64 0, i64* %recursiveDepth1
  store i64 0, i64* %decimalSum2
  %binaryNum8 = load i64, i64* %binaryNum3
  %decimalSum9 = load i64, i64* %decimalSum2
  %recursiveDepth10 = load i64, i64* %recursiveDepth1
  %recursiveDecimalSum11 = call i64 (i64, i64, i64) @recursiveDecimalSum(i64 %binaryNum8, i64 %decimalSum9, i64 %recursiveDepth10)
  store i64 %recursiveDecimalSum11, i64* %_0
  br label %exit
exit:
  %_14 = load i64, i64* %_0
  ret i64 %_14
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %number1 = alloca i64
  %waitTime2 = alloca i64
  br label %body1
body1:
  %_4 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_5 = call i32 (i8*, ...) @scanf(i8* %_4, i32* @.read_scratch)
  %_6 = load i32, i32* @.read_scratch
  %_7 = sext i32 %_6 to i64
  store i64 %_7, i64* %number1
  %number9 = load i64, i64* %number1
  %convertToDecimal10 = call i64 (i64) @convertToDecimal(i64 %number9)
  store i64 %convertToDecimal10, i64* %number1
  %number12 = load i64, i64* %number1
  %number13 = load i64, i64* %number1
  %_14 = mul i64 %number12, %number13
  store i64 %_14, i64* %waitTime2
  %waitTime16 = load i64, i64* %waitTime2
  %waitTime17 = icmp sgt i64 %waitTime16, 0
  br i1 %waitTime17, label %while.body2, label %while.end3
while.body2:
  %waitTime18 = load i64, i64* %waitTime2
  %wait19 = call i64 (i64) @wait(i64 %waitTime18)
  %waitTime20 = load i64, i64* %waitTime2
  %waitTime21 = sub i64 %waitTime20, 1
  store i64 %waitTime21, i64* %waitTime2
  %waitTime23 = load i64, i64* %waitTime2
  %waitTime24 = icmp sgt i64 %waitTime23, 0
  br i1 %waitTime24, label %while.body2, label %while.end3
while.end3:
  %number27 = load i64, i64* %number1
  %_28 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_29 = call i32 (i8*, ...) @printf(i8* %_28, i64 %number27)
  store i64 0, i64* %_0
  br label %exit
exit:
  %_32 = load i64, i64* %_0
  ret i64 %_32
}

