declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

define i64 @function(i64 %n) {
entry:
  %_0 = alloca i64
  %i1 = alloca i64
  %j2 = alloca i64
  %n3 = alloca i64
  store i64 %n, i64* %n3
  br label %body1
body1:
  %n6 = load i64, i64* %n3
  %n7 = icmp sle i64 %n6, 0
  br i1 %n7, label %if.then2, label %if.end3
if.then2:
  store i64 0, i64* %_0
  br label %exit
if.end3:
  store i64 0, i64* %i1
  %i12 = load i64, i64* %i1
  %n13 = load i64, i64* %n3
  %n14 = load i64, i64* %n3
  %_15 = mul i64 %n13, %n14
  %i16 = icmp slt i64 %i12, %_15
  br i1 %i16, label %while.body4, label %while.end5
while.body4:
  %i17 = load i64, i64* %i1
  %n18 = load i64, i64* %n3
  %_19 = add i64 %i17, %n18
  store i64 %_19, i64* %j2
  %j21 = load i64, i64* %j2
  %_22 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_23 = call i32 (i8*, ...) @printf(i8* %_22, i64 %j21)
  %i24 = load i64, i64* %i1
  %i25 = add i64 %i24, 1
  store i64 %i25, i64* %i1
  %i27 = load i64, i64* %i1
  %n28 = load i64, i64* %n3
  %n29 = load i64, i64* %n3
  %_30 = mul i64 %n28, %n29
  %i31 = icmp slt i64 %i27, %_30
  br i1 %i31, label %while.body4, label %while.end5
while.end5:
  %n34 = load i64, i64* %n3
  %n35 = sub i64 %n34, 1
  %function36 = call i64 (i64) @function(i64 %n35)
  store i64 %function36, i64* %_0
  br label %exit
exit:
  %_39 = load i64, i64* %_0
  ret i64 %_39
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
  %function9 = call i64 (i64) @function(i64 %num8)
  %_10 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_11 = call i32 (i8*, ...) @printf(i8* %_10, i64 0)
  store i64 0, i64* %_0
  br label %exit
exit:
  %_14 = load i64, i64* %_0
  ret i64 %_14
}

