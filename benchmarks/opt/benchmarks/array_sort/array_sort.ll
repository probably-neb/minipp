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
  %tmpIndex68 = alloca i64
  %tmpIndex69 = load i64, i64* %tmpIndex68
  %tmpVal70 = alloca i64
  %tmpVal71 = load i64, i64* %tmpVal70
  br label %while.cond11
while.cond11:
  %_20 = icmp slt i64 0, %size
  br i1 %_20, label %while.body2, label %while.exit10
while.body2:
  %size2 = phi i64 [ %size, %while.cond11 ], [ %size2, %while.fillback9 ]
  %arr7 = phi i64* [ %arr, %while.cond11 ], [ %arr5, %while.fillback9 ]
  %tmpIndex8 = phi i64 [ 0, %while.cond11 ], [ %index62, %while.fillback9 ]
  br label %while.cond13
while.cond13:
  %tmp.binop24 = icmp sgt i64 %tmpIndex8, 0
  %arr_auf25 = getelementptr i64, i64* %arr7, i64 %tmpIndex8
  %_26 = load i64, i64* %arr_auf25
  %tmp.binop28 = sub i64 %tmpIndex8, 1
  %arr_auf29 = getelementptr i64, i64* %arr7, i64 %tmp.binop28
  %_30 = load i64, i64* %arr_auf29
  %tmp.binop31 = icmp slt i64 %_26, %_30
  %_32 = and i1 %tmp.binop24, %tmp.binop31
  br i1 %_32, label %while.body4, label %while.exit7
while.body4:
  %arr4 = phi i64* [ %arr7, %while.cond13 ], [ %arr4, %while.fillback6 ]
  %tmpIndex10 = phi i64 [ %tmpIndex8, %while.cond13 ], [ %tmpIndex47, %while.fillback6 ]
  %arr_auf34 = getelementptr i64, i64* %arr4, i64 %tmpIndex10
  %tmpVal35 = load i64, i64* %arr_auf34
  %tmp.binop37 = sub i64 %tmpIndex10, 1
  %arr_auf38 = getelementptr i64, i64* %arr4, i64 %tmp.binop37
  %_39 = load i64, i64* %arr_auf38
  %arr_auf40 = getelementptr i64, i64* %arr4, i64 %tmpIndex10
  store i64 %_39, i64* %arr_auf40
  %tmp.binop43 = sub i64 %tmpIndex10, 1
  %arr_auf44 = getelementptr i64, i64* %arr4, i64 %tmp.binop43
  store i64 %tmpVal35, i64* %arr_auf44
  %tmpIndex47 = sub i64 %tmpIndex10, 1
  br label %while.cond25
while.cond25:
  %tmp.binop50 = icmp sgt i64 %tmpIndex47, 0
  %arr_auf51 = getelementptr i64, i64* %arr4, i64 %tmpIndex47
  %_52 = load i64, i64* %arr_auf51
  %tmp.binop54 = sub i64 %tmpIndex47, 1
  %arr_auf55 = getelementptr i64, i64* %arr4, i64 %tmp.binop54
  %_56 = load i64, i64* %arr_auf55
  %tmp.binop57 = icmp slt i64 %_52, %_56
  %_58 = and i1 %tmp.binop50, %tmp.binop57
  br i1 %_58, label %while.fillback6, label %while.exit7
while.fillback6:
  br label %while.body4
while.exit7:
  %arr5 = phi i64* [ %arr7, %while.cond13 ], [ %arr4, %while.cond25 ]
  %index62 = add i64 %tmpIndex8, 1
  br label %while.cond28
while.cond28:
  %_64 = icmp slt i64 %index62, %size2
  br i1 %_64, label %while.fillback9, label %while.exit10
while.fillback9:
  br label %while.body2
while.exit10:
  br label %exit
exit:
  ret void
}

define i64 @main() {
entry:
  br label %body0
body0:
  %.alloc1010 = alloca [ 10 x i64 ]
  %arr11 = bitcast [ 10 x i64 ]* %.alloc1010 to i64*
  br label %while.cond11
while.cond11:
  br label %while.body2
while.body2:
  %arr2 = phi i64* [ %arr11, %while.cond11 ], [ %arr2, %while.fillback4 ]
  %index6 = phi i64 [ 0, %while.cond11 ], [ %index24, %while.fillback4 ]
  %_17 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_18 = call i32 (i8*, ...) @scanf(i8* %_17, i32* @.read_scratch)
  %_19 = load i32, i32* @.read_scratch
  %_20 = sext i32 %_19 to i64
  %arr_auf21 = getelementptr i64, i64* %arr2, i64 %index6
  store i64 %_20, i64* %arr_auf21
  %index24 = add i64 %index6, 1
  br label %while.cond23
while.cond23:
  %_27 = icmp slt i64 %index24, 10
  br i1 %_27, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  call void (i64*, i64) @sort(i64* %arr2, i64 10)
  br label %while.cond16
while.cond16:
  br label %while.body7
while.body7:
  %arr0 = phi i64* [ %arr2, %while.cond16 ], [ %arr0, %while.fillback9 ]
  %index5 = phi i64 [ 0, %while.cond16 ], [ %index42, %while.fillback9 ]
  %arr_auf37 = getelementptr i64, i64* %arr0, i64 %index5
  %_38 = load i64, i64* %arr_auf37
  %_39 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_40 = call i32 (i8*, ...) @printf(i8* %_39, i64 %_38)
  %index42 = add i64 %index5, 1
  br label %while.cond28
while.cond28:
  %_45 = icmp slt i64 %index42, 10
  br i1 %_45, label %while.fillback9, label %exit
while.fillback9:
  br label %while.body7
exit:
  ret i64 0
}

