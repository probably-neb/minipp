%struct.thing = type { i64, i1, %struct.thing* }

declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

@gi1 = global i64 undef, align 8
@gb1 = global i1 undef, align 8
@gs1 = global %struct.thing* undef, align 8
@counter = global i64 undef, align 8

define void @printgroup(i64 %groupnum) {
entry:
  br label %body0
body0:
  %imm_store1 = add i64 1, 0
  %_2 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_3 = call i32 (i8*, ...) @printf(i8* %_2, i64 %imm_store1)
  %imm_store4 = add i64 0, 0
  %_5 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_6 = call i32 (i8*, ...) @printf(i8* %_5, i64 %imm_store4)
  %imm_store7 = add i64 1, 0
  %_8 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_9 = call i32 (i8*, ...) @printf(i8* %_8, i64 %imm_store7)
  %imm_store10 = add i64 0, 0
  %_11 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_12 = call i32 (i8*, ...) @printf(i8* %_11, i64 %imm_store10)
  %imm_store13 = add i64 1, 0
  %_14 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_15 = call i32 (i8*, ...) @printf(i8* %_14, i64 %imm_store13)
  %imm_store16 = add i64 0, 0
  %_17 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_18 = call i32 (i8*, ...) @printf(i8* %_17, i64 %imm_store16)
  %_19 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_20 = call i32 (i8*, ...) @printf(i8* %_19, i64 %groupnum)
  br label %exit
exit:
  ret void
}

define i1 @setcounter(i64 %val) {
entry:
  br label %body0
body0:
  store i64 %val, i64* @counter
  %imm_true4 = or i1 1, 0
  br label %exit
exit:
  %return_reg5 = phi i1 [ %imm_true4, %body0 ]
  ret i1 %return_reg5
}

define void @takealltypes(i64 %i, i1 %b, %struct.thing* %s) {
entry:
  br label %body0
body0:
  br label %if.cond1
if.cond1:
  %imm_store4 = add i64 3, 0
  %_5 = icmp eq i64 %i, %imm_store4
  br i1 %_5, label %then.body2, label %else.body4
then.body2:
  %imm_store7 = add i64 1, 0
  %_8 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_9 = call i32 (i8*, ...) @printf(i8* %_8, i64 %imm_store7)
  br label %then.exit3
then.exit3:
  br label %if.exit6
else.body4:
  %imm_store12 = add i64 0, 0
  %_13 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_14 = call i32 (i8*, ...) @printf(i8* %_13, i64 %imm_store12)
  br label %else.exit5
else.exit5:
  br label %if.exit6
if.exit6:
  br label %if.cond7
if.cond7:
  br i1 %b, label %then.body8, label %else.body10
then.body8:
  %imm_store19 = add i64 1, 0
  %_20 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_21 = call i32 (i8*, ...) @printf(i8* %_20, i64 %imm_store19)
  br label %then.exit9
then.exit9:
  br label %if.exit12
else.body10:
  %imm_store24 = add i64 0, 0
  %_25 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_26 = call i32 (i8*, ...) @printf(i8* %_25, i64 %imm_store24)
  br label %else.exit11
else.exit11:
  br label %if.exit12
if.exit12:
  br label %if.cond13
if.cond13:
  %s.b_auf30 = getelementptr %struct.thing, %struct.thing* %s, i1 0, i32 1
  %_31 = load i1, i1* %s.b_auf30
  br i1 %_31, label %then.body14, label %else.body16
then.body14:
  %imm_store33 = add i64 1, 0
  %_34 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_35 = call i32 (i8*, ...) @printf(i8* %_34, i64 %imm_store33)
  br label %then.exit15
then.exit15:
  br label %if.exit18
else.body16:
  %imm_store38 = add i64 0, 0
  %_39 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_40 = call i32 (i8*, ...) @printf(i8* %_39, i64 %imm_store38)
  br label %else.exit17
else.exit17:
  br label %if.exit18
if.exit18:
  br label %exit
exit:
  ret void
}

define void @tonofargs(i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6, i64 %a7, i64 %a8) {
entry:
  br label %body0
body0:
  br label %if.cond1
if.cond1:
  %imm_store9 = add i64 5, 0
  %_10 = icmp eq i64 %a5, %imm_store9
  br i1 %_10, label %then.body2, label %else.body4
then.body2:
  %imm_store12 = add i64 1, 0
  %_13 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_14 = call i32 (i8*, ...) @printf(i8* %_13, i64 %imm_store12)
  br label %then.exit3
then.exit3:
  br label %if.exit6
else.body4:
  %imm_store17 = add i64 0, 0
  %_18 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_19 = call i32 (i8*, ...) @printf(i8* %_18, i64 %imm_store17)
  %_20 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_21 = call i32 (i8*, ...) @printf(i8* %_20, i64 %a5)
  br label %else.exit5
else.exit5:
  br label %if.exit6
if.exit6:
  br label %if.cond7
if.cond7:
  %imm_store25 = add i64 6, 0
  %_26 = icmp eq i64 %a6, %imm_store25
  br i1 %_26, label %then.body8, label %else.body10
then.body8:
  %imm_store28 = add i64 1, 0
  %_29 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_30 = call i32 (i8*, ...) @printf(i8* %_29, i64 %imm_store28)
  br label %then.exit9
then.exit9:
  br label %if.exit12
else.body10:
  %imm_store33 = add i64 0, 0
  %_34 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_35 = call i32 (i8*, ...) @printf(i8* %_34, i64 %imm_store33)
  %_36 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_37 = call i32 (i8*, ...) @printf(i8* %_36, i64 %a6)
  br label %else.exit11
else.exit11:
  br label %if.exit12
if.exit12:
  br label %if.cond13
if.cond13:
  %imm_store41 = add i64 7, 0
  %_42 = icmp eq i64 %a7, %imm_store41
  br i1 %_42, label %then.body14, label %else.body16
then.body14:
  %imm_store44 = add i64 1, 0
  %_45 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_46 = call i32 (i8*, ...) @printf(i8* %_45, i64 %imm_store44)
  br label %then.exit15
then.exit15:
  br label %if.exit18
else.body16:
  %imm_store49 = add i64 0, 0
  %_50 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_51 = call i32 (i8*, ...) @printf(i8* %_50, i64 %imm_store49)
  %_52 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_53 = call i32 (i8*, ...) @printf(i8* %_52, i64 %a7)
  br label %else.exit17
else.exit17:
  br label %if.exit18
if.exit18:
  br label %if.cond19
if.cond19:
  %imm_store57 = add i64 8, 0
  %_58 = icmp eq i64 %a8, %imm_store57
  br i1 %_58, label %then.body20, label %else.body22
then.body20:
  %imm_store60 = add i64 1, 0
  %_61 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_62 = call i32 (i8*, ...) @printf(i8* %_61, i64 %imm_store60)
  br label %then.exit21
then.exit21:
  br label %if.exit24
else.body22:
  %imm_store65 = add i64 0, 0
  %_66 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_67 = call i32 (i8*, ...) @printf(i8* %_66, i64 %imm_store65)
  %_68 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_69 = call i32 (i8*, ...) @printf(i8* %_68, i64 %a8)
  br label %else.exit23
else.exit23:
  br label %if.exit24
if.exit24:
  br label %exit
exit:
  ret void
}

define i64 @returnint(i64 %ret) {
entry:
  br label %body0
body0:
  br label %exit
exit:
  %return_reg3 = phi i64 [ %ret, %body0 ]
  ret i64 %return_reg3
}

define i1 @returnbool(i1 %ret) {
entry:
  br label %body0
body0:
  br label %exit
exit:
  %return_reg3 = phi i1 [ %ret, %body0 ]
  ret i1 %return_reg3
}

define %struct.thing* @returnstruct(%struct.thing* %ret) {
entry:
  br label %body0
body0:
  br label %exit
exit:
  %return_reg3 = phi %struct.thing* [ %ret, %body0 ]
  ret %struct.thing* %return_reg3
}

define i64 @main() {
entry:
  %return_reg2 = alloca i64
  %_3 = load i64, i64* %return_reg2
  br label %body0
body0:
  %imm_store4 = add i64 0, 0
  store i64 %imm_store4, i64* @counter
  %imm_store6 = add i64 1, 0
  call void (i64) @printgroup(i64 %imm_store6)
  %b18 = or i1 0, 0
  %b29 = or i1 0, 0
  br label %if.cond1
if.cond1:
  %_11 = and i1 %b18, %b29
  br i1 %_11, label %then.body2, label %else.body4
then.body2:
  %imm_store13 = add i64 0, 0
  %_14 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_15 = call i32 (i8*, ...) @printf(i8* %_14, i64 %imm_store13)
  br label %then.exit3
then.exit3:
  br label %if.exit6
else.body4:
  %imm_store18 = add i64 1, 0
  %_19 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_20 = call i32 (i8*, ...) @printf(i8* %_19, i64 %imm_store18)
  br label %else.exit5
else.exit5:
  br label %if.exit6
if.exit6:
  %b123 = or i1 1, 0
  %b224 = or i1 0, 0
  br label %if.cond7
if.cond7:
  %_26 = and i1 %b123, %b224
  br i1 %_26, label %then.body8, label %else.body10
then.body8:
  %imm_store28 = add i64 0, 0
  %_29 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_30 = call i32 (i8*, ...) @printf(i8* %_29, i64 %imm_store28)
  br label %then.exit9
then.exit9:
  br label %if.exit12
else.body10:
  %imm_store33 = add i64 1, 0
  %_34 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_35 = call i32 (i8*, ...) @printf(i8* %_34, i64 %imm_store33)
  br label %else.exit11
else.exit11:
  br label %if.exit12
if.exit12:
  %b138 = or i1 0, 0
  %b239 = or i1 1, 0
  br label %if.cond13
if.cond13:
  %_41 = and i1 %b138, %b239
  br i1 %_41, label %then.body14, label %else.body16
then.body14:
  %imm_store43 = add i64 0, 0
  %_44 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_45 = call i32 (i8*, ...) @printf(i8* %_44, i64 %imm_store43)
  br label %then.exit15
then.exit15:
  br label %if.exit18
else.body16:
  %imm_store48 = add i64 1, 0
  %_49 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_50 = call i32 (i8*, ...) @printf(i8* %_49, i64 %imm_store48)
  br label %else.exit17
else.exit17:
  br label %if.exit18
if.exit18:
  %b153 = or i1 1, 0
  %b254 = or i1 1, 0
  br label %if.cond19
if.cond19:
  %_56 = and i1 %b153, %b254
  br i1 %_56, label %then.body20, label %else.body22
then.body20:
  %imm_store58 = add i64 1, 0
  %_59 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_60 = call i32 (i8*, ...) @printf(i8* %_59, i64 %imm_store58)
  br label %then.exit21
then.exit21:
  br label %if.exit24
else.body22:
  %imm_store63 = add i64 0, 0
  %_64 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_65 = call i32 (i8*, ...) @printf(i8* %_64, i64 %imm_store63)
  br label %else.exit23
else.exit23:
  br label %if.exit24
if.exit24:
  %imm_store68 = add i64 0, 0
  store i64 %imm_store68, i64* @counter
  %imm_store70 = add i64 2, 0
  call void (i64) @printgroup(i64 %imm_store70)
  %b172 = or i1 1, 0
  %b273 = or i1 1, 0
  br label %if.cond25
if.cond25:
  %_75 = or i1 %b172, %b273
  br i1 %_75, label %then.body26, label %else.body28
then.body26:
  %imm_store77 = add i64 1, 0
  %_78 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_79 = call i32 (i8*, ...) @printf(i8* %_78, i64 %imm_store77)
  br label %then.exit27
then.exit27:
  br label %if.exit30
else.body28:
  %imm_store82 = add i64 0, 0
  %_83 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_84 = call i32 (i8*, ...) @printf(i8* %_83, i64 %imm_store82)
  br label %else.exit29
else.exit29:
  br label %if.exit30
if.exit30:
  %b187 = or i1 1, 0
  %b288 = or i1 0, 0
  br label %if.cond31
if.cond31:
  %_90 = or i1 %b187, %b288
  br i1 %_90, label %then.body32, label %else.body34
then.body32:
  %imm_store92 = add i64 1, 0
  %_93 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_94 = call i32 (i8*, ...) @printf(i8* %_93, i64 %imm_store92)
  br label %then.exit33
then.exit33:
  br label %if.exit36
else.body34:
  %imm_store97 = add i64 0, 0
  %_98 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_99 = call i32 (i8*, ...) @printf(i8* %_98, i64 %imm_store97)
  br label %else.exit35
else.exit35:
  br label %if.exit36
if.exit36:
  %b1102 = or i1 0, 0
  %b2103 = or i1 1, 0
  br label %if.cond37
if.cond37:
  %_105 = or i1 %b1102, %b2103
  br i1 %_105, label %then.body38, label %else.body40
then.body38:
  %imm_store107 = add i64 1, 0
  %_108 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_109 = call i32 (i8*, ...) @printf(i8* %_108, i64 %imm_store107)
  br label %then.exit39
then.exit39:
  br label %if.exit42
else.body40:
  %imm_store112 = add i64 0, 0
  %_113 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_114 = call i32 (i8*, ...) @printf(i8* %_113, i64 %imm_store112)
  br label %else.exit41
else.exit41:
  br label %if.exit42
if.exit42:
  %b1117 = or i1 0, 0
  %b2118 = or i1 0, 0
  br label %if.cond43
if.cond43:
  %_120 = or i1 %b1117, %b2118
  br i1 %_120, label %then.body44, label %else.body46
then.body44:
  %imm_store122 = add i64 0, 0
  %_123 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_124 = call i32 (i8*, ...) @printf(i8* %_123, i64 %imm_store122)
  br label %then.exit45
then.exit45:
  br label %if.exit48
else.body46:
  %imm_store127 = add i64 1, 0
  %_128 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_129 = call i32 (i8*, ...) @printf(i8* %_128, i64 %imm_store127)
  br label %else.exit47
else.exit47:
  br label %if.exit48
if.exit48:
  %imm_store132 = add i64 3, 0
  call void (i64) @printgroup(i64 %imm_store132)
  br label %if.cond49
if.cond49:
  %imm_store135 = add i64 42, 0
  %imm_store136 = add i64 1, 0
  %_137 = icmp sgt i64 %imm_store135, %imm_store136
  br i1 %_137, label %then.body50, label %else.body52
then.body50:
  %imm_store139 = add i64 1, 0
  %_140 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_141 = call i32 (i8*, ...) @printf(i8* %_140, i64 %imm_store139)
  br label %then.exit51
then.exit51:
  br label %if.exit54
else.body52:
  %imm_store144 = add i64 0, 0
  %_145 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_146 = call i32 (i8*, ...) @printf(i8* %_145, i64 %imm_store144)
  br label %else.exit53
else.exit53:
  br label %if.exit54
if.exit54:
  br label %if.cond55
if.cond55:
  %imm_store150 = add i64 42, 0
  %imm_store151 = add i64 1, 0
  %_152 = icmp sge i64 %imm_store150, %imm_store151
  br i1 %_152, label %then.body56, label %else.body58
then.body56:
  %imm_store154 = add i64 1, 0
  %_155 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_156 = call i32 (i8*, ...) @printf(i8* %_155, i64 %imm_store154)
  br label %then.exit57
then.exit57:
  br label %if.exit60
else.body58:
  %imm_store159 = add i64 0, 0
  %_160 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_161 = call i32 (i8*, ...) @printf(i8* %_160, i64 %imm_store159)
  br label %else.exit59
else.exit59:
  br label %if.exit60
if.exit60:
  br label %if.cond61
if.cond61:
  %imm_store165 = add i64 42, 0
  %imm_store166 = add i64 1, 0
  %_167 = icmp slt i64 %imm_store165, %imm_store166
  br i1 %_167, label %then.body62, label %else.body64
then.body62:
  %imm_store169 = add i64 0, 0
  %_170 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_171 = call i32 (i8*, ...) @printf(i8* %_170, i64 %imm_store169)
  br label %then.exit63
then.exit63:
  br label %if.exit66
else.body64:
  %imm_store174 = add i64 1, 0
  %_175 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_176 = call i32 (i8*, ...) @printf(i8* %_175, i64 %imm_store174)
  br label %else.exit65
else.exit65:
  br label %if.exit66
if.exit66:
  br label %if.cond67
if.cond67:
  %imm_store180 = add i64 42, 0
  %imm_store181 = add i64 1, 0
  %_182 = icmp sle i64 %imm_store180, %imm_store181
  br i1 %_182, label %then.body68, label %else.body70
then.body68:
  %imm_store184 = add i64 0, 0
  %_185 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_186 = call i32 (i8*, ...) @printf(i8* %_185, i64 %imm_store184)
  br label %then.exit69
then.exit69:
  br label %if.exit72
else.body70:
  %imm_store189 = add i64 1, 0
  %_190 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_191 = call i32 (i8*, ...) @printf(i8* %_190, i64 %imm_store189)
  br label %else.exit71
else.exit71:
  br label %if.exit72
if.exit72:
  br label %if.cond73
if.cond73:
  %imm_store195 = add i64 42, 0
  %imm_store196 = add i64 1, 0
  %_197 = icmp eq i64 %imm_store195, %imm_store196
  br i1 %_197, label %then.body74, label %else.body76
then.body74:
  %imm_store199 = add i64 0, 0
  %_200 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_201 = call i32 (i8*, ...) @printf(i8* %_200, i64 %imm_store199)
  br label %then.exit75
then.exit75:
  br label %if.exit78
else.body76:
  %imm_store204 = add i64 1, 0
  %_205 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_206 = call i32 (i8*, ...) @printf(i8* %_205, i64 %imm_store204)
  br label %else.exit77
else.exit77:
  br label %if.exit78
if.exit78:
  br label %if.cond79
if.cond79:
  %imm_store210 = add i64 42, 0
  %imm_store211 = add i64 1, 0
  %_212 = icmp ne i64 %imm_store210, %imm_store211
  br i1 %_212, label %then.body80, label %else.body82
then.body80:
  %imm_store214 = add i64 1, 0
  %_215 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_216 = call i32 (i8*, ...) @printf(i8* %_215, i64 %imm_store214)
  br label %then.exit81
then.exit81:
  br label %if.exit84
else.body82:
  %imm_store219 = add i64 0, 0
  %_220 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_221 = call i32 (i8*, ...) @printf(i8* %_220, i64 %imm_store219)
  br label %else.exit83
else.exit83:
  br label %if.exit84
if.exit84:
  br label %if.cond85
if.cond85:
  %_225 = or i1 1, 0
  br i1 %_225, label %then.body86, label %else.body88
then.body86:
  %imm_store227 = add i64 1, 0
  %_228 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_229 = call i32 (i8*, ...) @printf(i8* %_228, i64 %imm_store227)
  br label %then.exit87
then.exit87:
  br label %if.exit90
else.body88:
  %imm_store232 = add i64 0, 0
  %_233 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_234 = call i32 (i8*, ...) @printf(i8* %_233, i64 %imm_store232)
  br label %else.exit89
else.exit89:
  br label %if.exit90
if.exit90:
  br label %if.cond91
if.cond91:
  %imm_true238 = or i1 1, 0
  %_239 = xor i1 %imm_true238, 1
  br i1 %_239, label %then.body92, label %else.body94
then.body92:
  %imm_store241 = add i64 0, 0
  %_242 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_243 = call i32 (i8*, ...) @printf(i8* %_242, i64 %imm_store241)
  br label %then.exit93
then.exit93:
  br label %if.exit96
else.body94:
  %imm_store246 = add i64 1, 0
  %_247 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_248 = call i32 (i8*, ...) @printf(i8* %_247, i64 %imm_store246)
  br label %else.exit95
else.exit95:
  br label %if.exit96
if.exit96:
  br label %if.cond97
if.cond97:
  %_252 = or i1 0, 0
  br i1 %_252, label %then.body98, label %else.body100
then.body98:
  %imm_store254 = add i64 0, 0
  %_255 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_256 = call i32 (i8*, ...) @printf(i8* %_255, i64 %imm_store254)
  br label %then.exit99
then.exit99:
  br label %if.exit102
else.body100:
  %imm_store259 = add i64 1, 0
  %_260 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_261 = call i32 (i8*, ...) @printf(i8* %_260, i64 %imm_store259)
  br label %else.exit101
else.exit101:
  br label %if.exit102
if.exit102:
  br label %if.cond103
if.cond103:
  %imm_false265 = or i1 0, 0
  %_266 = xor i1 %imm_false265, 1
  br i1 %_266, label %then.body104, label %else.body106
then.body104:
  %imm_store268 = add i64 1, 0
  %_269 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_270 = call i32 (i8*, ...) @printf(i8* %_269, i64 %imm_store268)
  br label %then.exit105
then.exit105:
  br label %if.exit108
else.body106:
  %imm_store273 = add i64 0, 0
  %_274 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_275 = call i32 (i8*, ...) @printf(i8* %_274, i64 %imm_store273)
  br label %else.exit107
else.exit107:
  br label %if.exit108
if.exit108:
  br label %if.cond109
if.cond109:
  %imm_false279 = or i1 0, 0
  %_280 = xor i1 %imm_false279, 1
  br i1 %_280, label %then.body110, label %else.body112
then.body110:
  %imm_store282 = add i64 1, 0
  %_283 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_284 = call i32 (i8*, ...) @printf(i8* %_283, i64 %imm_store282)
  br label %then.exit111
then.exit111:
  br label %if.exit114
else.body112:
  %imm_store287 = add i64 0, 0
  %_288 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_289 = call i32 (i8*, ...) @printf(i8* %_288, i64 %imm_store287)
  br label %else.exit113
else.exit113:
  br label %if.exit114
if.exit114:
  %imm_store292 = add i64 4, 0
  call void (i64) @printgroup(i64 %imm_store292)
  br label %if.cond115
if.cond115:
  %imm_store295 = add i64 2, 0
  %imm_store296 = add i64 3, 0
  %tmp.binop297 = add i64 %imm_store295, %imm_store296
  %imm_store298 = add i64 5, 0
  %_299 = icmp eq i64 %tmp.binop297, %imm_store298
  br i1 %_299, label %then.body116, label %else.body118
then.body116:
  %imm_store301 = add i64 1, 0
  %_302 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_303 = call i32 (i8*, ...) @printf(i8* %_302, i64 %imm_store301)
  br label %then.exit117
then.exit117:
  br label %if.exit120
else.body118:
  %imm_store306 = add i64 0, 0
  %_307 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_308 = call i32 (i8*, ...) @printf(i8* %_307, i64 %imm_store306)
  %imm_store309 = add i64 2, 0
  %imm_store310 = add i64 3, 0
  %tmp.binop311 = add i64 %imm_store309, %imm_store310
  %_312 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_313 = call i32 (i8*, ...) @printf(i8* %_312, i64 %tmp.binop311)
  br label %else.exit119
else.exit119:
  br label %if.exit120
if.exit120:
  br label %if.cond121
if.cond121:
  %imm_store317 = add i64 2, 0
  %imm_store318 = add i64 3, 0
  %tmp.binop319 = mul i64 %imm_store317, %imm_store318
  %imm_store320 = add i64 6, 0
  %_321 = icmp eq i64 %tmp.binop319, %imm_store320
  br i1 %_321, label %then.body122, label %else.body124
then.body122:
  %imm_store323 = add i64 1, 0
  %_324 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_325 = call i32 (i8*, ...) @printf(i8* %_324, i64 %imm_store323)
  br label %then.exit123
then.exit123:
  br label %if.exit126
else.body124:
  %imm_store328 = add i64 0, 0
  %_329 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_330 = call i32 (i8*, ...) @printf(i8* %_329, i64 %imm_store328)
  %imm_store331 = add i64 2, 0
  %imm_store332 = add i64 3, 0
  %tmp.binop333 = mul i64 %imm_store331, %imm_store332
  %_334 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_335 = call i32 (i8*, ...) @printf(i8* %_334, i64 %tmp.binop333)
  br label %else.exit125
else.exit125:
  br label %if.exit126
if.exit126:
  br label %if.cond127
if.cond127:
  %imm_store339 = add i64 3, 0
  %imm_store340 = add i64 2, 0
  %tmp.binop341 = sub i64 %imm_store339, %imm_store340
  %imm_store342 = add i64 1, 0
  %_343 = icmp eq i64 %tmp.binop341, %imm_store342
  br i1 %_343, label %then.body128, label %else.body130
then.body128:
  %imm_store345 = add i64 1, 0
  %_346 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_347 = call i32 (i8*, ...) @printf(i8* %_346, i64 %imm_store345)
  br label %then.exit129
then.exit129:
  br label %if.exit132
else.body130:
  %imm_store350 = add i64 0, 0
  %_351 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_352 = call i32 (i8*, ...) @printf(i8* %_351, i64 %imm_store350)
  %imm_store353 = add i64 3, 0
  %imm_store354 = add i64 2, 0
  %tmp.binop355 = sub i64 %imm_store353, %imm_store354
  %_356 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_357 = call i32 (i8*, ...) @printf(i8* %_356, i64 %tmp.binop355)
  br label %else.exit131
else.exit131:
  br label %if.exit132
if.exit132:
  br label %if.cond133
if.cond133:
  %imm_store361 = add i64 6, 0
  %imm_store362 = add i64 3, 0
  %tmp.binop363 = sdiv i64 %imm_store361, %imm_store362
  %imm_store364 = add i64 2, 0
  %_365 = icmp eq i64 %tmp.binop363, %imm_store364
  br i1 %_365, label %then.body134, label %else.body136
then.body134:
  %imm_store367 = add i64 1, 0
  %_368 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_369 = call i32 (i8*, ...) @printf(i8* %_368, i64 %imm_store367)
  br label %then.exit135
then.exit135:
  br label %if.exit138
else.body136:
  %imm_store372 = add i64 0, 0
  %_373 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_374 = call i32 (i8*, ...) @printf(i8* %_373, i64 %imm_store372)
  %imm_store375 = add i64 6, 0
  %imm_store376 = add i64 3, 0
  %tmp.binop377 = sdiv i64 %imm_store375, %imm_store376
  %_378 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_379 = call i32 (i8*, ...) @printf(i8* %_378, i64 %tmp.binop377)
  br label %else.exit137
else.exit137:
  br label %if.exit138
if.exit138:
  br label %if.cond139
if.cond139:
  %imm_store383 = add i64 6, 0
  %tmp.unop384 = sub i64 0, %imm_store383
  %imm_store385 = add i64 0, 0
  %_386 = icmp slt i64 %tmp.unop384, %imm_store385
  br i1 %_386, label %then.body140, label %else.body142
then.body140:
  %imm_store388 = add i64 1, 0
  %_389 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_390 = call i32 (i8*, ...) @printf(i8* %_389, i64 %imm_store388)
  br label %then.exit141
then.exit141:
  br label %if.exit144
else.body142:
  %imm_store393 = add i64 0, 0
  %_394 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_395 = call i32 (i8*, ...) @printf(i8* %_394, i64 %imm_store393)
  br label %else.exit143
else.exit143:
  br label %if.exit144
if.exit144:
  %imm_store398 = add i64 5, 0
  call void (i64) @printgroup(i64 %imm_store398)
  %i1400 = add i64 42, 0
  br label %if.cond145
if.cond145:
  %imm_store402 = add i64 42, 0
  %_403 = icmp eq i64 %i1400, %imm_store402
  br i1 %_403, label %then.body146, label %else.body148
then.body146:
  %imm_store405 = add i64 1, 0
  %_406 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_407 = call i32 (i8*, ...) @printf(i8* %_406, i64 %imm_store405)
  br label %then.exit147
then.exit147:
  br label %if.exit150
else.body148:
  %imm_store410 = add i64 0, 0
  %_411 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_412 = call i32 (i8*, ...) @printf(i8* %_411, i64 %imm_store410)
  br label %else.exit149
else.exit149:
  br label %if.exit150
if.exit150:
  %i1415 = add i64 3, 0
  %i2416 = add i64 2, 0
  %i3417 = add i64 %i1415, %i2416
  br label %if.cond151
if.cond151:
  %imm_store419 = add i64 5, 0
  %_420 = icmp eq i64 %i3417, %imm_store419
  br i1 %_420, label %then.body152, label %else.body154
then.body152:
  %imm_store422 = add i64 1, 0
  %_423 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_424 = call i32 (i8*, ...) @printf(i8* %_423, i64 %imm_store422)
  br label %then.exit153
then.exit153:
  br label %if.exit156
else.body154:
  %imm_store427 = add i64 0, 0
  %_428 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_429 = call i32 (i8*, ...) @printf(i8* %_428, i64 %imm_store427)
  br label %else.exit155
else.exit155:
  br label %if.exit156
if.exit156:
  %_432 = or i1 1, 0
  br label %if.cond157
if.cond157:
  br i1 %_432, label %then.body158, label %else.body160
then.body158:
  %imm_store435 = add i64 1, 0
  %_436 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_437 = call i32 (i8*, ...) @printf(i8* %_436, i64 %imm_store435)
  br label %then.exit159
then.exit159:
  br label %if.exit162
else.body160:
  %imm_store440 = add i64 0, 0
  %_441 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_442 = call i32 (i8*, ...) @printf(i8* %_441, i64 %imm_store440)
  br label %else.exit161
else.exit161:
  br label %if.exit162
if.exit162:
  br label %if.cond163
if.cond163:
  %_446 = xor i1 %_432, 1
  br i1 %_446, label %then.body164, label %else.body166
then.body164:
  %imm_store448 = add i64 0, 0
  %_449 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_450 = call i32 (i8*, ...) @printf(i8* %_449, i64 %imm_store448)
  br label %then.exit165
then.exit165:
  br label %if.exit168
else.body166:
  %imm_store453 = add i64 1, 0
  %_454 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_455 = call i32 (i8*, ...) @printf(i8* %_454, i64 %imm_store453)
  br label %else.exit167
else.exit167:
  br label %if.exit168
if.exit168:
  %_458 = or i1 0, 0
  br label %if.cond169
if.cond169:
  br i1 %_458, label %then.body170, label %else.body172
then.body170:
  %imm_store461 = add i64 0, 0
  %_462 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_463 = call i32 (i8*, ...) @printf(i8* %_462, i64 %imm_store461)
  br label %then.exit171
then.exit171:
  br label %if.exit174
else.body172:
  %imm_store466 = add i64 1, 0
  %_467 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_468 = call i32 (i8*, ...) @printf(i8* %_467, i64 %imm_store466)
  br label %else.exit173
else.exit173:
  br label %if.exit174
if.exit174:
  br label %if.cond175
if.cond175:
  %_472 = xor i1 %_458, 1
  br i1 %_472, label %then.body176, label %else.body178
then.body176:
  %imm_store474 = add i64 1, 0
  %_475 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_476 = call i32 (i8*, ...) @printf(i8* %_475, i64 %imm_store474)
  br label %then.exit177
then.exit177:
  br label %if.exit180
else.body178:
  %imm_store479 = add i64 0, 0
  %_480 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_481 = call i32 (i8*, ...) @printf(i8* %_480, i64 %imm_store479)
  br label %else.exit179
else.exit179:
  br label %if.exit180
if.exit180:
  br label %if.cond181
if.cond181:
  br i1 %_458, label %then.body182, label %else.body184
then.body182:
  %imm_store486 = add i64 0, 0
  %_487 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_488 = call i32 (i8*, ...) @printf(i8* %_487, i64 %imm_store486)
  br label %then.exit183
then.exit183:
  br label %if.exit186
else.body184:
  %imm_store491 = add i64 1, 0
  %_492 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_493 = call i32 (i8*, ...) @printf(i8* %_492, i64 %imm_store491)
  br label %else.exit185
else.exit185:
  br label %if.exit186
if.exit186:
  %imm_store496 = add i64 6, 0
  call void (i64) @printgroup(i64 %imm_store496)
  %i1498 = add i64 0, 0
  br label %while.cond1187
while.cond1187:
  %imm_store500 = add i64 5, 0
  %_501 = icmp slt i64 %i1498, %imm_store500
  br i1 %_501, label %while.body188, label %while.exit195
while.body188:
  %i11 = phi i64 [ %i1498, %while.cond1187 ], [ %i1513, %while.fillback194 ]
  br label %if.cond189
if.cond189:
  %imm_store504 = add i64 5, 0
  %_505 = icmp sge i64 %i11, %imm_store504
  br i1 %_505, label %then.body190, label %if.exit192
then.body190:
  %imm_store507 = add i64 0, 0
  %_508 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_509 = call i32 (i8*, ...) @printf(i8* %_508, i64 %imm_store507)
  br label %then.exit191
then.exit191:
  br label %if.exit192
if.exit192:
  %imm_store512 = add i64 5, 0
  %i1513 = add i64 %i11, %imm_store512
  br label %while.cond2193
while.cond2193:
  %imm_store515 = add i64 5, 0
  %_516 = icmp slt i64 %i1513, %imm_store515
  br i1 %_516, label %while.fillback194, label %while.exit195
while.fillback194:
  br label %while.body188
while.exit195:
  %i10 = phi i64 [ %i1498, %while.cond1187 ], [ %i1513, %while.cond2193 ]
  br label %if.cond196
if.cond196:
  %imm_store520 = add i64 5, 0
  %_521 = icmp eq i64 %i10, %imm_store520
  br i1 %_521, label %then.body197, label %else.body199
then.body197:
  %imm_store523 = add i64 1, 0
  %_524 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_525 = call i32 (i8*, ...) @printf(i8* %_524, i64 %imm_store523)
  br label %then.exit198
then.exit198:
  br label %if.exit201
else.body199:
  %imm_store528 = add i64 0, 0
  %_529 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_530 = call i32 (i8*, ...) @printf(i8* %_529, i64 %imm_store528)
  %_531 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_532 = call i32 (i8*, ...) @printf(i8* %_531, i64 %i10)
  br label %else.exit200
else.exit200:
  br label %if.exit201
if.exit201:
  %imm_store535 = add i64 7, 0
  call void (i64) @printgroup(i64 %imm_store535)
  %thing.malloc537 = call i8* (i32) @malloc(i32 24)
  %s1538 = bitcast i8* %thing.malloc537 to %struct.thing*
  %imm_store539 = add i64 42, 0
  %s1.i_auf540 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 0
  store i64 %imm_store539, i64* %s1.i_auf540
  %imm_true542 = or i1 1, 0
  %s1.b_auf543 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 1
  store i1 %imm_true542, i1* %s1.b_auf543
  br label %if.cond202
if.cond202:
  %s1.i_auf546 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 0
  %_547 = load i64, i64* %s1.i_auf546
  %imm_store548 = add i64 42, 0
  %_549 = icmp eq i64 %_547, %imm_store548
  br i1 %_549, label %then.body203, label %else.body205
then.body203:
  %imm_store551 = add i64 1, 0
  %_552 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_553 = call i32 (i8*, ...) @printf(i8* %_552, i64 %imm_store551)
  br label %then.exit204
then.exit204:
  br label %if.exit207
else.body205:
  %imm_store556 = add i64 0, 0
  %_557 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_558 = call i32 (i8*, ...) @printf(i8* %_557, i64 %imm_store556)
  %s1.i_auf559 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 0
  %_560 = load i64, i64* %s1.i_auf559
  %_561 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_562 = call i32 (i8*, ...) @printf(i8* %_561, i64 %_560)
  br label %else.exit206
else.exit206:
  br label %if.exit207
if.exit207:
  br label %if.cond208
if.cond208:
  %s1.b_auf566 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 1
  %_567 = load i1, i1* %s1.b_auf566
  br i1 %_567, label %then.body209, label %else.body211
then.body209:
  %imm_store569 = add i64 1, 0
  %_570 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_571 = call i32 (i8*, ...) @printf(i8* %_570, i64 %imm_store569)
  br label %then.exit210
then.exit210:
  br label %if.exit213
else.body211:
  %imm_store574 = add i64 0, 0
  %_575 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_576 = call i32 (i8*, ...) @printf(i8* %_575, i64 %imm_store574)
  br label %else.exit212
else.exit212:
  br label %if.exit213
if.exit213:
  %thing.malloc579 = call i8* (i32) @malloc(i32 24)
  %thing.bitcast580 = bitcast i8* %thing.malloc579 to %struct.thing*
  %s1.s_auf581 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 2
  store %struct.thing* %thing.bitcast580, %struct.thing** %s1.s_auf581
  %imm_store583 = add i64 13, 0
  %s1.s_auf584 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 2
  %thing585 = load %struct.thing*, %struct.thing** %s1.s_auf584
  %s1.s.i_auf586 = getelementptr %struct.thing, %struct.thing* %thing585, i1 0, i32 0
  store i64 %imm_store583, i64* %s1.s.i_auf586
  %imm_false588 = or i1 0, 0
  %s1.s_auf589 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 2
  %thing590 = load %struct.thing*, %struct.thing** %s1.s_auf589
  %s1.s.b_auf591 = getelementptr %struct.thing, %struct.thing* %thing590, i1 0, i32 1
  store i1 %imm_false588, i1* %s1.s.b_auf591
  br label %if.cond214
if.cond214:
  %s1.s_auf594 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 2
  %thing595 = load %struct.thing*, %struct.thing** %s1.s_auf594
  %s1.s.i_auf596 = getelementptr %struct.thing, %struct.thing* %thing595, i1 0, i32 0
  %_597 = load i64, i64* %s1.s.i_auf596
  %imm_store598 = add i64 13, 0
  %_599 = icmp eq i64 %_597, %imm_store598
  br i1 %_599, label %then.body215, label %else.body217
then.body215:
  %imm_store601 = add i64 1, 0
  %_602 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_603 = call i32 (i8*, ...) @printf(i8* %_602, i64 %imm_store601)
  br label %then.exit216
then.exit216:
  br label %if.exit219
else.body217:
  %imm_store606 = add i64 0, 0
  %_607 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_608 = call i32 (i8*, ...) @printf(i8* %_607, i64 %imm_store606)
  %s1.s_auf609 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 2
  %thing610 = load %struct.thing*, %struct.thing** %s1.s_auf609
  %s1.s.i_auf611 = getelementptr %struct.thing, %struct.thing* %thing610, i1 0, i32 0
  %_612 = load i64, i64* %s1.s.i_auf611
  %_613 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_614 = call i32 (i8*, ...) @printf(i8* %_613, i64 %_612)
  br label %else.exit218
else.exit218:
  br label %if.exit219
if.exit219:
  br label %if.cond220
if.cond220:
  %s1.s_auf618 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 2
  %thing619 = load %struct.thing*, %struct.thing** %s1.s_auf618
  %s1.s.b_auf620 = getelementptr %struct.thing, %struct.thing* %thing619, i1 0, i32 1
  %_621 = load i1, i1* %s1.s.b_auf620
  %_622 = xor i1 %_621, 1
  br i1 %_622, label %then.body221, label %else.body223
then.body221:
  %imm_store624 = add i64 1, 0
  %_625 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_626 = call i32 (i8*, ...) @printf(i8* %_625, i64 %imm_store624)
  br label %then.exit222
then.exit222:
  br label %if.exit225
else.body223:
  %imm_store629 = add i64 0, 0
  %_630 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_631 = call i32 (i8*, ...) @printf(i8* %_630, i64 %imm_store629)
  br label %else.exit224
else.exit224:
  br label %if.exit225
if.exit225:
  br label %if.cond226
if.cond226:
  %_635 = icmp eq %struct.thing* %s1538, %s1538
  br i1 %_635, label %then.body227, label %else.body229
then.body227:
  %imm_store637 = add i64 1, 0
  %_638 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_639 = call i32 (i8*, ...) @printf(i8* %_638, i64 %imm_store637)
  br label %then.exit228
then.exit228:
  br label %if.exit231
else.body229:
  %imm_store642 = add i64 0, 0
  %_643 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_644 = call i32 (i8*, ...) @printf(i8* %_643, i64 %imm_store642)
  br label %else.exit230
else.exit230:
  br label %if.exit231
if.exit231:
  br label %if.cond232
if.cond232:
  %s1.s_auf648 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 2
  %_649 = load %struct.thing*, %struct.thing** %s1.s_auf648
  %_650 = icmp ne %struct.thing* %s1538, %_649
  br i1 %_650, label %then.body233, label %else.body235
then.body233:
  %imm_store652 = add i64 1, 0
  %_653 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_654 = call i32 (i8*, ...) @printf(i8* %_653, i64 %imm_store652)
  br label %then.exit234
then.exit234:
  br label %if.exit237
else.body235:
  %imm_store657 = add i64 0, 0
  %_658 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_659 = call i32 (i8*, ...) @printf(i8* %_658, i64 %imm_store657)
  br label %else.exit236
else.exit236:
  br label %if.exit237
if.exit237:
  %s1.s_auf662 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 2
  %_663 = load %struct.thing*, %struct.thing** %s1.s_auf662
  %_664 = bitcast %struct.thing* %_663 to i8*
  call void (i8*) @free(i8* %_664)
  %_666 = bitcast %struct.thing* %s1538 to i8*
  call void (i8*) @free(i8* %_666)
  %imm_store668 = add i64 8, 0
  call void (i64) @printgroup(i64 %imm_store668)
  %imm_store670 = add i64 7, 0
  store i64 %imm_store670, i64* @gi1
  br label %if.cond238
if.cond238:
  %load_global673 = load i64, i64* @gi1
  %imm_store674 = add i64 7, 0
  %_675 = icmp eq i64 %load_global673, %imm_store674
  br i1 %_675, label %then.body239, label %else.body241
then.body239:
  %imm_store677 = add i64 1, 0
  %_678 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_679 = call i32 (i8*, ...) @printf(i8* %_678, i64 %imm_store677)
  br label %then.exit240
then.exit240:
  br label %if.exit243
else.body241:
  %imm_store682 = add i64 0, 0
  %_683 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_684 = call i32 (i8*, ...) @printf(i8* %_683, i64 %imm_store682)
  %load_global685 = load i64, i64* @gi1
  %_686 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_687 = call i32 (i8*, ...) @printf(i8* %_686, i64 %load_global685)
  br label %else.exit242
else.exit242:
  br label %if.exit243
if.exit243:
  %imm_true690 = or i1 1, 0
  store i1 %imm_true690, i1* @gb1
  br label %if.cond244
if.cond244:
  %_693 = load i1, i1* @gb1
  br i1 %_693, label %then.body245, label %else.body247
then.body245:
  %imm_store695 = add i64 1, 0
  %_696 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_697 = call i32 (i8*, ...) @printf(i8* %_696, i64 %imm_store695)
  br label %then.exit246
then.exit246:
  br label %if.exit249
else.body247:
  %imm_store700 = add i64 0, 0
  %_701 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_702 = call i32 (i8*, ...) @printf(i8* %_701, i64 %imm_store700)
  br label %else.exit248
else.exit248:
  br label %if.exit249
if.exit249:
  %thing.malloc705 = call i8* (i32) @malloc(i32 24)
  %thing.bitcast706 = bitcast i8* %thing.malloc705 to %struct.thing*
  store %struct.thing* %thing.bitcast706, %struct.thing** @gs1
  %imm_store708 = add i64 34, 0
  %_709 = load %struct.thing*, %struct.thing** @gs1
  %gs1.i_auf710 = getelementptr %struct.thing, %struct.thing* %_709, i1 0, i32 0
  store i64 %imm_store708, i64* %gs1.i_auf710
  %imm_false712 = or i1 0, 0
  %_713 = load %struct.thing*, %struct.thing** @gs1
  %gs1.b_auf714 = getelementptr %struct.thing, %struct.thing* %_713, i1 0, i32 1
  store i1 %imm_false712, i1* %gs1.b_auf714
  br label %if.cond250
if.cond250:
  %load_global717 = load %struct.thing*, %struct.thing** @gs1
  %gs1.i_auf718 = getelementptr %struct.thing, %struct.thing* %load_global717, i1 0, i32 0
  %_719 = load i64, i64* %gs1.i_auf718
  %imm_store720 = add i64 34, 0
  %_721 = icmp eq i64 %_719, %imm_store720
  br i1 %_721, label %then.body251, label %else.body253
then.body251:
  %imm_store723 = add i64 1, 0
  %_724 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_725 = call i32 (i8*, ...) @printf(i8* %_724, i64 %imm_store723)
  br label %then.exit252
then.exit252:
  br label %if.exit255
else.body253:
  %imm_store728 = add i64 0, 0
  %_729 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_730 = call i32 (i8*, ...) @printf(i8* %_729, i64 %imm_store728)
  %load_global731 = load %struct.thing*, %struct.thing** @gs1
  %gs1.i_auf732 = getelementptr %struct.thing, %struct.thing* %load_global731, i1 0, i32 0
  %_733 = load i64, i64* %gs1.i_auf732
  %_734 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_735 = call i32 (i8*, ...) @printf(i8* %_734, i64 %_733)
  br label %else.exit254
else.exit254:
  br label %if.exit255
if.exit255:
  br label %if.cond256
if.cond256:
  %load_global739 = load %struct.thing*, %struct.thing** @gs1
  %gs1.b_auf740 = getelementptr %struct.thing, %struct.thing* %load_global739, i1 0, i32 1
  %_741 = load i1, i1* %gs1.b_auf740
  %_742 = xor i1 %_741, 1
  br i1 %_742, label %then.body257, label %else.body259
then.body257:
  %imm_store744 = add i64 1, 0
  %_745 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_746 = call i32 (i8*, ...) @printf(i8* %_745, i64 %imm_store744)
  br label %then.exit258
then.exit258:
  br label %if.exit261
else.body259:
  %imm_store749 = add i64 0, 0
  %_750 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_751 = call i32 (i8*, ...) @printf(i8* %_750, i64 %imm_store749)
  br label %else.exit260
else.exit260:
  br label %if.exit261
if.exit261:
  %thing.malloc754 = call i8* (i32) @malloc(i32 24)
  %thing.bitcast755 = bitcast i8* %thing.malloc754 to %struct.thing*
  %_756 = load %struct.thing*, %struct.thing** @gs1
  %gs1.s_auf757 = getelementptr %struct.thing, %struct.thing* %_756, i1 0, i32 2
  store %struct.thing* %thing.bitcast755, %struct.thing** %gs1.s_auf757
  %imm_store759 = add i64 16, 0
  %_760 = load %struct.thing*, %struct.thing** @gs1
  %gs1.s_auf761 = getelementptr %struct.thing, %struct.thing* %_760, i1 0, i32 2
  %thing762 = load %struct.thing*, %struct.thing** %gs1.s_auf761
  %gs1.s.i_auf763 = getelementptr %struct.thing, %struct.thing* %thing762, i1 0, i32 0
  store i64 %imm_store759, i64* %gs1.s.i_auf763
  %imm_true765 = or i1 1, 0
  %_766 = load %struct.thing*, %struct.thing** @gs1
  %gs1.s_auf767 = getelementptr %struct.thing, %struct.thing* %_766, i1 0, i32 2
  %thing768 = load %struct.thing*, %struct.thing** %gs1.s_auf767
  %gs1.s.b_auf769 = getelementptr %struct.thing, %struct.thing* %thing768, i1 0, i32 1
  store i1 %imm_true765, i1* %gs1.s.b_auf769
  br label %if.cond262
if.cond262:
  %load_global772 = load %struct.thing*, %struct.thing** @gs1
  %gs1.s_auf773 = getelementptr %struct.thing, %struct.thing* %load_global772, i1 0, i32 2
  %thing774 = load %struct.thing*, %struct.thing** %gs1.s_auf773
  %gs1.s.i_auf775 = getelementptr %struct.thing, %struct.thing* %thing774, i1 0, i32 0
  %_776 = load i64, i64* %gs1.s.i_auf775
  %imm_store777 = add i64 16, 0
  %_778 = icmp eq i64 %_776, %imm_store777
  br i1 %_778, label %then.body263, label %else.body265
then.body263:
  %imm_store780 = add i64 1, 0
  %_781 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_782 = call i32 (i8*, ...) @printf(i8* %_781, i64 %imm_store780)
  br label %then.exit264
then.exit264:
  br label %if.exit267
else.body265:
  %imm_store785 = add i64 0, 0
  %_786 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_787 = call i32 (i8*, ...) @printf(i8* %_786, i64 %imm_store785)
  %load_global788 = load %struct.thing*, %struct.thing** @gs1
  %gs1.s_auf789 = getelementptr %struct.thing, %struct.thing* %load_global788, i1 0, i32 2
  %thing790 = load %struct.thing*, %struct.thing** %gs1.s_auf789
  %gs1.s.i_auf791 = getelementptr %struct.thing, %struct.thing* %thing790, i1 0, i32 0
  %_792 = load i64, i64* %gs1.s.i_auf791
  %_793 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_794 = call i32 (i8*, ...) @printf(i8* %_793, i64 %_792)
  br label %else.exit266
else.exit266:
  br label %if.exit267
if.exit267:
  br label %if.cond268
if.cond268:
  %load_global798 = load %struct.thing*, %struct.thing** @gs1
  %gs1.s_auf799 = getelementptr %struct.thing, %struct.thing* %load_global798, i1 0, i32 2
  %thing800 = load %struct.thing*, %struct.thing** %gs1.s_auf799
  %gs1.s.b_auf801 = getelementptr %struct.thing, %struct.thing* %thing800, i1 0, i32 1
  %_802 = load i1, i1* %gs1.s.b_auf801
  br i1 %_802, label %then.body269, label %else.body271
then.body269:
  %imm_store804 = add i64 1, 0
  %_805 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_806 = call i32 (i8*, ...) @printf(i8* %_805, i64 %imm_store804)
  br label %then.exit270
then.exit270:
  br label %if.exit273
else.body271:
  %imm_store809 = add i64 0, 0
  %_810 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_811 = call i32 (i8*, ...) @printf(i8* %_810, i64 %imm_store809)
  br label %else.exit272
else.exit272:
  br label %if.exit273
if.exit273:
  %load_global814 = load %struct.thing*, %struct.thing** @gs1
  %gs1.s_auf815 = getelementptr %struct.thing, %struct.thing* %load_global814, i1 0, i32 2
  %_816 = load %struct.thing*, %struct.thing** %gs1.s_auf815
  %_817 = bitcast %struct.thing* %_816 to i8*
  call void (i8*) @free(i8* %_817)
  %load_global819 = load %struct.thing*, %struct.thing** @gs1
  %_820 = bitcast %struct.thing* %load_global819 to i8*
  call void (i8*) @free(i8* %_820)
  %imm_store822 = add i64 9, 0
  call void (i64) @printgroup(i64 %imm_store822)
  %thing.malloc824 = call i8* (i32) @malloc(i32 24)
  %s1825 = bitcast i8* %thing.malloc824 to %struct.thing*
  %imm_true826 = or i1 1, 0
  %s1.b_auf827 = getelementptr %struct.thing, %struct.thing* %s1825, i1 0, i32 1
  store i1 %imm_true826, i1* %s1.b_auf827
  %imm_store829 = add i64 3, 0
  %imm_true830 = or i1 1, 0
  call void (i64, i1, %struct.thing*) @takealltypes(i64 %imm_store829, i1 %imm_true830, %struct.thing* %s1825)
  %imm_store832 = add i64 2, 0
  %_833 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_834 = call i32 (i8*, ...) @printf(i8* %_833, i64 %imm_store832)
  %imm_store835 = add i64 1, 0
  %imm_store836 = add i64 2, 0
  %imm_store837 = add i64 3, 0
  %imm_store838 = add i64 4, 0
  %imm_store839 = add i64 5, 0
  %imm_store840 = add i64 6, 0
  %imm_store841 = add i64 7, 0
  %imm_store842 = add i64 8, 0
  call void (i64, i64, i64, i64, i64, i64, i64, i64) @tonofargs(i64 %imm_store835, i64 %imm_store836, i64 %imm_store837, i64 %imm_store838, i64 %imm_store839, i64 %imm_store840, i64 %imm_store841, i64 %imm_store842)
  %imm_store844 = add i64 3, 0
  %_845 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_846 = call i32 (i8*, ...) @printf(i8* %_845, i64 %imm_store844)
  %imm_store847 = add i64 3, 0
  %i1848 = call i64 (i64) @returnint(i64 %imm_store847)
  br label %if.cond274
if.cond274:
  %imm_store850 = add i64 3, 0
  %_851 = icmp eq i64 %i1848, %imm_store850
  br i1 %_851, label %then.body275, label %else.body277
then.body275:
  %imm_store853 = add i64 1, 0
  %_854 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_855 = call i32 (i8*, ...) @printf(i8* %_854, i64 %imm_store853)
  br label %then.exit276
then.exit276:
  br label %if.exit279
else.body277:
  %imm_store858 = add i64 0, 0
  %_859 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_860 = call i32 (i8*, ...) @printf(i8* %_859, i64 %imm_store858)
  %_861 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_862 = call i32 (i8*, ...) @printf(i8* %_861, i64 %i1848)
  br label %else.exit278
else.exit278:
  br label %if.exit279
if.exit279:
  %imm_true865 = or i1 1, 0
  %_866 = call i1 (i1) @returnbool(i1 %imm_true865)
  br label %if.cond280
if.cond280:
  br i1 %_866, label %then.body281, label %else.body283
then.body281:
  %imm_store869 = add i64 1, 0
  %_870 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_871 = call i32 (i8*, ...) @printf(i8* %_870, i64 %imm_store869)
  br label %then.exit282
then.exit282:
  br label %if.exit285
else.body283:
  %imm_store874 = add i64 0, 0
  %_875 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_876 = call i32 (i8*, ...) @printf(i8* %_875, i64 %imm_store874)
  br label %else.exit284
else.exit284:
  br label %if.exit285
if.exit285:
  %thing.malloc879 = call i8* (i32) @malloc(i32 24)
  %s1880 = bitcast i8* %thing.malloc879 to %struct.thing*
  %s2881 = call %struct.thing* (%struct.thing*) @returnstruct(%struct.thing* %s1880)
  br label %if.cond286
if.cond286:
  %_883 = icmp eq %struct.thing* %s1880, %s2881
  br i1 %_883, label %then.body287, label %else.body289
then.body287:
  %imm_store885 = add i64 1, 0
  %_886 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_887 = call i32 (i8*, ...) @printf(i8* %_886, i64 %imm_store885)
  br label %then.exit288
then.exit288:
  br label %if.exit291
else.body289:
  %imm_store890 = add i64 0, 0
  %_891 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_892 = call i32 (i8*, ...) @printf(i8* %_891, i64 %imm_store890)
  br label %else.exit290
else.exit290:
  br label %if.exit291
if.exit291:
  %imm_store895 = add i64 10, 0
  call void (i64) @printgroup(i64 %imm_store895)
  %imm_store897 = add i64 0, 0
  br label %exit
exit:
  %return_reg898 = phi i64 [ %imm_store897, %if.exit291 ]
  ret i64 %return_reg898
}

