%struct.Power = type { i64, i64 }

declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

define i64 @calcPower(i64 %base, i64 %exp) {
entry:
  %_0 = alloca i64
  %result1 = alloca i64
  %base2 = alloca i64
  store i64 %base, i64* %base2
  %exp4 = alloca i64
  store i64 %exp, i64* %exp4
  br label %body1
body1:
  store i64 1, i64* %result1
  %exp8 = load i64, i64* %exp4
  %exp9 = icmp sgt i64 %exp8, 0
  br i1 %exp9, label %while.body2, label %while.end3
while.body2:
  %result10 = load i64, i64* %result1
  %base11 = load i64, i64* %base2
  %_12 = mul i64 %result10, %base11
  store i64 %_12, i64* %result1
  %exp14 = load i64, i64* %exp4
  %exp15 = sub i64 %exp14, 1
  store i64 %exp15, i64* %exp4
  %exp17 = load i64, i64* %exp4
  %exp18 = icmp sgt i64 %exp17, 0
  br i1 %exp18, label %while.body2, label %while.end3
while.end3:
  %result21 = load i64, i64* %result1
  store i64 %result21, i64* %_0
  br label %exit
exit:
  %_24 = load i64, i64* %_0
  ret i64 %_24
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %power1 = alloca %struct.Power*
  %input2 = alloca i64
  %result3 = alloca i64
  %exp4 = alloca i64
  %i5 = alloca i64
  br label %body1
body1:
  store i64 0, i64* %result3
  %Power8 = call i8* (i32) @malloc(i32 16)
  %Power9 = bitcast i8* %Power8 to %struct.Power*
  store %struct.Power* %Power9, %struct.Power** %power1
  %_11 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_12 = call i32 (i8*, ...) @scanf(i8* %_11, i32* @.read_scratch)
  %_13 = load i32, i32* @.read_scratch
  %_14 = sext i32 %_13 to i64
  store i64 %_14, i64* %input2
  %power16 = load %struct.Power*, %struct.Power** %power1
  %base17 = getelementptr %struct.Power, %struct.Power* %power16, i1 0, i32 0
  %input18 = load i64, i64* %input2
  store i64 %input18, i64* %base17
  %_20 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_21 = call i32 (i8*, ...) @scanf(i8* %_20, i32* @.read_scratch)
  %_22 = load i32, i32* @.read_scratch
  %_23 = sext i32 %_22 to i64
  store i64 %_23, i64* %input2
  %input25 = load i64, i64* %input2
  %input26 = icmp slt i64 %input25, 0
  br i1 %input26, label %if.then2, label %if.end3
if.then2:
  %_27 = sub i64 0, 1
  store i64 %_27, i64* %_0
  br label %exit
if.end3:
  %power31 = load %struct.Power*, %struct.Power** %power1
  %exp32 = getelementptr %struct.Power, %struct.Power* %power31, i1 0, i32 1
  %input33 = load i64, i64* %input2
  store i64 %input33, i64* %exp32
  store i64 0, i64* %i5
  %i36 = load i64, i64* %i5
  %i37 = icmp slt i64 %i36, 1000000
  br i1 %i37, label %while.body4, label %while.end5
while.body4:
  %i38 = load i64, i64* %i5
  %i39 = add i64 %i38, 1
  store i64 %i39, i64* %i5
  %power41 = load %struct.Power*, %struct.Power** %power1
  %base42 = getelementptr %struct.Power, %struct.Power* %power41, i1 0, i32 0
  %base43 = load i64, i64* %base42
  %power44 = load %struct.Power*, %struct.Power** %power1
  %exp45 = getelementptr %struct.Power, %struct.Power* %power44, i1 0, i32 1
  %exp46 = load i64, i64* %exp45
  %calcPower47 = call i64 (i64, i64) @calcPower(i64 %base43, i64 %exp46)
  store i64 %calcPower47, i64* %result3
  %i49 = load i64, i64* %i5
  %i50 = icmp slt i64 %i49, 1000000
  br i1 %i50, label %while.body4, label %while.end5
while.end5:
  %result53 = load i64, i64* %result3
  %_54 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_55 = call i32 (i8*, ...) @printf(i8* %_54, i64 %result53)
  store i64 0, i64* %_0
  br label %exit
exit:
  %_58 = load i64, i64* %_0
  ret i64 %_58
}

