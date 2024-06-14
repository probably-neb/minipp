declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

define i64 @sum(i64 %a, i64 %b) {
entry:
  %_0 = alloca i64
  %a1 = alloca i64
  store i64 %a, i64* %a1
  %b3 = alloca i64
  store i64 %b, i64* %b3
  br label %body1
body1:
  %a6 = load i64, i64* %a1
  %b7 = load i64, i64* %b3
  %_8 = add i64 %a6, %b7
  store i64 %_8, i64* %_0
  br label %exit
exit:
  %_11 = load i64, i64* %_0
  ret i64 %_11
}

define i64 @fact(i64 %n) {
entry:
  %_0 = alloca i64
  %t1 = alloca i64
  %n2 = alloca i64
  store i64 %n, i64* %n2
  br label %body1
body1:
  %n5 = load i64, i64* %n2
  %n6 = icmp eq i64 %n5, 1
  %n7 = load i64, i64* %n2
  %n8 = icmp eq i64 %n7, 0
  %_9 = or i1 %n6, %n8
  br i1 %_9, label %if.then2, label %if.end3
if.then2:
  store i64 1, i64* %_0
  br label %exit
if.end3:
  %n13 = load i64, i64* %n2
  %n14 = icmp sle i64 %n13, 1
  br i1 %n14, label %if.then4, label %if.end5
if.then4:
  %_15 = sub i64 0, 1
  %n16 = load i64, i64* %n2
  %n17 = mul i64 %_15, %n16
  %fact18 = call i64 (i64) @fact(i64 %n17)
  store i64 %fact18, i64* %_0
  br label %exit
if.end5:
  %n22 = load i64, i64* %n2
  %n23 = load i64, i64* %n2
  %n24 = sub i64 %n23, 1
  %fact25 = call i64 (i64) @fact(i64 %n24)
  %_26 = mul i64 %n22, %fact25
  store i64 %_26, i64* %t1
  %t28 = load i64, i64* %t1
  store i64 %t28, i64* %_0
  br label %exit
exit:
  %_31 = load i64, i64* %_0
  ret i64 %_31
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %num11 = alloca i64
  %num22 = alloca i64
  %flag3 = alloca i64
  br label %body1
body1:
  store i64 0, i64* %flag3
  %flag6 = load i64, i64* %flag3
  %_7 = sub i64 0, 1
  %flag8 = icmp ne i64 %flag6, %_7
  br i1 %flag8, label %while.body2, label %while.end3
while.body2:
  %_9 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_10 = call i32 (i8*, ...) @scanf(i8* %_9, i32* @.read_scratch)
  %_11 = load i32, i32* @.read_scratch
  %_12 = sext i32 %_11 to i64
  store i64 %_12, i64* %num11
  %_14 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_15 = call i32 (i8*, ...) @scanf(i8* %_14, i32* @.read_scratch)
  %_16 = load i32, i32* @.read_scratch
  %_17 = sext i32 %_16 to i64
  store i64 %_17, i64* %num22
  %num119 = load i64, i64* %num11
  %fact20 = call i64 (i64) @fact(i64 %num119)
  store i64 %fact20, i64* %num11
  %num222 = load i64, i64* %num22
  %fact23 = call i64 (i64) @fact(i64 %num222)
  store i64 %fact23, i64* %num22
  %num125 = load i64, i64* %num11
  %num226 = load i64, i64* %num22
  %sum27 = call i64 (i64, i64) @sum(i64 %num125, i64 %num226)
  %_28 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_29 = call i32 (i8*, ...) @printf(i8* %_28, i64 %sum27)
  %_30 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_31 = call i32 (i8*, ...) @scanf(i8* %_30, i32* @.read_scratch)
  %_32 = load i32, i32* @.read_scratch
  %_33 = sext i32 %_32 to i64
  store i64 %_33, i64* %flag3
  %flag35 = load i64, i64* %flag3
  %_36 = sub i64 0, 1
  %flag37 = icmp ne i64 %flag35, %_36
  br i1 %flag37, label %while.body2, label %while.end3
while.end3:
  store i64 0, i64* %_0
  br label %exit
exit:
  %_42 = load i64, i64* %_0
  ret i64 %_42
}

