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
  br label %body0
body0:
  %prev16 = mul i64 %seed, %seed
  %linkedNums.malloc17 = call i8* (i32) @malloc(i32 16)
  %prevNode18 = bitcast i8* %linkedNums.malloc17 to %struct.linkedNums*
  %prevNode.num_auf19 = getelementptr %struct.linkedNums, %struct.linkedNums* %prevNode18, i1 0, i32 0
  store i64 %prev16, i64* %prevNode.num_auf19
  %prevNode.next_auf21 = getelementptr %struct.linkedNums, %struct.linkedNums* %prevNode18, i1 0, i32 1
  store %struct.linkedNums* null, %struct.linkedNums** %prevNode.next_auf21
  %tmp.binop24 = sub i64 %num, 1
  br label %while.cond11
while.cond11:
  %_27 = icmp sgt i64 %tmp.binop24, 0
  br i1 %_27, label %while.body2, label %while.exit5
while.body2:
  %prevNode4 = phi %struct.linkedNums* [ %prevNode18, %while.cond11 ], [ %prevNode42, %while.fillback4 ]
  %seed6 = phi i64 [ %seed, %while.cond11 ], [ %seed6, %while.fillback4 ]
  %num8 = phi i64 [ %tmp.binop24, %while.cond11 ], [ %num48, %while.fillback4 ]
  %prev10 = phi i64 [ %prev16, %while.cond11 ], [ %prev40, %while.fillback4 ]
  %tmp.binop29 = mul i64 %prev10, %prev10
  %tmp.binop30 = sdiv i64 %tmp.binop29, %seed6
  %tmp.binop32 = sdiv i64 %seed6, 2
  %tmp.binop33 = mul i64 %tmp.binop30, %tmp.binop32
  %cur35 = add i64 %tmp.binop33, 1
  %tmp.binop37 = sdiv i64 %cur35, 1000000000
  %tmp.binop39 = mul i64 %tmp.binop37, 1000000000
  %prev40 = sub i64 %cur35, %tmp.binop39
  %linkedNums.malloc41 = call i8* (i32) @malloc(i32 16)
  %prevNode42 = bitcast i8* %linkedNums.malloc41 to %struct.linkedNums*
  %curNode.num_auf43 = getelementptr %struct.linkedNums, %struct.linkedNums* %prevNode42, i1 0, i32 0
  store i64 %prev40, i64* %curNode.num_auf43
  %curNode.next_auf45 = getelementptr %struct.linkedNums, %struct.linkedNums* %prevNode42, i1 0, i32 1
  store %struct.linkedNums* %prevNode4, %struct.linkedNums** %curNode.next_auf45
  %num48 = sub i64 %num8, 1
  br label %while.cond23
while.cond23:
  %_51 = icmp sgt i64 %num48, 0
  br i1 %_51, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %curNode13 = phi %struct.linkedNums* [ null, %while.cond11 ], [ %prevNode42, %while.cond23 ]
  br label %exit
exit:
  ret %struct.linkedNums* %curNode13
}

define i64 @calcMean(%struct.linkedNums* %nums) {
entry:
  br label %while.cond11
while.cond11:
  %_14 = icmp ne %struct.linkedNums* %nums, null
  br i1 %_14, label %while.body2, label %while.exit5
while.body2:
  %sum1 = phi i64 [ 0, %while.cond11 ], [ %sum20, %while.fillback4 ]
  %num3 = phi i64 [ 0, %while.cond11 ], [ %num17, %while.fillback4 ]
  %nums7 = phi %struct.linkedNums* [ %nums, %while.cond11 ], [ %nums22, %while.fillback4 ]
  %num17 = add i64 %num3, 1
  %nums.num_auf18 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums7, i1 0, i32 0
  %_19 = load i64, i64* %nums.num_auf18
  %sum20 = add i64 %sum1, %_19
  %nums.next_auf21 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums7, i1 0, i32 1
  %nums22 = load %struct.linkedNums*, %struct.linkedNums** %nums.next_auf21
  br label %while.cond23
while.cond23:
  %_24 = icmp ne %struct.linkedNums* %nums22, null
  br i1 %_24, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %sum2 = phi i64 [ 0, %while.cond11 ], [ %sum20, %while.cond23 ]
  %num4 = phi i64 [ 0, %while.cond11 ], [ %num17, %while.cond23 ]
  br label %if.cond6
if.cond6:
  %_29 = icmp ne i64 %num4, 0
  br i1 %_29, label %then.body7, label %if.exit9
then.body7:
  %mean31 = sdiv i64 %sum2, %num4
  br label %then.exit8
then.exit8:
  br label %if.exit9
if.exit9:
  %mean5 = phi i64 [ 0, %if.cond6 ], [ %mean31, %then.exit8 ]
  br label %exit
exit:
  ret i64 %mean5
}

define i64 @approxSqrt(i64 %num) {
entry:
  br label %while.cond11
while.cond11:
  %_14 = icmp slt i64 0, %num
  br i1 %_14, label %while.body2, label %while.exit5
while.body2:
  %prev1 = phi i64 [ 1, %while.cond11 ], [ %guess18, %while.fillback4 ]
  %num3 = phi i64 [ %num, %while.cond11 ], [ %num3, %while.fillback4 ]
  %result16 = mul i64 %prev1, %prev1
  %guess18 = add i64 %prev1, 1
  br label %while.cond23
while.cond23:
  %_20 = icmp slt i64 %result16, %num3
  br i1 %_20, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %prev6 = phi i64 [ 1, %while.cond11 ], [ %prev1, %while.cond23 ]
  br label %exit
exit:
  ret i64 %prev6
}

define void @approxSqrtAll(%struct.linkedNums* %nums) {
entry:
  br label %while.cond11
while.cond11:
  %_4 = icmp ne %struct.linkedNums* %nums, null
  br i1 %_4, label %while.body2, label %while.exit5
while.body2:
  %nums2 = phi %struct.linkedNums* [ %nums, %while.cond11 ], [ %nums12, %while.fillback4 ]
  %nums.num_auf6 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums2, i1 0, i32 0
  %_7 = load i64, i64* %nums.num_auf6
  %aufrufen_approxSqrt8 = call i64 (i64) @approxSqrt(i64 %_7)
  %_9 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_10 = call i32 (i8*, ...) @printf(i8* %_9, i64 %aufrufen_approxSqrt8)
  %nums.next_auf11 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums2, i1 0, i32 1
  %nums12 = load %struct.linkedNums*, %struct.linkedNums** %nums.next_auf11
  br label %while.cond23
while.cond23:
  %_14 = icmp ne %struct.linkedNums* %nums12, null
  br i1 %_14, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  br label %exit
exit:
  ret void
}

define void @range(%struct.linkedNums* %nums) {
entry:
  br label %while.cond11
while.cond11:
  %_19 = icmp ne %struct.linkedNums* %nums, null
  br i1 %_19, label %while.body2, label %while.exit21
while.body2:
  %min3 = phi i64 [ 0, %while.cond11 ], [ %min1, %while.fillback20 ]
  %max7 = phi i64 [ 0, %while.cond11 ], [ %max5, %while.fillback20 ]
  %nums10 = phi %struct.linkedNums* [ %nums, %while.cond11 ], [ %nums53, %while.fillback20 ]
  %_14 = phi i1 [ 1, %while.cond11 ], [ %first12, %while.fillback20 ]
  br label %if.cond3
if.cond3:
  br i1 %_14, label %then.body4, label %if.cond7
then.body4:
  %nums.num_auf23 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums10, i1 0, i32 0
  %min24 = load i64, i64* %nums.num_auf23
  %nums.num_auf25 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums10, i1 0, i32 0
  %max26 = load i64, i64* %nums.num_auf25
  br label %then.exit5
then.exit5:
  br label %if.exit18
if.cond7:
  %nums.num_auf31 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums10, i1 0, i32 0
  %_32 = load i64, i64* %nums.num_auf31
  %_33 = icmp slt i64 %_32, %min3
  br i1 %_33, label %then.body8, label %if.cond11
then.body8:
  %nums.num_auf35 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums10, i1 0, i32 0
  %min36 = load i64, i64* %nums.num_auf35
  br label %then.exit9
then.exit9:
  br label %if.exit16
if.cond11:
  %nums.num_auf40 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums10, i1 0, i32 0
  %_41 = load i64, i64* %nums.num_auf40
  %_42 = icmp sgt i64 %_41, %max7
  br i1 %_42, label %then.body12, label %if.exit14
then.body12:
  %nums.num_auf44 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums10, i1 0, i32 0
  %max45 = load i64, i64* %nums.num_auf44
  br label %then.exit13
then.exit13:
  br label %if.exit14
if.exit14:
  %max8 = phi i64 [ %max7, %if.cond11 ], [ %max45, %then.exit13 ]
  br label %else.exit15
else.exit15:
  br label %if.exit16
if.exit16:
  %min4 = phi i64 [ %min36, %then.exit9 ], [ %min3, %else.exit15 ]
  %max9 = phi i64 [ %max7, %then.exit9 ], [ %max8, %else.exit15 ]
  br label %else.exit17
else.exit17:
  br label %if.exit18
if.exit18:
  %min1 = phi i64 [ %min24, %then.exit5 ], [ %min4, %else.exit17 ]
  %max5 = phi i64 [ %max26, %then.exit5 ], [ %max9, %else.exit17 ]
  %first12 = phi i1 [ 0, %then.exit5 ], [ %_14, %else.exit17 ]
  %nums.next_auf52 = getelementptr %struct.linkedNums, %struct.linkedNums* %nums10, i1 0, i32 1
  %nums53 = load %struct.linkedNums*, %struct.linkedNums** %nums.next_auf52
  br label %while.cond219
while.cond219:
  %_55 = icmp ne %struct.linkedNums* %nums53, null
  br i1 %_55, label %while.fillback20, label %while.exit21
while.fillback20:
  br label %while.body2
while.exit21:
  %min2 = phi i64 [ 0, %while.cond11 ], [ %min1, %while.cond219 ]
  %max6 = phi i64 [ 0, %while.cond11 ], [ %max5, %while.cond219 ]
  %_58 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_59 = call i32 (i8*, ...) @printf(i8* %_58, i64 %min2)
  %_60 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_61 = call i32 (i8*, ...) @printf(i8* %_60, i64 %max6)
  br label %exit
exit:
  ret void
}

define i64 @main() {
entry:
  %return_reg0 = alloca i64
  %_1 = load i64, i64* %return_reg0
  br label %body0
body0:
  %_2 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_3 = call i32 (i8*, ...) @scanf(i8* %_2, i32* @.read_scratch)
  %_4 = load i32, i32* @.read_scratch
  %seed5 = sext i32 %_4 to i64
  %_6 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_7 = call i32 (i8*, ...) @scanf(i8* %_6, i32* @.read_scratch)
  %_8 = load i32, i32* @.read_scratch
  %num9 = sext i32 %_8 to i64
  %nums10 = call %struct.linkedNums* (i64, i64) @getRands(i64 %seed5, i64 %num9)
  %mean11 = call i64 (%struct.linkedNums*) @calcMean(%struct.linkedNums* %nums10)
  %_12 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_13 = call i32 (i8*, ...) @printf(i8* %_12, i64 %mean11)
  call void (%struct.linkedNums*) @range(%struct.linkedNums* %nums10)
  call void (%struct.linkedNums*) @approxSqrtAll(%struct.linkedNums* %nums10)
  br label %exit
exit:
  ret i64 0
}

