%struct.linkedNums = type { i64, %struct.linkedNums* }

declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

define %struct.linkedNums* @getRands(i64 %seed, i64 %num) {
entry:
  %_0 = alloca %struct.linkedNums*
  %cur1 = alloca i64
  %prev2 = alloca i64
  %curNode3 = alloca %struct.linkedNums*
  %prevNode4 = alloca %struct.linkedNums*
  %seed5 = alloca i64
  store i64 %seed, i64* %seed5
  %num7 = alloca i64
  store i64 %num, i64* %num7
  br label %body1
body1:
  store %struct.linkedNums* null, %struct.linkedNums** %curNode3
  %seed11 = load i64, i64* %seed5
  %seed12 = load i64, i64* %seed5
  %_13 = mul i64 %seed11, %seed12
  store i64 %_13, i64* %cur1
  %linkedNums15 = call i8* (i32) @malloc(i32 16)
  %linkedNums16 = bitcast i8* %linkedNums15 to %struct.linkedNums*
  store %struct.linkedNums* %linkedNums16, %struct.linkedNums** %prevNode4
  %prevNode18 = load %struct.linkedNums*, %struct.linkedNums** %prevNode4
  %num19 = getelementptr %struct.linkedNums, %struct.linkedNums* %prevNode18, i1 0, i32 0
  %cur20 = load i64, i64* %cur1
  store i64 %cur20, i64* %num19
  %prevNode22 = load %struct.linkedNums*, %struct.linkedNums** %prevNode4
  %next23 = getelementptr %struct.linkedNums, %struct.linkedNums* %prevNode22, i1 0, i32 1
  store %struct.linkedNums* null, %struct.linkedNums** %next23
  %num25 = load i64, i64* %num7
  %num26 = sub i64 %num25, 1
  store i64 %num26, i64* %num7
  %cur28 = load i64, i64* %cur1
  store i64 %cur28, i64* %prev2
  %num30 = load i64, i64* %num7
  %num31 = icmp sgt i64 %num30, 0
  br i1 %num31, label %while.body2, label %while.end3
while.body2:
  %prev32 = load i64, i64* %prev2
  %prev33 = load i64, i64* %prev2
  %_34 = mul i64 %prev32, %prev33
  %seed35 = load i64, i64* %seed5
  %seed36 = sdiv i64 %_34, %seed35
  %seed37 = load i64, i64* %seed5
  %seed38 = sdiv i64 %seed37, 2
  %_39 = mul i64 %seed36, %seed38
  %_40 = add i64 %_39, 1
  store i64 %_40, i64* %cur1
  %cur42 = load i64, i64* %cur1
  %cur43 = load i64, i64* %cur1
  %cur44 = sdiv i64 %cur43, 1000000000
  %cur45 = mul i64 %cur44, 1000000000
  %_46 = sub i64 %cur42, %cur45
  store i64 %_46, i64* %cur1
  %linkedNums48 = call i8* (i32) @malloc(i32 16)
  %linkedNums49 = bitcast i8* %linkedNums48 to %struct.linkedNums*
  store %struct.linkedNums* %linkedNums49, %struct.linkedNums** %curNode3
  %curNode51 = load %struct.linkedNums*, %struct.linkedNums** %curNode3
  %num52 = getelementptr %struct.linkedNums, %struct.linkedNums* %curNode51, i1 0, i32 0
  %cur53 = load i64, i64* %cur1
  store i64 %cur53, i64* %num52
  %curNode55 = load %struct.linkedNums*, %struct.linkedNums** %curNode3
  %next56 = getelementptr %struct.linkedNums, %struct.linkedNums* %curNode55, i1 0, i32 1
  %prevNode57 = load %struct.linkedNums*, %struct.linkedNums** %prevNode4
  store %struct.linkedNums* %prevNode57, %struct.linkedNums** %next56
  %curNode59 = load %struct.linkedNums*, %struct.linkedNums** %curNode3
  store %struct.linkedNums* %curNode59, %struct.linkedNums** %prevNode4
  %num61 = load i64, i64* %num7
  %num62 = sub i64 %num61, 1
  store i64 %num62, i64* %num7
  %cur64 = load i64, i64* %cur1
  store i64 %cur64, i64* %prev2
  %num66 = load i64, i64* %num7
  %num67 = icmp sgt i64 %num66, 0
  br i1 %num67, label %while.body2, label %while.end3
while.end3:
  %curNode70 = load %struct.linkedNums*, %struct.linkedNums** %curNode3
  store %struct.linkedNums* %curNode70, %struct.linkedNums** %_0
  br label %exit
exit:
  %_73 = load %struct.linkedNums*, %struct.linkedNums** %_0
  ret %struct.linkedNums* %_73
}

define i64 @calcMean(%struct.linkedNums* %nums) {
entry:
  %_0 = alloca i64
  %sum1 = alloca i64
  %num2 = alloca i64
  %mean3 = alloca i64
  %nums4 = alloca %struct.linkedNums*
  store %struct.linkedNums* %nums, %struct.linkedNums** %nums4
  br label %body1
body1:
  store i64 0, i64* %sum1
  store i64 0, i64* %num2
  store i64 0, i64* %mean3
  %nums10 = load %struct.linkedNums*, %struct.linkedNums** %nums4
  %nums11 = icmp ne %struct.linkedNums* %nums10, null
  br i1 %nums11, label %while.body2, label %while.end3
while.body2:
  %num12 = load i64, i64* %num2
  %num13 = add i64 %num12, 1
  store i64 %num13, i64* %num2
  %sum15 = load i64, i64* %sum1
  %nums16 = load %struct.linkedNums*, %struct.linkedNums** %nums4
  %num17 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums16, i1 0, i32 0
  %num18 = load i64, i64* %num17
  %_19 = add i64 %sum15, %num18
  store i64 %_19, i64* %sum1
  %nums21 = load %struct.linkedNums*, %struct.linkedNums** %nums4
  %next22 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums21, i1 0, i32 1
  %next23 = load %struct.linkedNums*, %struct.linkedNums** %next22
  store %struct.linkedNums* %next23, %struct.linkedNums** %nums4
  %nums25 = load %struct.linkedNums*, %struct.linkedNums** %nums4
  %nums26 = icmp ne %struct.linkedNums* %nums25, null
  br i1 %nums26, label %while.body2, label %while.end3
while.end3:
  %num29 = load i64, i64* %num2
  %num30 = icmp ne i64 %num29, 0
  br i1 %num30, label %if.then4, label %if.end5
if.then4:
  %sum31 = load i64, i64* %sum1
  %num32 = load i64, i64* %num2
  %_33 = sdiv i64 %sum31, %num32
  store i64 %_33, i64* %mean3
  br label %if.end5
if.end5:
  %mean37 = load i64, i64* %mean3
  store i64 %mean37, i64* %_0
  br label %exit
exit:
  %_40 = load i64, i64* %_0
  ret i64 %_40
}

define i64 @approxSqrt(i64 %num) {
entry:
  %_0 = alloca i64
  %guess1 = alloca i64
  %result2 = alloca i64
  %prev3 = alloca i64
  %num4 = alloca i64
  store i64 %num, i64* %num4
  br label %body1
body1:
  store i64 1, i64* %guess1
  %guess8 = load i64, i64* %guess1
  store i64 %guess8, i64* %prev3
  store i64 0, i64* %result2
  %result11 = load i64, i64* %result2
  %num12 = load i64, i64* %num4
  %_13 = icmp slt i64 %result11, %num12
  br i1 %_13, label %while.body2, label %while.end3
while.body2:
  %guess14 = load i64, i64* %guess1
  %guess15 = load i64, i64* %guess1
  %_16 = mul i64 %guess14, %guess15
  store i64 %_16, i64* %result2
  %guess18 = load i64, i64* %guess1
  store i64 %guess18, i64* %prev3
  %guess20 = load i64, i64* %guess1
  %guess21 = add i64 %guess20, 1
  store i64 %guess21, i64* %guess1
  %result23 = load i64, i64* %result2
  %num24 = load i64, i64* %num4
  %_25 = icmp slt i64 %result23, %num24
  br i1 %_25, label %while.body2, label %while.end3
while.end3:
  %prev28 = load i64, i64* %prev3
  store i64 %prev28, i64* %_0
  br label %exit
exit:
  %_31 = load i64, i64* %_0
  ret i64 %_31
}

define void @approxSqrtAll(%struct.linkedNums* %nums) {
entry:
  %nums0 = alloca %struct.linkedNums*
  store %struct.linkedNums* %nums, %struct.linkedNums** %nums0
  br label %body1
body1:
  %nums3 = load %struct.linkedNums*, %struct.linkedNums** %nums0
  %nums4 = icmp ne %struct.linkedNums* %nums3, null
  br i1 %nums4, label %while.body2, label %while.end3
while.body2:
  %nums5 = load %struct.linkedNums*, %struct.linkedNums** %nums0
  %num6 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums5, i1 0, i32 0
  %num7 = load i64, i64* %num6
  %approxSqrt8 = call i64 (i64) @approxSqrt(i64 %num7)
  %_9 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_10 = call i32 (i8*, ...) @printf(i8* %_9, i64 %approxSqrt8)
  %nums11 = load %struct.linkedNums*, %struct.linkedNums** %nums0
  %next12 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums11, i1 0, i32 1
  %next13 = load %struct.linkedNums*, %struct.linkedNums** %next12
  store %struct.linkedNums* %next13, %struct.linkedNums** %nums0
  %nums15 = load %struct.linkedNums*, %struct.linkedNums** %nums0
  %nums16 = icmp ne %struct.linkedNums* %nums15, null
  br i1 %nums16, label %while.body2, label %while.end3
while.end3:
  br label %exit
exit:
  ret void
}

define void @range(%struct.linkedNums* %nums) {
entry:
  %min0 = alloca i64
  %max1 = alloca i64
  %first2 = alloca i1
  %nums3 = alloca %struct.linkedNums*
  store %struct.linkedNums* %nums, %struct.linkedNums** %nums3
  br label %body1
body1:
  store i64 0, i64* %min0
  store i64 0, i64* %max1
  store i1 1, i1* %first2
  %nums9 = load %struct.linkedNums*, %struct.linkedNums** %nums3
  %nums10 = icmp ne %struct.linkedNums* %nums9, null
  br i1 %nums10, label %while.body2, label %while.end11
while.body2:
  %first11 = load i1, i1* %first2
  br i1 %first11, label %if.then3, label %if.else4
if.then3:
  %nums12 = load %struct.linkedNums*, %struct.linkedNums** %nums3
  %num13 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums12, i1 0, i32 0
  %num14 = load i64, i64* %num13
  store i64 %num14, i64* %min0
  %nums16 = load %struct.linkedNums*, %struct.linkedNums** %nums3
  %num17 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums16, i1 0, i32 0
  %num18 = load i64, i64* %num17
  store i64 %num18, i64* %max1
  store i1 0, i1* %first2
  br label %if.end10
if.else4:
  %nums21 = load %struct.linkedNums*, %struct.linkedNums** %nums3
  %num22 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums21, i1 0, i32 0
  %num23 = load i64, i64* %num22
  %min24 = load i64, i64* %min0
  %_25 = icmp slt i64 %num23, %min24
  br i1 %_25, label %if.then5, label %if.else6
if.then5:
  %nums26 = load %struct.linkedNums*, %struct.linkedNums** %nums3
  %num27 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums26, i1 0, i32 0
  %num28 = load i64, i64* %num27
  store i64 %num28, i64* %min0
  br label %if.end9
if.else6:
  %nums30 = load %struct.linkedNums*, %struct.linkedNums** %nums3
  %num31 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums30, i1 0, i32 0
  %num32 = load i64, i64* %num31
  %max33 = load i64, i64* %max1
  %_34 = icmp sgt i64 %num32, %max33
  br i1 %_34, label %if.then7, label %if.end8
if.then7:
  %nums35 = load %struct.linkedNums*, %struct.linkedNums** %nums3
  %num36 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums35, i1 0, i32 0
  %num37 = load i64, i64* %num36
  store i64 %num37, i64* %max1
  br label %if.end8
if.end8:
  br label %if.end9
if.end9:
  br label %if.end10
if.end10:
  %nums47 = load %struct.linkedNums*, %struct.linkedNums** %nums3
  %next48 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums47, i1 0, i32 1
  %next49 = load %struct.linkedNums*, %struct.linkedNums** %next48
  store %struct.linkedNums* %next49, %struct.linkedNums** %nums3
  %nums51 = load %struct.linkedNums*, %struct.linkedNums** %nums3
  %nums52 = icmp ne %struct.linkedNums* %nums51, null
  br i1 %nums52, label %while.body2, label %while.end11
while.end11:
  %min55 = load i64, i64* %min0
  %_56 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_57 = call i32 (i8*, ...) @printf(i8* %_56, i64 %min55)
  %max58 = load i64, i64* %max1
  %_59 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_60 = call i32 (i8*, ...) @printf(i8* %_59, i64 %max58)
  br label %exit
exit:
  ret void
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %seed1 = alloca i64
  %num2 = alloca i64
  %mean3 = alloca i64
  %nums4 = alloca %struct.linkedNums*
  br label %body1
body1:
  %_6 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_7 = call i32 (i8*, ...) @scanf(i8* %_6, i32* @.read_scratch)
  %_8 = load i32, i32* @.read_scratch
  %_9 = sext i32 %_8 to i64
  store i64 %_9, i64* %seed1
  %_11 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_12 = call i32 (i8*, ...) @scanf(i8* %_11, i32* @.read_scratch)
  %_13 = load i32, i32* @.read_scratch
  %_14 = sext i32 %_13 to i64
  store i64 %_14, i64* %num2
  %seed16 = load i64, i64* %seed1
  %num17 = load i64, i64* %num2
  %getRands18 = call %struct.linkedNums* (i64, i64) @getRands(i64 %seed16, i64 %num17)
  store %struct.linkedNums* %getRands18, %struct.linkedNums** %nums4
  %nums20 = load %struct.linkedNums*, %struct.linkedNums** %nums4
  %calcMean21 = call i64 (%struct.linkedNums*) @calcMean(%struct.linkedNums* %nums20)
  store i64 %calcMean21, i64* %mean3
  %mean23 = load i64, i64* %mean3
  %_24 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_25 = call i32 (i8*, ...) @printf(i8* %_24, i64 %mean23)
  %nums26 = load %struct.linkedNums*, %struct.linkedNums** %nums4
  call void (%struct.linkedNums*) @range(%struct.linkedNums* %nums26)
  %nums28 = load %struct.linkedNums*, %struct.linkedNums** %nums4
  call void (%struct.linkedNums*) @approxSqrtAll(%struct.linkedNums* %nums28)
  store i64 0, i64* %_0
  br label %exit
exit:
  %_32 = load i64, i64* %_0
  ret i64 %_32
}

