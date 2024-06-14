%struct.IntHolder = type { i64 }

declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

@interval = global i64 undef, align 8
@end = global i64 undef, align 8

define i64 @multBy4xTimes(%struct.IntHolder* %num, i64 %timesLeft) {
entry:
  %_0 = alloca i64
  %num1 = alloca %struct.IntHolder*
  store %struct.IntHolder* %num, %struct.IntHolder** %num1
  %timesLeft3 = alloca i64
  store i64 %timesLeft, i64* %timesLeft3
  br label %body1
body1:
  %timesLeft6 = load i64, i64* %timesLeft3
  %timesLeft7 = icmp sle i64 %timesLeft6, 0
  br i1 %timesLeft7, label %if.then2, label %if.end3
if.then2:
  %num8 = load %struct.IntHolder*, %struct.IntHolder** %num1
  %num9 = getelementptr %struct.IntHolder, %struct.IntHolder* %num8, i1 0, i32 0
  %num10 = load i64, i64* %num9
  store i64 %num10, i64* %_0
  br label %exit
if.end3:
  %num14 = load %struct.IntHolder*, %struct.IntHolder** %num1
  %num15 = getelementptr %struct.IntHolder, %struct.IntHolder* %num14, i1 0, i32 0
  %num16 = load %struct.IntHolder*, %struct.IntHolder** %num1
  %num17 = getelementptr %struct.IntHolder, %struct.IntHolder* %num16, i1 0, i32 0
  %num18 = load i64, i64* %num17
  %num19 = mul i64 4, %num18
  store i64 %num19, i64* %num15
  %num21 = load %struct.IntHolder*, %struct.IntHolder** %num1
  %timesLeft22 = load i64, i64* %timesLeft3
  %timesLeft23 = sub i64 %timesLeft22, 1
  %multBy4xTimes24 = call i64 (%struct.IntHolder*, i64) @multBy4xTimes(%struct.IntHolder* %num21, i64 %timesLeft23)
  %num25 = load %struct.IntHolder*, %struct.IntHolder** %num1
  %num26 = getelementptr %struct.IntHolder, %struct.IntHolder* %num25, i1 0, i32 0
  %num27 = load i64, i64* %num26
  store i64 %num27, i64* %_0
  br label %exit
exit:
  %_30 = load i64, i64* %_0
  ret i64 %_30
}

define void @divideBy8(%struct.IntHolder* %num) {
entry:
  %num0 = alloca %struct.IntHolder*
  store %struct.IntHolder* %num, %struct.IntHolder** %num0
  br label %body1
body1:
  %num3 = load %struct.IntHolder*, %struct.IntHolder** %num0
  %num4 = getelementptr %struct.IntHolder, %struct.IntHolder* %num3, i1 0, i32 0
  %num5 = load %struct.IntHolder*, %struct.IntHolder** %num0
  %num6 = getelementptr %struct.IntHolder, %struct.IntHolder* %num5, i1 0, i32 0
  %num7 = load i64, i64* %num6
  %num8 = sdiv i64 %num7, 2
  store i64 %num8, i64* %num4
  %num10 = load %struct.IntHolder*, %struct.IntHolder** %num0
  %num11 = getelementptr %struct.IntHolder, %struct.IntHolder* %num10, i1 0, i32 0
  %num12 = load %struct.IntHolder*, %struct.IntHolder** %num0
  %num13 = getelementptr %struct.IntHolder, %struct.IntHolder* %num12, i1 0, i32 0
  %num14 = load i64, i64* %num13
  %num15 = sdiv i64 %num14, 2
  store i64 %num15, i64* %num11
  %num17 = load %struct.IntHolder*, %struct.IntHolder** %num0
  %num18 = getelementptr %struct.IntHolder, %struct.IntHolder* %num17, i1 0, i32 0
  %num19 = load %struct.IntHolder*, %struct.IntHolder** %num0
  %num20 = getelementptr %struct.IntHolder, %struct.IntHolder* %num19, i1 0, i32 0
  %num21 = load i64, i64* %num20
  %num22 = sdiv i64 %num21, 2
  store i64 %num22, i64* %num18
  br label %exit
exit:
  ret void
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %start1 = alloca i64
  %countOuter2 = alloca i64
  %countInner3 = alloca i64
  %calc4 = alloca i64
  %tempAnswer5 = alloca i64
  %tempInterval6 = alloca i64
  %x7 = alloca %struct.IntHolder*
  %uselessVar8 = alloca i1
  %uselessVar29 = alloca i1
  br label %body1
body1:
  %IntHolder11 = call i8* (i32) @malloc(i32 8)
  %IntHolder12 = bitcast i8* %IntHolder11 to %struct.IntHolder*
  store %struct.IntHolder* %IntHolder12, %struct.IntHolder** %x7
  store i64 1000000, i64* @end
  %_15 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_16 = call i32 (i8*, ...) @scanf(i8* %_15, i32* @.read_scratch)
  %_17 = load i32, i32* @.read_scratch
  %_18 = sext i32 %_17 to i64
  store i64 %_18, i64* %start1
  %_20 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_21 = call i32 (i8*, ...) @scanf(i8* %_20, i32* @.read_scratch)
  %_22 = load i32, i32* @.read_scratch
  %_23 = sext i32 %_22 to i64
  store i64 %_23, i64* @interval
  %start25 = load i64, i64* %start1
  %_26 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_27 = call i32 (i8*, ...) @printf(i8* %_26, i64 %start25)
  %interval28 = load i64, i64* @interval
  %_29 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_30 = call i32 (i8*, ...) @printf(i8* %_29, i64 %interval28)
  store i64 0, i64* %countOuter2
  store i64 0, i64* %countInner3
  store i64 0, i64* %calc4
  %countOuter34 = load i64, i64* %countOuter2
  %countOuter35 = icmp slt i64 %countOuter34, 50
  br i1 %countOuter35, label %while.body2, label %while.end7
while.body2:
  store i64 0, i64* %countInner3
  %countInner37 = load i64, i64* %countInner3
  %end38 = load i64, i64* @end
  %_39 = icmp sle i64 %countInner37, %end38
  br i1 %_39, label %while.body3, label %while.end6
while.body3:
  %_40 = mul i64 1, 2
  %_41 = mul i64 %_40, 3
  %_42 = mul i64 %_41, 4
  %_43 = mul i64 %_42, 5
  %_44 = mul i64 %_43, 6
  %_45 = mul i64 %_44, 7
  %_46 = mul i64 %_45, 8
  %_47 = mul i64 %_46, 9
  %_48 = mul i64 %_47, 10
  %_49 = mul i64 %_48, 11
  store i64 %_49, i64* %calc4
  %countInner51 = load i64, i64* %countInner3
  %countInner52 = add i64 %countInner51, 1
  store i64 %countInner52, i64* %countInner3
  %x54 = load %struct.IntHolder*, %struct.IntHolder** %x7
  %num55 = getelementptr %struct.IntHolder, %struct.IntHolder* %x54, i1 0, i32 0
  %countInner56 = load i64, i64* %countInner3
  store i64 %countInner56, i64* %num55
  %x58 = load %struct.IntHolder*, %struct.IntHolder** %x7
  %num59 = getelementptr %struct.IntHolder, %struct.IntHolder* %x58, i1 0, i32 0
  %num60 = load i64, i64* %num59
  store i64 %num60, i64* %tempAnswer5
  %x62 = load %struct.IntHolder*, %struct.IntHolder** %x7
  %multBy4xTimes63 = call i64 (%struct.IntHolder*, i64) @multBy4xTimes(%struct.IntHolder* %x62, i64 2)
  %x64 = load %struct.IntHolder*, %struct.IntHolder** %x7
  call void (%struct.IntHolder*) @divideBy8(%struct.IntHolder* %x64)
  %interval66 = load i64, i64* @interval
  %interval67 = sub i64 %interval66, 1
  store i64 %interval67, i64* %tempInterval6
  %tempInterval69 = load i64, i64* %tempInterval6
  %tempInterval70 = icmp sle i64 %tempInterval69, 0
  store i1 %tempInterval70, i1* %uselessVar8
  %tempInterval72 = load i64, i64* %tempInterval6
  %tempInterval73 = icmp sle i64 %tempInterval72, 0
  br i1 %tempInterval73, label %if.then4, label %if.end5
if.then4:
  store i64 1, i64* %tempInterval6
  br label %if.end5
if.end5:
  %countInner77 = load i64, i64* %countInner3
  %tempInterval78 = load i64, i64* %tempInterval6
  %_79 = add i64 %countInner77, %tempInterval78
  store i64 %_79, i64* %countInner3
  %countInner81 = load i64, i64* %countInner3
  %end82 = load i64, i64* @end
  %_83 = icmp sle i64 %countInner81, %end82
  br i1 %_83, label %while.body3, label %while.end6
while.end6:
  %countOuter86 = load i64, i64* %countOuter2
  %countOuter87 = add i64 %countOuter86, 1
  store i64 %countOuter87, i64* %countOuter2
  %countOuter89 = load i64, i64* %countOuter2
  %countOuter90 = icmp slt i64 %countOuter89, 50
  br i1 %countOuter90, label %while.body2, label %while.end7
while.end7:
  %countInner93 = load i64, i64* %countInner3
  %_94 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_95 = call i32 (i8*, ...) @printf(i8* %_94, i64 %countInner93)
  %calc96 = load i64, i64* %calc4
  %_97 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_98 = call i32 (i8*, ...) @printf(i8* %_97, i64 %calc96)
  store i64 0, i64* %_0
  br label %exit
exit:
  %_101 = load i64, i64* %_0
  ret i64 %_101
}

