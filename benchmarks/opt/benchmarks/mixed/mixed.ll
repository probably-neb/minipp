%struct.simple = type { i64 }
%struct.foo = type { i64, i1, %struct.simple* }

declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

@globalfoo = global %struct.foo* undef, align 8

define void @tailrecursive(i64 %num) {
entry:
  br label %if.cond1
if.cond1:
  %_3 = icmp sle i64 %num, 0
  br i1 %_3, label %exit, label %if.exit3
if.exit3:
  %tmp.binop7 = sub i64 %num, 1
  call void (i64) @tailrecursive(i64 %tmp.binop7)
  br label %exit
exit:
  ret void
}

define i64 @add(i64 %x, i64 %y) {
entry:
  br label %body0
body0:
  %tmp.binop4 = add i64 %x, %y
  br label %exit
exit:
  %return_reg5 = phi i64 [ %tmp.binop4, %body0 ]
  ret i64 %return_reg5
}

define void @domath(i64 %num) {
entry:
  %tmp87 = alloca i64
  %tmp88 = load i64, i64* %tmp87
  br label %body0
body0:
  %foo.malloc9 = call i8* (i32) @malloc(i32 24)
  %math110 = bitcast i8* %foo.malloc9 to %struct.foo*
  %simple.malloc11 = call i8* (i32) @malloc(i32 8)
  %simple.bitcast12 = bitcast i8* %simple.malloc11 to %struct.simple*
  %math1.simp_auf13 = getelementptr %struct.foo, %struct.foo* %math110, i1 0, i32 2
  store %struct.simple* %simple.bitcast12, %struct.simple** %math1.simp_auf13
  %foo.malloc15 = call i8* (i32) @malloc(i32 24)
  %math216 = bitcast i8* %foo.malloc15 to %struct.foo*
  %simple.malloc17 = call i8* (i32) @malloc(i32 8)
  %simple.bitcast18 = bitcast i8* %simple.malloc17 to %struct.simple*
  %math2.simp_auf19 = getelementptr %struct.foo, %struct.foo* %math216, i1 0, i32 2
  store %struct.simple* %simple.bitcast18, %struct.simple** %math2.simp_auf19
  %math1.bar_auf21 = getelementptr %struct.foo, %struct.foo* %math110, i1 0, i32 0
  store i64 %num, i64* %math1.bar_auf21
  %math2.bar_auf24 = getelementptr %struct.foo, %struct.foo* %math216, i1 0, i32 0
  store i64 3, i64* %math2.bar_auf24
  %math1.bar_auf26 = getelementptr %struct.foo, %struct.foo* %math110, i1 0, i32 0
  %_27 = load i64, i64* %math1.bar_auf26
  %math1.simp_auf28 = getelementptr %struct.foo, %struct.foo* %math110, i1 0, i32 2
  %simple29 = load %struct.simple*, %struct.simple** %math1.simp_auf28
  %math1.simp.one_auf30 = getelementptr %struct.simple, %struct.simple* %simple29, i1 0, i32 0
  store i64 %_27, i64* %math1.simp.one_auf30
  %math2.bar_auf32 = getelementptr %struct.foo, %struct.foo* %math216, i1 0, i32 0
  %_33 = load i64, i64* %math2.bar_auf32
  %math2.simp_auf34 = getelementptr %struct.foo, %struct.foo* %math216, i1 0, i32 2
  %simple35 = load %struct.simple*, %struct.simple** %math2.simp_auf34
  %math2.simp.one_auf36 = getelementptr %struct.simple, %struct.simple* %simple35, i1 0, i32 0
  store i64 %_33, i64* %math2.simp.one_auf36
  br label %while.cond11
while.cond11:
  %_40 = icmp sgt i64 %num, 0
  br i1 %_40, label %while.body2, label %while.exit5
while.body2:
  %math11 = phi %struct.foo* [ %math110, %while.cond11 ], [ %math11, %while.fillback4 ]
  %math25 = phi %struct.foo* [ %math216, %while.cond11 ], [ %math25, %while.fillback4 ]
  %num8 = phi i64 [ %num, %while.cond11 ], [ %num68, %while.fillback4 ]
  %math1.bar_auf42 = getelementptr %struct.foo, %struct.foo* %math11, i1 0, i32 0
  %_43 = load i64, i64* %math1.bar_auf42
  %math2.bar_auf44 = getelementptr %struct.foo, %struct.foo* %math25, i1 0, i32 0
  %_45 = load i64, i64* %math2.bar_auf44
  %math1.simp_auf47 = getelementptr %struct.foo, %struct.foo* %math11, i1 0, i32 2
  %simple48 = load %struct.simple*, %struct.simple** %math1.simp_auf47
  %math1.simp.one_auf49 = getelementptr %struct.simple, %struct.simple* %simple48, i1 0, i32 0
  %_50 = load i64, i64* %math1.simp.one_auf49
  %math2.bar_auf52 = getelementptr %struct.foo, %struct.foo* %math25, i1 0, i32 0
  %_53 = load i64, i64* %math2.bar_auf52
  %math2.simp_auf55 = getelementptr %struct.foo, %struct.foo* %math25, i1 0, i32 2
  %simple56 = load %struct.simple*, %struct.simple** %math2.simp_auf55
  %math2.simp.one_auf57 = getelementptr %struct.simple, %struct.simple* %simple56, i1 0, i32 0
  %_58 = load i64, i64* %math2.simp.one_auf57
  %math1.bar_auf59 = getelementptr %struct.foo, %struct.foo* %math11, i1 0, i32 0
  %_60 = load i64, i64* %math1.bar_auf59
  %tmp61 = call i64 (i64, i64) @add(i64 %_58, i64 %_60)
  %math2.bar_auf62 = getelementptr %struct.foo, %struct.foo* %math25, i1 0, i32 0
  %_63 = load i64, i64* %math2.bar_auf62
  %math1.bar_auf64 = getelementptr %struct.foo, %struct.foo* %math11, i1 0, i32 0
  %_65 = load i64, i64* %math1.bar_auf64
  %num68 = sub i64 %num8, 1
  br label %while.cond23
while.cond23:
  %_71 = icmp sgt i64 %num68, 0
  br i1 %_71, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %math12 = phi %struct.foo* [ %math110, %while.cond11 ], [ %math11, %while.cond23 ]
  %math26 = phi %struct.foo* [ %math216, %while.cond11 ], [ %math25, %while.cond23 ]
  %math1.simp_auf74 = getelementptr %struct.foo, %struct.foo* %math12, i1 0, i32 2
  %_75 = load %struct.simple*, %struct.simple** %math1.simp_auf74
  %_76 = bitcast %struct.simple* %_75 to i8*
  call void (i8*) @free(i8* %_76)
  %math2.simp_auf78 = getelementptr %struct.foo, %struct.foo* %math26, i1 0, i32 2
  %_79 = load %struct.simple*, %struct.simple** %math2.simp_auf78
  %_80 = bitcast %struct.simple* %_79 to i8*
  call void (i8*) @free(i8* %_80)
  %_82 = bitcast %struct.foo* %math12 to i8*
  call void (i8*) @free(i8* %_82)
  %_84 = bitcast %struct.foo* %math26 to i8*
  call void (i8*) @free(i8* %_84)
  br label %exit
exit:
  ret void
}

define void @objinstantiation(i64 %num) {
entry:
  %tmp21 = alloca %struct.foo*
  %tmp22 = load %struct.foo*, %struct.foo** %tmp21
  br label %while.cond11
while.cond11:
  %_7 = icmp sgt i64 %num, 0
  br i1 %_7, label %while.body2, label %while.exit5
while.body2:
  %num4 = phi i64 [ %num, %while.cond11 ], [ %num14, %while.fillback4 ]
  %foo.malloc9 = call i8* (i32) @malloc(i32 24)
  %tmp10 = bitcast i8* %foo.malloc9 to %struct.foo*
  %_11 = bitcast %struct.foo* %tmp10 to i8*
  call void (i8*) @free(i8* %_11)
  %num14 = sub i64 %num4, 1
  br label %while.cond23
while.cond23:
  %_17 = icmp sgt i64 %num14, 0
  br i1 %_17, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  br label %exit
exit:
  ret void
}

define i64 @ackermann(i64 %m, i64 %n) {
entry:
  br label %if.cond1
if.cond1:
  %_6 = icmp eq i64 %m, 0
  br i1 %_6, label %then.body2, label %if.cond4
then.body2:
  %tmp.binop9 = add i64 %n, 1
  br label %exit
if.cond4:
  %_14 = icmp eq i64 %n, 0
  br i1 %_14, label %then.body5, label %else.body6
then.body5:
  %tmp.binop17 = sub i64 %m, 1
  %aufrufen_ackermann19 = call i64 (i64, i64) @ackermann(i64 %tmp.binop17, i64 1)
  br label %exit
else.body6:
  %tmp.binop22 = sub i64 %m, 1
  %tmp.binop24 = sub i64 %n, 1
  %aufrufen_ackermann25 = call i64 (i64, i64) @ackermann(i64 %m, i64 %tmp.binop24)
  %aufrufen_ackermann26 = call i64 (i64, i64) @ackermann(i64 %tmp.binop22, i64 %aufrufen_ackermann25)
  br label %exit
exit:
  %return_reg10 = phi i64 [ %tmp.binop9, %then.body2 ], [ %aufrufen_ackermann19, %then.body5 ], [ %aufrufen_ackermann26, %else.body6 ]
  ret i64 %return_reg10
}

define i64 @main() {
entry:
  br label %body0
body0:
  %_2 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_3 = call i32 (i8*, ...) @scanf(i8* %_2, i32* @.read_scratch)
  %_4 = load i32, i32* @.read_scratch
  %a5 = sext i32 %_4 to i64
  %_6 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_7 = call i32 (i8*, ...) @scanf(i8* %_6, i32* @.read_scratch)
  %_8 = load i32, i32* @.read_scratch
  %b9 = sext i32 %_8 to i64
  %_10 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_11 = call i32 (i8*, ...) @scanf(i8* %_10, i32* @.read_scratch)
  %_12 = load i32, i32* @.read_scratch
  %c13 = sext i32 %_12 to i64
  %_14 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_15 = call i32 (i8*, ...) @scanf(i8* %_14, i32* @.read_scratch)
  %_16 = load i32, i32* @.read_scratch
  %d17 = sext i32 %_16 to i64
  %_18 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_19 = call i32 (i8*, ...) @scanf(i8* %_18, i32* @.read_scratch)
  %_20 = load i32, i32* @.read_scratch
  %e21 = sext i32 %_20 to i64
  call void (i64) @tailrecursive(i64 %a5)
  %_23 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_24 = call i32 (i8*, ...) @printf(i8* %_23, i64 %a5)
  call void (i64) @domath(i64 %b9)
  %_26 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_27 = call i32 (i8*, ...) @printf(i8* %_26, i64 %b9)
  call void (i64) @objinstantiation(i64 %c13)
  %_29 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_30 = call i32 (i8*, ...) @printf(i8* %_29, i64 %c13)
  %aufrufen_ackermann31 = call i64 (i64, i64) @ackermann(i64 %d17, i64 %e21)
  %_32 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_33 = call i32 (i8*, ...) @printf(i8* %_32, i64 %aufrufen_ackermann31)
  br label %exit
exit:
  ret i64 0
}

