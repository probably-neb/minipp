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
  br label %body0
body0:
  br label %if.cond1
if.cond1:
  %imm_store4 = add i64 0, 0
  %_5 = icmp eq i64 %input, %imm_store4
  br i1 %_5, label %then.body2, label %else.body3
then.body2:
  %imm_store7 = add i64 0, 0
  br label %exit
else.body3:
  br label %if.cond4
if.cond4:
  %imm_store11 = add i64 2, 0
  %_12 = icmp sle i64 %input, %imm_store11
  br i1 %_12, label %then.body5, label %else.body6
then.body5:
  %imm_store14 = add i64 1, 0
  br label %exit
else.body6:
  %imm_store16 = add i64 1, 0
  %tmp.binop17 = sub i64 %input, %imm_store16
  %aufrufen_computeFib18 = call i64 (i64) @computeFib(i64 %tmp.binop17)
  %imm_store19 = add i64 2, 0
  %tmp.binop20 = sub i64 %input, %imm_store19
  %aufrufen_computeFib21 = call i64 (i64) @computeFib(i64 %tmp.binop20)
  %tmp.binop22 = add i64 %aufrufen_computeFib18, %aufrufen_computeFib21
  br label %exit
exit:
  %return_reg8 = phi i64 [ %imm_store7, %then.body2 ], [ %imm_store14, %then.body5 ], [ %tmp.binop22, %else.body6 ]
  ret i64 %return_reg8
}

define i64 @main() {
entry:
  br label %body0
body0:
  %_2 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_3 = call i32 (i8*, ...) @scanf(i8* %_2, i32* @.read_scratch)
  %_4 = load i32, i32* @.read_scratch
  %input5 = sext i32 %_4 to i64
  %aufrufen_computeFib6 = call i64 (i64) @computeFib(i64 %input5)
  %_7 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_8 = call i32 (i8*, ...) @printf(i8* %_7, i64 %aufrufen_computeFib6)
  %imm_store9 = add i64 0, 0
  br label %exit
exit:
  %return_reg10 = phi i64 [ %imm_store9, %body0 ]
  ret i64 %return_reg10
}

