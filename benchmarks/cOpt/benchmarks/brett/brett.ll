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
  %groupnum0 = alloca i64
  store i64 %groupnum, i64* %groupnum0
  br label %body1
body1:
  %_3 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_4 = call i32 (i8*, ...) @printf(i8* %_3, i64 1)
  %_5 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_6 = call i32 (i8*, ...) @printf(i8* %_5, i64 0)
  %_7 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_8 = call i32 (i8*, ...) @printf(i8* %_7, i64 1)
  %_9 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_10 = call i32 (i8*, ...) @printf(i8* %_9, i64 0)
  %_11 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_12 = call i32 (i8*, ...) @printf(i8* %_11, i64 1)
  %_13 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_14 = call i32 (i8*, ...) @printf(i8* %_13, i64 0)
  %groupnum15 = load i64, i64* %groupnum0
  %_16 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_17 = call i32 (i8*, ...) @printf(i8* %_16, i64 %groupnum15)
  br label %exit
exit:
  ret void
}

define i1 @setcounter(i64 %val) {
entry:
  %_0 = alloca i1
  %val1 = alloca i64
  store i64 %val, i64* %val1
  br label %body1
body1:
  %val4 = load i64, i64* %val1
  store i64 %val4, i64* @counter
  store i1 1, i1* %_0
  br label %exit
exit:
  %_8 = load i1, i1* %_0
  ret i1 %_8
}

define void @takealltypes(i64 %i, i1 %b, %struct.thing* %s) {
entry:
  %i0 = alloca i64
  store i64 %i, i64* %i0
  %b2 = alloca i1
  store i1 %b, i1* %b2
  %s4 = alloca %struct.thing*
  store %struct.thing* %s, %struct.thing** %s4
  br label %body1
body1:
  %i7 = load i64, i64* %i0
  %i8 = icmp eq i64 %i7, 3
  br i1 %i8, label %if.then2, label %if.else3
if.then2:
  %_9 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_10 = call i32 (i8*, ...) @printf(i8* %_9, i64 1)
  br label %if.end4
if.else3:
  %_11 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_12 = call i32 (i8*, ...) @printf(i8* %_11, i64 0)
  br label %if.end4
if.end4:
  %b16 = load i1, i1* %b2
  br i1 %b16, label %if.then5, label %if.else6
if.then5:
  %_17 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_18 = call i32 (i8*, ...) @printf(i8* %_17, i64 1)
  br label %if.end7
if.else6:
  %_19 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_20 = call i32 (i8*, ...) @printf(i8* %_19, i64 0)
  br label %if.end7
if.end7:
  %s24 = load %struct.thing*, %struct.thing** %s4
  %b25 = getelementptr %struct.thing, %struct.thing* %s24, i1 0, i32 1
  %b26 = load i1, i1* %b25
  br i1 %b26, label %if.then8, label %if.else9
if.then8:
  %_27 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_28 = call i32 (i8*, ...) @printf(i8* %_27, i64 1)
  br label %if.end10
if.else9:
  %_29 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_30 = call i32 (i8*, ...) @printf(i8* %_29, i64 0)
  br label %if.end10
if.end10:
  br label %exit
exit:
  ret void
}

define void @tonofargs(i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6, i64 %a7, i64 %a8) {
entry:
  %a10 = alloca i64
  store i64 %a1, i64* %a10
  %a22 = alloca i64
  store i64 %a2, i64* %a22
  %a34 = alloca i64
  store i64 %a3, i64* %a34
  %a46 = alloca i64
  store i64 %a4, i64* %a46
  %a58 = alloca i64
  store i64 %a5, i64* %a58
  %a610 = alloca i64
  store i64 %a6, i64* %a610
  %a712 = alloca i64
  store i64 %a7, i64* %a712
  %a814 = alloca i64
  store i64 %a8, i64* %a814
  br label %body1
body1:
  %a517 = load i64, i64* %a58
  %a518 = icmp eq i64 %a517, 5
  br i1 %a518, label %if.then2, label %if.else3
if.then2:
  %_19 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_20 = call i32 (i8*, ...) @printf(i8* %_19, i64 1)
  br label %if.end4
if.else3:
  %_21 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_22 = call i32 (i8*, ...) @printf(i8* %_21, i64 0)
  %a523 = load i64, i64* %a58
  %_24 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_25 = call i32 (i8*, ...) @printf(i8* %_24, i64 %a523)
  br label %if.end4
if.end4:
  %a629 = load i64, i64* %a610
  %a630 = icmp eq i64 %a629, 6
  br i1 %a630, label %if.then5, label %if.else6
if.then5:
  %_31 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_32 = call i32 (i8*, ...) @printf(i8* %_31, i64 1)
  br label %if.end7
if.else6:
  %_33 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_34 = call i32 (i8*, ...) @printf(i8* %_33, i64 0)
  %a635 = load i64, i64* %a610
  %_36 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_37 = call i32 (i8*, ...) @printf(i8* %_36, i64 %a635)
  br label %if.end7
if.end7:
  %a741 = load i64, i64* %a712
  %a742 = icmp eq i64 %a741, 7
  br i1 %a742, label %if.then8, label %if.else9
if.then8:
  %_43 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_44 = call i32 (i8*, ...) @printf(i8* %_43, i64 1)
  br label %if.end10
if.else9:
  %_45 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_46 = call i32 (i8*, ...) @printf(i8* %_45, i64 0)
  %a747 = load i64, i64* %a712
  %_48 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_49 = call i32 (i8*, ...) @printf(i8* %_48, i64 %a747)
  br label %if.end10
if.end10:
  %a853 = load i64, i64* %a814
  %a854 = icmp eq i64 %a853, 8
  br i1 %a854, label %if.then11, label %if.else12
if.then11:
  %_55 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_56 = call i32 (i8*, ...) @printf(i8* %_55, i64 1)
  br label %if.end13
if.else12:
  %_57 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_58 = call i32 (i8*, ...) @printf(i8* %_57, i64 0)
  %a859 = load i64, i64* %a814
  %_60 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_61 = call i32 (i8*, ...) @printf(i8* %_60, i64 %a859)
  br label %if.end13
if.end13:
  br label %exit
exit:
  ret void
}

define i64 @returnint(i64 %ret) {
entry:
  %_0 = alloca i64
  %ret1 = alloca i64
  store i64 %ret, i64* %ret1
  br label %body1
body1:
  %ret4 = load i64, i64* %ret1
  store i64 %ret4, i64* %_0
  br label %exit
exit:
  %_7 = load i64, i64* %_0
  ret i64 %_7
}

define i1 @returnbool(i1 %ret) {
entry:
  %_0 = alloca i1
  %ret1 = alloca i1
  store i1 %ret, i1* %ret1
  br label %body1
body1:
  %ret4 = load i1, i1* %ret1
  store i1 %ret4, i1* %_0
  br label %exit
exit:
  %_7 = load i1, i1* %_0
  ret i1 %_7
}

define %struct.thing* @returnstruct(%struct.thing* %ret) {
entry:
  %_0 = alloca %struct.thing*
  %ret1 = alloca %struct.thing*
  store %struct.thing* %ret, %struct.thing** %ret1
  br label %body1
body1:
  %ret4 = load %struct.thing*, %struct.thing** %ret1
  store %struct.thing* %ret4, %struct.thing** %_0
  br label %exit
exit:
  %_7 = load %struct.thing*, %struct.thing** %_0
  ret %struct.thing* %_7
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %b11 = alloca i1
  %b22 = alloca i1
  %i13 = alloca i64
  %i24 = alloca i64
  %i35 = alloca i64
  %s16 = alloca %struct.thing*
  %s27 = alloca %struct.thing*
  br label %body1
body1:
  store i64 0, i64* @counter
  call void (i64) @printgroup(i64 1)
  store i1 0, i1* %b11
  store i1 0, i1* %b22
  %b113 = load i1, i1* %b11
  %b214 = load i1, i1* %b22
  %_15 = and i1 %b113, %b214
  br i1 %_15, label %if.then2, label %if.else3
if.then2:
  %_16 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_17 = call i32 (i8*, ...) @printf(i8* %_16, i64 0)
  br label %if.end4
if.else3:
  %_18 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_19 = call i32 (i8*, ...) @printf(i8* %_18, i64 1)
  br label %if.end4
if.end4:
  store i1 1, i1* %b11
  store i1 0, i1* %b22
  %b125 = load i1, i1* %b11
  %b226 = load i1, i1* %b22
  %_27 = and i1 %b125, %b226
  br i1 %_27, label %if.then5, label %if.else6
if.then5:
  %_28 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_29 = call i32 (i8*, ...) @printf(i8* %_28, i64 0)
  br label %if.end7
if.else6:
  %_30 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_31 = call i32 (i8*, ...) @printf(i8* %_30, i64 1)
  br label %if.end7
if.end7:
  store i1 0, i1* %b11
  store i1 1, i1* %b22
  %b137 = load i1, i1* %b11
  %b238 = load i1, i1* %b22
  %_39 = and i1 %b137, %b238
  br i1 %_39, label %if.then8, label %if.else9
if.then8:
  %_40 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_41 = call i32 (i8*, ...) @printf(i8* %_40, i64 0)
  br label %if.end10
if.else9:
  %_42 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_43 = call i32 (i8*, ...) @printf(i8* %_42, i64 1)
  br label %if.end10
if.end10:
  store i1 1, i1* %b11
  store i1 1, i1* %b22
  %b149 = load i1, i1* %b11
  %b250 = load i1, i1* %b22
  %_51 = and i1 %b149, %b250
  br i1 %_51, label %if.then11, label %if.else12
if.then11:
  %_52 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_53 = call i32 (i8*, ...) @printf(i8* %_52, i64 1)
  br label %if.end13
if.else12:
  %_54 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_55 = call i32 (i8*, ...) @printf(i8* %_54, i64 0)
  br label %if.end13
if.end13:
  store i64 0, i64* @counter
  call void (i64) @printgroup(i64 2)
  store i1 1, i1* %b11
  store i1 1, i1* %b22
  %b163 = load i1, i1* %b11
  %b264 = load i1, i1* %b22
  %_65 = or i1 %b163, %b264
  br i1 %_65, label %if.then14, label %if.else15
if.then14:
  %_66 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_67 = call i32 (i8*, ...) @printf(i8* %_66, i64 1)
  br label %if.end16
if.else15:
  %_68 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_69 = call i32 (i8*, ...) @printf(i8* %_68, i64 0)
  br label %if.end16
if.end16:
  store i1 1, i1* %b11
  store i1 0, i1* %b22
  %b175 = load i1, i1* %b11
  %b276 = load i1, i1* %b22
  %_77 = or i1 %b175, %b276
  br i1 %_77, label %if.then17, label %if.else18
if.then17:
  %_78 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_79 = call i32 (i8*, ...) @printf(i8* %_78, i64 1)
  br label %if.end19
if.else18:
  %_80 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_81 = call i32 (i8*, ...) @printf(i8* %_80, i64 0)
  br label %if.end19
if.end19:
  store i1 0, i1* %b11
  store i1 1, i1* %b22
  %b187 = load i1, i1* %b11
  %b288 = load i1, i1* %b22
  %_89 = or i1 %b187, %b288
  br i1 %_89, label %if.then20, label %if.else21
if.then20:
  %_90 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_91 = call i32 (i8*, ...) @printf(i8* %_90, i64 1)
  br label %if.end22
if.else21:
  %_92 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_93 = call i32 (i8*, ...) @printf(i8* %_92, i64 0)
  br label %if.end22
if.end22:
  store i1 0, i1* %b11
  store i1 0, i1* %b22
  %b199 = load i1, i1* %b11
  %b2100 = load i1, i1* %b22
  %_101 = or i1 %b199, %b2100
  br i1 %_101, label %if.then23, label %if.else24
if.then23:
  %_102 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_103 = call i32 (i8*, ...) @printf(i8* %_102, i64 0)
  br label %if.end25
if.else24:
  %_104 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_105 = call i32 (i8*, ...) @printf(i8* %_104, i64 1)
  br label %if.end25
if.end25:
  call void (i64) @printgroup(i64 3)
  %_110 = icmp sgt i64 42, 1
  br i1 %_110, label %if.then26, label %if.else27
if.then26:
  %_111 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_112 = call i32 (i8*, ...) @printf(i8* %_111, i64 1)
  br label %if.end28
if.else27:
  %_113 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_114 = call i32 (i8*, ...) @printf(i8* %_113, i64 0)
  br label %if.end28
if.end28:
  %_118 = icmp sge i64 42, 1
  br i1 %_118, label %if.then29, label %if.else30
if.then29:
  %_119 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_120 = call i32 (i8*, ...) @printf(i8* %_119, i64 1)
  br label %if.end31
if.else30:
  %_121 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_122 = call i32 (i8*, ...) @printf(i8* %_121, i64 0)
  br label %if.end31
if.end31:
  %_126 = icmp slt i64 42, 1
  br i1 %_126, label %if.then32, label %if.else33
if.then32:
  %_127 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_128 = call i32 (i8*, ...) @printf(i8* %_127, i64 0)
  br label %if.end34
if.else33:
  %_129 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_130 = call i32 (i8*, ...) @printf(i8* %_129, i64 1)
  br label %if.end34
if.end34:
  %_134 = icmp sle i64 42, 1
  br i1 %_134, label %if.then35, label %if.else36
if.then35:
  %_135 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_136 = call i32 (i8*, ...) @printf(i8* %_135, i64 0)
  br label %if.end37
if.else36:
  %_137 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_138 = call i32 (i8*, ...) @printf(i8* %_137, i64 1)
  br label %if.end37
if.end37:
  %_142 = icmp eq i64 42, 1
  br i1 %_142, label %if.then38, label %if.else39
if.then38:
  %_143 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_144 = call i32 (i8*, ...) @printf(i8* %_143, i64 0)
  br label %if.end40
if.else39:
  %_145 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_146 = call i32 (i8*, ...) @printf(i8* %_145, i64 1)
  br label %if.end40
if.end40:
  %_150 = icmp ne i64 42, 1
  br i1 %_150, label %if.then41, label %if.else42
if.then41:
  %_151 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_152 = call i32 (i8*, ...) @printf(i8* %_151, i64 1)
  br label %if.end43
if.else42:
  %_153 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_154 = call i32 (i8*, ...) @printf(i8* %_153, i64 0)
  br label %if.end43
if.end43:
  br i1 1, label %if.then44, label %if.else45
if.then44:
  %_158 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_159 = call i32 (i8*, ...) @printf(i8* %_158, i64 1)
  br label %if.end46
if.else45:
  %_160 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_161 = call i32 (i8*, ...) @printf(i8* %_160, i64 0)
  br label %if.end46
if.end46:
  %_165 = xor i1 1, 1
  br i1 %_165, label %if.then47, label %if.else48
if.then47:
  %_166 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_167 = call i32 (i8*, ...) @printf(i8* %_166, i64 0)
  br label %if.end49
if.else48:
  %_168 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_169 = call i32 (i8*, ...) @printf(i8* %_168, i64 1)
  br label %if.end49
if.end49:
  br i1 0, label %if.then50, label %if.else51
if.then50:
  %_173 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_174 = call i32 (i8*, ...) @printf(i8* %_173, i64 0)
  br label %if.end52
if.else51:
  %_175 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_176 = call i32 (i8*, ...) @printf(i8* %_175, i64 1)
  br label %if.end52
if.end52:
  %_180 = xor i1 0, 1
  br i1 %_180, label %if.then53, label %if.else54
if.then53:
  %_181 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_182 = call i32 (i8*, ...) @printf(i8* %_181, i64 1)
  br label %if.end55
if.else54:
  %_183 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_184 = call i32 (i8*, ...) @printf(i8* %_183, i64 0)
  br label %if.end55
if.end55:
  %_188 = xor i1 0, 1
  br i1 %_188, label %if.then56, label %if.else57
if.then56:
  %_189 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_190 = call i32 (i8*, ...) @printf(i8* %_189, i64 1)
  br label %if.end58
if.else57:
  %_191 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_192 = call i32 (i8*, ...) @printf(i8* %_191, i64 0)
  br label %if.end58
if.end58:
  call void (i64) @printgroup(i64 4)
  %_197 = add i64 2, 3
  %_198 = icmp eq i64 %_197, 5
  br i1 %_198, label %if.then59, label %if.else60
if.then59:
  %_199 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_200 = call i32 (i8*, ...) @printf(i8* %_199, i64 1)
  br label %if.end61
if.else60:
  %_201 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_202 = call i32 (i8*, ...) @printf(i8* %_201, i64 0)
  %_203 = add i64 2, 3
  %_204 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_205 = call i32 (i8*, ...) @printf(i8* %_204, i64 %_203)
  br label %if.end61
if.end61:
  %_209 = mul i64 2, 3
  %_210 = icmp eq i64 %_209, 6
  br i1 %_210, label %if.then62, label %if.else63
if.then62:
  %_211 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_212 = call i32 (i8*, ...) @printf(i8* %_211, i64 1)
  br label %if.end64
if.else63:
  %_213 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_214 = call i32 (i8*, ...) @printf(i8* %_213, i64 0)
  %_215 = mul i64 2, 3
  %_216 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_217 = call i32 (i8*, ...) @printf(i8* %_216, i64 %_215)
  br label %if.end64
if.end64:
  %_221 = sub i64 3, 2
  %_222 = icmp eq i64 %_221, 1
  br i1 %_222, label %if.then65, label %if.else66
if.then65:
  %_223 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_224 = call i32 (i8*, ...) @printf(i8* %_223, i64 1)
  br label %if.end67
if.else66:
  %_225 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_226 = call i32 (i8*, ...) @printf(i8* %_225, i64 0)
  %_227 = sub i64 3, 2
  %_228 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_229 = call i32 (i8*, ...) @printf(i8* %_228, i64 %_227)
  br label %if.end67
if.end67:
  %_233 = sdiv i64 6, 3
  %_234 = icmp eq i64 %_233, 2
  br i1 %_234, label %if.then68, label %if.else69
if.then68:
  %_235 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_236 = call i32 (i8*, ...) @printf(i8* %_235, i64 1)
  br label %if.end70
if.else69:
  %_237 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_238 = call i32 (i8*, ...) @printf(i8* %_237, i64 0)
  %_239 = sdiv i64 6, 3
  %_240 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_241 = call i32 (i8*, ...) @printf(i8* %_240, i64 %_239)
  br label %if.end70
if.end70:
  %_245 = sub i64 0, 6
  %_246 = icmp slt i64 %_245, 0
  br i1 %_246, label %if.then71, label %if.else72
if.then71:
  %_247 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_248 = call i32 (i8*, ...) @printf(i8* %_247, i64 1)
  br label %if.end73
if.else72:
  %_249 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_250 = call i32 (i8*, ...) @printf(i8* %_249, i64 0)
  br label %if.end73
if.end73:
  call void (i64) @printgroup(i64 5)
  store i64 42, i64* %i13
  %i1256 = load i64, i64* %i13
  %i1257 = icmp eq i64 %i1256, 42
  br i1 %i1257, label %if.then74, label %if.else75
if.then74:
  %_258 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_259 = call i32 (i8*, ...) @printf(i8* %_258, i64 1)
  br label %if.end76
if.else75:
  %_260 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_261 = call i32 (i8*, ...) @printf(i8* %_260, i64 0)
  br label %if.end76
if.end76:
  store i64 3, i64* %i13
  store i64 2, i64* %i24
  %i1267 = load i64, i64* %i13
  %i2268 = load i64, i64* %i24
  %_269 = add i64 %i1267, %i2268
  store i64 %_269, i64* %i35
  %i3271 = load i64, i64* %i35
  %i3272 = icmp eq i64 %i3271, 5
  br i1 %i3272, label %if.then77, label %if.else78
if.then77:
  %_273 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_274 = call i32 (i8*, ...) @printf(i8* %_273, i64 1)
  br label %if.end79
if.else78:
  %_275 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_276 = call i32 (i8*, ...) @printf(i8* %_275, i64 0)
  br label %if.end79
if.end79:
  store i1 1, i1* %b11
  %b1281 = load i1, i1* %b11
  br i1 %b1281, label %if.then80, label %if.else81
if.then80:
  %_282 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_283 = call i32 (i8*, ...) @printf(i8* %_282, i64 1)
  br label %if.end82
if.else81:
  %_284 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_285 = call i32 (i8*, ...) @printf(i8* %_284, i64 0)
  br label %if.end82
if.end82:
  %b1289 = load i1, i1* %b11
  %b1290 = xor i1 %b1289, 1
  br i1 %b1290, label %if.then83, label %if.else84
if.then83:
  %_291 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_292 = call i32 (i8*, ...) @printf(i8* %_291, i64 0)
  br label %if.end85
if.else84:
  %_293 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_294 = call i32 (i8*, ...) @printf(i8* %_293, i64 1)
  br label %if.end85
if.end85:
  store i1 0, i1* %b11
  %b1299 = load i1, i1* %b11
  br i1 %b1299, label %if.then86, label %if.else87
if.then86:
  %_300 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_301 = call i32 (i8*, ...) @printf(i8* %_300, i64 0)
  br label %if.end88
if.else87:
  %_302 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_303 = call i32 (i8*, ...) @printf(i8* %_302, i64 1)
  br label %if.end88
if.end88:
  %b1307 = load i1, i1* %b11
  %b1308 = xor i1 %b1307, 1
  br i1 %b1308, label %if.then89, label %if.else90
if.then89:
  %_309 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_310 = call i32 (i8*, ...) @printf(i8* %_309, i64 1)
  br label %if.end91
if.else90:
  %_311 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_312 = call i32 (i8*, ...) @printf(i8* %_311, i64 0)
  br label %if.end91
if.end91:
  %b1316 = load i1, i1* %b11
  br i1 %b1316, label %if.then92, label %if.else93
if.then92:
  %_317 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_318 = call i32 (i8*, ...) @printf(i8* %_317, i64 0)
  br label %if.end94
if.else93:
  %_319 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_320 = call i32 (i8*, ...) @printf(i8* %_319, i64 1)
  br label %if.end94
if.end94:
  call void (i64) @printgroup(i64 6)
  store i64 0, i64* %i13
  %i1326 = load i64, i64* %i13
  %i1327 = icmp slt i64 %i1326, 5
  br i1 %i1327, label %while.body95, label %while.end98
while.body95:
  %i1328 = load i64, i64* %i13
  %i1329 = icmp sge i64 %i1328, 5
  br i1 %i1329, label %if.then96, label %if.end97
if.then96:
  %_330 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_331 = call i32 (i8*, ...) @printf(i8* %_330, i64 0)
  br label %if.end97
if.end97:
  %i1334 = load i64, i64* %i13
  %i1335 = add i64 %i1334, 5
  store i64 %i1335, i64* %i13
  %i1337 = load i64, i64* %i13
  %i1338 = icmp slt i64 %i1337, 5
  br i1 %i1338, label %while.body95, label %while.end98
while.end98:
  %i1341 = load i64, i64* %i13
  %i1342 = icmp eq i64 %i1341, 5
  br i1 %i1342, label %if.then99, label %if.else100
if.then99:
  %_343 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_344 = call i32 (i8*, ...) @printf(i8* %_343, i64 1)
  br label %if.end101
if.else100:
  %_345 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_346 = call i32 (i8*, ...) @printf(i8* %_345, i64 0)
  %i1347 = load i64, i64* %i13
  %_348 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_349 = call i32 (i8*, ...) @printf(i8* %_348, i64 %i1347)
  br label %if.end101
if.end101:
  call void (i64) @printgroup(i64 7)
  %thing354 = call i8* (i32) @malloc(i32 24)
  %thing355 = bitcast i8* %thing354 to %struct.thing*
  store %struct.thing* %thing355, %struct.thing** %s16
  %s1357 = load %struct.thing*, %struct.thing** %s16
  %i358 = getelementptr %struct.thing, %struct.thing* %s1357, i1 0, i32 0
  store i64 42, i64* %i358
  %s1360 = load %struct.thing*, %struct.thing** %s16
  %b361 = getelementptr %struct.thing, %struct.thing* %s1360, i1 0, i32 1
  store i1 1, i1* %b361
  %s1363 = load %struct.thing*, %struct.thing** %s16
  %i364 = getelementptr %struct.thing, %struct.thing* %s1363, i1 0, i32 0
  %i365 = load i64, i64* %i364
  %i366 = icmp eq i64 %i365, 42
  br i1 %i366, label %if.then102, label %if.else103
if.then102:
  %_367 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_368 = call i32 (i8*, ...) @printf(i8* %_367, i64 1)
  br label %if.end104
if.else103:
  %_369 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_370 = call i32 (i8*, ...) @printf(i8* %_369, i64 0)
  %s1371 = load %struct.thing*, %struct.thing** %s16
  %i372 = getelementptr %struct.thing, %struct.thing* %s1371, i1 0, i32 0
  %i373 = load i64, i64* %i372
  %_374 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_375 = call i32 (i8*, ...) @printf(i8* %_374, i64 %i373)
  br label %if.end104
if.end104:
  %s1379 = load %struct.thing*, %struct.thing** %s16
  %b380 = getelementptr %struct.thing, %struct.thing* %s1379, i1 0, i32 1
  %b381 = load i1, i1* %b380
  br i1 %b381, label %if.then105, label %if.else106
if.then105:
  %_382 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_383 = call i32 (i8*, ...) @printf(i8* %_382, i64 1)
  br label %if.end107
if.else106:
  %_384 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_385 = call i32 (i8*, ...) @printf(i8* %_384, i64 0)
  br label %if.end107
if.end107:
  %s1389 = load %struct.thing*, %struct.thing** %s16
  %s390 = getelementptr %struct.thing, %struct.thing* %s1389, i1 0, i32 2
  %thing391 = call i8* (i32) @malloc(i32 24)
  %thing392 = bitcast i8* %thing391 to %struct.thing*
  store %struct.thing* %thing392, %struct.thing** %s390
  %s1394 = load %struct.thing*, %struct.thing** %s16
  %s395 = getelementptr %struct.thing, %struct.thing* %s1394, i1 0, i32 2
  %thing396 = load %struct.thing*, %struct.thing** %s395
  %i397 = getelementptr %struct.thing, %struct.thing* %thing396, i1 0, i32 0
  store i64 13, i64* %i397
  %s1399 = load %struct.thing*, %struct.thing** %s16
  %s400 = getelementptr %struct.thing, %struct.thing* %s1399, i1 0, i32 2
  %thing401 = load %struct.thing*, %struct.thing** %s400
  %b402 = getelementptr %struct.thing, %struct.thing* %thing401, i1 0, i32 1
  store i1 0, i1* %b402
  %s1404 = load %struct.thing*, %struct.thing** %s16
  %s405 = getelementptr %struct.thing, %struct.thing* %s1404, i1 0, i32 2
  %thing406 = load %struct.thing*, %struct.thing** %s405
  %i407 = getelementptr %struct.thing, %struct.thing* %thing406, i1 0, i32 0
  %i408 = load i64, i64* %i407
  %i409 = icmp eq i64 %i408, 13
  br i1 %i409, label %if.then108, label %if.else109
if.then108:
  %_410 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_411 = call i32 (i8*, ...) @printf(i8* %_410, i64 1)
  br label %if.end110
if.else109:
  %_412 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_413 = call i32 (i8*, ...) @printf(i8* %_412, i64 0)
  %s1414 = load %struct.thing*, %struct.thing** %s16
  %s415 = getelementptr %struct.thing, %struct.thing* %s1414, i1 0, i32 2
  %thing416 = load %struct.thing*, %struct.thing** %s415
  %i417 = getelementptr %struct.thing, %struct.thing* %thing416, i1 0, i32 0
  %i418 = load i64, i64* %i417
  %_419 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_420 = call i32 (i8*, ...) @printf(i8* %_419, i64 %i418)
  br label %if.end110
if.end110:
  %s1424 = load %struct.thing*, %struct.thing** %s16
  %s425 = getelementptr %struct.thing, %struct.thing* %s1424, i1 0, i32 2
  %thing426 = load %struct.thing*, %struct.thing** %s425
  %b427 = getelementptr %struct.thing, %struct.thing* %thing426, i1 0, i32 1
  %b428 = load i1, i1* %b427
  %b429 = xor i1 %b428, 1
  br i1 %b429, label %if.then111, label %if.else112
if.then111:
  %_430 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_431 = call i32 (i8*, ...) @printf(i8* %_430, i64 1)
  br label %if.end113
if.else112:
  %_432 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_433 = call i32 (i8*, ...) @printf(i8* %_432, i64 0)
  br label %if.end113
if.end113:
  %s1437 = load %struct.thing*, %struct.thing** %s16
  %s1438 = load %struct.thing*, %struct.thing** %s16
  %_439 = icmp eq %struct.thing* %s1437, %s1438
  br i1 %_439, label %if.then114, label %if.else115
if.then114:
  %_440 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_441 = call i32 (i8*, ...) @printf(i8* %_440, i64 1)
  br label %if.end116
if.else115:
  %_442 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_443 = call i32 (i8*, ...) @printf(i8* %_442, i64 0)
  br label %if.end116
if.end116:
  %s1447 = load %struct.thing*, %struct.thing** %s16
  %s1448 = load %struct.thing*, %struct.thing** %s16
  %s449 = getelementptr %struct.thing, %struct.thing* %s1448, i1 0, i32 2
  %s450 = load %struct.thing*, %struct.thing** %s449
  %_451 = icmp ne %struct.thing* %s1447, %s450
  br i1 %_451, label %if.then117, label %if.else118
if.then117:
  %_452 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_453 = call i32 (i8*, ...) @printf(i8* %_452, i64 1)
  br label %if.end119
if.else118:
  %_454 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_455 = call i32 (i8*, ...) @printf(i8* %_454, i64 0)
  br label %if.end119
if.end119:
  %s1459 = load %struct.thing*, %struct.thing** %s16
  %s460 = getelementptr %struct.thing, %struct.thing* %s1459, i1 0, i32 2
  %s461 = load %struct.thing*, %struct.thing** %s460
  %_462 = bitcast %struct.thing* %s461 to i8*
  call void (i8*) @free(i8* %_462)
  %s1464 = load %struct.thing*, %struct.thing** %s16
  %_465 = bitcast %struct.thing* %s1464 to i8*
  call void (i8*) @free(i8* %_465)
  call void (i64) @printgroup(i64 8)
  store i64 7, i64* @gi1
  %gi1469 = load i64, i64* @gi1
  %gi1470 = icmp eq i64 %gi1469, 7
  br i1 %gi1470, label %if.then120, label %if.else121
if.then120:
  %_471 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_472 = call i32 (i8*, ...) @printf(i8* %_471, i64 1)
  br label %if.end122
if.else121:
  %_473 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_474 = call i32 (i8*, ...) @printf(i8* %_473, i64 0)
  %gi1475 = load i64, i64* @gi1
  %_476 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_477 = call i32 (i8*, ...) @printf(i8* %_476, i64 %gi1475)
  br label %if.end122
if.end122:
  store i1 1, i1* @gb1
  %gb1482 = load i1, i1* @gb1
  br i1 %gb1482, label %if.then123, label %if.else124
if.then123:
  %_483 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_484 = call i32 (i8*, ...) @printf(i8* %_483, i64 1)
  br label %if.end125
if.else124:
  %_485 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_486 = call i32 (i8*, ...) @printf(i8* %_485, i64 0)
  br label %if.end125
if.end125:
  %thing490 = call i8* (i32) @malloc(i32 24)
  %thing491 = bitcast i8* %thing490 to %struct.thing*
  store %struct.thing* %thing491, %struct.thing** @gs1
  %gs1493 = load %struct.thing*, %struct.thing** @gs1
  %i494 = getelementptr %struct.thing, %struct.thing* %gs1493, i1 0, i32 0
  store i64 34, i64* %i494
  %gs1496 = load %struct.thing*, %struct.thing** @gs1
  %b497 = getelementptr %struct.thing, %struct.thing* %gs1496, i1 0, i32 1
  store i1 0, i1* %b497
  %gs1499 = load %struct.thing*, %struct.thing** @gs1
  %i500 = getelementptr %struct.thing, %struct.thing* %gs1499, i1 0, i32 0
  %i501 = load i64, i64* %i500
  %i502 = icmp eq i64 %i501, 34
  br i1 %i502, label %if.then126, label %if.else127
if.then126:
  %_503 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_504 = call i32 (i8*, ...) @printf(i8* %_503, i64 1)
  br label %if.end128
if.else127:
  %_505 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_506 = call i32 (i8*, ...) @printf(i8* %_505, i64 0)
  %gs1507 = load %struct.thing*, %struct.thing** @gs1
  %i508 = getelementptr %struct.thing, %struct.thing* %gs1507, i1 0, i32 0
  %i509 = load i64, i64* %i508
  %_510 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_511 = call i32 (i8*, ...) @printf(i8* %_510, i64 %i509)
  br label %if.end128
if.end128:
  %gs1515 = load %struct.thing*, %struct.thing** @gs1
  %b516 = getelementptr %struct.thing, %struct.thing* %gs1515, i1 0, i32 1
  %b517 = load i1, i1* %b516
  %b518 = xor i1 %b517, 1
  br i1 %b518, label %if.then129, label %if.else130
if.then129:
  %_519 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_520 = call i32 (i8*, ...) @printf(i8* %_519, i64 1)
  br label %if.end131
if.else130:
  %_521 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_522 = call i32 (i8*, ...) @printf(i8* %_521, i64 0)
  br label %if.end131
if.end131:
  %gs1526 = load %struct.thing*, %struct.thing** @gs1
  %s527 = getelementptr %struct.thing, %struct.thing* %gs1526, i1 0, i32 2
  %thing528 = call i8* (i32) @malloc(i32 24)
  %thing529 = bitcast i8* %thing528 to %struct.thing*
  store %struct.thing* %thing529, %struct.thing** %s527
  %gs1531 = load %struct.thing*, %struct.thing** @gs1
  %s532 = getelementptr %struct.thing, %struct.thing* %gs1531, i1 0, i32 2
  %thing533 = load %struct.thing*, %struct.thing** %s532
  %i534 = getelementptr %struct.thing, %struct.thing* %thing533, i1 0, i32 0
  store i64 16, i64* %i534
  %gs1536 = load %struct.thing*, %struct.thing** @gs1
  %s537 = getelementptr %struct.thing, %struct.thing* %gs1536, i1 0, i32 2
  %thing538 = load %struct.thing*, %struct.thing** %s537
  %b539 = getelementptr %struct.thing, %struct.thing* %thing538, i1 0, i32 1
  store i1 1, i1* %b539
  %gs1541 = load %struct.thing*, %struct.thing** @gs1
  %s542 = getelementptr %struct.thing, %struct.thing* %gs1541, i1 0, i32 2
  %thing543 = load %struct.thing*, %struct.thing** %s542
  %i544 = getelementptr %struct.thing, %struct.thing* %thing543, i1 0, i32 0
  %i545 = load i64, i64* %i544
  %i546 = icmp eq i64 %i545, 16
  br i1 %i546, label %if.then132, label %if.else133
if.then132:
  %_547 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_548 = call i32 (i8*, ...) @printf(i8* %_547, i64 1)
  br label %if.end134
if.else133:
  %_549 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_550 = call i32 (i8*, ...) @printf(i8* %_549, i64 0)
  %gs1551 = load %struct.thing*, %struct.thing** @gs1
  %s552 = getelementptr %struct.thing, %struct.thing* %gs1551, i1 0, i32 2
  %thing553 = load %struct.thing*, %struct.thing** %s552
  %i554 = getelementptr %struct.thing, %struct.thing* %thing553, i1 0, i32 0
  %i555 = load i64, i64* %i554
  %_556 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_557 = call i32 (i8*, ...) @printf(i8* %_556, i64 %i555)
  br label %if.end134
if.end134:
  %gs1561 = load %struct.thing*, %struct.thing** @gs1
  %s562 = getelementptr %struct.thing, %struct.thing* %gs1561, i1 0, i32 2
  %thing563 = load %struct.thing*, %struct.thing** %s562
  %b564 = getelementptr %struct.thing, %struct.thing* %thing563, i1 0, i32 1
  %b565 = load i1, i1* %b564
  br i1 %b565, label %if.then135, label %if.else136
if.then135:
  %_566 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_567 = call i32 (i8*, ...) @printf(i8* %_566, i64 1)
  br label %if.end137
if.else136:
  %_568 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_569 = call i32 (i8*, ...) @printf(i8* %_568, i64 0)
  br label %if.end137
if.end137:
  %gs1573 = load %struct.thing*, %struct.thing** @gs1
  %s574 = getelementptr %struct.thing, %struct.thing* %gs1573, i1 0, i32 2
  %s575 = load %struct.thing*, %struct.thing** %s574
  %_576 = bitcast %struct.thing* %s575 to i8*
  call void (i8*) @free(i8* %_576)
  %gs1578 = load %struct.thing*, %struct.thing** @gs1
  %_579 = bitcast %struct.thing* %gs1578 to i8*
  call void (i8*) @free(i8* %_579)
  call void (i64) @printgroup(i64 9)
  %thing582 = call i8* (i32) @malloc(i32 24)
  %thing583 = bitcast i8* %thing582 to %struct.thing*
  store %struct.thing* %thing583, %struct.thing** %s16
  %s1585 = load %struct.thing*, %struct.thing** %s16
  %b586 = getelementptr %struct.thing, %struct.thing* %s1585, i1 0, i32 1
  store i1 1, i1* %b586
  %s1588 = load %struct.thing*, %struct.thing** %s16
  call void (i64, i1, %struct.thing*) @takealltypes(i64 3, i1 1, %struct.thing* %s1588)
  %_590 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_591 = call i32 (i8*, ...) @printf(i8* %_590, i64 2)
  call void (i64, i64, i64, i64, i64, i64, i64, i64) @tonofargs(i64 1, i64 2, i64 3, i64 4, i64 5, i64 6, i64 7, i64 8)
  %_593 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_594 = call i32 (i8*, ...) @printf(i8* %_593, i64 3)
  %returnint595 = call i64 (i64) @returnint(i64 3)
  store i64 %returnint595, i64* %i13
  %i1597 = load i64, i64* %i13
  %i1598 = icmp eq i64 %i1597, 3
  br i1 %i1598, label %if.then138, label %if.else139
if.then138:
  %_599 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_600 = call i32 (i8*, ...) @printf(i8* %_599, i64 1)
  br label %if.end140
if.else139:
  %_601 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_602 = call i32 (i8*, ...) @printf(i8* %_601, i64 0)
  %i1603 = load i64, i64* %i13
  %_604 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_605 = call i32 (i8*, ...) @printf(i8* %_604, i64 %i1603)
  br label %if.end140
if.end140:
  %returnbool609 = call i1 (i1) @returnbool(i1 1)
  store i1 %returnbool609, i1* %b11
  %b1611 = load i1, i1* %b11
  br i1 %b1611, label %if.then141, label %if.else142
if.then141:
  %_612 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_613 = call i32 (i8*, ...) @printf(i8* %_612, i64 1)
  br label %if.end143
if.else142:
  %_614 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_615 = call i32 (i8*, ...) @printf(i8* %_614, i64 0)
  br label %if.end143
if.end143:
  %thing619 = call i8* (i32) @malloc(i32 24)
  %thing620 = bitcast i8* %thing619 to %struct.thing*
  store %struct.thing* %thing620, %struct.thing** %s16
  %s1622 = load %struct.thing*, %struct.thing** %s16
  %returnstruct623 = call %struct.thing* (%struct.thing*) @returnstruct(%struct.thing* %s1622)
  store %struct.thing* %returnstruct623, %struct.thing** %s27
  %s1625 = load %struct.thing*, %struct.thing** %s16
  %s2626 = load %struct.thing*, %struct.thing** %s27
  %_627 = icmp eq %struct.thing* %s1625, %s2626
  br i1 %_627, label %if.then144, label %if.else145
if.then144:
  %_628 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_629 = call i32 (i8*, ...) @printf(i8* %_628, i64 1)
  br label %if.end146
if.else145:
  %_630 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_631 = call i32 (i8*, ...) @printf(i8* %_630, i64 0)
  br label %if.end146
if.end146:
  call void (i64) @printgroup(i64 10)
  store i64 0, i64* %_0
  br label %exit
exit:
  %_638 = load i64, i64* %_0
  ret i64 %_638
}

