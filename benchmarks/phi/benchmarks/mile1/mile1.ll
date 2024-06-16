%struct.Power = type { i64, i64 }

declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

define i64 @calcPower(i64 %base, i64 %exp) {
entry:
  br label %body0
body0:
  %result10 = add i64 1, 0
  br label %while.cond11
while.cond11:
  %imm_store12 = add i64 0, 0
  %_13 = icmp sgt i64 %exp, %imm_store12
  br i1 %_13, label %while.body2, label %while.exit5
while.body2:
  %result2 = phi i64 [ %result10, %while.cond11 ], [ %result15, %while.fillback4 ]
  %base4 = phi i64 [ %base, %while.cond11 ], [ %base4, %while.fillback4 ]
  %exp7 = phi i64 [ %exp, %while.cond11 ], [ %exp17, %while.fillback4 ]
  %result15 = mul i64 %result2, %base4
  %imm_store16 = add i64 1, 0
  %exp17 = sub i64 %exp7, %imm_store16
  br label %while.cond23
while.cond23:
  %imm_store19 = add i64 0, 0
  %_20 = icmp sgt i64 %exp17, %imm_store19
  br i1 %_20, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %result3 = phi i64 [ %result10, %while.cond11 ], [ %result15, %while.cond23 ]
  %base5 = phi i64 [ %base, %while.cond11 ], [ %base4, %while.cond23 ]
  %exp6 = phi i64 [ %exp, %while.cond11 ], [ %exp17, %while.cond23 ]
  br label %exit
exit:
  %return_reg23 = phi i64 [ %result3, %while.exit5 ]
  ret i64 %return_reg23
}

define i64 @main() {
entry:
  br label %body0
body0:
  %result11 = add i64 0, 0
  %Power.malloc12 = call i8* (i32) @malloc(i32 16)
  %power13 = bitcast i8* %Power.malloc12 to %struct.Power*
  %_14 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_15 = call i32 (i8*, ...) @scanf(i8* %_14, i32* @.read_scratch)
  %_16 = load i32, i32* @.read_scratch
  %input17 = sext i32 %_16 to i64
  %power.base_auf18 = getelementptr %struct.Power, %struct.Power* %power13, i1 0, i32 0
  store i64 %input17, i64* %power.base_auf18
  %_20 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_21 = call i32 (i8*, ...) @scanf(i8* %_20, i32* @.read_scratch)
  %_22 = load i32, i32* @.read_scratch
  %input23 = sext i32 %_22 to i64
  br label %if.cond1
if.cond1:
  %imm_store25 = add i64 0, 0
  %_26 = icmp slt i64 %input23, %imm_store25
  br i1 %_26, label %then.body2, label %if.exit3
then.body2:
  %imm_store28 = add i64 1, 0
  %tmp.unop29 = sub i64 0, %imm_store28
  br label %exit
if.exit3:
  %power.exp_auf32 = getelementptr %struct.Power, %struct.Power* %power13, i1 0, i32 1
  store i64 %input23, i64* %power.exp_auf32
  %i34 = add i64 0, 0
  br label %while.cond14
while.cond14:
  %imm_store36 = add i64 1000000, 0
  %_37 = icmp slt i64 %i34, %imm_store36
  br i1 %_37, label %while.body5, label %while.exit8
while.body5:
  %power0 = phi %struct.Power* [ %power13, %while.cond14 ], [ %power0, %while.fillback7 ]
  %i4 = phi i64 [ %i34, %while.cond14 ], [ %i40, %while.fillback7 ]
  %result7 = phi i64 [ %result11, %while.cond14 ], [ %result45, %while.fillback7 ]
  %imm_store39 = add i64 1, 0
  %i40 = add i64 %i4, %imm_store39
  %power.base_auf41 = getelementptr %struct.Power, %struct.Power* %power0, i1 0, i32 0
  %_42 = load i64, i64* %power.base_auf41
  %power.exp_auf43 = getelementptr %struct.Power, %struct.Power* %power0, i1 0, i32 1
  %_44 = load i64, i64* %power.exp_auf43
  %result45 = call i64 (i64, i64) @calcPower(i64 %_42, i64 %_44)
  br label %while.cond26
while.cond26:
  %imm_store47 = add i64 1000000, 0
  %_48 = icmp slt i64 %i40, %imm_store47
  br i1 %_48, label %while.fillback7, label %while.exit8
while.fillback7:
  br label %while.body5
while.exit8:
  %power1 = phi %struct.Power* [ %power13, %while.cond14 ], [ %power0, %while.cond26 ]
  %i3 = phi i64 [ %i34, %while.cond14 ], [ %i40, %while.cond26 ]
  %result6 = phi i64 [ %result11, %while.cond14 ], [ %result45, %while.cond26 ]
  %_51 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_52 = call i32 (i8*, ...) @printf(i8* %_51, i64 %result6)
  %imm_store53 = add i64 0, 0
  br label %exit
exit:
  %return_reg30 = phi i64 [ %tmp.unop29, %then.body2 ], [ %imm_store53, %while.exit8 ]
  ret i64 %return_reg30
}

