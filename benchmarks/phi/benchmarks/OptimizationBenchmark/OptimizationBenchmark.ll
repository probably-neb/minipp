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
  br label %body0
body0:
  %imm_store2 = add i64 8, 0
  %imm_store3 = add i64 9, 0
  %tmp.binop4 = mul i64 %imm_store2, %imm_store3
  %imm_store5 = add i64 4, 0
  %tmp.binop6 = sdiv i64 %tmp.binop4, %imm_store5
  %imm_store7 = add i64 2, 0
  %tmp.binop8 = add i64 %tmp.binop6, %imm_store7
  %imm_store9 = add i64 5, 0
  %imm_store10 = add i64 8, 0
  %tmp.binop11 = mul i64 %imm_store9, %imm_store10
  %tmp.binop12 = sub i64 %tmp.binop8, %tmp.binop11
  %imm_store13 = add i64 9, 0
  %tmp.binop14 = add i64 %tmp.binop12, %imm_store13
  %imm_store15 = add i64 12, 0
  %tmp.binop16 = sub i64 %tmp.binop14, %imm_store15
  %imm_store17 = add i64 6, 0
  %tmp.binop18 = add i64 %tmp.binop16, %imm_store17
  %imm_store19 = add i64 9, 0
  %tmp.binop20 = sub i64 %tmp.binop18, %imm_store19
  %imm_store21 = add i64 18, 0
  %tmp.binop22 = sub i64 %tmp.binop20, %imm_store21
  %imm_store23 = add i64 23, 0
  %imm_store24 = add i64 3, 0
  %tmp.binop25 = mul i64 %imm_store23, %imm_store24
  %imm_store26 = add i64 23, 0
  %tmp.binop27 = sdiv i64 %tmp.binop25, %imm_store26
  %imm_store28 = add i64 90, 0
  %tmp.binop29 = mul i64 %tmp.binop27, %imm_store28
  %a30 = add i64 %tmp.binop22, %tmp.binop29
  br label %exit
exit:
  %return_reg31 = phi i64 [ %a30, %body0 ]
  ret i64 %return_reg31
}

define i64 @constantPropagation() {
entry:
  br label %body0
body0:
  %a2 = add i64 4, 0
  %b3 = add i64 7, 0
  %c4 = add i64 8, 0
  %d5 = add i64 5, 0
  %e6 = add i64 11, 0
  %f7 = add i64 21, 0
  %g8 = add i64 %a2, %b3
  %h9 = add i64 %c4, %d5
  %i10 = add i64 %e6, %f7
  %j11 = add i64 %g8, %h9
  %k12 = mul i64 %i10, %j11
  %tmp.binop13 = mul i64 %h9, %i10
  %tmp.binop14 = add i64 %e6, %tmp.binop13
  %l15 = sub i64 %tmp.binop14, %k12
  %tmp.binop16 = mul i64 %i10, %j11
  %tmp.binop17 = sub i64 %h9, %tmp.binop16
  %tmp.binop18 = sdiv i64 %k12, %l15
  %m19 = add i64 %tmp.binop17, %tmp.binop18
  %tmp.binop20 = add i64 %e6, %f7
  %tmp.binop21 = add i64 %tmp.binop20, %g8
  %tmp.binop22 = add i64 %tmp.binop21, %h9
  %tmp.binop23 = add i64 %tmp.binop22, %i10
  %n24 = sub i64 %tmp.binop23, %j11
  %tmp.binop25 = sub i64 %n24, %m19
  %tmp.binop26 = add i64 %tmp.binop25, %h9
  %tmp.binop27 = sub i64 %tmp.binop26, %a2
  %o28 = sub i64 %tmp.binop27, %b3
  %tmp.binop29 = add i64 %k12, %l15
  %tmp.binop30 = sub i64 %tmp.binop29, %g8
  %p31 = sub i64 %tmp.binop30, %h9
  %tmp.binop32 = sub i64 %b3, %a2
  %tmp.binop33 = mul i64 %tmp.binop32, %d5
  %q34 = sub i64 %tmp.binop33, %i10
  %tmp.binop35 = mul i64 %l15, %c4
  %tmp.binop36 = mul i64 %tmp.binop35, %d5
  %r37 = add i64 %tmp.binop36, %o28
  %tmp.binop38 = mul i64 %b3, %a2
  %tmp.binop39 = mul i64 %tmp.binop38, %c4
  %tmp.binop40 = sdiv i64 %tmp.binop39, %e6
  %s41 = sub i64 %tmp.binop40, %o28
  %tmp.binop42 = add i64 %i10, %k12
  %tmp.binop43 = add i64 %tmp.binop42, %c4
  %t44 = sub i64 %tmp.binop43, %p31
  %tmp.binop45 = add i64 %n24, %o28
  %tmp.binop46 = mul i64 %f7, %a2
  %u47 = sub i64 %tmp.binop45, %tmp.binop46
  %tmp.binop48 = mul i64 %a2, %b3
  %tmp.binop49 = sub i64 %tmp.binop48, %k12
  %v50 = sub i64 %tmp.binop49, %l15
  %tmp.binop51 = sub i64 %v50, %s41
  %tmp.binop52 = mul i64 %r37, %d5
  %w53 = sub i64 %tmp.binop51, %tmp.binop52
  %tmp.binop54 = sub i64 %o28, %w53
  %tmp.binop55 = sub i64 %tmp.binop54, %v50
  %x56 = sub i64 %tmp.binop55, %n24
  %tmp.binop57 = mul i64 %p31, %x56
  %tmp.binop58 = add i64 %tmp.binop57, %t44
  %y59 = sub i64 %tmp.binop58, %w53
  %tmp.binop60 = sub i64 %w53, %x56
  %tmp.binop61 = add i64 %tmp.binop60, %y59
  %z62 = add i64 %tmp.binop61, %k12
  br label %exit
exit:
  %return_reg63 = phi i64 [ %z62, %body0 ]
  ret i64 %return_reg63
}

define i64 @deadCodeElimination() {
entry:
  br label %body0
body0:
  %a2 = add i64 4, 0
  %a3 = add i64 5, 0
  %a4 = add i64 7, 0
  %a5 = add i64 8, 0
  %b6 = add i64 6, 0
  %b7 = add i64 9, 0
  %b8 = add i64 12, 0
  %b9 = add i64 8, 0
  %c10 = add i64 10, 0
  %c11 = add i64 13, 0
  %c12 = add i64 9, 0
  %d13 = add i64 45, 0
  %d14 = add i64 12, 0
  %d15 = add i64 3, 0
  %e16 = add i64 23, 0
  %e17 = add i64 10, 0
  %imm_store18 = add i64 11, 0
  store i64 %imm_store18, i64* @global1
  %imm_store20 = add i64 5, 0
  store i64 %imm_store20, i64* @global1
  %imm_store22 = add i64 9, 0
  store i64 %imm_store22, i64* @global1
  %tmp.binop24 = add i64 %a5, %b9
  %tmp.binop25 = add i64 %tmp.binop24, %c12
  %tmp.binop26 = add i64 %tmp.binop25, %d15
  %tmp.binop27 = add i64 %tmp.binop26, %e17
  br label %exit
exit:
  %return_reg28 = phi i64 [ %tmp.binop27, %body0 ]
  ret i64 %return_reg28
}

define i64 @sum(i64 %number) {
entry:
  br label %body0
body0:
  %total7 = add i64 0, 0
  br label %while.cond11
while.cond11:
  %imm_store9 = add i64 0, 0
  %_10 = icmp sgt i64 %number, %imm_store9
  br i1 %_10, label %while.body2, label %while.exit5
while.body2:
  %number2 = phi i64 [ %number, %while.cond11 ], [ %number14, %while.fillback4 ]
  %total3 = phi i64 [ %total7, %while.cond11 ], [ %total12, %while.fillback4 ]
  %total12 = add i64 %total3, %number2
  %imm_store13 = add i64 1, 0
  %number14 = sub i64 %number2, %imm_store13
  br label %while.cond23
while.cond23:
  %imm_store16 = add i64 0, 0
  %_17 = icmp sgt i64 %number14, %imm_store16
  br i1 %_17, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %number1 = phi i64 [ %number, %while.cond11 ], [ %number14, %while.cond23 ]
  %total4 = phi i64 [ %total7, %while.cond11 ], [ %total12, %while.cond23 ]
  br label %exit
exit:
  %return_reg20 = phi i64 [ %total4, %while.exit5 ]
  ret i64 %return_reg20
}

define i64 @doesntModifyGlobals() {
entry:
  br label %body0
body0:
  %a2 = add i64 1, 0
  %b3 = add i64 2, 0
  %tmp.binop4 = add i64 %a2, %b3
  br label %exit
exit:
  %return_reg5 = phi i64 [ %tmp.binop4, %body0 ]
  ret i64 %return_reg5
}

define i64 @interProceduralOptimization() {
entry:
  br label %body0
body0:
  %imm_store5 = add i64 1, 0
  store i64 %imm_store5, i64* @global1
  %imm_store7 = add i64 0, 0
  store i64 %imm_store7, i64* @global2
  %imm_store9 = add i64 0, 0
  store i64 %imm_store9, i64* @global3
  %imm_store11 = add i64 100, 0
  %a12 = call i64 (i64) @sum(i64 %imm_store11)
  br label %if.cond1
if.cond1:
  %load_global14 = load i64, i64* @global1
  %imm_store15 = add i64 1, 0
  %_16 = icmp eq i64 %load_global14, %imm_store15
  br i1 %_16, label %then.body2, label %else.body4
then.body2:
  %imm_store18 = add i64 10000, 0
  %a19 = call i64 (i64) @sum(i64 %imm_store18)
  br label %then.exit3
then.exit3:
  br label %if.exit14
else.body4:
  br label %if.cond5
if.cond5:
  %load_global23 = load i64, i64* @global2
  %imm_store24 = add i64 2, 0
  %_25 = icmp eq i64 %load_global23, %imm_store24
  br i1 %_25, label %then.body6, label %if.exit8
then.body6:
  %imm_store27 = add i64 20000, 0
  %a28 = call i64 (i64) @sum(i64 %imm_store27)
  br label %then.exit7
then.exit7:
  br label %if.exit8
if.exit8:
  %a1 = phi i64 [ %a12, %if.cond5 ], [ %a28, %then.exit7 ]
  br label %if.cond9
if.cond9:
  %load_global32 = load i64, i64* @global3
  %imm_store33 = add i64 3, 0
  %_34 = icmp eq i64 %load_global32, %imm_store33
  br i1 %_34, label %then.body10, label %if.exit12
then.body10:
  %imm_store36 = add i64 30000, 0
  %a37 = call i64 (i64) @sum(i64 %imm_store36)
  br label %then.exit11
then.exit11:
  br label %if.exit12
if.exit12:
  %a2 = phi i64 [ %a1, %if.cond9 ], [ %a37, %then.exit11 ]
  br label %else.exit13
else.exit13:
  br label %if.exit14
if.exit14:
  %a0 = phi i64 [ %a19, %then.exit3 ], [ %a2, %else.exit13 ]
  br label %exit
exit:
  %return_reg42 = phi i64 [ %a0, %if.exit14 ]
  ret i64 %return_reg42
}

define i64 @commonSubexpressionElimination() {
entry:
  br label %body0
body0:
  %a2 = add i64 11, 0
  %b3 = add i64 22, 0
  %c4 = add i64 33, 0
  %d5 = add i64 44, 0
  %e6 = add i64 55, 0
  %f7 = add i64 66, 0
  %g8 = add i64 77, 0
  %h9 = mul i64 %a2, %b3
  %i10 = sdiv i64 %c4, %d5
  %j11 = mul i64 %e6, %f7
  %tmp.binop12 = mul i64 %a2, %b3
  %tmp.binop13 = sdiv i64 %c4, %d5
  %tmp.binop14 = add i64 %tmp.binop12, %tmp.binop13
  %tmp.binop15 = mul i64 %e6, %f7
  %tmp.binop16 = sub i64 %tmp.binop14, %tmp.binop15
  %k17 = add i64 %tmp.binop16, %g8
  %tmp.binop18 = mul i64 %a2, %b3
  %tmp.binop19 = sdiv i64 %c4, %d5
  %tmp.binop20 = add i64 %tmp.binop18, %tmp.binop19
  %tmp.binop21 = mul i64 %e6, %f7
  %tmp.binop22 = sub i64 %tmp.binop20, %tmp.binop21
  %l23 = add i64 %tmp.binop22, %g8
  %tmp.binop24 = mul i64 %a2, %b3
  %tmp.binop25 = sdiv i64 %c4, %d5
  %tmp.binop26 = add i64 %tmp.binop24, %tmp.binop25
  %tmp.binop27 = mul i64 %e6, %f7
  %tmp.binop28 = sub i64 %tmp.binop26, %tmp.binop27
  %m29 = add i64 %tmp.binop28, %g8
  %tmp.binop30 = mul i64 %a2, %b3
  %tmp.binop31 = sdiv i64 %c4, %d5
  %tmp.binop32 = add i64 %tmp.binop30, %tmp.binop31
  %tmp.binop33 = mul i64 %e6, %f7
  %tmp.binop34 = sub i64 %tmp.binop32, %tmp.binop33
  %n35 = add i64 %tmp.binop34, %g8
  %tmp.binop36 = mul i64 %a2, %b3
  %tmp.binop37 = sdiv i64 %c4, %d5
  %tmp.binop38 = add i64 %tmp.binop36, %tmp.binop37
  %tmp.binop39 = mul i64 %e6, %f7
  %tmp.binop40 = sub i64 %tmp.binop38, %tmp.binop39
  %o41 = add i64 %tmp.binop40, %g8
  %tmp.binop42 = mul i64 %a2, %b3
  %tmp.binop43 = sdiv i64 %c4, %d5
  %tmp.binop44 = add i64 %tmp.binop42, %tmp.binop43
  %tmp.binop45 = mul i64 %e6, %f7
  %tmp.binop46 = sub i64 %tmp.binop44, %tmp.binop45
  %p47 = add i64 %tmp.binop46, %g8
  %tmp.binop48 = mul i64 %a2, %b3
  %tmp.binop49 = sdiv i64 %c4, %d5
  %tmp.binop50 = add i64 %tmp.binop48, %tmp.binop49
  %tmp.binop51 = mul i64 %e6, %f7
  %tmp.binop52 = sub i64 %tmp.binop50, %tmp.binop51
  %q53 = add i64 %tmp.binop52, %g8
  %tmp.binop54 = mul i64 %a2, %b3
  %tmp.binop55 = sdiv i64 %c4, %d5
  %tmp.binop56 = add i64 %tmp.binop54, %tmp.binop55
  %tmp.binop57 = mul i64 %e6, %f7
  %tmp.binop58 = sub i64 %tmp.binop56, %tmp.binop57
  %r59 = add i64 %tmp.binop58, %g8
  %tmp.binop60 = mul i64 %a2, %b3
  %tmp.binop61 = sdiv i64 %c4, %d5
  %tmp.binop62 = add i64 %tmp.binop60, %tmp.binop61
  %tmp.binop63 = mul i64 %e6, %f7
  %tmp.binop64 = sub i64 %tmp.binop62, %tmp.binop63
  %s65 = add i64 %tmp.binop64, %g8
  %tmp.binop66 = mul i64 %a2, %b3
  %tmp.binop67 = sdiv i64 %c4, %d5
  %tmp.binop68 = add i64 %tmp.binop66, %tmp.binop67
  %tmp.binop69 = mul i64 %e6, %f7
  %tmp.binop70 = sub i64 %tmp.binop68, %tmp.binop69
  %t71 = add i64 %tmp.binop70, %g8
  %tmp.binop72 = mul i64 %a2, %b3
  %tmp.binop73 = sdiv i64 %c4, %d5
  %tmp.binop74 = add i64 %tmp.binop72, %tmp.binop73
  %tmp.binop75 = mul i64 %e6, %f7
  %tmp.binop76 = sub i64 %tmp.binop74, %tmp.binop75
  %u77 = add i64 %tmp.binop76, %g8
  %tmp.binop78 = mul i64 %b3, %a2
  %tmp.binop79 = sdiv i64 %c4, %d5
  %tmp.binop80 = add i64 %tmp.binop78, %tmp.binop79
  %tmp.binop81 = mul i64 %e6, %f7
  %tmp.binop82 = sub i64 %tmp.binop80, %tmp.binop81
  %v83 = add i64 %tmp.binop82, %g8
  %tmp.binop84 = mul i64 %a2, %b3
  %tmp.binop85 = sdiv i64 %c4, %d5
  %tmp.binop86 = add i64 %tmp.binop84, %tmp.binop85
  %tmp.binop87 = mul i64 %f7, %e6
  %tmp.binop88 = sub i64 %tmp.binop86, %tmp.binop87
  %w89 = add i64 %tmp.binop88, %g8
  %tmp.binop90 = mul i64 %a2, %b3
  %tmp.binop91 = add i64 %g8, %tmp.binop90
  %tmp.binop92 = sdiv i64 %c4, %d5
  %tmp.binop93 = add i64 %tmp.binop91, %tmp.binop92
  %tmp.binop94 = mul i64 %e6, %f7
  %x95 = sub i64 %tmp.binop93, %tmp.binop94
  %tmp.binop96 = mul i64 %a2, %b3
  %tmp.binop97 = sdiv i64 %c4, %d5
  %tmp.binop98 = add i64 %tmp.binop96, %tmp.binop97
  %tmp.binop99 = mul i64 %e6, %f7
  %tmp.binop100 = sub i64 %tmp.binop98, %tmp.binop99
  %y101 = add i64 %tmp.binop100, %g8
  %tmp.binop102 = sdiv i64 %c4, %d5
  %tmp.binop103 = mul i64 %a2, %b3
  %tmp.binop104 = add i64 %tmp.binop102, %tmp.binop103
  %tmp.binop105 = mul i64 %e6, %f7
  %tmp.binop106 = sub i64 %tmp.binop104, %tmp.binop105
  %z107 = add i64 %tmp.binop106, %g8
  %tmp.binop108 = add i64 %a2, %b3
  %tmp.binop109 = add i64 %tmp.binop108, %c4
  %tmp.binop110 = add i64 %tmp.binop109, %d5
  %tmp.binop111 = add i64 %tmp.binop110, %e6
  %tmp.binop112 = add i64 %tmp.binop111, %f7
  %tmp.binop113 = add i64 %tmp.binop112, %g8
  %tmp.binop114 = add i64 %tmp.binop113, %h9
  %tmp.binop115 = add i64 %tmp.binop114, %i10
  %tmp.binop116 = add i64 %tmp.binop115, %j11
  %tmp.binop117 = add i64 %tmp.binop116, %k17
  %tmp.binop118 = add i64 %tmp.binop117, %l23
  %tmp.binop119 = add i64 %tmp.binop118, %m29
  %tmp.binop120 = add i64 %tmp.binop119, %n35
  %tmp.binop121 = add i64 %tmp.binop120, %o41
  %tmp.binop122 = add i64 %tmp.binop121, %p47
  %tmp.binop123 = add i64 %tmp.binop122, %q53
  %tmp.binop124 = add i64 %tmp.binop123, %r59
  %tmp.binop125 = add i64 %tmp.binop124, %s65
  %tmp.binop126 = add i64 %tmp.binop125, %t71
  %tmp.binop127 = add i64 %tmp.binop126, %u77
  %tmp.binop128 = add i64 %tmp.binop127, %v83
  %tmp.binop129 = add i64 %tmp.binop128, %w89
  %tmp.binop130 = add i64 %tmp.binop129, %x95
  %tmp.binop131 = add i64 %tmp.binop130, %y101
  %tmp.binop132 = add i64 %tmp.binop131, %z107
  br label %exit
exit:
  %return_reg133 = phi i64 [ %tmp.binop132, %body0 ]
  ret i64 %return_reg133
}

define i64 @hoisting() {
entry:
  %h41 = alloca i64
  %h42 = load i64, i64* %h41
  %g43 = alloca i64
  %g44 = load i64, i64* %g43
  %e45 = alloca i64
  %e46 = load i64, i64* %e45
  br label %body0
body0:
  %a18 = add i64 1, 0
  %b19 = add i64 2, 0
  %c20 = add i64 3, 0
  %d21 = add i64 4, 0
  %i22 = add i64 0, 0
  br label %while.cond11
while.cond11:
  %imm_store24 = add i64 1000000, 0
  %_25 = icmp slt i64 %i22, %imm_store24
  br i1 %_25, label %while.body2, label %while.exit5
while.body2:
  %b0 = phi i64 [ %b19, %while.cond11 ], [ %b0, %while.fillback4 ]
  %i2 = phi i64 [ %i22, %while.cond11 ], [ %i33, %while.fillback4 ]
  %h5 = phi i64 [ %h42, %while.cond11 ], [ %h31, %while.fillback4 ]
  %g7 = phi i64 [ %g44, %while.cond11 ], [ %g29, %while.fillback4 ]
  %a8 = phi i64 [ %a18, %while.cond11 ], [ %a8, %while.fillback4 ]
  %c10 = phi i64 [ %c20, %while.cond11 ], [ %c10, %while.fillback4 ]
  %d12 = phi i64 [ %d21, %while.cond11 ], [ %d12, %while.fillback4 ]
  %e15 = phi i64 [ %e46, %while.cond11 ], [ %e27, %while.fillback4 ]
  %e27 = add i64 5, 0
  %tmp.binop28 = add i64 %a8, %b0
  %g29 = add i64 %tmp.binop28, %c10
  %tmp.binop30 = add i64 %c10, %d12
  %h31 = add i64 %tmp.binop30, %g29
  %imm_store32 = add i64 1, 0
  %i33 = add i64 %i2, %imm_store32
  br label %while.cond23
while.cond23:
  %imm_store35 = add i64 1000000, 0
  %_36 = icmp slt i64 %i33, %imm_store35
  br i1 %_36, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %b1 = phi i64 [ %b19, %while.cond11 ], [ %b0, %while.cond23 ]
  %i3 = phi i64 [ %i22, %while.cond11 ], [ %i33, %while.cond23 ]
  %h4 = phi i64 [ %h42, %while.cond11 ], [ %h31, %while.cond23 ]
  %g6 = phi i64 [ %g44, %while.cond11 ], [ %g29, %while.cond23 ]
  %a9 = phi i64 [ %a18, %while.cond11 ], [ %a8, %while.cond23 ]
  %c11 = phi i64 [ %c20, %while.cond11 ], [ %c10, %while.cond23 ]
  %d13 = phi i64 [ %d21, %while.cond11 ], [ %d12, %while.cond23 ]
  %e14 = phi i64 [ %e46, %while.cond11 ], [ %e27, %while.cond23 ]
  br label %exit
exit:
  %return_reg39 = phi i64 [ %b1, %while.exit5 ]
  ret i64 %return_reg39
}

define i64 @doubleIf() {
entry:
  br label %body0
body0:
  %a9 = add i64 1, 0
  %b10 = add i64 2, 0
  %c11 = add i64 3, 0
  %d12 = add i64 0, 0
  br label %if.cond1
if.cond1:
  %imm_store14 = add i64 1, 0
  %_15 = icmp eq i64 %a9, %imm_store14
  br i1 %_15, label %then.body2, label %if.exit10
then.body2:
  %b17 = add i64 20, 0
  br label %if.cond3
if.cond3:
  %imm_store19 = add i64 1, 0
  %_20 = icmp eq i64 %a9, %imm_store19
  br i1 %_20, label %then.body4, label %else.body6
then.body4:
  %b22 = add i64 200, 0
  %c23 = add i64 300, 0
  br label %then.exit5
then.exit5:
  br label %if.exit8
else.body6:
  %a26 = add i64 1, 0
  %b27 = add i64 2, 0
  %c28 = add i64 3, 0
  br label %else.exit7
else.exit7:
  br label %if.exit8
if.exit8:
  %b1 = phi i64 [ %b22, %then.exit5 ], [ %b27, %else.exit7 ]
  %a2 = phi i64 [ %a9, %then.exit5 ], [ %a26, %else.exit7 ]
  %c4 = phi i64 [ %c23, %then.exit5 ], [ %c28, %else.exit7 ]
  %d31 = add i64 50, 0
  br label %then.exit9
then.exit9:
  br label %if.exit10
if.exit10:
  %b0 = phi i64 [ %b10, %if.cond1 ], [ %b1, %then.exit9 ]
  %a3 = phi i64 [ %a9, %if.cond1 ], [ %a2, %then.exit9 ]
  %c5 = phi i64 [ %c11, %if.cond1 ], [ %c4, %then.exit9 ]
  %d6 = phi i64 [ %d12, %if.cond1 ], [ %d31, %then.exit9 ]
  br label %exit
exit:
  %return_reg34 = phi i64 [ %d6, %if.exit10 ]
  ret i64 %return_reg34
}

define i64 @integerDivide() {
entry:
  br label %body0
body0:
  %a2 = add i64 3000, 0
  %imm_store3 = add i64 2, 0
  %a4 = sdiv i64 %a2, %imm_store3
  %imm_store5 = add i64 4, 0
  %a6 = mul i64 %a4, %imm_store5
  %imm_store7 = add i64 8, 0
  %a8 = sdiv i64 %a6, %imm_store7
  %imm_store9 = add i64 16, 0
  %a10 = sdiv i64 %a8, %imm_store9
  %imm_store11 = add i64 32, 0
  %a12 = mul i64 %a10, %imm_store11
  %imm_store13 = add i64 64, 0
  %a14 = sdiv i64 %a12, %imm_store13
  %imm_store15 = add i64 128, 0
  %a16 = mul i64 %a14, %imm_store15
  %imm_store17 = add i64 4, 0
  %a18 = sdiv i64 %a16, %imm_store17
  br label %exit
exit:
  %return_reg19 = phi i64 [ %a18, %body0 ]
  ret i64 %return_reg19
}

define i64 @association() {
entry:
  br label %body0
body0:
  %a2 = add i64 10, 0
  %imm_store3 = add i64 2, 0
  %a4 = mul i64 %a2, %imm_store3
  %imm_store5 = add i64 2, 0
  %a6 = sdiv i64 %a4, %imm_store5
  %imm_store7 = add i64 3, 0
  %a8 = mul i64 %imm_store7, %a6
  %imm_store9 = add i64 3, 0
  %a10 = sdiv i64 %a8, %imm_store9
  %imm_store11 = add i64 4, 0
  %a12 = mul i64 %a10, %imm_store11
  %imm_store13 = add i64 4, 0
  %a14 = sdiv i64 %a12, %imm_store13
  %imm_store15 = add i64 4, 0
  %a16 = add i64 %a14, %imm_store15
  %imm_store17 = add i64 4, 0
  %a18 = sub i64 %a16, %imm_store17
  %imm_store19 = add i64 50, 0
  %a20 = mul i64 %a18, %imm_store19
  %imm_store21 = add i64 50, 0
  %a22 = sdiv i64 %a20, %imm_store21
  br label %exit
exit:
  %return_reg23 = phi i64 [ %a22, %body0 ]
  ret i64 %return_reg23
}

define i64 @tailRecursionHelper(i64 %value, i64 %sum) {
entry:
  br label %body0
body0:
  br label %if.cond1
if.cond1:
  %imm_store5 = add i64 0, 0
  %_6 = icmp eq i64 %value, %imm_store5
  br i1 %_6, label %then.body2, label %else.body3
then.body2:
  br label %exit
else.body3:
  %imm_store10 = add i64 1, 0
  %tmp.binop11 = sub i64 %value, %imm_store10
  %tmp.binop12 = add i64 %sum, %value
  %aufrufen_tailRecursionHelper13 = call i64 (i64, i64) @tailRecursionHelper(i64 %tmp.binop11, i64 %tmp.binop12)
  br label %exit
exit:
  %return_reg8 = phi i64 [ %sum, %then.body2 ], [ %aufrufen_tailRecursionHelper13, %else.body3 ]
  ret i64 %return_reg8
}

define i64 @tailRecursion(i64 %value) {
entry:
  br label %body0
body0:
  %imm_store3 = add i64 0, 0
  %aufrufen_tailRecursionHelper4 = call i64 (i64, i64) @tailRecursionHelper(i64 %value, i64 %imm_store3)
  br label %exit
exit:
  %return_reg5 = phi i64 [ %aufrufen_tailRecursionHelper4, %body0 ]
  ret i64 %return_reg5
}

define i64 @unswitching() {
entry:
  br label %body0
body0:
  %a7 = add i64 1, 0
  %b8 = add i64 2, 0
  br label %while.cond11
while.cond11:
  %imm_store10 = add i64 1000000, 0
  %_11 = icmp slt i64 %a7, %imm_store10
  br i1 %_11, label %while.body2, label %while.exit11
while.body2:
  %b0 = phi i64 [ %b8, %while.cond11 ], [ %b0, %while.fillback10 ]
  %a4 = phi i64 [ %a7, %while.cond11 ], [ %a2, %while.fillback10 ]
  br label %if.cond3
if.cond3:
  %imm_store14 = add i64 2, 0
  %_15 = icmp eq i64 %b0, %imm_store14
  br i1 %_15, label %then.body4, label %else.body6
then.body4:
  %imm_store17 = add i64 1, 0
  %a18 = add i64 %a4, %imm_store17
  br label %then.exit5
then.exit5:
  br label %if.exit8
else.body6:
  %imm_store21 = add i64 2, 0
  %a22 = add i64 %a4, %imm_store21
  br label %else.exit7
else.exit7:
  br label %if.exit8
if.exit8:
  %a2 = phi i64 [ %a18, %then.exit5 ], [ %a22, %else.exit7 ]
  br label %while.cond29
while.cond29:
  %imm_store26 = add i64 1000000, 0
  %_27 = icmp slt i64 %a2, %imm_store26
  br i1 %_27, label %while.fillback10, label %while.exit11
while.fillback10:
  br label %while.body2
while.exit11:
  %b1 = phi i64 [ %b8, %while.cond11 ], [ %b0, %while.cond29 ]
  %a3 = phi i64 [ %a7, %while.cond11 ], [ %a2, %while.cond29 ]
  br label %exit
exit:
  %return_reg30 = phi i64 [ %a3, %while.exit11 ]
  ret i64 %return_reg30
}

define i64 @randomCalculation(i64 %number) {
entry:
  %b50 = alloca i64
  %b51 = load i64, i64* %b50
  %a52 = alloca i64
  %a53 = load i64, i64* %a52
  %c54 = alloca i64
  %c55 = load i64, i64* %c54
  %d56 = alloca i64
  %d57 = load i64, i64* %d56
  %e58 = alloca i64
  %e59 = load i64, i64* %e58
  br label %body0
body0:
  %i19 = add i64 0, 0
  %sum20 = add i64 0, 0
  br label %while.cond11
while.cond11:
  %_22 = icmp slt i64 %i19, %number
  br i1 %_22, label %while.body2, label %while.exit5
while.body2:
  %b2 = phi i64 [ %b51, %while.cond11 ], [ %b25, %while.fillback4 ]
  %i3 = phi i64 [ %i19, %while.cond11 ], [ %i43, %while.fillback4 ]
  %sum5 = phi i64 [ %sum20, %while.cond11 ], [ %sum29, %while.fillback4 ]
  %number7 = phi i64 [ %number, %while.cond11 ], [ %number7, %while.fillback4 ]
  %a10 = phi i64 [ %a53, %while.cond11 ], [ %a24, %while.fillback4 ]
  %c12 = phi i64 [ %c55, %while.cond11 ], [ %c26, %while.fillback4 ]
  %d14 = phi i64 [ %d57, %while.cond11 ], [ %d27, %while.fillback4 ]
  %e16 = phi i64 [ %e59, %while.cond11 ], [ %e28, %while.fillback4 ]
  %a24 = add i64 4, 0
  %b25 = add i64 7, 0
  %c26 = add i64 8, 0
  %d27 = add i64 %a24, %b25
  %e28 = add i64 %d27, %c26
  %sum29 = add i64 %sum5, %e28
  %imm_store30 = add i64 2, 0
  %i31 = mul i64 %i3, %imm_store30
  %imm_store32 = add i64 2, 0
  %i33 = sdiv i64 %i31, %imm_store32
  %imm_store34 = add i64 3, 0
  %i35 = mul i64 %imm_store34, %i33
  %imm_store36 = add i64 3, 0
  %i37 = sdiv i64 %i35, %imm_store36
  %imm_store38 = add i64 4, 0
  %i39 = mul i64 %i37, %imm_store38
  %imm_store40 = add i64 4, 0
  %i41 = sdiv i64 %i39, %imm_store40
  %imm_store42 = add i64 1, 0
  %i43 = add i64 %i41, %imm_store42
  br label %while.cond23
while.cond23:
  %_45 = icmp slt i64 %i43, %number7
  br i1 %_45, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %b1 = phi i64 [ %b51, %while.cond11 ], [ %b25, %while.cond23 ]
  %i4 = phi i64 [ %i19, %while.cond11 ], [ %i43, %while.cond23 ]
  %sum6 = phi i64 [ %sum20, %while.cond11 ], [ %sum29, %while.cond23 ]
  %number8 = phi i64 [ %number, %while.cond11 ], [ %number7, %while.cond23 ]
  %a9 = phi i64 [ %a53, %while.cond11 ], [ %a24, %while.cond23 ]
  %c11 = phi i64 [ %c55, %while.cond11 ], [ %c26, %while.cond23 ]
  %d13 = phi i64 [ %d57, %while.cond11 ], [ %d27, %while.cond23 ]
  %e15 = phi i64 [ %e59, %while.cond11 ], [ %e28, %while.cond23 ]
  br label %exit
exit:
  %return_reg48 = phi i64 [ %sum6, %while.exit5 ]
  ret i64 %return_reg48
}

define i64 @iterativeFibonacci(i64 %number) {
entry:
  %sum29 = alloca i64
  %sum30 = load i64, i64* %sum29
  br label %body0
body0:
  %imm_store13 = add i64 1, 0
  %previous14 = sub i64 0, %imm_store13
  %result15 = add i64 1, 0
  %i16 = add i64 0, 0
  br label %while.cond11
while.cond11:
  %_18 = icmp slt i64 %i16, %number
  br i1 %_18, label %while.body2, label %while.exit5
while.body2:
  %previous1 = phi i64 [ %result15, %while.cond11 ], [ %result20, %while.fillback4 ]
  %number3 = phi i64 [ %number, %while.cond11 ], [ %number3, %while.fillback4 ]
  %i5 = phi i64 [ %i16, %while.cond11 ], [ %i22, %while.fillback4 ]
  %previous7 = phi i64 [ %previous14, %while.cond11 ], [ %previous1, %while.fillback4 ]
  %sum10 = phi i64 [ %sum30, %while.cond11 ], [ %result20, %while.fillback4 ]
  %result20 = add i64 %previous1, %previous7
  %imm_store21 = add i64 1, 0
  %i22 = add i64 %i5, %imm_store21
  br label %while.cond23
while.cond23:
  %_24 = icmp slt i64 %i22, %number3
  br i1 %_24, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %result2 = phi i64 [ %result15, %while.cond11 ], [ %result20, %while.cond23 ]
  %number4 = phi i64 [ %number, %while.cond11 ], [ %number3, %while.cond23 ]
  %i6 = phi i64 [ %i16, %while.cond11 ], [ %i22, %while.cond23 ]
  %previous8 = phi i64 [ %previous14, %while.cond11 ], [ %previous1, %while.cond23 ]
  %sum9 = phi i64 [ %sum30, %while.cond11 ], [ %result20, %while.cond23 ]
  br label %exit
exit:
  %return_reg27 = phi i64 [ %result2, %while.exit5 ]
  ret i64 %return_reg27
}

define i64 @recursiveFibonacci(i64 %number) {
entry:
  br label %body0
body0:
  br label %if.cond1
if.cond1:
  %imm_store4 = add i64 0, 0
  %tmp.binop5 = icmp sle i64 %number, %imm_store4
  %imm_store6 = add i64 1, 0
  %tmp.binop7 = icmp eq i64 %number, %imm_store6
  %_8 = or i1 %tmp.binop5, %tmp.binop7
  br i1 %_8, label %then.body2, label %else.body3
then.body2:
  br label %exit
else.body3:
  %imm_store12 = add i64 1, 0
  %tmp.binop13 = sub i64 %number, %imm_store12
  %aufrufen_recursiveFibonacci14 = call i64 (i64) @recursiveFibonacci(i64 %tmp.binop13)
  %imm_store15 = add i64 2, 0
  %tmp.binop16 = sub i64 %number, %imm_store15
  %aufrufen_recursiveFibonacci17 = call i64 (i64) @recursiveFibonacci(i64 %tmp.binop16)
  %tmp.binop18 = add i64 %aufrufen_recursiveFibonacci14, %aufrufen_recursiveFibonacci17
  br label %exit
exit:
  %return_reg10 = phi i64 [ %number, %then.body2 ], [ %tmp.binop18, %else.body3 ]
  ret i64 %return_reg10
}

define i64 @main() {
entry:
  %return_reg6 = alloca i64
  %_7 = load i64, i64* %return_reg6
  %result76 = alloca i64
  %result77 = load i64, i64* %result76
  br label %body0
body0:
  %_8 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_9 = call i32 (i8*, ...) @scanf(i8* %_8, i32* @.read_scratch)
  %_10 = load i32, i32* @.read_scratch
  %input11 = sext i32 %_10 to i64
  %i12 = add i64 1, 0
  br label %while.cond11
while.cond11:
  %_14 = icmp slt i64 %i12, %input11
  br i1 %_14, label %while.body2, label %while.exit5
while.body2:
  %result1 = phi i64 [ %result77, %while.cond11 ], [ %result61, %while.fillback4 ]
  %input2 = phi i64 [ %input11, %while.cond11 ], [ %input2, %while.fillback4 ]
  %i4 = phi i64 [ %i12, %while.cond11 ], [ %i65, %while.fillback4 ]
  %result16 = call i64 () @constantFolding()
  %_17 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_18 = call i32 (i8*, ...) @printf(i8* %_17, i64 %result16)
  %result19 = call i64 () @constantPropagation()
  %_20 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_21 = call i32 (i8*, ...) @printf(i8* %_20, i64 %result19)
  %result22 = call i64 () @deadCodeElimination()
  %_23 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_24 = call i32 (i8*, ...) @printf(i8* %_23, i64 %result22)
  %result25 = call i64 () @interProceduralOptimization()
  %_26 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_27 = call i32 (i8*, ...) @printf(i8* %_26, i64 %result25)
  %result28 = call i64 () @commonSubexpressionElimination()
  %_29 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_30 = call i32 (i8*, ...) @printf(i8* %_29, i64 %result28)
  %result31 = call i64 () @hoisting()
  %_32 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_33 = call i32 (i8*, ...) @printf(i8* %_32, i64 %result31)
  %result34 = call i64 () @doubleIf()
  %_35 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_36 = call i32 (i8*, ...) @printf(i8* %_35, i64 %result34)
  %result37 = call i64 () @integerDivide()
  %_38 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_39 = call i32 (i8*, ...) @printf(i8* %_38, i64 %result37)
  %result40 = call i64 () @association()
  %_41 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_42 = call i32 (i8*, ...) @printf(i8* %_41, i64 %result40)
  %imm_store43 = add i64 1000, 0
  %tmp.binop44 = sdiv i64 %input2, %imm_store43
  %result45 = call i64 (i64) @tailRecursion(i64 %tmp.binop44)
  %_46 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_47 = call i32 (i8*, ...) @printf(i8* %_46, i64 %result45)
  %result48 = call i64 () @unswitching()
  %_49 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_50 = call i32 (i8*, ...) @printf(i8* %_49, i64 %result48)
  %result51 = call i64 (i64) @randomCalculation(i64 %input2)
  %_52 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_53 = call i32 (i8*, ...) @printf(i8* %_52, i64 %result51)
  %imm_store54 = add i64 5, 0
  %tmp.binop55 = sdiv i64 %input2, %imm_store54
  %result56 = call i64 (i64) @iterativeFibonacci(i64 %tmp.binop55)
  %_57 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_58 = call i32 (i8*, ...) @printf(i8* %_57, i64 %result56)
  %imm_store59 = add i64 1000, 0
  %tmp.binop60 = sdiv i64 %input2, %imm_store59
  %result61 = call i64 (i64) @recursiveFibonacci(i64 %tmp.binop60)
  %_62 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_63 = call i32 (i8*, ...) @printf(i8* %_62, i64 %result61)
  %imm_store64 = add i64 1, 0
  %i65 = add i64 %i4, %imm_store64
  br label %while.cond23
while.cond23:
  %_67 = icmp slt i64 %i65, %input2
  br i1 %_67, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %result0 = phi i64 [ %result77, %while.cond11 ], [ %result61, %while.cond23 ]
  %input3 = phi i64 [ %input11, %while.cond11 ], [ %input2, %while.cond23 ]
  %i5 = phi i64 [ %i12, %while.cond11 ], [ %i65, %while.cond23 ]
  %imm_store70 = add i64 9999, 0
  %_71 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_72 = call i32 (i8*, ...) @printf(i8* %_71, i64 %imm_store70)
  %imm_store73 = add i64 0, 0
  br label %exit
exit:
  %return_reg74 = phi i64 [ %imm_store73, %while.exit5 ]
  ret i64 %return_reg74
}

