declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

define i64 @sum(i64* %arr, i64 %size, i64 %index) {
entry:
  %_0 = alloca i64
  %arr1 = alloca i64*
  store i64* %arr, i64** %arr1
  %size3 = alloca i64
  store i64 %size, i64* %size3
  %index5 = alloca i64
  store i64 %index, i64* %index5
  br label %body1
body1:
  %index8 = load i64, i64* %index5
  %size9 = load i64, i64* %size3
  %_10 = icmp sge i64 %index8, %size9
  br i1 %_10, label %if.then2, label %if.end3
if.then2:
  store i64 0, i64* %_0
  br label %exit
if.end3:
  %arr14 = load i64*, i64** %arr1
  %index15 = load i64, i64* %index5
  %arr16 = getelementptr i64, i64* %arr14, i64 %index15
  %arr17 = load i64, i64* %arr16
  %arr18 = load i64*, i64** %arr1
  %size19 = load i64, i64* %size3
  %index20 = load i64, i64* %index5
  %index21 = add i64 %index20, 1
  %sum22 = call i64 (i64*, i64, i64) @sum(i64* %arr18, i64 %size19, i64 %index21)
  %_23 = add i64 %arr17, %sum22
  store i64 %_23, i64* %_0
  br label %exit
exit:
  %_26 = load i64, i64* %_0
  ret i64 %_26
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %arr1 = alloca i64*
  %index2 = alloca i64
  br label %body1
body1:
  %_4 = alloca [ 10 x i64 ]
  %_5 = bitcast [ 10 x i64 ]* %_4 to i64*
  store i64* %_5, i64** %arr1
  store i64 0, i64* %index2
  %index8 = load i64, i64* %index2
  %index9 = icmp slt i64 %index8, 10
  br i1 %index9, label %while.body2, label %while.end3
while.body2:
  %arr10 = load i64*, i64** %arr1
  %index11 = load i64, i64* %index2
  %arr12 = getelementptr i64, i64* %arr10, i64 %index11
  %_13 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_14 = call i32 (i8*, ...) @scanf(i8* %_13, i32* @.read_scratch)
  %_15 = load i32, i32* @.read_scratch
  %_16 = sext i32 %_15 to i64
  store i64 %_16, i64* %arr12
  %index18 = load i64, i64* %index2
  %index19 = add i64 %index18, 1
  store i64 %index19, i64* %index2
  %index21 = load i64, i64* %index2
  %index22 = icmp slt i64 %index21, 10
  br i1 %index22, label %while.body2, label %while.end3
while.end3:
  %arr25 = load i64*, i64** %arr1
  %sum26 = call i64 (i64*, i64, i64) @sum(i64* %arr25, i64 10, i64 0)
  %_27 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_28 = call i32 (i8*, ...) @printf(i8* %_27, i64 %sum26)
  store i64 0, i64* %_0
  br label %exit
exit:
  %_31 = load i64, i64* %_0
  ret i64 %_31
}

