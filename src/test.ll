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
  %_0 = alloca i64
  %square1 = alloca i64
  %delta2 = alloca i64
  %a3 = alloca i64
  %a4 = alloca i64
  store i64 %a, i64* %a4
  br label %body1
body1:
  store i64 1, i64* %square1
  store i64 3, i64* %delta2
  %square9 = load i64, i64* %square1
  %a10 = load i64, i64* %a3
  %_11 = icmp sle i64 %square9, %a10
  br i1 %_11, label %while.body2, label %while.end3
while.body2:
  %square12 = load i64, i64* %square1
  %delta13 = load i64, i64* %delta2
  %_14 = add i64 %square12, %delta13
  store i64 %_14, i64* %square1
  %delta16 = load i64, i64* %delta2
  %delta17 = add i64 %delta16, 2
  store i64 %delta17, i64* %delta2
  %square19 = load i64, i64* %square1
  %a20 = load i64, i64* %a3
  %_21 = icmp sle i64 %square19, %a20
  br i1 %_21, label %while.body2, label %while.end3
while.end3:
  %delta24 = load i64, i64* %delta2
  %delta25 = sdiv i64 %delta24, 2
  %delta26 = sub i64 %delta25, 1
  store i64 %delta26, i64* %_0
  br label %exit
exit:
  %_29 = load i64, i64* %_0
  ret i64 %_29
}

define i1 @prime(i64 %a) {
entry:
  %_0 = alloca i1
  %max1 = alloca i64
  %divisor2 = alloca i64
  %remainder3 = alloca i64
  %limit4 = alloca i64
  %a5 = alloca i64
  store i64 %a, i64* %a5
  br label %body1
body1:
  %a8 = load i64, i64* %a5
  %a9 = icmp slt i64 %a8, 2
  br i1 %a9, label %if.then2, label %if.else3
if.then2:
  store i1 0, i1* %_0
  br label %exit
if.else3:
  %a12 = load i64, i64* %a5
  %isqrt13 = call i64 (i64) @isqrt(i64 %a12)
  store i64 %isqrt13, i64* %max1
  store i64 2, i64* %divisor2
  %divisor16 = load i64, i64* %divisor2
  %max17 = load i64, i64* %max1
  %_18 = icmp sle i64 %divisor16, %max17
  br i1 %_18, label %while.body4, label %while.end7
while.body4:
  %a19 = load i64, i64* %a5
  %a20 = load i64, i64* %a5
  %divisor21 = load i64, i64* %divisor2
  %_22 = sdiv i64 %a20, %divisor21
  %divisor23 = load i64, i64* %divisor2
  %divisor24 = mul i64 %_22, %divisor23
  %_25 = sub i64 %a19, %divisor24
  store i64 %_25, i64* %remainder3
  %remainder27 = load i64, i64* %remainder3
  %remainder28 = icmp eq i64 %remainder27, 0
  br i1 %remainder28, label %if.then5, label %if.end6
if.then5:
  store i1 0, i1* %_0
  br label %exit
if.end6:
  %divisor32 = load i64, i64* %divisor2
  %divisor33 = add i64 %divisor32, 1
  store i64 %divisor33, i64* %divisor2
  %divisor35 = load i64, i64* %divisor2
  %max36 = load i64, i64* %max1
  %_37 = icmp sle i64 %divisor35, %max36
  br i1 %_37, label %while.body4, label %while.end7
while.end7:
  store i1 1, i1* %_0
  br label %exit
if.end8:
  br label %exit
exit:
  %_44 = load i1, i1* %_0
  ret i1 %_44
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %limit1 = alloca i64
  %a2 = alloca i64
  br label %body1
body1:
  %_4 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_5 = call i32 (i8*, ...) @scanf(i8* %_4, i32* @.read_scratch)
  %_6 = load i32, i32* @.read_scratch
  %_7 = sext i32 %_6 to i64
  store i64 %_7, i64* %limit1
  store i64 0, i64* %a2
  %a10 = load i64, i64* %a2
  %limit11 = load i64, i64* %limit1
  %_12 = icmp sle i64 %a10, %limit11
  br i1 %_12, label %while.body2, label %while.end5
while.body2:
  %a13 = load i64, i64* %a2
  %prime14 = call i1 (i64) @prime(i64 %a13)
  br i1 %prime14, label %if.then3, label %if.end4
if.then3:
  %a15 = load i64, i64* %a2
  %_16 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_17 = call i32 (i8*, ...) @printf(i8* %_16, i64 %a15)
  br label %if.end4
if.end4:
  %a20 = load i64, i64* %a2
  %a21 = add i64 %a20, 1
  store i64 %a21, i64* %a2
  %a23 = load i64, i64* %a2
  %limit24 = load i64, i64* %limit1
  %_25 = icmp sle i64 %a23, %limit24
  br i1 %_25, label %while.body2, label %while.end5
while.end5:
  store i64 0, i64* %_0
  br label %exit
exit:
  %_30 = load i64, i64* %_0
  ret i64 %_30
}


