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
  br label %body0
body0:
  br label %if.cond1
if.cond1:
  %_6 = icmp sge i64 %index, %size
  br i1 %_6, label %then.body2, label %if.exit3
then.body2:
  %imm_store8 = add i64 0, 0
  br label %exit
if.exit3:
  %arr_auf11 = getelementptr i64, i64* %arr, i64 %index
  %_12 = load i64, i64* %arr_auf11
  %imm_store13 = add i64 1, 0
  %tmp.binop14 = add i64 %index, %imm_store13
  %aufrufen_sum15 = call i64 (i64*, i64, i64) @sum(i64* %arr, i64 %size, i64 %tmp.binop14)
  %tmp.binop16 = add i64 %_12, %aufrufen_sum15
  br label %exit
exit:
  %return_reg9 = phi i64 [ %imm_store8, %then.body2 ], [ %tmp.binop16, %if.exit3 ]
  ret i64 %return_reg9
}

define i64 @main() {
entry:
  br label %body0
body0:
  %.alloc106 = alloca [ 10 x i64 ]
  %arr7 = bitcast [ 10 x i64 ]* %.alloc106 to i64*
  %index8 = add i64 0, 0
  br label %while.cond11
while.cond11:
  %imm_store10 = add i64 10, 0
  %_11 = icmp slt i64 %index8, %imm_store10
  br i1 %_11, label %while.body2, label %while.exit5
while.body2:
  %arr0 = phi i64* [ %arr7, %while.cond11 ], [ %arr0, %while.fillback4 ]
  %index2 = phi i64 [ %index8, %while.cond11 ], [ %index20, %while.fillback4 ]
  %_13 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_14 = call i32 (i8*, ...) @scanf(i8* %_13, i32* @.read_scratch)
  %_15 = load i32, i32* @.read_scratch
  %_16 = sext i32 %_15 to i64
  %arr_auf17 = getelementptr i64, i64* %arr0, i64 %index2
  store i64 %_16, i64* %arr_auf17
  %imm_store19 = add i64 1, 0
  %index20 = add i64 %index2, %imm_store19
  br label %while.cond23
while.cond23:
  %imm_store22 = add i64 10, 0
  %_23 = icmp slt i64 %index20, %imm_store22
  br i1 %_23, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %arr1 = phi i64* [ %arr7, %while.cond11 ], [ %arr0, %while.cond23 ]
  %index3 = phi i64 [ %index8, %while.cond11 ], [ %index20, %while.cond23 ]
  %imm_store26 = add i64 10, 0
  %imm_store27 = add i64 0, 0
  %aufrufen_sum28 = call i64 (i64*, i64, i64) @sum(i64* %arr1, i64 %imm_store26, i64 %imm_store27)
  %_29 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_30 = call i32 (i8*, ...) @printf(i8* %_29, i64 %aufrufen_sum28)
  %imm_store31 = add i64 0, 0
  br label %exit
exit:
  %return_reg32 = phi i64 [ %imm_store31, %while.exit5 ]
  ret i64 %return_reg32
}

