declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

define void @sort(i64* %arr, i64 %size) {
entry:
  %index0 = alloca i64
  %tmpVal1 = alloca i64
  %tmpIndex2 = alloca i64
  %arr3 = alloca i64*
  store i64* %arr, i64** %arr3
  %size5 = alloca i64
  store i64 %size, i64* %size5
  br label %body1
body1:
  store i64 0, i64* %index0
  %index9 = load i64, i64* %index0
  %size10 = load i64, i64* %size5
  %_11 = icmp slt i64 %index9, %size10
  br i1 %_11, label %while.body2, label %while.end5
while.body2:
  %index12 = load i64, i64* %index0
  store i64 %index12, i64* %tmpIndex2
  %tmpIndex14 = load i64, i64* %tmpIndex2
  %tmpIndex15 = icmp sgt i64 %tmpIndex14, 0
  %arr16 = load i64*, i64** %arr3
  %tmpIndex17 = load i64, i64* %tmpIndex2
  %arr18 = getelementptr i64, i64* %arr16, i64 %tmpIndex17
  %arr19 = load i64, i64* %arr18
  %arr20 = load i64*, i64** %arr3
  %tmpIndex21 = load i64, i64* %tmpIndex2
  %tmpIndex22 = sub i64 %tmpIndex21, 1
  %arr23 = getelementptr i64, i64* %arr20, i64 %tmpIndex22
  %arr24 = load i64, i64* %arr23
  %_25 = icmp slt i64 %arr19, %arr24
  %tmpIndex26 = and i1 %tmpIndex15, %_25
  br i1 %tmpIndex26, label %while.body3, label %while.end4
while.body3:
  %arr27 = load i64*, i64** %arr3
  %tmpIndex28 = load i64, i64* %tmpIndex2
  %arr29 = getelementptr i64, i64* %arr27, i64 %tmpIndex28
  %arr30 = load i64, i64* %arr29
  store i64 %arr30, i64* %tmpVal1
  %arr32 = load i64*, i64** %arr3
  %tmpIndex33 = load i64, i64* %tmpIndex2
  %arr34 = getelementptr i64, i64* %arr32, i64 %tmpIndex33
  %arr35 = load i64*, i64** %arr3
  %tmpIndex36 = load i64, i64* %tmpIndex2
  %tmpIndex37 = sub i64 %tmpIndex36, 1
  %arr38 = getelementptr i64, i64* %arr35, i64 %tmpIndex37
  %arr39 = load i64, i64* %arr38
  store i64 %arr39, i64* %arr34
  %arr41 = load i64*, i64** %arr3
  %tmpIndex42 = load i64, i64* %tmpIndex2
  %tmpIndex43 = sub i64 %tmpIndex42, 1
  %arr44 = getelementptr i64, i64* %arr41, i64 %tmpIndex43
  %tmpVal45 = load i64, i64* %tmpVal1
  store i64 %tmpVal45, i64* %arr44
  %tmpIndex47 = load i64, i64* %tmpIndex2
  %tmpIndex48 = sub i64 %tmpIndex47, 1
  store i64 %tmpIndex48, i64* %tmpIndex2
  %tmpIndex50 = load i64, i64* %tmpIndex2
  %tmpIndex51 = icmp sgt i64 %tmpIndex50, 0
  %arr52 = load i64*, i64** %arr3
  %tmpIndex53 = load i64, i64* %tmpIndex2
  %arr54 = getelementptr i64, i64* %arr52, i64 %tmpIndex53
  %arr55 = load i64, i64* %arr54
  %arr56 = load i64*, i64** %arr3
  %tmpIndex57 = load i64, i64* %tmpIndex2
  %tmpIndex58 = sub i64 %tmpIndex57, 1
  %arr59 = getelementptr i64, i64* %arr56, i64 %tmpIndex58
  %arr60 = load i64, i64* %arr59
  %_61 = icmp slt i64 %arr55, %arr60
  %tmpIndex62 = and i1 %tmpIndex51, %_61
  br i1 %tmpIndex62, label %while.body3, label %while.end4
while.end4:
  %index65 = load i64, i64* %index0
  %index66 = add i64 %index65, 1
  store i64 %index66, i64* %index0
  %index68 = load i64, i64* %index0
  %size69 = load i64, i64* %size5
  %_70 = icmp slt i64 %index68, %size69
  br i1 %_70, label %while.body2, label %while.end5
while.end5:
  br label %exit
exit:
  ret void
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
  call void (i64*, i64) @sort(i64* %arr25, i64 10)
  store i64 0, i64* %index2
  %index28 = load i64, i64* %index2
  %index29 = icmp slt i64 %index28, 10
  br i1 %index29, label %while.body4, label %while.end5
while.body4:
  %arr30 = load i64*, i64** %arr1
  %index31 = load i64, i64* %index2
  %arr32 = getelementptr i64, i64* %arr30, i64 %index31
  %arr33 = load i64, i64* %arr32
  %_34 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_35 = call i32 (i8*, ...) @printf(i8* %_34, i64 %arr33)
  %index36 = load i64, i64* %index2
  %index37 = add i64 %index36, 1
  store i64 %index37, i64* %index2
  %index39 = load i64, i64* %index2
  %index40 = icmp slt i64 %index39, 10
  br i1 %index40, label %while.body4, label %while.end5
while.end5:
  store i64 0, i64* %_0
  br label %exit
exit:
  %_45 = load i64, i64* %_0
  ret i64 %_45
}

