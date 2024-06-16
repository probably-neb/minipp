declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

define i64 @sum(i64 %a, i64 %b) {
entry:
  br label %body0
body0:
  %tmp.binop4 = add i64 %a, %b
  br label %exit
exit:
  %return_reg5 = phi i64 [ %tmp.binop4, %body0 ]
  ret i64 %return_reg5
}

define i64 @fact(i64 %n) {
entry:
  br label %body0
body0:
  br label %if.cond1
if.cond1:
  %imm_store5 = add i64 1, 0
  %tmp.binop6 = icmp eq i64 %n, %imm_store5
  %imm_store7 = add i64 0, 0
  %tmp.binop8 = icmp eq i64 %n, %imm_store7
  %_9 = or i1 %tmp.binop6, %tmp.binop8
  br i1 %_9, label %then.body2, label %if.exit3
then.body2:
  %imm_store11 = add i64 1, 0
  br label %exit
if.exit3:
  br label %if.cond4
if.cond4:
  %imm_store15 = add i64 1, 0
  %_16 = icmp sle i64 %n, %imm_store15
  br i1 %_16, label %then.body5, label %if.exit6
then.body5:
  %imm_store18 = add i64 1, 0
  %tmp.unop19 = sub i64 0, %imm_store18
  %tmp.binop20 = mul i64 %tmp.unop19, %n
  %aufrufen_fact21 = call i64 (i64) @fact(i64 %tmp.binop20)
  br label %exit
if.exit6:
  %imm_store23 = add i64 1, 0
  %tmp.binop24 = sub i64 %n, %imm_store23
  %aufrufen_fact25 = call i64 (i64) @fact(i64 %tmp.binop24)
  %t26 = mul i64 %n, %aufrufen_fact25
  br label %exit
exit:
  %return_reg12 = phi i64 [ %imm_store11, %then.body2 ], [ %aufrufen_fact21, %then.body5 ], [ %t26, %if.exit6 ]
  ret i64 %return_reg12
}

define i64 @main() {
entry:
  %num140 = alloca i64
  %num141 = load i64, i64* %num140
  %num242 = alloca i64
  %num243 = load i64, i64* %num242
  br label %body0
body0:
  %flag8 = add i64 0, 0
  br label %while.cond11
while.cond11:
  %imm_store10 = add i64 1, 0
  %tmp.unop11 = sub i64 0, %imm_store10
  %_12 = icmp ne i64 %flag8, %tmp.unop11
  br i1 %_12, label %while.body2, label %while.exit5
while.body2:
  %flag0 = phi i64 [ %flag8, %while.cond11 ], [ %flag30, %while.fillback4 ]
  %num13 = phi i64 [ %num141, %while.cond11 ], [ %num122, %while.fillback4 ]
  %num25 = phi i64 [ %num243, %while.cond11 ], [ %num223, %while.fillback4 ]
  %_14 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_15 = call i32 (i8*, ...) @scanf(i8* %_14, i32* @.read_scratch)
  %_16 = load i32, i32* @.read_scratch
  %num117 = sext i32 %_16 to i64
  %_18 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_19 = call i32 (i8*, ...) @scanf(i8* %_18, i32* @.read_scratch)
  %_20 = load i32, i32* @.read_scratch
  %num221 = sext i32 %_20 to i64
  %num122 = call i64 (i64) @fact(i64 %num117)
  %num223 = call i64 (i64) @fact(i64 %num221)
  %aufrufen_sum24 = call i64 (i64, i64) @sum(i64 %num122, i64 %num223)
  %_25 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_26 = call i32 (i8*, ...) @printf(i8* %_25, i64 %aufrufen_sum24)
  %_27 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_28 = call i32 (i8*, ...) @scanf(i8* %_27, i32* @.read_scratch)
  %_29 = load i32, i32* @.read_scratch
  %flag30 = sext i32 %_29 to i64
  br label %while.cond23
while.cond23:
  %imm_store32 = add i64 1, 0
  %tmp.unop33 = sub i64 0, %imm_store32
  %_34 = icmp ne i64 %flag30, %tmp.unop33
  br i1 %_34, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %flag1 = phi i64 [ %flag8, %while.cond11 ], [ %flag30, %while.cond23 ]
  %num12 = phi i64 [ %num141, %while.cond11 ], [ %num122, %while.cond23 ]
  %num24 = phi i64 [ %num243, %while.cond11 ], [ %num223, %while.cond23 ]
  %imm_store37 = add i64 0, 0
  br label %exit
exit:
  %return_reg38 = phi i64 [ %imm_store37, %while.exit5 ]
  ret i64 %return_reg38
}

