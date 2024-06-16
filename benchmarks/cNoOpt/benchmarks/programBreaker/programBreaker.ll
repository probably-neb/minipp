declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

@GLOBAL = global i64 undef, align 8
@count = global i64 undef, align 8

define i64 @fun2(i64 %x, i64 %y) {
entry:
  %_0 = alloca i64
  %x1 = alloca i64
  store i64 %x, i64* %x1
  %y3 = alloca i64
  store i64 %y, i64* %y3
  br label %body1
body1:
  %x6 = load i64, i64* %x1
  %x7 = icmp eq i64 %x6, 0
  br i1 %x7, label %if.then2, label %if.else3
if.then2:
  %y8 = load i64, i64* %y3
  store i64 %y8, i64* %_0
  br label %exit
if.else3:
  %x11 = load i64, i64* %x1
  %x12 = sub i64 %x11, 1
  %y13 = load i64, i64* %y3
  %fun214 = call i64 (i64, i64) @fun2(i64 %x12, i64 %y13)
  store i64 %fun214, i64* %_0
  br label %exit
if.end4:
  br label %exit
exit:
  %_19 = load i64, i64* %_0
  ret i64 %_19
}

define i64 @fun1(i64 %x, i64 %y, i64 %z) {
entry:
  %_0 = alloca i64
  %retVal1 = alloca i64
  %x2 = alloca i64
  store i64 %x, i64* %x2
  %y4 = alloca i64
  store i64 %y, i64* %y4
  %z6 = alloca i64
  store i64 %z, i64* %z6
  br label %body1
body1:
  %_9 = add i64 5, 6
  %x10 = load i64, i64* %x2
  %x11 = mul i64 %x10, 2
  %x12 = sub i64 %_9, %x11
  %y13 = load i64, i64* %y4
  %y14 = sdiv i64 4, %y13
  %_15 = add i64 %x12, %y14
  %z16 = load i64, i64* %z6
  %z17 = add i64 %_15, %z16
  store i64 %z17, i64* %retVal1
  %retVal19 = load i64, i64* %retVal1
  %y20 = load i64, i64* %y4
  %_21 = icmp sgt i64 %retVal19, %y20
  br i1 %_21, label %if.then2, label %if.else3
if.then2:
  %retVal22 = load i64, i64* %retVal1
  %x23 = load i64, i64* %x2
  %fun224 = call i64 (i64, i64) @fun2(i64 %retVal22, i64 %x23)
  store i64 %fun224, i64* %_0
  br label %exit
if.else3:
  %_27 = icmp slt i64 5, 6
  %retVal28 = load i64, i64* %retVal1
  %y29 = load i64, i64* %y4
  %_30 = icmp sle i64 %retVal28, %y29
  %_31 = and i1 %_27, %_30
  br i1 %_31, label %if.then4, label %if.end5
if.then4:
  %retVal32 = load i64, i64* %retVal1
  %y33 = load i64, i64* %y4
  %fun234 = call i64 (i64, i64) @fun2(i64 %retVal32, i64 %y33)
  store i64 %fun234, i64* %_0
  br label %exit
if.end5:
  br label %if.end6
if.end6:
  %retVal40 = load i64, i64* %retVal1
  store i64 %retVal40, i64* %_0
  br label %exit
exit:
  %_43 = load i64, i64* %_0
  ret i64 %_43
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %i1 = alloca i64
  br label %body1
body1:
  store i64 0, i64* %i1
  %_4 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_5 = call i32 (i8*, ...) @scanf(i8* %_4, i32* @.read_scratch)
  %_6 = load i32, i32* @.read_scratch
  %_7 = sext i32 %_6 to i64
  store i64 %_7, i64* %i1
  %i9 = load i64, i64* %i1
  %i10 = icmp slt i64 %i9, 10000
  br i1 %i10, label %while.body2, label %while.end3
while.body2:
  %i11 = load i64, i64* %i1
  %fun112 = call i64 (i64, i64, i64) @fun1(i64 3, i64 %i11, i64 5)
  %_13 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_14 = call i32 (i8*, ...) @printf(i8* %_13, i64 %fun112)
  %i15 = load i64, i64* %i1
  %i16 = add i64 %i15, 1
  store i64 %i16, i64* %i1
  %i18 = load i64, i64* %i1
  %i19 = icmp slt i64 %i18, 10000
  br i1 %i19, label %while.body2, label %while.end3
while.end3:
  store i64 0, i64* %_0
  br label %exit
exit:
  %_24 = load i64, i64* %_0
  ret i64 %_24
}

