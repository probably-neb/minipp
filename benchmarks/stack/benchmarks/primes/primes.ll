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
  store i64 %a, i64* %a3
  br label %body1
body1:
  store i64 1, i64* %square1
  store i64 3, i64* %delta2
  %square8 = load i64, i64* %square1
  %a9 = load i64, i64* %a3
  %_10 = icmp sle i64 %square8, %a9
  br i1 %_10, label %while.body2, label %while.end3
while.body2:
  %square11 = load i64, i64* %square1
  %delta12 = load i64, i64* %delta2
  %_13 = add i64 %square11, %delta12
  store i64 %_13, i64* %square1
  %delta15 = load i64, i64* %delta2
  %delta16 = add i64 %delta15, 2
  store i64 %delta16, i64* %delta2
  %square18 = load i64, i64* %square1
  %a19 = load i64, i64* %a3
  %_20 = icmp sle i64 %square18, %a19
  br i1 %_20, label %while.body2, label %while.end3
while.end3:
  %delta23 = load i64, i64* %delta2
  %delta24 = sdiv i64 %delta23, 2
  %delta25 = sub i64 %delta24, 1
  store i64 %delta25, i64* %_0
  br label %exit
exit:
  %_28 = load i64, i64* %_0
  ret i64 %_28
}

define i1 @prime(i64 %a) {
entry:
  %_0 = alloca i1
  %max1 = alloca i64
  %divisor2 = alloca i64
  %remainder3 = alloca i64
  %a4 = alloca i64
  store i64 %a, i64* %a4
  br label %body1
body1:
  %a7 = load i64, i64* %a4
  %a8 = icmp slt i64 %a7, 2
  br i1 %a8, label %if.then2, label %if.else3
if.then2:
  store i1 0, i1* %_0
  br label %exit
if.else3:
  %a11 = load i64, i64* %a4
  %isqrt12 = call i64 (i64) @isqrt(i64 %a11)
  store i64 %isqrt12, i64* %max1
  store i64 2, i64* %divisor2
  %divisor15 = load i64, i64* %divisor2
  %max16 = load i64, i64* %max1
  %_17 = icmp sle i64 %divisor15, %max16
  br i1 %_17, label %while.body4, label %while.end7
while.body4:
  %a18 = load i64, i64* %a4
  %a19 = load i64, i64* %a4
  %divisor20 = load i64, i64* %divisor2
  %_21 = sdiv i64 %a19, %divisor20
  %divisor22 = load i64, i64* %divisor2
  %divisor23 = mul i64 %_21, %divisor22
  %_24 = sub i64 %a18, %divisor23
  store i64 %_24, i64* %remainder3
  %remainder26 = load i64, i64* %remainder3
  %remainder27 = icmp eq i64 %remainder26, 0
  br i1 %remainder27, label %if.then5, label %if.end6
if.then5:
  store i1 0, i1* %_0
  br label %exit
if.end6:
  %divisor31 = load i64, i64* %divisor2
  %divisor32 = add i64 %divisor31, 1
  store i64 %divisor32, i64* %divisor2
  %divisor34 = load i64, i64* %divisor2
  %max35 = load i64, i64* %max1
  %_36 = icmp sle i64 %divisor34, %max35
  br i1 %_36, label %while.body4, label %while.end7
while.end7:
  store i1 1, i1* %_0
  br label %exit
if.end8:
  br label %exit
exit:
  %_43 = load i1, i1* %_0
  ret i1 %_43
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

