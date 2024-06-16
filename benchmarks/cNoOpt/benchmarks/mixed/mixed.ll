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
  %num0 = alloca i64
  store i64 %num, i64* %num0
  br label %body1
body1:
  %num3 = load i64, i64* %num0
  %num4 = icmp sle i64 %num3, 0
  br i1 %num4, label %if.then2, label %if.end3
if.then2:
  br label %exit
if.end3:
  %num7 = load i64, i64* %num0
  %num8 = sub i64 %num7, 1
  call void (i64) @tailrecursive(i64 %num8)
  br label %exit
exit:
  ret void
}

define i64 @add(i64 %x, i64 %y) {
entry:
  %_0 = alloca i64
  %x1 = alloca i64
  store i64 %x, i64* %x1
  %y3 = alloca i64
  store i64 %y, i64* %y3
  br label %body1
body1:
  %x6 = load i64, i64* %x1
  %y7 = load i64, i64* %y3
  %_8 = add i64 %x6, %y7
  store i64 %_8, i64* %_0
  br label %exit
exit:
  %_11 = load i64, i64* %_0
  ret i64 %_11
}

define void @domath(i64 %num) {
entry:
  %math10 = alloca %struct.foo*
  %math21 = alloca %struct.foo*
  %tmp2 = alloca i64
  %num3 = alloca i64
  store i64 %num, i64* %num3
  br label %body1
body1:
  %foo6 = call i8* (i32) @malloc(i32 24)
  %foo7 = bitcast i8* %foo6 to %struct.foo*
  store %struct.foo* %foo7, %struct.foo** %math10
  %math19 = load %struct.foo*, %struct.foo** %math10
  %simp10 = getelementptr %struct.foo, %struct.foo* %math19, i1 0, i32 2
  %simple11 = call i8* (i32) @malloc(i32 8)
  %simple12 = bitcast i8* %simple11 to %struct.simple*
  store %struct.simple* %simple12, %struct.simple** %simp10
  %foo14 = call i8* (i32) @malloc(i32 24)
  %foo15 = bitcast i8* %foo14 to %struct.foo*
  store %struct.foo* %foo15, %struct.foo** %math21
  %math217 = load %struct.foo*, %struct.foo** %math21
  %simp18 = getelementptr %struct.foo, %struct.foo* %math217, i1 0, i32 2
  %simple19 = call i8* (i32) @malloc(i32 8)
  %simple20 = bitcast i8* %simple19 to %struct.simple*
  store %struct.simple* %simple20, %struct.simple** %simp18
  %math122 = load %struct.foo*, %struct.foo** %math10
  %bar23 = getelementptr %struct.foo, %struct.foo* %math122, i1 0, i32 0
  %num24 = load i64, i64* %num3
  store i64 %num24, i64* %bar23
  %math226 = load %struct.foo*, %struct.foo** %math21
  %bar27 = getelementptr %struct.foo, %struct.foo* %math226, i1 0, i32 0
  store i64 3, i64* %bar27
  %math129 = load %struct.foo*, %struct.foo** %math10
  %simp30 = getelementptr %struct.foo, %struct.foo* %math129, i1 0, i32 2
  %simple31 = load %struct.simple*, %struct.simple** %simp30
  %one32 = getelementptr %struct.simple, %struct.simple* %simple31, i1 0, i32 0
  %math133 = load %struct.foo*, %struct.foo** %math10
  %bar34 = getelementptr %struct.foo, %struct.foo* %math133, i1 0, i32 0
  %bar35 = load i64, i64* %bar34
  store i64 %bar35, i64* %one32
  %math237 = load %struct.foo*, %struct.foo** %math21
  %simp38 = getelementptr %struct.foo, %struct.foo* %math237, i1 0, i32 2
  %simple39 = load %struct.simple*, %struct.simple** %simp38
  %one40 = getelementptr %struct.simple, %struct.simple* %simple39, i1 0, i32 0
  %math241 = load %struct.foo*, %struct.foo** %math21
  %bar42 = getelementptr %struct.foo, %struct.foo* %math241, i1 0, i32 0
  %bar43 = load i64, i64* %bar42
  store i64 %bar43, i64* %one40
  %num45 = load i64, i64* %num3
  %num46 = icmp sgt i64 %num45, 0
  br i1 %num46, label %while.body2, label %while.end3
while.body2:
  %math147 = load %struct.foo*, %struct.foo** %math10
  %bar48 = getelementptr %struct.foo, %struct.foo* %math147, i1 0, i32 0
  %bar49 = load i64, i64* %bar48
  %math250 = load %struct.foo*, %struct.foo** %math21
  %bar51 = getelementptr %struct.foo, %struct.foo* %math250, i1 0, i32 0
  %bar52 = load i64, i64* %bar51
  %_53 = mul i64 %bar49, %bar52
  store i64 %_53, i64* %tmp2
  %tmp55 = load i64, i64* %tmp2
  %math156 = load %struct.foo*, %struct.foo** %math10
  %simp57 = getelementptr %struct.foo, %struct.foo* %math156, i1 0, i32 2
  %simple58 = load %struct.simple*, %struct.simple** %simp57
  %one59 = getelementptr %struct.simple, %struct.simple* %simple58, i1 0, i32 0
  %one60 = load i64, i64* %one59
  %_61 = mul i64 %tmp55, %one60
  %math262 = load %struct.foo*, %struct.foo** %math21
  %bar63 = getelementptr %struct.foo, %struct.foo* %math262, i1 0, i32 0
  %bar64 = load i64, i64* %bar63
  %bar65 = sdiv i64 %_61, %bar64
  store i64 %bar65, i64* %tmp2
  %math267 = load %struct.foo*, %struct.foo** %math21
  %simp68 = getelementptr %struct.foo, %struct.foo* %math267, i1 0, i32 2
  %simple69 = load %struct.simple*, %struct.simple** %simp68
  %one70 = getelementptr %struct.simple, %struct.simple* %simple69, i1 0, i32 0
  %one71 = load i64, i64* %one70
  %math172 = load %struct.foo*, %struct.foo** %math10
  %bar73 = getelementptr %struct.foo, %struct.foo* %math172, i1 0, i32 0
  %bar74 = load i64, i64* %bar73
  %add75 = call i64 (i64, i64) @add(i64 %one71, i64 %bar74)
  store i64 %add75, i64* %tmp2
  %math277 = load %struct.foo*, %struct.foo** %math21
  %bar78 = getelementptr %struct.foo, %struct.foo* %math277, i1 0, i32 0
  %bar79 = load i64, i64* %bar78
  %math180 = load %struct.foo*, %struct.foo** %math10
  %bar81 = getelementptr %struct.foo, %struct.foo* %math180, i1 0, i32 0
  %bar82 = load i64, i64* %bar81
  %_83 = sub i64 %bar79, %bar82
  store i64 %_83, i64* %tmp2
  %num85 = load i64, i64* %num3
  %num86 = sub i64 %num85, 1
  store i64 %num86, i64* %num3
  %num88 = load i64, i64* %num3
  %num89 = icmp sgt i64 %num88, 0
  br i1 %num89, label %while.body2, label %while.end3
while.end3:
  %math192 = load %struct.foo*, %struct.foo** %math10
  %simp93 = getelementptr %struct.foo, %struct.foo* %math192, i1 0, i32 2
  %simp94 = load %struct.simple*, %struct.simple** %simp93
  %_95 = bitcast %struct.simple* %simp94 to i8*
  call void (i8*) @free(i8* %_95)
  %math297 = load %struct.foo*, %struct.foo** %math21
  %simp98 = getelementptr %struct.foo, %struct.foo* %math297, i1 0, i32 2
  %simp99 = load %struct.simple*, %struct.simple** %simp98
  %_100 = bitcast %struct.simple* %simp99 to i8*
  call void (i8*) @free(i8* %_100)
  %math1102 = load %struct.foo*, %struct.foo** %math10
  %_103 = bitcast %struct.foo* %math1102 to i8*
  call void (i8*) @free(i8* %_103)
  %math2105 = load %struct.foo*, %struct.foo** %math21
  %_106 = bitcast %struct.foo* %math2105 to i8*
  call void (i8*) @free(i8* %_106)
  br label %exit
exit:
  ret void
}

define void @objinstantiation(i64 %num) {
entry:
  %tmp0 = alloca %struct.foo*
  %num1 = alloca i64
  store i64 %num, i64* %num1
  br label %body1
body1:
  %num4 = load i64, i64* %num1
  %num5 = icmp sgt i64 %num4, 0
  br i1 %num5, label %while.body2, label %while.end3
while.body2:
  %foo6 = call i8* (i32) @malloc(i32 24)
  %foo7 = bitcast i8* %foo6 to %struct.foo*
  store %struct.foo* %foo7, %struct.foo** %tmp0
  %tmp9 = load %struct.foo*, %struct.foo** %tmp0
  %_10 = bitcast %struct.foo* %tmp9 to i8*
  call void (i8*) @free(i8* %_10)
  %num12 = load i64, i64* %num1
  %num13 = sub i64 %num12, 1
  store i64 %num13, i64* %num1
  %num15 = load i64, i64* %num1
  %num16 = icmp sgt i64 %num15, 0
  br i1 %num16, label %while.body2, label %while.end3
while.end3:
  br label %exit
exit:
  ret void
}

define i64 @ackermann(i64 %m, i64 %n) {
entry:
  %_0 = alloca i64
  %m1 = alloca i64
  store i64 %m, i64* %m1
  %n3 = alloca i64
  store i64 %n, i64* %n3
  br label %body1
body1:
  %m6 = load i64, i64* %m1
  %m7 = icmp eq i64 %m6, 0
  br i1 %m7, label %if.then2, label %if.end3
if.then2:
  %n8 = load i64, i64* %n3
  %n9 = add i64 %n8, 1
  store i64 %n9, i64* %_0
  br label %exit
if.end3:
  %n13 = load i64, i64* %n3
  %n14 = icmp eq i64 %n13, 0
  br i1 %n14, label %if.then4, label %if.else5
if.then4:
  %m15 = load i64, i64* %m1
  %m16 = sub i64 %m15, 1
  %ackermann17 = call i64 (i64, i64) @ackermann(i64 %m16, i64 1)
  store i64 %ackermann17, i64* %_0
  br label %exit
if.else5:
  %m20 = load i64, i64* %m1
  %m21 = sub i64 %m20, 1
  %m22 = load i64, i64* %m1
  %n23 = load i64, i64* %n3
  %n24 = sub i64 %n23, 1
  %ackermann25 = call i64 (i64, i64) @ackermann(i64 %m22, i64 %n24)
  %ackermann26 = call i64 (i64, i64) @ackermann(i64 %m21, i64 %ackermann25)
  store i64 %ackermann26, i64* %_0
  br label %exit
if.end6:
  br label %exit
exit:
  %_31 = load i64, i64* %_0
  ret i64 %_31
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %a1 = alloca i64
  %b2 = alloca i64
  %c3 = alloca i64
  %d4 = alloca i64
  %e5 = alloca i64
  br label %body1
body1:
  %_7 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_8 = call i32 (i8*, ...) @scanf(i8* %_7, i32* @.read_scratch)
  %_9 = load i32, i32* @.read_scratch
  %_10 = sext i32 %_9 to i64
  store i64 %_10, i64* %a1
  %_12 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_13 = call i32 (i8*, ...) @scanf(i8* %_12, i32* @.read_scratch)
  %_14 = load i32, i32* @.read_scratch
  %_15 = sext i32 %_14 to i64
  store i64 %_15, i64* %b2
  %_17 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_18 = call i32 (i8*, ...) @scanf(i8* %_17, i32* @.read_scratch)
  %_19 = load i32, i32* @.read_scratch
  %_20 = sext i32 %_19 to i64
  store i64 %_20, i64* %c3
  %_22 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_23 = call i32 (i8*, ...) @scanf(i8* %_22, i32* @.read_scratch)
  %_24 = load i32, i32* @.read_scratch
  %_25 = sext i32 %_24 to i64
  store i64 %_25, i64* %d4
  %_27 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_28 = call i32 (i8*, ...) @scanf(i8* %_27, i32* @.read_scratch)
  %_29 = load i32, i32* @.read_scratch
  %_30 = sext i32 %_29 to i64
  store i64 %_30, i64* %e5
  %a32 = load i64, i64* %a1
  call void (i64) @tailrecursive(i64 %a32)
  %a34 = load i64, i64* %a1
  %_35 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_36 = call i32 (i8*, ...) @printf(i8* %_35, i64 %a34)
  %b37 = load i64, i64* %b2
  call void (i64) @domath(i64 %b37)
  %b39 = load i64, i64* %b2
  %_40 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_41 = call i32 (i8*, ...) @printf(i8* %_40, i64 %b39)
  %c42 = load i64, i64* %c3
  call void (i64) @objinstantiation(i64 %c42)
  %c44 = load i64, i64* %c3
  %_45 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_46 = call i32 (i8*, ...) @printf(i8* %_45, i64 %c44)
  %d47 = load i64, i64* %d4
  %e48 = load i64, i64* %e5
  %ackermann49 = call i64 (i64, i64) @ackermann(i64 %d47, i64 %e48)
  %_50 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_51 = call i32 (i8*, ...) @printf(i8* %_50, i64 %ackermann49)
  store i64 0, i64* %_0
  br label %exit
exit:
  %_54 = load i64, i64* %_0
  ret i64 %_54
}

