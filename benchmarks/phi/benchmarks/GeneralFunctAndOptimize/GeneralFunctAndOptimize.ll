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
  br label %body0
body0:
  br label %if.cond1
if.cond1:
  %imm_store6 = add i64 0, 0
  %_7 = icmp sle i64 %timesLeft, %imm_store6
  br i1 %_7, label %then.body2, label %if.exit3
then.body2:
  %num.num_auf9 = getelementptr %struct.IntHolder, %struct.IntHolder* %num, i1 0, i32 0
  %_10 = load i64, i64* %num.num_auf9
  br label %exit
if.exit3:
  %imm_store13 = add i64 4, 0
  %num.num_auf14 = getelementptr %struct.IntHolder, %struct.IntHolder* %num, i1 0, i32 0
  %_15 = load i64, i64* %num.num_auf14
  %tmp.binop16 = mul i64 %imm_store13, %_15
  %num.num_auf17 = getelementptr %struct.IntHolder, %struct.IntHolder* %num, i1 0, i32 0
  store i64 %tmp.binop16, i64* %num.num_auf17
  %imm_store19 = add i64 1, 0
  %tmp.binop20 = sub i64 %timesLeft, %imm_store19
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
  %imm_store3 = add i64 2, 0
  %tmp.binop4 = sdiv i64 %_2, %imm_store3
  %num.num_auf5 = getelementptr %struct.IntHolder, %struct.IntHolder* %num, i1 0, i32 0
  store i64 %tmp.binop4, i64* %num.num_auf5
  %num.num_auf7 = getelementptr %struct.IntHolder, %struct.IntHolder* %num, i1 0, i32 0
  %_8 = load i64, i64* %num.num_auf7
  %imm_store9 = add i64 2, 0
  %tmp.binop10 = sdiv i64 %_8, %imm_store9
  %num.num_auf11 = getelementptr %struct.IntHolder, %struct.IntHolder* %num, i1 0, i32 0
  store i64 %tmp.binop10, i64* %num.num_auf11
  %num.num_auf13 = getelementptr %struct.IntHolder, %struct.IntHolder* %num, i1 0, i32 0
  %_14 = load i64, i64* %num.num_auf13
  %imm_store15 = add i64 2, 0
  %tmp.binop16 = sdiv i64 %_14, %imm_store15
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
  %imm_store31 = add i64 1000000, 0
  store i64 %imm_store31, i64* @end
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
  %countOuter47 = add i64 0, 0
  %countInner48 = add i64 0, 0
  %calc49 = add i64 0, 0
  br label %while.cond11
while.cond11:
  %imm_store51 = add i64 50, 0
  %_52 = icmp slt i64 %countOuter47, %imm_store51
  br i1 %_52, label %while.body2, label %while.exit14
while.body2:
  %countInner3 = phi i64 [ %countInner48, %while.cond11 ], [ %countInner0, %while.fillback13 ]
  %tempAnswer7 = phi i64 [ %tempAnswer122, %while.cond11 ], [ %tempAnswer5, %while.fillback13 ]
  %countOuter8 = phi i64 [ %countOuter47, %while.cond11 ], [ %countOuter108, %while.fillback13 ]
  %calc10 = phi i64 [ %calc49, %while.cond11 ], [ %calc13, %while.fillback13 ]
  %tempInterval17 = phi i64 [ %tempInterval124, %while.cond11 ], [ %tempInterval15, %while.fillback13 ]
  %x22 = phi %struct.IntHolder* [ %x30, %while.cond11 ], [ %x20, %while.fillback13 ]
  %uselessVar26 = phi i1 [ %uselessVar126, %while.cond11 ], [ %uselessVar24, %while.fillback13 ]
  %countInner54 = add i64 0, 0
  br label %while.cond13
while.cond13:
  %load_global56 = load i64, i64* @end
  %_57 = icmp sle i64 %countInner54, %load_global56
  br i1 %_57, label %while.body4, label %while.exit11
while.body4:
  %countInner1 = phi i64 [ %countInner54, %while.cond13 ], [ %countInner101, %while.fillback10 ]
  %tempAnswer4 = phi i64 [ %tempAnswer7, %while.cond13 ], [ %tempAnswer85, %while.fillback10 ]
  %calc12 = phi i64 [ %calc10, %while.cond13 ], [ %calc79, %while.fillback10 ]
  %tempInterval14 = phi i64 [ %tempInterval17, %while.cond13 ], [ %tempInterval18, %while.fillback10 ]
  %x19 = phi %struct.IntHolder* [ %x22, %while.cond13 ], [ %x19, %while.fillback10 ]
  %uselessVar23 = phi i1 [ %uselessVar26, %while.cond13 ], [ %uselessVar93, %while.fillback10 ]
  %imm_store59 = add i64 1, 0
  %imm_store60 = add i64 2, 0
  %tmp.binop61 = mul i64 %imm_store59, %imm_store60
  %imm_store62 = add i64 3, 0
  %tmp.binop63 = mul i64 %tmp.binop61, %imm_store62
  %imm_store64 = add i64 4, 0
  %tmp.binop65 = mul i64 %tmp.binop63, %imm_store64
  %imm_store66 = add i64 5, 0
  %tmp.binop67 = mul i64 %tmp.binop65, %imm_store66
  %imm_store68 = add i64 6, 0
  %tmp.binop69 = mul i64 %tmp.binop67, %imm_store68
  %imm_store70 = add i64 7, 0
  %tmp.binop71 = mul i64 %tmp.binop69, %imm_store70
  %imm_store72 = add i64 8, 0
  %tmp.binop73 = mul i64 %tmp.binop71, %imm_store72
  %imm_store74 = add i64 9, 0
  %tmp.binop75 = mul i64 %tmp.binop73, %imm_store74
  %imm_store76 = add i64 10, 0
  %tmp.binop77 = mul i64 %tmp.binop75, %imm_store76
  %imm_store78 = add i64 11, 0
  %calc79 = mul i64 %tmp.binop77, %imm_store78
  %imm_store80 = add i64 1, 0
  %countInner81 = add i64 %countInner1, %imm_store80
  %x.num_auf82 = getelementptr %struct.IntHolder, %struct.IntHolder* %x19, i1 0, i32 0
  store i64 %countInner81, i64* %x.num_auf82
  %x.num_auf84 = getelementptr %struct.IntHolder, %struct.IntHolder* %x19, i1 0, i32 0
  %tempAnswer85 = load i64, i64* %x.num_auf84
  %imm_store86 = add i64 2, 0
  %aufrufen_multBy4xTimes87 = call i64 (%struct.IntHolder*, i64) @multBy4xTimes(%struct.IntHolder* %x19, i64 %imm_store86)
  call void (%struct.IntHolder*) @divideBy8(%struct.IntHolder* %x19)
  %load_global89 = load i64, i64* @interval
  %imm_store90 = add i64 1, 0
  %tempInterval91 = sub i64 %load_global89, %imm_store90
  %imm_store92 = add i64 0, 0
  %uselessVar93 = icmp sle i64 %tempInterval91, %imm_store92
  br label %if.cond5
if.cond5:
  %imm_store95 = add i64 0, 0
  %_96 = icmp sle i64 %tempInterval91, %imm_store95
  br i1 %_96, label %then.body6, label %if.exit8
then.body6:
  %tempInterval98 = add i64 1, 0
  br label %then.exit7
then.exit7:
  br label %if.exit8
if.exit8:
  %tempInterval18 = phi i64 [ %tempInterval91, %if.cond5 ], [ %tempInterval98, %then.exit7 ]
  %countInner101 = add i64 %countInner81, %tempInterval18
  br label %while.cond29
while.cond29:
  %load_global103 = load i64, i64* @end
  %_104 = icmp sle i64 %countInner101, %load_global103
  br i1 %_104, label %while.fillback10, label %while.exit11
while.fillback10:
  br label %while.body4
while.exit11:
  %countInner0 = phi i64 [ %countInner54, %while.cond13 ], [ %countInner101, %while.cond29 ]
  %tempAnswer5 = phi i64 [ %tempAnswer7, %while.cond13 ], [ %tempAnswer85, %while.cond29 ]
  %calc13 = phi i64 [ %calc10, %while.cond13 ], [ %calc79, %while.cond29 ]
  %tempInterval15 = phi i64 [ %tempInterval17, %while.cond13 ], [ %tempInterval18, %while.cond29 ]
  %x20 = phi %struct.IntHolder* [ %x22, %while.cond13 ], [ %x19, %while.cond29 ]
  %uselessVar24 = phi i1 [ %uselessVar26, %while.cond13 ], [ %uselessVar93, %while.cond29 ]
  %imm_store107 = add i64 1, 0
  %countOuter108 = add i64 %countOuter8, %imm_store107
  br label %while.cond212
while.cond212:
  %imm_store110 = add i64 50, 0
  %_111 = icmp slt i64 %countOuter108, %imm_store110
  br i1 %_111, label %while.fillback13, label %while.exit14
while.fillback13:
  br label %while.body2
while.exit14:
  %countInner2 = phi i64 [ %countInner48, %while.cond11 ], [ %countInner0, %while.cond212 ]
  %tempAnswer6 = phi i64 [ %tempAnswer122, %while.cond11 ], [ %tempAnswer5, %while.cond212 ]
  %countOuter9 = phi i64 [ %countOuter47, %while.cond11 ], [ %countOuter108, %while.cond212 ]
  %calc11 = phi i64 [ %calc49, %while.cond11 ], [ %calc13, %while.cond212 ]
  %tempInterval16 = phi i64 [ %tempInterval124, %while.cond11 ], [ %tempInterval15, %while.cond212 ]
  %x21 = phi %struct.IntHolder* [ %x30, %while.cond11 ], [ %x20, %while.cond212 ]
  %uselessVar25 = phi i1 [ %uselessVar126, %while.cond11 ], [ %uselessVar24, %while.cond212 ]
  %_114 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_115 = call i32 (i8*, ...) @printf(i8* %_114, i64 %countInner2)
  %_116 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_117 = call i32 (i8*, ...) @printf(i8* %_116, i64 %calc11)
  %imm_store118 = add i64 0, 0
  br label %exit
exit:
  %return_reg119 = phi i64 [ %imm_store118, %while.exit14 ]
  ret i64 %return_reg119
}

