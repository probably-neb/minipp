declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

@global1 = global i64 undef, align 8
@global2 = global i64 undef, align 8
@global3 = global i64 undef, align 8

define i64 @constantFolding() {
entry:
  %_0 = alloca i64
  %a1 = alloca i64
  br label %body1
body1:
  %_3 = mul i64 8, 9
  %_4 = sdiv i64 %_3, 4
  %_5 = add i64 %_4, 2
  %_6 = mul i64 5, 8
  %_7 = sub i64 %_5, %_6
  %_8 = add i64 %_7, 9
  %_9 = sub i64 %_8, 12
  %_10 = add i64 %_9, 6
  %_11 = sub i64 %_10, 9
  %_12 = sub i64 %_11, 18
  %_13 = mul i64 23, 3
  %_14 = sdiv i64 %_13, 23
  %_15 = mul i64 %_14, 90
  %_16 = add i64 %_12, %_15
  store i64 %_16, i64* %a1
  %a18 = load i64, i64* %a1
  store i64 %a18, i64* %_0
  br label %exit
exit:
  %_21 = load i64, i64* %_0
  ret i64 %_21
}

define i64 @constantPropagation() {
entry:
  %_0 = alloca i64
  %a1 = alloca i64
  %b2 = alloca i64
  %c3 = alloca i64
  %d4 = alloca i64
  %e5 = alloca i64
  %f6 = alloca i64
  %g7 = alloca i64
  %h8 = alloca i64
  %i9 = alloca i64
  %j10 = alloca i64
  %k11 = alloca i64
  %l12 = alloca i64
  %m13 = alloca i64
  %n14 = alloca i64
  %o15 = alloca i64
  %p16 = alloca i64
  %q17 = alloca i64
  %r18 = alloca i64
  %s19 = alloca i64
  %t20 = alloca i64
  %u21 = alloca i64
  %v22 = alloca i64
  %w23 = alloca i64
  %x24 = alloca i64
  %y25 = alloca i64
  %z26 = alloca i64
  br label %body1
body1:
  store i64 4, i64* %a1
  store i64 7, i64* %b2
  store i64 8, i64* %c3
  store i64 5, i64* %d4
  store i64 11, i64* %e5
  store i64 21, i64* %f6
  %a34 = load i64, i64* %a1
  %b35 = load i64, i64* %b2
  %_36 = add i64 %a34, %b35
  store i64 %_36, i64* %g7
  %c38 = load i64, i64* %c3
  %d39 = load i64, i64* %d4
  %_40 = add i64 %c38, %d39
  store i64 %_40, i64* %h8
  %e42 = load i64, i64* %e5
  %f43 = load i64, i64* %f6
  %_44 = add i64 %e42, %f43
  store i64 %_44, i64* %i9
  %g46 = load i64, i64* %g7
  %h47 = load i64, i64* %h8
  %_48 = add i64 %g46, %h47
  store i64 %_48, i64* %j10
  %i50 = load i64, i64* %i9
  %j51 = load i64, i64* %j10
  %_52 = mul i64 %i50, %j51
  store i64 %_52, i64* %k11
  %e54 = load i64, i64* %e5
  %h55 = load i64, i64* %h8
  %i56 = load i64, i64* %i9
  %_57 = mul i64 %h55, %i56
  %e58 = add i64 %e54, %_57
  %k59 = load i64, i64* %k11
  %_60 = sub i64 %e58, %k59
  store i64 %_60, i64* %l12
  %h62 = load i64, i64* %h8
  %i63 = load i64, i64* %i9
  %j64 = load i64, i64* %j10
  %_65 = mul i64 %i63, %j64
  %h66 = sub i64 %h62, %_65
  %k67 = load i64, i64* %k11
  %l68 = load i64, i64* %l12
  %_69 = sdiv i64 %k67, %l68
  %h70 = add i64 %h66, %_69
  store i64 %h70, i64* %m13
  %e72 = load i64, i64* %e5
  %f73 = load i64, i64* %f6
  %_74 = add i64 %e72, %f73
  %g75 = load i64, i64* %g7
  %g76 = add i64 %_74, %g75
  %h77 = load i64, i64* %h8
  %_78 = add i64 %g76, %h77
  %i79 = load i64, i64* %i9
  %i80 = add i64 %_78, %i79
  %j81 = load i64, i64* %j10
  %_82 = sub i64 %i80, %j81
  store i64 %_82, i64* %n14
  %n84 = load i64, i64* %n14
  %m85 = load i64, i64* %m13
  %_86 = sub i64 %n84, %m85
  %h87 = load i64, i64* %h8
  %h88 = add i64 %_86, %h87
  %a89 = load i64, i64* %a1
  %_90 = sub i64 %h88, %a89
  %b91 = load i64, i64* %b2
  %b92 = sub i64 %_90, %b91
  store i64 %b92, i64* %o15
  %k94 = load i64, i64* %k11
  %l95 = load i64, i64* %l12
  %_96 = add i64 %k94, %l95
  %g97 = load i64, i64* %g7
  %g98 = sub i64 %_96, %g97
  %h99 = load i64, i64* %h8
  %_100 = sub i64 %g98, %h99
  store i64 %_100, i64* %p16
  %b102 = load i64, i64* %b2
  %a103 = load i64, i64* %a1
  %_104 = sub i64 %b102, %a103
  %d105 = load i64, i64* %d4
  %d106 = mul i64 %_104, %d105
  %i107 = load i64, i64* %i9
  %_108 = sub i64 %d106, %i107
  store i64 %_108, i64* %q17
  %l110 = load i64, i64* %l12
  %c111 = load i64, i64* %c3
  %_112 = mul i64 %l110, %c111
  %d113 = load i64, i64* %d4
  %d114 = mul i64 %_112, %d113
  %o115 = load i64, i64* %o15
  %_116 = add i64 %d114, %o115
  store i64 %_116, i64* %r18
  %b118 = load i64, i64* %b2
  %a119 = load i64, i64* %a1
  %_120 = mul i64 %b118, %a119
  %c121 = load i64, i64* %c3
  %c122 = mul i64 %_120, %c121
  %e123 = load i64, i64* %e5
  %_124 = sdiv i64 %c122, %e123
  %o125 = load i64, i64* %o15
  %o126 = sub i64 %_124, %o125
  store i64 %o126, i64* %s19
  %i128 = load i64, i64* %i9
  %k129 = load i64, i64* %k11
  %_130 = add i64 %i128, %k129
  %c131 = load i64, i64* %c3
  %c132 = add i64 %_130, %c131
  %p133 = load i64, i64* %p16
  %_134 = sub i64 %c132, %p133
  store i64 %_134, i64* %t20
  %n136 = load i64, i64* %n14
  %o137 = load i64, i64* %o15
  %_138 = add i64 %n136, %o137
  %f139 = load i64, i64* %f6
  %a140 = load i64, i64* %a1
  %_141 = mul i64 %f139, %a140
  %_142 = sub i64 %_138, %_141
  store i64 %_142, i64* %u21
  %a144 = load i64, i64* %a1
  %b145 = load i64, i64* %b2
  %_146 = mul i64 %a144, %b145
  %k147 = load i64, i64* %k11
  %k148 = sub i64 %_146, %k147
  %l149 = load i64, i64* %l12
  %_150 = sub i64 %k148, %l149
  store i64 %_150, i64* %v22
  %v152 = load i64, i64* %v22
  %s153 = load i64, i64* %s19
  %_154 = sub i64 %v152, %s153
  %r155 = load i64, i64* %r18
  %d156 = load i64, i64* %d4
  %_157 = mul i64 %r155, %d156
  %_158 = sub i64 %_154, %_157
  store i64 %_158, i64* %w23
  %o160 = load i64, i64* %o15
  %w161 = load i64, i64* %w23
  %_162 = sub i64 %o160, %w161
  %v163 = load i64, i64* %v22
  %v164 = sub i64 %_162, %v163
  %n165 = load i64, i64* %n14
  %_166 = sub i64 %v164, %n165
  store i64 %_166, i64* %x24
  %p168 = load i64, i64* %p16
  %x169 = load i64, i64* %x24
  %_170 = mul i64 %p168, %x169
  %t171 = load i64, i64* %t20
  %t172 = add i64 %_170, %t171
  %w173 = load i64, i64* %w23
  %_174 = sub i64 %t172, %w173
  store i64 %_174, i64* %y25
  %w176 = load i64, i64* %w23
  %x177 = load i64, i64* %x24
  %_178 = sub i64 %w176, %x177
  %y179 = load i64, i64* %y25
  %y180 = add i64 %_178, %y179
  %k181 = load i64, i64* %k11
  %_182 = add i64 %y180, %k181
  store i64 %_182, i64* %z26
  %z184 = load i64, i64* %z26
  store i64 %z184, i64* %_0
  br label %exit
exit:
  %_187 = load i64, i64* %_0
  ret i64 %_187
}

define i64 @deadCodeElimination() {
entry:
  %_0 = alloca i64
  %a1 = alloca i64
  %b2 = alloca i64
  %c3 = alloca i64
  %d4 = alloca i64
  %e5 = alloca i64
  br label %body1
body1:
  store i64 4, i64* %a1
  store i64 5, i64* %a1
  store i64 7, i64* %a1
  store i64 8, i64* %a1
  store i64 6, i64* %b2
  store i64 9, i64* %b2
  store i64 12, i64* %b2
  store i64 8, i64* %b2
  store i64 10, i64* %c3
  store i64 13, i64* %c3
  store i64 9, i64* %c3
  store i64 45, i64* %d4
  store i64 12, i64* %d4
  store i64 3, i64* %d4
  store i64 23, i64* %e5
  store i64 10, i64* %e5
  store i64 11, i64* @global1
  store i64 5, i64* @global1
  store i64 9, i64* @global1
  %a26 = load i64, i64* %a1
  %b27 = load i64, i64* %b2
  %_28 = add i64 %a26, %b27
  %c29 = load i64, i64* %c3
  %c30 = add i64 %_28, %c29
  %d31 = load i64, i64* %d4
  %_32 = add i64 %c30, %d31
  %e33 = load i64, i64* %e5
  %e34 = add i64 %_32, %e33
  store i64 %e34, i64* %_0
  br label %exit
exit:
  %_37 = load i64, i64* %_0
  ret i64 %_37
}

define i64 @sum(i64 %number) {
entry:
  %_0 = alloca i64
  %total1 = alloca i64
  %number2 = alloca i64
  store i64 %number, i64* %number2
  br label %body1
body1:
  store i64 0, i64* %total1
  %number6 = load i64, i64* %number2
  %number7 = icmp sgt i64 %number6, 0
  br i1 %number7, label %while.body2, label %while.end3
while.body2:
  %total8 = load i64, i64* %total1
  %number9 = load i64, i64* %number2
  %_10 = add i64 %total8, %number9
  store i64 %_10, i64* %total1
  %number12 = load i64, i64* %number2
  %number13 = sub i64 %number12, 1
  store i64 %number13, i64* %number2
  %number15 = load i64, i64* %number2
  %number16 = icmp sgt i64 %number15, 0
  br i1 %number16, label %while.body2, label %while.end3
while.end3:
  %total19 = load i64, i64* %total1
  store i64 %total19, i64* %_0
  br label %exit
exit:
  %_22 = load i64, i64* %_0
  ret i64 %_22
}

define i64 @doesntModifyGlobals() {
entry:
  %_0 = alloca i64
  %a1 = alloca i64
  %b2 = alloca i64
  br label %body1
body1:
  store i64 1, i64* %a1
  store i64 2, i64* %b2
  %a6 = load i64, i64* %a1
  %b7 = load i64, i64* %b2
  %_8 = add i64 %a6, %b7
  store i64 %_8, i64* %_0
  br label %exit
exit:
  %_11 = load i64, i64* %_0
  ret i64 %_11
}

define i64 @interProceduralOptimization() {
entry:
  %_0 = alloca i64
  %a1 = alloca i64
  br label %body1
body1:
  store i64 1, i64* @global1
  store i64 0, i64* @global2
  store i64 0, i64* @global3
  %sum6 = call i64 (i64) @sum(i64 100)
  store i64 %sum6, i64* %a1
  %global18 = load i64, i64* @global1
  %global19 = icmp eq i64 %global18, 1
  br i1 %global19, label %if.then2, label %if.else3
if.then2:
  %sum10 = call i64 (i64) @sum(i64 10000)
  store i64 %sum10, i64* %a1
  br label %if.end8
if.else3:
  %global212 = load i64, i64* @global2
  %global213 = icmp eq i64 %global212, 2
  br i1 %global213, label %if.then4, label %if.end5
if.then4:
  %sum14 = call i64 (i64) @sum(i64 20000)
  store i64 %sum14, i64* %a1
  br label %if.end5
if.end5:
  %global318 = load i64, i64* @global3
  %global319 = icmp eq i64 %global318, 3
  br i1 %global319, label %if.then6, label %if.end7
if.then6:
  %sum20 = call i64 (i64) @sum(i64 30000)
  store i64 %sum20, i64* %a1
  br label %if.end7
if.end7:
  br label %if.end8
if.end8:
  %a27 = load i64, i64* %a1
  store i64 %a27, i64* %_0
  br label %exit
exit:
  %_30 = load i64, i64* %_0
  ret i64 %_30
}

define i64 @commonSubexpressionElimination() {
entry:
  %_0 = alloca i64
  %a1 = alloca i64
  %b2 = alloca i64
  %c3 = alloca i64
  %d4 = alloca i64
  %e5 = alloca i64
  %f6 = alloca i64
  %g7 = alloca i64
  %h8 = alloca i64
  %i9 = alloca i64
  %j10 = alloca i64
  %k11 = alloca i64
  %l12 = alloca i64
  %m13 = alloca i64
  %n14 = alloca i64
  %o15 = alloca i64
  %p16 = alloca i64
  %q17 = alloca i64
  %r18 = alloca i64
  %s19 = alloca i64
  %t20 = alloca i64
  %u21 = alloca i64
  %v22 = alloca i64
  %w23 = alloca i64
  %x24 = alloca i64
  %y25 = alloca i64
  %z26 = alloca i64
  br label %body1
body1:
  store i64 11, i64* %a1
  store i64 22, i64* %b2
  store i64 33, i64* %c3
  store i64 44, i64* %d4
  store i64 55, i64* %e5
  store i64 66, i64* %f6
  store i64 77, i64* %g7
  %a35 = load i64, i64* %a1
  %b36 = load i64, i64* %b2
  %_37 = mul i64 %a35, %b36
  store i64 %_37, i64* %h8
  %c39 = load i64, i64* %c3
  %d40 = load i64, i64* %d4
  %_41 = sdiv i64 %c39, %d40
  store i64 %_41, i64* %i9
  %e43 = load i64, i64* %e5
  %f44 = load i64, i64* %f6
  %_45 = mul i64 %e43, %f44
  store i64 %_45, i64* %j10
  %a47 = load i64, i64* %a1
  %b48 = load i64, i64* %b2
  %_49 = mul i64 %a47, %b48
  %c50 = load i64, i64* %c3
  %d51 = load i64, i64* %d4
  %_52 = sdiv i64 %c50, %d51
  %_53 = add i64 %_49, %_52
  %e54 = load i64, i64* %e5
  %f55 = load i64, i64* %f6
  %_56 = mul i64 %e54, %f55
  %_57 = sub i64 %_53, %_56
  %g58 = load i64, i64* %g7
  %g59 = add i64 %_57, %g58
  store i64 %g59, i64* %k11
  %a61 = load i64, i64* %a1
  %b62 = load i64, i64* %b2
  %_63 = mul i64 %a61, %b62
  %c64 = load i64, i64* %c3
  %d65 = load i64, i64* %d4
  %_66 = sdiv i64 %c64, %d65
  %_67 = add i64 %_63, %_66
  %e68 = load i64, i64* %e5
  %f69 = load i64, i64* %f6
  %_70 = mul i64 %e68, %f69
  %_71 = sub i64 %_67, %_70
  %g72 = load i64, i64* %g7
  %g73 = add i64 %_71, %g72
  store i64 %g73, i64* %l12
  %a75 = load i64, i64* %a1
  %b76 = load i64, i64* %b2
  %_77 = mul i64 %a75, %b76
  %c78 = load i64, i64* %c3
  %d79 = load i64, i64* %d4
  %_80 = sdiv i64 %c78, %d79
  %_81 = add i64 %_77, %_80
  %e82 = load i64, i64* %e5
  %f83 = load i64, i64* %f6
  %_84 = mul i64 %e82, %f83
  %_85 = sub i64 %_81, %_84
  %g86 = load i64, i64* %g7
  %g87 = add i64 %_85, %g86
  store i64 %g87, i64* %m13
  %a89 = load i64, i64* %a1
  %b90 = load i64, i64* %b2
  %_91 = mul i64 %a89, %b90
  %c92 = load i64, i64* %c3
  %d93 = load i64, i64* %d4
  %_94 = sdiv i64 %c92, %d93
  %_95 = add i64 %_91, %_94
  %e96 = load i64, i64* %e5
  %f97 = load i64, i64* %f6
  %_98 = mul i64 %e96, %f97
  %_99 = sub i64 %_95, %_98
  %g100 = load i64, i64* %g7
  %g101 = add i64 %_99, %g100
  store i64 %g101, i64* %n14
  %a103 = load i64, i64* %a1
  %b104 = load i64, i64* %b2
  %_105 = mul i64 %a103, %b104
  %c106 = load i64, i64* %c3
  %d107 = load i64, i64* %d4
  %_108 = sdiv i64 %c106, %d107
  %_109 = add i64 %_105, %_108
  %e110 = load i64, i64* %e5
  %f111 = load i64, i64* %f6
  %_112 = mul i64 %e110, %f111
  %_113 = sub i64 %_109, %_112
  %g114 = load i64, i64* %g7
  %g115 = add i64 %_113, %g114
  store i64 %g115, i64* %o15
  %a117 = load i64, i64* %a1
  %b118 = load i64, i64* %b2
  %_119 = mul i64 %a117, %b118
  %c120 = load i64, i64* %c3
  %d121 = load i64, i64* %d4
  %_122 = sdiv i64 %c120, %d121
  %_123 = add i64 %_119, %_122
  %e124 = load i64, i64* %e5
  %f125 = load i64, i64* %f6
  %_126 = mul i64 %e124, %f125
  %_127 = sub i64 %_123, %_126
  %g128 = load i64, i64* %g7
  %g129 = add i64 %_127, %g128
  store i64 %g129, i64* %p16
  %a131 = load i64, i64* %a1
  %b132 = load i64, i64* %b2
  %_133 = mul i64 %a131, %b132
  %c134 = load i64, i64* %c3
  %d135 = load i64, i64* %d4
  %_136 = sdiv i64 %c134, %d135
  %_137 = add i64 %_133, %_136
  %e138 = load i64, i64* %e5
  %f139 = load i64, i64* %f6
  %_140 = mul i64 %e138, %f139
  %_141 = sub i64 %_137, %_140
  %g142 = load i64, i64* %g7
  %g143 = add i64 %_141, %g142
  store i64 %g143, i64* %q17
  %a145 = load i64, i64* %a1
  %b146 = load i64, i64* %b2
  %_147 = mul i64 %a145, %b146
  %c148 = load i64, i64* %c3
  %d149 = load i64, i64* %d4
  %_150 = sdiv i64 %c148, %d149
  %_151 = add i64 %_147, %_150
  %e152 = load i64, i64* %e5
  %f153 = load i64, i64* %f6
  %_154 = mul i64 %e152, %f153
  %_155 = sub i64 %_151, %_154
  %g156 = load i64, i64* %g7
  %g157 = add i64 %_155, %g156
  store i64 %g157, i64* %r18
  %a159 = load i64, i64* %a1
  %b160 = load i64, i64* %b2
  %_161 = mul i64 %a159, %b160
  %c162 = load i64, i64* %c3
  %d163 = load i64, i64* %d4
  %_164 = sdiv i64 %c162, %d163
  %_165 = add i64 %_161, %_164
  %e166 = load i64, i64* %e5
  %f167 = load i64, i64* %f6
  %_168 = mul i64 %e166, %f167
  %_169 = sub i64 %_165, %_168
  %g170 = load i64, i64* %g7
  %g171 = add i64 %_169, %g170
  store i64 %g171, i64* %s19
  %a173 = load i64, i64* %a1
  %b174 = load i64, i64* %b2
  %_175 = mul i64 %a173, %b174
  %c176 = load i64, i64* %c3
  %d177 = load i64, i64* %d4
  %_178 = sdiv i64 %c176, %d177
  %_179 = add i64 %_175, %_178
  %e180 = load i64, i64* %e5
  %f181 = load i64, i64* %f6
  %_182 = mul i64 %e180, %f181
  %_183 = sub i64 %_179, %_182
  %g184 = load i64, i64* %g7
  %g185 = add i64 %_183, %g184
  store i64 %g185, i64* %t20
  %a187 = load i64, i64* %a1
  %b188 = load i64, i64* %b2
  %_189 = mul i64 %a187, %b188
  %c190 = load i64, i64* %c3
  %d191 = load i64, i64* %d4
  %_192 = sdiv i64 %c190, %d191
  %_193 = add i64 %_189, %_192
  %e194 = load i64, i64* %e5
  %f195 = load i64, i64* %f6
  %_196 = mul i64 %e194, %f195
  %_197 = sub i64 %_193, %_196
  %g198 = load i64, i64* %g7
  %g199 = add i64 %_197, %g198
  store i64 %g199, i64* %u21
  %b201 = load i64, i64* %b2
  %a202 = load i64, i64* %a1
  %_203 = mul i64 %b201, %a202
  %c204 = load i64, i64* %c3
  %d205 = load i64, i64* %d4
  %_206 = sdiv i64 %c204, %d205
  %_207 = add i64 %_203, %_206
  %e208 = load i64, i64* %e5
  %f209 = load i64, i64* %f6
  %_210 = mul i64 %e208, %f209
  %_211 = sub i64 %_207, %_210
  %g212 = load i64, i64* %g7
  %g213 = add i64 %_211, %g212
  store i64 %g213, i64* %v22
  %a215 = load i64, i64* %a1
  %b216 = load i64, i64* %b2
  %_217 = mul i64 %a215, %b216
  %c218 = load i64, i64* %c3
  %d219 = load i64, i64* %d4
  %_220 = sdiv i64 %c218, %d219
  %_221 = add i64 %_217, %_220
  %f222 = load i64, i64* %f6
  %e223 = load i64, i64* %e5
  %_224 = mul i64 %f222, %e223
  %_225 = sub i64 %_221, %_224
  %g226 = load i64, i64* %g7
  %g227 = add i64 %_225, %g226
  store i64 %g227, i64* %w23
  %g229 = load i64, i64* %g7
  %a230 = load i64, i64* %a1
  %b231 = load i64, i64* %b2
  %_232 = mul i64 %a230, %b231
  %g233 = add i64 %g229, %_232
  %c234 = load i64, i64* %c3
  %d235 = load i64, i64* %d4
  %_236 = sdiv i64 %c234, %d235
  %g237 = add i64 %g233, %_236
  %e238 = load i64, i64* %e5
  %f239 = load i64, i64* %f6
  %_240 = mul i64 %e238, %f239
  %g241 = sub i64 %g237, %_240
  store i64 %g241, i64* %x24
  %a243 = load i64, i64* %a1
  %b244 = load i64, i64* %b2
  %_245 = mul i64 %a243, %b244
  %c246 = load i64, i64* %c3
  %d247 = load i64, i64* %d4
  %_248 = sdiv i64 %c246, %d247
  %_249 = add i64 %_245, %_248
  %e250 = load i64, i64* %e5
  %f251 = load i64, i64* %f6
  %_252 = mul i64 %e250, %f251
  %_253 = sub i64 %_249, %_252
  %g254 = load i64, i64* %g7
  %g255 = add i64 %_253, %g254
  store i64 %g255, i64* %y25
  %c257 = load i64, i64* %c3
  %d258 = load i64, i64* %d4
  %_259 = sdiv i64 %c257, %d258
  %a260 = load i64, i64* %a1
  %b261 = load i64, i64* %b2
  %_262 = mul i64 %a260, %b261
  %_263 = add i64 %_259, %_262
  %e264 = load i64, i64* %e5
  %f265 = load i64, i64* %f6
  %_266 = mul i64 %e264, %f265
  %_267 = sub i64 %_263, %_266
  %g268 = load i64, i64* %g7
  %g269 = add i64 %_267, %g268
  store i64 %g269, i64* %z26
  %a271 = load i64, i64* %a1
  %b272 = load i64, i64* %b2
  %_273 = add i64 %a271, %b272
  %c274 = load i64, i64* %c3
  %c275 = add i64 %_273, %c274
  %d276 = load i64, i64* %d4
  %_277 = add i64 %c275, %d276
  %e278 = load i64, i64* %e5
  %e279 = add i64 %_277, %e278
  %f280 = load i64, i64* %f6
  %_281 = add i64 %e279, %f280
  %g282 = load i64, i64* %g7
  %g283 = add i64 %_281, %g282
  %h284 = load i64, i64* %h8
  %_285 = add i64 %g283, %h284
  %i286 = load i64, i64* %i9
  %i287 = add i64 %_285, %i286
  %j288 = load i64, i64* %j10
  %_289 = add i64 %i287, %j288
  %k290 = load i64, i64* %k11
  %k291 = add i64 %_289, %k290
  %l292 = load i64, i64* %l12
  %_293 = add i64 %k291, %l292
  %m294 = load i64, i64* %m13
  %m295 = add i64 %_293, %m294
  %n296 = load i64, i64* %n14
  %_297 = add i64 %m295, %n296
  %o298 = load i64, i64* %o15
  %o299 = add i64 %_297, %o298
  %p300 = load i64, i64* %p16
  %_301 = add i64 %o299, %p300
  %q302 = load i64, i64* %q17
  %q303 = add i64 %_301, %q302
  %r304 = load i64, i64* %r18
  %_305 = add i64 %q303, %r304
  %s306 = load i64, i64* %s19
  %s307 = add i64 %_305, %s306
  %t308 = load i64, i64* %t20
  %_309 = add i64 %s307, %t308
  %u310 = load i64, i64* %u21
  %u311 = add i64 %_309, %u310
  %v312 = load i64, i64* %v22
  %_313 = add i64 %u311, %v312
  %w314 = load i64, i64* %w23
  %w315 = add i64 %_313, %w314
  %x316 = load i64, i64* %x24
  %_317 = add i64 %w315, %x316
  %y318 = load i64, i64* %y25
  %y319 = add i64 %_317, %y318
  %z320 = load i64, i64* %z26
  %_321 = add i64 %y319, %z320
  store i64 %_321, i64* %_0
  br label %exit
exit:
  %_324 = load i64, i64* %_0
  ret i64 %_324
}

define i64 @hoisting() {
entry:
  %_0 = alloca i64
  %a1 = alloca i64
  %b2 = alloca i64
  %c3 = alloca i64
  %d4 = alloca i64
  %e5 = alloca i64
  %f6 = alloca i64
  %g7 = alloca i64
  %h8 = alloca i64
  %i9 = alloca i64
  br label %body1
body1:
  store i64 1, i64* %a1
  store i64 2, i64* %b2
  store i64 3, i64* %c3
  store i64 4, i64* %d4
  store i64 0, i64* %i9
  %i16 = load i64, i64* %i9
  %i17 = icmp slt i64 %i16, 1000000
  br i1 %i17, label %while.body2, label %while.end3
while.body2:
  store i64 5, i64* %e5
  %a19 = load i64, i64* %a1
  %b20 = load i64, i64* %b2
  %_21 = add i64 %a19, %b20
  %c22 = load i64, i64* %c3
  %c23 = add i64 %_21, %c22
  store i64 %c23, i64* %g7
  %c25 = load i64, i64* %c3
  %d26 = load i64, i64* %d4
  %_27 = add i64 %c25, %d26
  %g28 = load i64, i64* %g7
  %g29 = add i64 %_27, %g28
  store i64 %g29, i64* %h8
  %i31 = load i64, i64* %i9
  %i32 = add i64 %i31, 1
  store i64 %i32, i64* %i9
  %i34 = load i64, i64* %i9
  %i35 = icmp slt i64 %i34, 1000000
  br i1 %i35, label %while.body2, label %while.end3
while.end3:
  %b38 = load i64, i64* %b2
  store i64 %b38, i64* %_0
  br label %exit
exit:
  %_41 = load i64, i64* %_0
  ret i64 %_41
}

define i64 @doubleIf() {
entry:
  %_0 = alloca i64
  %a1 = alloca i64
  %b2 = alloca i64
  %c3 = alloca i64
  %d4 = alloca i64
  br label %body1
body1:
  store i64 1, i64* %a1
  store i64 2, i64* %b2
  store i64 3, i64* %c3
  store i64 0, i64* %d4
  %a10 = load i64, i64* %a1
  %a11 = icmp eq i64 %a10, 1
  br i1 %a11, label %if.then2, label %if.end6
if.then2:
  store i64 20, i64* %b2
  %a13 = load i64, i64* %a1
  %a14 = icmp eq i64 %a13, 1
  br i1 %a14, label %if.then3, label %if.else4
if.then3:
  store i64 200, i64* %b2
  store i64 300, i64* %c3
  br label %if.end5
if.else4:
  store i64 1, i64* %a1
  store i64 2, i64* %b2
  store i64 3, i64* %c3
  br label %if.end5
if.end5:
  store i64 50, i64* %d4
  br label %if.end6
if.end6:
  %d26 = load i64, i64* %d4
  store i64 %d26, i64* %_0
  br label %exit
exit:
  %_29 = load i64, i64* %_0
  ret i64 %_29
}

define i64 @integerDivide() {
entry:
  %_0 = alloca i64
  %a1 = alloca i64
  br label %body1
body1:
  store i64 3000, i64* %a1
  %a4 = load i64, i64* %a1
  %a5 = sdiv i64 %a4, 2
  store i64 %a5, i64* %a1
  %a7 = load i64, i64* %a1
  %a8 = mul i64 %a7, 4
  store i64 %a8, i64* %a1
  %a10 = load i64, i64* %a1
  %a11 = sdiv i64 %a10, 8
  store i64 %a11, i64* %a1
  %a13 = load i64, i64* %a1
  %a14 = sdiv i64 %a13, 16
  store i64 %a14, i64* %a1
  %a16 = load i64, i64* %a1
  %a17 = mul i64 %a16, 32
  store i64 %a17, i64* %a1
  %a19 = load i64, i64* %a1
  %a20 = sdiv i64 %a19, 64
  store i64 %a20, i64* %a1
  %a22 = load i64, i64* %a1
  %a23 = mul i64 %a22, 128
  store i64 %a23, i64* %a1
  %a25 = load i64, i64* %a1
  %a26 = sdiv i64 %a25, 4
  store i64 %a26, i64* %a1
  %a28 = load i64, i64* %a1
  store i64 %a28, i64* %_0
  br label %exit
exit:
  %_31 = load i64, i64* %_0
  ret i64 %_31
}

define i64 @association() {
entry:
  %_0 = alloca i64
  %a1 = alloca i64
  br label %body1
body1:
  store i64 10, i64* %a1
  %a4 = load i64, i64* %a1
  %a5 = mul i64 %a4, 2
  store i64 %a5, i64* %a1
  %a7 = load i64, i64* %a1
  %a8 = sdiv i64 %a7, 2
  store i64 %a8, i64* %a1
  %a10 = load i64, i64* %a1
  %a11 = mul i64 3, %a10
  store i64 %a11, i64* %a1
  %a13 = load i64, i64* %a1
  %a14 = sdiv i64 %a13, 3
  store i64 %a14, i64* %a1
  %a16 = load i64, i64* %a1
  %a17 = mul i64 %a16, 4
  store i64 %a17, i64* %a1
  %a19 = load i64, i64* %a1
  %a20 = sdiv i64 %a19, 4
  store i64 %a20, i64* %a1
  %a22 = load i64, i64* %a1
  %a23 = add i64 %a22, 4
  store i64 %a23, i64* %a1
  %a25 = load i64, i64* %a1
  %a26 = sub i64 %a25, 4
  store i64 %a26, i64* %a1
  %a28 = load i64, i64* %a1
  %a29 = mul i64 %a28, 50
  store i64 %a29, i64* %a1
  %a31 = load i64, i64* %a1
  %a32 = sdiv i64 %a31, 50
  store i64 %a32, i64* %a1
  %a34 = load i64, i64* %a1
  store i64 %a34, i64* %_0
  br label %exit
exit:
  %_37 = load i64, i64* %_0
  ret i64 %_37
}

define i64 @tailRecursionHelper(i64 %value, i64 %sum) {
entry:
  %_0 = alloca i64
  %value1 = alloca i64
  store i64 %value, i64* %value1
  %sum3 = alloca i64
  store i64 %sum, i64* %sum3
  br label %body1
body1:
  %value6 = load i64, i64* %value1
  %value7 = icmp eq i64 %value6, 0
  br i1 %value7, label %if.then2, label %if.else3
if.then2:
  %sum8 = load i64, i64* %sum3
  store i64 %sum8, i64* %_0
  br label %exit
if.else3:
  %value11 = load i64, i64* %value1
  %value12 = sub i64 %value11, 1
  %sum13 = load i64, i64* %sum3
  %value14 = load i64, i64* %value1
  %_15 = add i64 %sum13, %value14
  %tailRecursionHelper16 = call i64 (i64, i64) @tailRecursionHelper(i64 %value12, i64 %_15)
  store i64 %tailRecursionHelper16, i64* %_0
  br label %exit
if.end4:
  br label %exit
exit:
  %_21 = load i64, i64* %_0
  ret i64 %_21
}

define i64 @tailRecursion(i64 %value) {
entry:
  %_0 = alloca i64
  %value1 = alloca i64
  store i64 %value, i64* %value1
  br label %body1
body1:
  %value4 = load i64, i64* %value1
  %tailRecursionHelper5 = call i64 (i64, i64) @tailRecursionHelper(i64 %value4, i64 0)
  store i64 %tailRecursionHelper5, i64* %_0
  br label %exit
exit:
  %_8 = load i64, i64* %_0
  ret i64 %_8
}

define i64 @unswitching() {
entry:
  %_0 = alloca i64
  %a1 = alloca i64
  %b2 = alloca i64
  br label %body1
body1:
  store i64 1, i64* %a1
  store i64 2, i64* %b2
  %a6 = load i64, i64* %a1
  %a7 = icmp slt i64 %a6, 1000000
  br i1 %a7, label %while.body2, label %while.end6
while.body2:
  %b8 = load i64, i64* %b2
  %b9 = icmp eq i64 %b8, 2
  br i1 %b9, label %if.then3, label %if.else4
if.then3:
  %a10 = load i64, i64* %a1
  %a11 = add i64 %a10, 1
  store i64 %a11, i64* %a1
  br label %if.end5
if.else4:
  %a13 = load i64, i64* %a1
  %a14 = add i64 %a13, 2
  store i64 %a14, i64* %a1
  br label %if.end5
if.end5:
  %a19 = load i64, i64* %a1
  %a20 = icmp slt i64 %a19, 1000000
  br i1 %a20, label %while.body2, label %while.end6
while.end6:
  %a23 = load i64, i64* %a1
  store i64 %a23, i64* %_0
  br label %exit
exit:
  %_26 = load i64, i64* %_0
  ret i64 %_26
}

define i64 @randomCalculation(i64 %number) {
entry:
  %_0 = alloca i64
  %a1 = alloca i64
  %b2 = alloca i64
  %c3 = alloca i64
  %d4 = alloca i64
  %e5 = alloca i64
  %i6 = alloca i64
  %sum7 = alloca i64
  %number8 = alloca i64
  store i64 %number, i64* %number8
  br label %body1
body1:
  store i64 0, i64* %i6
  store i64 0, i64* %sum7
  %i13 = load i64, i64* %i6
  %number14 = load i64, i64* %number8
  %_15 = icmp slt i64 %i13, %number14
  br i1 %_15, label %while.body2, label %while.end3
while.body2:
  store i64 4, i64* %a1
  store i64 7, i64* %b2
  store i64 8, i64* %c3
  %a19 = load i64, i64* %a1
  %b20 = load i64, i64* %b2
  %_21 = add i64 %a19, %b20
  store i64 %_21, i64* %d4
  %d23 = load i64, i64* %d4
  %c24 = load i64, i64* %c3
  %_25 = add i64 %d23, %c24
  store i64 %_25, i64* %e5
  %sum27 = load i64, i64* %sum7
  %e28 = load i64, i64* %e5
  %_29 = add i64 %sum27, %e28
  store i64 %_29, i64* %sum7
  %i31 = load i64, i64* %i6
  %i32 = mul i64 %i31, 2
  store i64 %i32, i64* %i6
  %i34 = load i64, i64* %i6
  %i35 = sdiv i64 %i34, 2
  store i64 %i35, i64* %i6
  %i37 = load i64, i64* %i6
  %i38 = mul i64 3, %i37
  store i64 %i38, i64* %i6
  %i40 = load i64, i64* %i6
  %i41 = sdiv i64 %i40, 3
  store i64 %i41, i64* %i6
  %i43 = load i64, i64* %i6
  %i44 = mul i64 %i43, 4
  store i64 %i44, i64* %i6
  %i46 = load i64, i64* %i6
  %i47 = sdiv i64 %i46, 4
  store i64 %i47, i64* %i6
  %i49 = load i64, i64* %i6
  %i50 = add i64 %i49, 1
  store i64 %i50, i64* %i6
  %i52 = load i64, i64* %i6
  %number53 = load i64, i64* %number8
  %_54 = icmp slt i64 %i52, %number53
  br i1 %_54, label %while.body2, label %while.end3
while.end3:
  %sum57 = load i64, i64* %sum7
  store i64 %sum57, i64* %_0
  br label %exit
exit:
  %_60 = load i64, i64* %_0
  ret i64 %_60
}

define i64 @iterativeFibonacci(i64 %number) {
entry:
  %_0 = alloca i64
  %previous1 = alloca i64
  %result2 = alloca i64
  %count3 = alloca i64
  %i4 = alloca i64
  %sum5 = alloca i64
  %number6 = alloca i64
  store i64 %number, i64* %number6
  br label %body1
body1:
  %_9 = sub i64 0, 1
  store i64 %_9, i64* %previous1
  store i64 1, i64* %result2
  store i64 0, i64* %i4
  %i13 = load i64, i64* %i4
  %number14 = load i64, i64* %number6
  %_15 = icmp slt i64 %i13, %number14
  br i1 %_15, label %while.body2, label %while.end3
while.body2:
  %result16 = load i64, i64* %result2
  %previous17 = load i64, i64* %previous1
  %_18 = add i64 %result16, %previous17
  store i64 %_18, i64* %sum5
  %result20 = load i64, i64* %result2
  store i64 %result20, i64* %previous1
  %sum22 = load i64, i64* %sum5
  store i64 %sum22, i64* %result2
  %i24 = load i64, i64* %i4
  %i25 = add i64 %i24, 1
  store i64 %i25, i64* %i4
  %i27 = load i64, i64* %i4
  %number28 = load i64, i64* %number6
  %_29 = icmp slt i64 %i27, %number28
  br i1 %_29, label %while.body2, label %while.end3
while.end3:
  %result32 = load i64, i64* %result2
  store i64 %result32, i64* %_0
  br label %exit
exit:
  %_35 = load i64, i64* %_0
  ret i64 %_35
}

define i64 @recursiveFibonacci(i64 %number) {
entry:
  %_0 = alloca i64
  %number1 = alloca i64
  store i64 %number, i64* %number1
  br label %body1
body1:
  %number4 = load i64, i64* %number1
  %number5 = icmp sle i64 %number4, 0
  %number6 = load i64, i64* %number1
  %number7 = icmp eq i64 %number6, 1
  %_8 = or i1 %number5, %number7
  br i1 %_8, label %if.then2, label %if.else3
if.then2:
  %number9 = load i64, i64* %number1
  store i64 %number9, i64* %_0
  br label %exit
if.else3:
  %number12 = load i64, i64* %number1
  %number13 = sub i64 %number12, 1
  %recursiveFibonacci14 = call i64 (i64) @recursiveFibonacci(i64 %number13)
  %number15 = load i64, i64* %number1
  %number16 = sub i64 %number15, 2
  %recursiveFibonacci17 = call i64 (i64) @recursiveFibonacci(i64 %number16)
  %_18 = add i64 %recursiveFibonacci14, %recursiveFibonacci17
  store i64 %_18, i64* %_0
  br label %exit
if.end4:
  br label %exit
exit:
  %_23 = load i64, i64* %_0
  ret i64 %_23
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %input1 = alloca i64
  %result2 = alloca i64
  %i3 = alloca i64
  br label %body1
body1:
  %_5 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_6 = call i32 (i8*, ...) @scanf(i8* %_5, i32* @.read_scratch)
  %_7 = load i32, i32* @.read_scratch
  %_8 = sext i32 %_7 to i64
  store i64 %_8, i64* %input1
  store i64 1, i64* %i3
  %i11 = load i64, i64* %i3
  %input12 = load i64, i64* %input1
  %_13 = icmp slt i64 %i11, %input12
  br i1 %_13, label %while.body2, label %while.end3
while.body2:
  %constantFolding14 = call i64 () @constantFolding()
  store i64 %constantFolding14, i64* %result2
  %result16 = load i64, i64* %result2
  %_17 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_18 = call i32 (i8*, ...) @printf(i8* %_17, i64 %result16)
  %constantPropagation19 = call i64 () @constantPropagation()
  store i64 %constantPropagation19, i64* %result2
  %result21 = load i64, i64* %result2
  %_22 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_23 = call i32 (i8*, ...) @printf(i8* %_22, i64 %result21)
  %deadCodeElimination24 = call i64 () @deadCodeElimination()
  store i64 %deadCodeElimination24, i64* %result2
  %result26 = load i64, i64* %result2
  %_27 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_28 = call i32 (i8*, ...) @printf(i8* %_27, i64 %result26)
  %interProceduralOptimization29 = call i64 () @interProceduralOptimization()
  store i64 %interProceduralOptimization29, i64* %result2
  %result31 = load i64, i64* %result2
  %_32 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_33 = call i32 (i8*, ...) @printf(i8* %_32, i64 %result31)
  %commonSubexpressionElimination34 = call i64 () @commonSubexpressionElimination()
  store i64 %commonSubexpressionElimination34, i64* %result2
  %result36 = load i64, i64* %result2
  %_37 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_38 = call i32 (i8*, ...) @printf(i8* %_37, i64 %result36)
  %hoisting39 = call i64 () @hoisting()
  store i64 %hoisting39, i64* %result2
  %result41 = load i64, i64* %result2
  %_42 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_43 = call i32 (i8*, ...) @printf(i8* %_42, i64 %result41)
  %doubleIf44 = call i64 () @doubleIf()
  store i64 %doubleIf44, i64* %result2
  %result46 = load i64, i64* %result2
  %_47 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_48 = call i32 (i8*, ...) @printf(i8* %_47, i64 %result46)
  %integerDivide49 = call i64 () @integerDivide()
  store i64 %integerDivide49, i64* %result2
  %result51 = load i64, i64* %result2
  %_52 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_53 = call i32 (i8*, ...) @printf(i8* %_52, i64 %result51)
  %association54 = call i64 () @association()
  store i64 %association54, i64* %result2
  %result56 = load i64, i64* %result2
  %_57 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_58 = call i32 (i8*, ...) @printf(i8* %_57, i64 %result56)
  %input59 = load i64, i64* %input1
  %input60 = sdiv i64 %input59, 1000
  %tailRecursion61 = call i64 (i64) @tailRecursion(i64 %input60)
  store i64 %tailRecursion61, i64* %result2
  %result63 = load i64, i64* %result2
  %_64 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_65 = call i32 (i8*, ...) @printf(i8* %_64, i64 %result63)
  %unswitching66 = call i64 () @unswitching()
  store i64 %unswitching66, i64* %result2
  %result68 = load i64, i64* %result2
  %_69 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_70 = call i32 (i8*, ...) @printf(i8* %_69, i64 %result68)
  %input71 = load i64, i64* %input1
  %randomCalculation72 = call i64 (i64) @randomCalculation(i64 %input71)
  store i64 %randomCalculation72, i64* %result2
  %result74 = load i64, i64* %result2
  %_75 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_76 = call i32 (i8*, ...) @printf(i8* %_75, i64 %result74)
  %input77 = load i64, i64* %input1
  %input78 = sdiv i64 %input77, 5
  %iterativeFibonacci79 = call i64 (i64) @iterativeFibonacci(i64 %input78)
  store i64 %iterativeFibonacci79, i64* %result2
  %result81 = load i64, i64* %result2
  %_82 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_83 = call i32 (i8*, ...) @printf(i8* %_82, i64 %result81)
  %input84 = load i64, i64* %input1
  %input85 = sdiv i64 %input84, 1000
  %recursiveFibonacci86 = call i64 (i64) @recursiveFibonacci(i64 %input85)
  store i64 %recursiveFibonacci86, i64* %result2
  %result88 = load i64, i64* %result2
  %_89 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_90 = call i32 (i8*, ...) @printf(i8* %_89, i64 %result88)
  %i91 = load i64, i64* %i3
  %i92 = add i64 %i91, 1
  store i64 %i92, i64* %i3
  %i94 = load i64, i64* %i3
  %input95 = load i64, i64* %input1
  %_96 = icmp slt i64 %i94, %input95
  br i1 %_96, label %while.body2, label %while.end3
while.end3:
  %_99 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_100 = call i32 (i8*, ...) @printf(i8* %_99, i64 9999)
  store i64 0, i64* %_0
  br label %exit
exit:
  %_103 = load i64, i64* %_0
  ret i64 %_103
}

