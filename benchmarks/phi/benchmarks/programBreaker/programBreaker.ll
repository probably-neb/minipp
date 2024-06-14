declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

@GLOBAL = global i64 undef, align 8
@count = global i64 undef, align 8

define i64 @fun2(i64 %x, i64 %y) {
entry:
  br label %body0
body0:
  br label %if.cond1
if.cond1:
  %imm_store5 = add i64 0, 0
  %_6 = icmp eq i64 %x, %imm_store5
  br i1 %_6, label %then.body2, label %else.body3
then.body2:
  br label %exit
else.body3:
  %imm_store10 = add i64 1, 0
  %tmp.binop11 = sub i64 %x, %imm_store10
  %aufrufen_fun212 = call i64 (i64, i64) @fun2(i64 %tmp.binop11, i64 %y)
  br label %exit
exit:
  %return_reg8 = phi i64 [ %y, %then.body2 ], [ %aufrufen_fun212, %else.body3 ]
  ret i64 %return_reg8
}

define i64 @fun1(i64 %x, i64 %y, i64 %z) {
entry:
  br label %body0
body0:
  %imm_store5 = add i64 5, 0
  %imm_store6 = add i64 6, 0
  %tmp.binop7 = add i64 %imm_store5, %imm_store6
  %imm_store8 = add i64 2, 0
  %tmp.binop9 = mul i64 %x, %imm_store8
  %tmp.binop10 = sub i64 %tmp.binop7, %tmp.binop9
  %imm_store11 = add i64 4, 0
  %tmp.binop12 = sdiv i64 %imm_store11, %y
  %tmp.binop13 = add i64 %tmp.binop10, %tmp.binop12
  %retVal14 = add i64 %tmp.binop13, %z
  br label %if.cond1
if.cond1:
  %_16 = icmp sgt i64 %retVal14, %y
  br i1 %_16, label %then.body2, label %else.body3
then.body2:
  %aufrufen_fun218 = call i64 (i64, i64) @fun2(i64 %retVal14, i64 %x)
  br label %exit
else.body3:
  br label %if.cond4
if.cond4:
  %imm_store22 = add i64 5, 0
  %imm_store23 = add i64 6, 0
  %tmp.binop24 = icmp slt i64 %imm_store22, %imm_store23
  %tmp.binop25 = icmp sle i64 %retVal14, %y
  %_26 = and i1 %tmp.binop24, %tmp.binop25
  br i1 %_26, label %then.body5, label %if.exit7
then.body5:
  %aufrufen_fun228 = call i64 (i64, i64) @fun2(i64 %retVal14, i64 %y)
  br label %exit
exit:
  %return_reg19 = phi i64 [ %aufrufen_fun218, %then.body2 ], [ %aufrufen_fun228, %then.body5 ], [ %retVal14, %if.exit9 ]
  ret i64 %return_reg19
if.exit7:
  br label %else.exit8
else.exit8:
  br label %if.exit9
if.exit9:
  br label %exit
}

define i64 @main() {
entry:
  br label %body0
body0:
  %i4 = add i64 0, 0
  %_5 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_6 = call i32 (i8*, ...) @scanf(i8* %_5, i32* @.read_scratch)
  %_7 = load i32, i32* @.read_scratch
  %i8 = sext i32 %_7 to i64
  br label %while.cond11
while.cond11:
  %imm_store10 = add i64 10000, 0
  %_11 = icmp slt i64 %i8, %imm_store10
  br i1 %_11, label %while.body2, label %while.exit5
while.body2:
  %i0 = phi i64 [ %i8, %while.cond11 ], [ %i19, %while.fillback4 ]
  %imm_store13 = add i64 3, 0
  %imm_store14 = add i64 5, 0
  %aufrufen_fun115 = call i64 (i64, i64, i64) @fun1(i64 %imm_store13, i64 %i0, i64 %imm_store14)
  %_16 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_17 = call i32 (i8*, ...) @printf(i8* %_16, i64 %aufrufen_fun115)
  %imm_store18 = add i64 1, 0
  %i19 = add i64 %i0, %imm_store18
  br label %while.cond23
while.cond23:
  %imm_store21 = add i64 10000, 0
  %_22 = icmp slt i64 %i19, %imm_store21
  br i1 %_22, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %i1 = phi i64 [ %i8, %while.cond11 ], [ %i19, %while.cond23 ]
  %imm_store25 = add i64 0, 0
  br label %exit
exit:
  %return_reg26 = phi i64 [ %imm_store25, %while.exit5 ]
  ret i64 %return_reg26
}

