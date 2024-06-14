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
  br label %if.cond1
if.cond1:
  %_6 = icmp eq i64 %x, 0
  br i1 %_6, label %then.body2, label %else.body3
then.body2:
  br label %exit
else.body3:
  %tmp.binop11 = sub i64 %x, 1
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
  %tmp.binop9 = mul i64 %x, 2
  %tmp.binop10 = sub i64 11, %tmp.binop9
  %tmp.binop12 = sdiv i64 4, %y
  %tmp.binop13 = add i64 %tmp.binop10, %tmp.binop12
  %retVal14 = add i64 %tmp.binop13, %z
  br label %if.cond1
if.cond1:
  %_16 = icmp sgt i64 %retVal14, %y
  br i1 %_16, label %then.body2, label %if.cond4
then.body2:
  %aufrufen_fun218 = call i64 (i64, i64) @fun2(i64 %retVal14, i64 %x)
  br label %exit
if.cond4:
  %tmp.binop25 = icmp sle i64 %retVal14, %y
  %_26 = and i1 1, %tmp.binop25
  br i1 %_26, label %then.body5, label %if.exit9
then.body5:
  %aufrufen_fun228 = call i64 (i64, i64) @fun2(i64 %retVal14, i64 %y)
  br label %exit
exit:
  %return_reg19 = phi i64 [ %aufrufen_fun218, %then.body2 ], [ %aufrufen_fun228, %then.body5 ], [ %retVal14, %if.exit9 ]
  ret i64 %return_reg19
if.exit9:
  br label %exit
}

define i64 @main() {
entry:
  br label %body0
body0:
  %_5 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_6 = call i32 (i8*, ...) @scanf(i8* %_5, i32* @.read_scratch)
  %_7 = load i32, i32* @.read_scratch
  %i8 = sext i32 %_7 to i64
  br label %while.cond11
while.cond11:
  %_11 = icmp slt i64 %i8, 10000
  br i1 %_11, label %while.body2, label %while.exit5
while.body2:
  %i0 = phi i64 [ %i8, %while.cond11 ], [ %i19, %while.fillback4 ]
  %aufrufen_fun115 = call i64 (i64, i64, i64) @fun1(i64 3, i64 %i0, i64 5)
  %_16 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_17 = call i32 (i8*, ...) @printf(i8* %_16, i64 %aufrufen_fun115)
  %i19 = add i64 %i0, 1
  br label %while.cond23
while.cond23:
  %_22 = icmp slt i64 %i19, 10000
  br i1 %_22, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  br label %exit
exit:
  ret i64 0
}

