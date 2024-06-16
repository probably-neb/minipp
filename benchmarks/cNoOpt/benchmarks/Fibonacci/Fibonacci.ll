declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

define i64 @computeFib(i64 %input) {
entry:
  %_0 = alloca i64
  %input1 = alloca i64
  store i64 %input, i64* %input1
  br label %body1
body1:
  %input4 = load i64, i64* %input1
  %input5 = icmp eq i64 %input4, 0
  br i1 %input5, label %if.then2, label %if.else3
if.then2:
  store i64 0, i64* %_0
  br label %exit
if.else3:
  %input8 = load i64, i64* %input1
  %input9 = icmp sle i64 %input8, 2
  br i1 %input9, label %if.then4, label %if.else5
if.then4:
  store i64 1, i64* %_0
  br label %exit
if.else5:
  %input12 = load i64, i64* %input1
  %input13 = sub i64 %input12, 1
  %computeFib14 = call i64 (i64) @computeFib(i64 %input13)
  %input15 = load i64, i64* %input1
  %input16 = sub i64 %input15, 2
  %computeFib17 = call i64 (i64) @computeFib(i64 %input16)
  %_18 = add i64 %computeFib14, %computeFib17
  store i64 %_18, i64* %_0
  br label %exit
if.end6:
  br label %if.end7
if.end7:
  br label %exit
exit:
  %_25 = load i64, i64* %_0
  ret i64 %_25
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %input1 = alloca i64
  br label %body1
body1:
  %_3 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_4 = call i32 (i8*, ...) @scanf(i8* %_3, i32* @.read_scratch)
  %_5 = load i32, i32* @.read_scratch
  %_6 = sext i32 %_5 to i64
  store i64 %_6, i64* %input1
  %input8 = load i64, i64* %input1
  %computeFib9 = call i64 (i64) @computeFib(i64 %input8)
  %_10 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_11 = call i32 (i8*, ...) @printf(i8* %_10, i64 %computeFib9)
  store i64 0, i64* %_0
  br label %exit
exit:
  %_14 = load i64, i64* %_0
  ret i64 %_14
}

