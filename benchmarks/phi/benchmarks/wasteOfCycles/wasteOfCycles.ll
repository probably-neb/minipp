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
  %j38 = alloca i64
  %j39 = load i64, i64* %j38
  br label %body0
body0:
  br label %if.cond1
if.cond1:
  %imm_store13 = add i64 0, 0
  %_14 = icmp sle i64 %n, %imm_store13
  br i1 %_14, label %then.body2, label %if.exit3
then.body2:
  %imm_store16 = add i64 0, 0
  br label %exit
if.exit3:
  %i19 = add i64 0, 0
  br label %while.cond14
while.cond14:
  %tmp.binop21 = mul i64 %n, %n
  %_22 = icmp slt i64 %i19, %tmp.binop21
  br i1 %_22, label %while.body5, label %while.exit8
while.body5:
  %j2 = phi i64 [ %j39, %while.cond14 ], [ %j24, %while.fillback7 ]
  %n4 = phi i64 [ %n, %while.cond14 ], [ %n4, %while.fillback7 ]
  %i8 = phi i64 [ %i19, %while.cond14 ], [ %i28, %while.fillback7 ]
  %j24 = add i64 %i8, %n4
  %_25 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_26 = call i32 (i8*, ...) @printf(i8* %_25, i64 %j24)
  %imm_store27 = add i64 1, 0
  %i28 = add i64 %i8, %imm_store27
  br label %while.cond26
while.cond26:
  %tmp.binop30 = mul i64 %n4, %n4
  %_31 = icmp slt i64 %i28, %tmp.binop30
  br i1 %_31, label %while.fillback7, label %while.exit8
while.fillback7:
  br label %while.body5
while.exit8:
  %j1 = phi i64 [ %j39, %while.cond14 ], [ %j24, %while.cond26 ]
  %n5 = phi i64 [ %n, %while.cond14 ], [ %n4, %while.cond26 ]
  %i7 = phi i64 [ %i19, %while.cond14 ], [ %i28, %while.cond26 ]
  %imm_store34 = add i64 1, 0
  %tmp.binop35 = sub i64 %n5, %imm_store34
  %aufrufen_function36 = call i64 (i64) @function(i64 %tmp.binop35)
  br label %exit
exit:
  %return_reg17 = phi i64 [ %imm_store16, %then.body2 ], [ %aufrufen_function36, %while.exit8 ]
  ret i64 %return_reg17
}

define i64 @main() {
entry:
  br label %body0
body0:
  %_2 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_3 = call i32 (i8*, ...) @scanf(i8* %_2, i32* @.read_scratch)
  %_4 = load i32, i32* @.read_scratch
  %num5 = sext i32 %_4 to i64
  %aufrufen_function6 = call i64 (i64) @function(i64 %num5)
  %imm_store7 = add i64 0, 0
  %_8 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_9 = call i32 (i8*, ...) @printf(i8* %_8, i64 %imm_store7)
  %imm_store10 = add i64 0, 0
  br label %exit
exit:
  %return_reg11 = phi i64 [ %imm_store10, %body0 ]
  ret i64 %return_reg11
}

