declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

define i64 @mod(i64 %a, i64 %b) {
entry:
  %_0 = alloca i64
  %a1 = alloca i64
  store i64 %a, i64* %a1
  %b3 = alloca i64
  store i64 %b, i64* %b3
  br label %body1
body1:
  %a6 = load i64, i64* %a1
  %a7 = load i64, i64* %a1
  %b8 = load i64, i64* %b3
  %_9 = sdiv i64 %a7, %b8
  %b10 = load i64, i64* %b3
  %b11 = mul i64 %_9, %b10
  %_12 = sub i64 %a6, %b11
  store i64 %_12, i64* %_0
  br label %exit
exit:
  %_15 = load i64, i64* %_0
  ret i64 %_15
}

define void @hailstone(i64 %n) {
entry:
  %n0 = alloca i64
  store i64 %n, i64* %n0
  br label %body1
body1:
  br i1 1, label %while.body2, label %while.end8
while.body2:
  %n3 = load i64, i64* %n0
  %_4 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_5 = call i32 (i8*, ...) @printf(i8* %_4, i64 %n3)
  %n6 = load i64, i64* %n0
  %mod7 = call i64 (i64, i64) @mod(i64 %n6, i64 2)
  %mod8 = icmp eq i64 %mod7, 1
  br i1 %mod8, label %if.then3, label %if.else4
if.then3:
  %n9 = load i64, i64* %n0
  %n10 = mul i64 3, %n9
  %n11 = add i64 %n10, 1
  store i64 %n11, i64* %n0
  br label %if.end5
if.else4:
  %n13 = load i64, i64* %n0
  %n14 = sdiv i64 %n13, 2
  store i64 %n14, i64* %n0
  br label %if.end5
if.end5:
  %n19 = load i64, i64* %n0
  %n20 = icmp sle i64 %n19, 1
  br i1 %n20, label %if.then6, label %if.end7
if.then6:
  %n21 = load i64, i64* %n0
  %_22 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_23 = call i32 (i8*, ...) @printf(i8* %_22, i64 %n21)
  br label %exit
if.end7:
  br i1 1, label %while.body2, label %while.end8
while.end8:
  br label %exit
exit:
  ret void
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %num1 = alloca i64
  br label %body1
body1:
  %_3 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_4 = call i32 (i8*, ...) @scanf(i8* %_3, i32* @.read_scratch)
  %_5 = load i32, i32* @.read_scratch
  %_6 = sext i32 %_5 to i64
  store i64 %_6, i64* %num1
  %num8 = load i64, i64* %num1
  call void (i64) @hailstone(i64 %num8)
  store i64 0, i64* %_0
  br label %exit
exit:
  %_12 = load i64, i64* %_0
  ret i64 %_12
}

