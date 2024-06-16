declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

define i64 @mod(i64 %a, i64 %b) {
entry:
  br label %body0
body0:
  %tmp.binop4 = sdiv i64 %a, %b
  %tmp.binop5 = mul i64 %tmp.binop4, %b
  %tmp.binop6 = sub i64 %a, %tmp.binop5
  br label %exit
exit:
  %return_reg7 = phi i64 [ %tmp.binop6, %body0 ]
  ret i64 %return_reg7
}

define void @hailstone(i64 %n) {
entry:
  br label %while.cond11
while.cond11:
  br label %while.body2
while.body2:
  %n4 = phi i64 [ %n, %while.cond11 ], [ %n1, %while.fillback13 ]
  %_8 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_9 = call i32 (i8*, ...) @printf(i8* %_8, i64 %n4)
  br label %if.cond3
if.cond3:
  %aufrufen_mod12 = call i64 (i64, i64) @mod(i64 %n4, i64 2)
  %_14 = icmp eq i64 %aufrufen_mod12, 1
  br i1 %_14, label %then.body4, label %else.body6
then.body4:
  %tmp.binop17 = mul i64 3, %n4
  %n19 = add i64 %tmp.binop17, 1
  br label %then.exit5
then.exit5:
  br label %if.exit8
else.body6:
  %n23 = sdiv i64 %n4, 2
  br label %else.exit7
else.exit7:
  br label %if.exit8
if.exit8:
  %n1 = phi i64 [ %n19, %then.exit5 ], [ %n23, %else.exit7 ]
  br label %if.cond9
if.cond9:
  %_28 = icmp sle i64 %n1, 1
  br i1 %_28, label %then.body10, label %while.fillback13
then.body10:
  %_30 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_31 = call i32 (i8*, ...) @printf(i8* %_30, i64 %n1)
  br label %exit
while.fillback13:
  br label %while.body2
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
  %num5 = sext i32 %_4 to i64
  call void (i64) @hailstone(i64 %num5)
  br label %exit
exit:
  ret i64 0
}

