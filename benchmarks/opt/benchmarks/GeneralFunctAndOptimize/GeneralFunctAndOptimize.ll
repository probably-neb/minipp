%struct.IntHolder = type { i64 }

declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

@interval = global i64 undef, align 8
@end = global i64 undef, align 8

define i64 @multBy4xTimes(%struct.IntHolder* %num, i64 %timesLeft) {
entry:
  br label %if.cond1
if.cond1:
  %_7 = icmp sle i64 %timesLeft, 0
  br i1 %_7, label %then.body2, label %if.exit3
then.body2:
  %num.num_auf9 = getelementptr %struct.IntHolder, %struct.IntHolder* %num, i1 0, i32 0
  %_10 = load i64, i64* %num.num_auf9
  br label %exit
if.exit3:
  %num.num_auf14 = getelementptr %struct.IntHolder, %struct.IntHolder* %num, i1 0, i32 0
  %_15 = load i64, i64* %num.num_auf14
  %tmp.binop16 = mul i64 4, %_15
  %num.num_auf17 = getelementptr %struct.IntHolder, %struct.IntHolder* %num, i1 0, i32 0
  store i64 %tmp.binop16, i64* %num.num_auf17
  %tmp.binop20 = sub i64 %timesLeft, 1
  %aufrufen_multBy4xTimes21 = call i64 (%struct.IntHolder*, i64) @multBy4xTimes(%struct.IntHolder* %num, i64 %tmp.binop20)
  %num.num_auf22 = getelementptr %struct.IntHolder, %struct.IntHolder* %num, i1 0, i32 0
  %_23 = load i64, i64* %num.num_auf22
  br label %exit
exit:
  %return_reg11 = phi i64 [ %_10, %then.body2 ], [ %_23, %if.exit3 ]
  ret i64 %return_reg11
}

define void @divideBy8(%struct.IntHolder* %num) {
entry:
  br label %body0
body0:
  %num.num_auf1 = getelementptr %struct.IntHolder, %struct.IntHolder* %num, i1 0, i32 0
  %_2 = load i64, i64* %num.num_auf1
  %tmp.binop4 = sdiv i64 %_2, 2
  %num.num_auf5 = getelementptr %struct.IntHolder, %struct.IntHolder* %num, i1 0, i32 0
  store i64 %tmp.binop4, i64* %num.num_auf5
  %num.num_auf7 = getelementptr %struct.IntHolder, %struct.IntHolder* %num, i1 0, i32 0
  %_8 = load i64, i64* %num.num_auf7
  %tmp.binop10 = sdiv i64 %_8, 2
  %num.num_auf11 = getelementptr %struct.IntHolder, %struct.IntHolder* %num, i1 0, i32 0
  store i64 %tmp.binop10, i64* %num.num_auf11
  %num.num_auf13 = getelementptr %struct.IntHolder, %struct.IntHolder* %num, i1 0, i32 0
  %_14 = load i64, i64* %num.num_auf13
  %tmp.binop16 = sdiv i64 %_14, 2
  %num.num_auf17 = getelementptr %struct.IntHolder, %struct.IntHolder* %num, i1 0, i32 0
  store i64 %tmp.binop16, i64* %num.num_auf17
  br label %exit
exit:
  ret void
}

define i64 @main() {
entry:
  %tempAnswer121 = alloca i64
  %tempAnswer122 = load i64, i64* %tempAnswer121
  %tempInterval123 = alloca i64
  %tempInterval124 = load i64, i64* %tempInterval123
  %uselessVar125 = alloca i1
  %uselessVar126 = load i1, i1* %uselessVar125
  br label %body0
body0:
  %IntHolder.malloc29 = call i8* (i32) @malloc(i32 8)
  %x30 = bitcast i8* %IntHolder.malloc29 to %struct.IntHolder*
  store i64 1000000, i64* @end
  %_33 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_34 = call i32 (i8*, ...) @scanf(i8* %_33, i32* @.read_scratch)
  %_35 = load i32, i32* @.read_scratch
  %start36 = sext i32 %_35 to i64
  %_37 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_38 = call i32 (i8*, ...) @scanf(i8* %_37, i32* @.read_scratch)
  %_39 = load i32, i32* @.read_scratch
  %_40 = sext i32 %_39 to i64
  store i64 %_40, i64* @interval
  %_42 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_43 = call i32 (i8*, ...) @printf(i8* %_42, i64 %start36)
  %load_global44 = load i64, i64* @interval
  %_45 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_46 = call i32 (i8*, ...) @printf(i8* %_45, i64 %load_global44)
  br label %while.cond11
while.cond11:
  br label %while.body2
while.body2:
  %countOuter8 = phi i64 [ 0, %while.cond11 ], [ %countOuter108, %while.fillback13 ]
  %calc10 = phi i64 [ 0, %while.cond11 ], [ %calc13, %while.fillback13 ]
  %x22 = phi %struct.IntHolder* [ %x30, %while.cond11 ], [ %x20, %while.fillback13 ]
  br label %while.cond13
while.cond13:
  %load_global56 = load i64, i64* @end
  %_57 = icmp sle i64 0, %load_global56
  br i1 %_57, label %while.body4, label %while.exit11
while.body4:
  %countInner1 = phi i64 [ 0, %while.cond13 ], [ %countInner101, %while.fillback10 ]
  %x19 = phi %struct.IntHolder* [ %x22, %while.cond13 ], [ %x19, %while.fillback10 ]
  %countInner81 = add i64 %countInner1, 1
  %x.num_auf82 = getelementptr %struct.IntHolder, %struct.IntHolder* %x19, i1 0, i32 0
  store i64 %countInner81, i64* %x.num_auf82
  %x.num_auf84 = getelementptr %struct.IntHolder, %struct.IntHolder* %x19, i1 0, i32 0
  %tempAnswer85 = load i64, i64* %x.num_auf84
  %aufrufen_multBy4xTimes87 = call i64 (%struct.IntHolder*, i64) @multBy4xTimes(%struct.IntHolder* %x19, i64 2)
  call void (%struct.IntHolder*) @divideBy8(%struct.IntHolder* %x19)
  %load_global89 = load i64, i64* @interval
  %tempInterval91 = sub i64 %load_global89, 1
  br label %if.cond5
if.cond5:
  %_96 = icmp sle i64 %tempInterval91, 0
  br i1 %_96, label %then.exit7, label %if.exit8
then.exit7:
  br label %if.exit8
if.exit8:
  %tempInterval18 = phi i64 [ %tempInterval91, %if.cond5 ], [ 1, %then.exit7 ]
  %countInner101 = add i64 %countInner81, %tempInterval18
  br label %while.cond29
while.cond29:
  %load_global103 = load i64, i64* @end
  %_104 = icmp sle i64 %countInner101, %load_global103
  br i1 %_104, label %while.fillback10, label %while.exit11
while.fillback10:
  br label %while.body4
while.exit11:
  %countInner0 = phi i64 [ 0, %while.cond13 ], [ %countInner101, %while.cond29 ]
  %calc13 = phi i64 [ %calc10, %while.cond13 ], [ 39916800, %while.cond29 ]
  %x20 = phi %struct.IntHolder* [ %x22, %while.cond13 ], [ %x19, %while.cond29 ]
  %countOuter108 = add i64 %countOuter8, 1
  br label %while.cond212
while.cond212:
  %_111 = icmp slt i64 %countOuter108, 50
  br i1 %_111, label %while.fillback13, label %while.exit14
while.fillback13:
  br label %while.body2
while.exit14:
  %_114 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_115 = call i32 (i8*, ...) @printf(i8* %_114, i64 %countInner0)
  %_116 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_117 = call i32 (i8*, ...) @printf(i8* %_116, i64 %calc13)
  br label %exit
exit:
  ret i64 0
}

