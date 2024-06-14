%struct.gameBoard = type { i64, i64, i64, i64, i64, i64, i64, i64, i64 }

declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

define void @cleanBoard(%struct.gameBoard* %board) {
entry:
  br label %body0
body0:
  %imm_store1 = add i64 0, 0
  %board.a_auf2 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 0
  store i64 %imm_store1, i64* %board.a_auf2
  %imm_store4 = add i64 0, 0
  %board.b_auf5 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 1
  store i64 %imm_store4, i64* %board.b_auf5
  %imm_store7 = add i64 0, 0
  %board.c_auf8 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 2
  store i64 %imm_store7, i64* %board.c_auf8
  %imm_store10 = add i64 0, 0
  %board.d_auf11 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 3
  store i64 %imm_store10, i64* %board.d_auf11
  %imm_store13 = add i64 0, 0
  %board.e_auf14 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 4
  store i64 %imm_store13, i64* %board.e_auf14
  %imm_store16 = add i64 0, 0
  %board.f_auf17 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 5
  store i64 %imm_store16, i64* %board.f_auf17
  %imm_store19 = add i64 0, 0
  %board.g_auf20 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 6
  store i64 %imm_store19, i64* %board.g_auf20
  %imm_store22 = add i64 0, 0
  %board.h_auf23 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 7
  store i64 %imm_store22, i64* %board.h_auf23
  %imm_store25 = add i64 0, 0
  %board.i_auf26 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 8
  store i64 %imm_store25, i64* %board.i_auf26
  br label %exit
exit:
  ret void
}

define void @printBoard(%struct.gameBoard* %board) {
entry:
  br label %body0
body0:
  %board.a_auf1 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 0
  %_2 = load i64, i64* %board.a_auf1
  %_3 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_4 = call i32 (i8*, ...) @printf(i8* %_3, i64 %_2)
  %board.b_auf5 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 1
  %_6 = load i64, i64* %board.b_auf5
  %_7 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_8 = call i32 (i8*, ...) @printf(i8* %_7, i64 %_6)
  %board.c_auf9 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 2
  %_10 = load i64, i64* %board.c_auf9
  %_11 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_12 = call i32 (i8*, ...) @printf(i8* %_11, i64 %_10)
  %board.d_auf13 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 3
  %_14 = load i64, i64* %board.d_auf13
  %_15 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_16 = call i32 (i8*, ...) @printf(i8* %_15, i64 %_14)
  %board.e_auf17 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 4
  %_18 = load i64, i64* %board.e_auf17
  %_19 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_20 = call i32 (i8*, ...) @printf(i8* %_19, i64 %_18)
  %board.f_auf21 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 5
  %_22 = load i64, i64* %board.f_auf21
  %_23 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_24 = call i32 (i8*, ...) @printf(i8* %_23, i64 %_22)
  %board.g_auf25 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 6
  %_26 = load i64, i64* %board.g_auf25
  %_27 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_28 = call i32 (i8*, ...) @printf(i8* %_27, i64 %_26)
  %board.h_auf29 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 7
  %_30 = load i64, i64* %board.h_auf29
  %_31 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_32 = call i32 (i8*, ...) @printf(i8* %_31, i64 %_30)
  %board.i_auf33 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 8
  %_34 = load i64, i64* %board.i_auf33
  %_35 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_36 = call i32 (i8*, ...) @printf(i8* %_35, i64 %_34)
  br label %exit
exit:
  ret void
}

define void @printMoveBoard() {
entry:
  br label %body0
body0:
  %imm_store0 = add i64 123, 0
  %_1 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_2 = call i32 (i8*, ...) @printf(i8* %_1, i64 %imm_store0)
  %imm_store3 = add i64 456, 0
  %_4 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_5 = call i32 (i8*, ...) @printf(i8* %_4, i64 %imm_store3)
  %imm_store6 = add i64 789, 0
  %_7 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_8 = call i32 (i8*, ...) @printf(i8* %_7, i64 %imm_store6)
  br label %exit
exit:
  ret void
}

define void @placePiece(%struct.gameBoard* %board, i64 %turn, i64 %placement) {
entry:
  br label %body0
body0:
  br label %if.cond1
if.cond1:
  %imm_store13 = add i64 1, 0
  %_14 = icmp eq i64 %placement, %imm_store13
  br i1 %_14, label %then.body2, label %else.body4
then.body2:
  %board.a_auf16 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 0
  store i64 %turn, i64* %board.a_auf16
  br label %then.exit3
then.exit3:
  br label %if.exit52
else.body4:
  br label %if.cond5
if.cond5:
  %imm_store21 = add i64 2, 0
  %_22 = icmp eq i64 %placement, %imm_store21
  br i1 %_22, label %then.body6, label %else.body8
then.body6:
  %board.b_auf24 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 1
  store i64 %turn, i64* %board.b_auf24
  br label %then.exit7
then.exit7:
  br label %if.exit50
else.body8:
  br label %if.cond9
if.cond9:
  %imm_store29 = add i64 3, 0
  %_30 = icmp eq i64 %placement, %imm_store29
  br i1 %_30, label %then.body10, label %else.body12
then.body10:
  %board.c_auf32 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 2
  store i64 %turn, i64* %board.c_auf32
  br label %then.exit11
then.exit11:
  br label %if.exit48
else.body12:
  br label %if.cond13
if.cond13:
  %imm_store37 = add i64 4, 0
  %_38 = icmp eq i64 %placement, %imm_store37
  br i1 %_38, label %then.body14, label %else.body16
then.body14:
  %board.d_auf40 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 3
  store i64 %turn, i64* %board.d_auf40
  br label %then.exit15
then.exit15:
  br label %if.exit46
else.body16:
  br label %if.cond17
if.cond17:
  %imm_store45 = add i64 5, 0
  %_46 = icmp eq i64 %placement, %imm_store45
  br i1 %_46, label %then.body18, label %else.body20
then.body18:
  %board.e_auf48 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 4
  store i64 %turn, i64* %board.e_auf48
  br label %then.exit19
then.exit19:
  br label %if.exit44
else.body20:
  br label %if.cond21
if.cond21:
  %imm_store53 = add i64 6, 0
  %_54 = icmp eq i64 %placement, %imm_store53
  br i1 %_54, label %then.body22, label %else.body24
then.body22:
  %board.f_auf56 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 5
  store i64 %turn, i64* %board.f_auf56
  br label %then.exit23
then.exit23:
  br label %if.exit42
else.body24:
  br label %if.cond25
if.cond25:
  %imm_store61 = add i64 7, 0
  %_62 = icmp eq i64 %placement, %imm_store61
  br i1 %_62, label %then.body26, label %else.body28
then.body26:
  %board.g_auf64 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 6
  store i64 %turn, i64* %board.g_auf64
  br label %then.exit27
then.exit27:
  br label %if.exit40
else.body28:
  br label %if.cond29
if.cond29:
  %imm_store69 = add i64 8, 0
  %_70 = icmp eq i64 %placement, %imm_store69
  br i1 %_70, label %then.body30, label %else.body32
then.body30:
  %board.h_auf72 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 7
  store i64 %turn, i64* %board.h_auf72
  br label %then.exit31
then.exit31:
  br label %if.exit38
else.body32:
  br label %if.cond33
if.cond33:
  %imm_store77 = add i64 9, 0
  %_78 = icmp eq i64 %placement, %imm_store77
  br i1 %_78, label %then.body34, label %if.exit36
then.body34:
  %board.i_auf80 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 8
  store i64 %turn, i64* %board.i_auf80
  br label %then.exit35
then.exit35:
  br label %if.exit36
if.exit36:
  %board10 = phi %struct.gameBoard* [ %board, %if.cond33 ], [ %board, %then.exit35 ]
  br label %else.exit37
else.exit37:
  br label %if.exit38
if.exit38:
  %board11 = phi %struct.gameBoard* [ %board, %then.exit31 ], [ %board10, %else.exit37 ]
  br label %else.exit39
else.exit39:
  br label %if.exit40
if.exit40:
  %board8 = phi %struct.gameBoard* [ %board, %then.exit27 ], [ %board11, %else.exit39 ]
  br label %else.exit41
else.exit41:
  br label %if.exit42
if.exit42:
  %board9 = phi %struct.gameBoard* [ %board, %then.exit23 ], [ %board8, %else.exit41 ]
  br label %else.exit43
else.exit43:
  br label %if.exit44
if.exit44:
  %board7 = phi %struct.gameBoard* [ %board, %then.exit19 ], [ %board9, %else.exit43 ]
  br label %else.exit45
else.exit45:
  br label %if.exit46
if.exit46:
  %board6 = phi %struct.gameBoard* [ %board, %then.exit15 ], [ %board7, %else.exit45 ]
  br label %else.exit47
else.exit47:
  br label %if.exit48
if.exit48:
  %board3 = phi %struct.gameBoard* [ %board, %then.exit11 ], [ %board6, %else.exit47 ]
  br label %else.exit49
else.exit49:
  br label %if.exit50
if.exit50:
  %board4 = phi %struct.gameBoard* [ %board, %then.exit7 ], [ %board3, %else.exit49 ]
  br label %else.exit51
else.exit51:
  br label %if.exit52
if.exit52:
  %board5 = phi %struct.gameBoard* [ %board, %then.exit3 ], [ %board4, %else.exit51 ]
  br label %exit
exit:
  ret void
}

define i64 @checkWinner(%struct.gameBoard* %board) {
entry:
  br label %body0
body0:
  br label %if.cond1
if.cond1:
  %board.a_auf4 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 0
  %_5 = load i64, i64* %board.a_auf4
  %imm_store6 = add i64 1, 0
  %_7 = icmp eq i64 %_5, %imm_store6
  br i1 %_7, label %then.body2, label %if.exit11
then.body2:
  br label %if.cond3
if.cond3:
  %board.b_auf10 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 1
  %_11 = load i64, i64* %board.b_auf10
  %imm_store12 = add i64 1, 0
  %_13 = icmp eq i64 %_11, %imm_store12
  br i1 %_13, label %then.body4, label %if.exit9
then.body4:
  br label %if.cond5
if.cond5:
  %board.c_auf16 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 2
  %_17 = load i64, i64* %board.c_auf16
  %imm_store18 = add i64 1, 0
  %_19 = icmp eq i64 %_17, %imm_store18
  br i1 %_19, label %then.body6, label %if.exit7
then.body6:
  %imm_store21 = add i64 0, 0
  br label %exit
if.exit7:
  br label %then.exit8
then.exit8:
  br label %if.exit9
if.exit9:
  br label %then.exit10
then.exit10:
  br label %if.exit11
if.exit11:
  br label %if.cond12
if.cond12:
  %board.a_auf29 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 0
  %_30 = load i64, i64* %board.a_auf29
  %imm_store31 = add i64 2, 0
  %_32 = icmp eq i64 %_30, %imm_store31
  br i1 %_32, label %then.body13, label %if.exit22
then.body13:
  br label %if.cond14
if.cond14:
  %board.b_auf35 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 1
  %_36 = load i64, i64* %board.b_auf35
  %imm_store37 = add i64 2, 0
  %_38 = icmp eq i64 %_36, %imm_store37
  br i1 %_38, label %then.body15, label %if.exit20
then.body15:
  br label %if.cond16
if.cond16:
  %board.c_auf41 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 2
  %_42 = load i64, i64* %board.c_auf41
  %imm_store43 = add i64 2, 0
  %_44 = icmp eq i64 %_42, %imm_store43
  br i1 %_44, label %then.body17, label %if.exit18
then.body17:
  %imm_store46 = add i64 1, 0
  br label %exit
if.exit18:
  br label %then.exit19
then.exit19:
  br label %if.exit20
if.exit20:
  br label %then.exit21
then.exit21:
  br label %if.exit22
if.exit22:
  br label %if.cond23
if.cond23:
  %board.d_auf53 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 3
  %_54 = load i64, i64* %board.d_auf53
  %imm_store55 = add i64 1, 0
  %_56 = icmp eq i64 %_54, %imm_store55
  br i1 %_56, label %then.body24, label %if.exit33
then.body24:
  br label %if.cond25
if.cond25:
  %board.e_auf59 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 4
  %_60 = load i64, i64* %board.e_auf59
  %imm_store61 = add i64 1, 0
  %_62 = icmp eq i64 %_60, %imm_store61
  br i1 %_62, label %then.body26, label %if.exit31
then.body26:
  br label %if.cond27
if.cond27:
  %board.f_auf65 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 5
  %_66 = load i64, i64* %board.f_auf65
  %imm_store67 = add i64 1, 0
  %_68 = icmp eq i64 %_66, %imm_store67
  br i1 %_68, label %then.body28, label %if.exit29
then.body28:
  %imm_store70 = add i64 0, 0
  br label %exit
if.exit29:
  br label %then.exit30
then.exit30:
  br label %if.exit31
if.exit31:
  br label %then.exit32
then.exit32:
  br label %if.exit33
if.exit33:
  br label %if.cond34
if.cond34:
  %board.d_auf77 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 3
  %_78 = load i64, i64* %board.d_auf77
  %imm_store79 = add i64 2, 0
  %_80 = icmp eq i64 %_78, %imm_store79
  br i1 %_80, label %then.body35, label %if.exit44
then.body35:
  br label %if.cond36
if.cond36:
  %board.e_auf83 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 4
  %_84 = load i64, i64* %board.e_auf83
  %imm_store85 = add i64 2, 0
  %_86 = icmp eq i64 %_84, %imm_store85
  br i1 %_86, label %then.body37, label %if.exit42
then.body37:
  br label %if.cond38
if.cond38:
  %board.f_auf89 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 5
  %_90 = load i64, i64* %board.f_auf89
  %imm_store91 = add i64 2, 0
  %_92 = icmp eq i64 %_90, %imm_store91
  br i1 %_92, label %then.body39, label %if.exit40
then.body39:
  %imm_store94 = add i64 1, 0
  br label %exit
if.exit40:
  br label %then.exit41
then.exit41:
  br label %if.exit42
if.exit42:
  br label %then.exit43
then.exit43:
  br label %if.exit44
if.exit44:
  br label %if.cond45
if.cond45:
  %board.g_auf101 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 6
  %_102 = load i64, i64* %board.g_auf101
  %imm_store103 = add i64 1, 0
  %_104 = icmp eq i64 %_102, %imm_store103
  br i1 %_104, label %then.body46, label %if.exit55
then.body46:
  br label %if.cond47
if.cond47:
  %board.h_auf107 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 7
  %_108 = load i64, i64* %board.h_auf107
  %imm_store109 = add i64 1, 0
  %_110 = icmp eq i64 %_108, %imm_store109
  br i1 %_110, label %then.body48, label %if.exit53
then.body48:
  br label %if.cond49
if.cond49:
  %board.i_auf113 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 8
  %_114 = load i64, i64* %board.i_auf113
  %imm_store115 = add i64 1, 0
  %_116 = icmp eq i64 %_114, %imm_store115
  br i1 %_116, label %then.body50, label %if.exit51
then.body50:
  %imm_store118 = add i64 0, 0
  br label %exit
if.exit51:
  br label %then.exit52
then.exit52:
  br label %if.exit53
if.exit53:
  br label %then.exit54
then.exit54:
  br label %if.exit55
if.exit55:
  br label %if.cond56
if.cond56:
  %board.g_auf125 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 6
  %_126 = load i64, i64* %board.g_auf125
  %imm_store127 = add i64 2, 0
  %_128 = icmp eq i64 %_126, %imm_store127
  br i1 %_128, label %then.body57, label %if.exit66
then.body57:
  br label %if.cond58
if.cond58:
  %board.h_auf131 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 7
  %_132 = load i64, i64* %board.h_auf131
  %imm_store133 = add i64 2, 0
  %_134 = icmp eq i64 %_132, %imm_store133
  br i1 %_134, label %then.body59, label %if.exit64
then.body59:
  br label %if.cond60
if.cond60:
  %board.i_auf137 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 8
  %_138 = load i64, i64* %board.i_auf137
  %imm_store139 = add i64 2, 0
  %_140 = icmp eq i64 %_138, %imm_store139
  br i1 %_140, label %then.body61, label %if.exit62
then.body61:
  %imm_store142 = add i64 1, 0
  br label %exit
if.exit62:
  br label %then.exit63
then.exit63:
  br label %if.exit64
if.exit64:
  br label %then.exit65
then.exit65:
  br label %if.exit66
if.exit66:
  br label %if.cond67
if.cond67:
  %board.a_auf149 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 0
  %_150 = load i64, i64* %board.a_auf149
  %imm_store151 = add i64 1, 0
  %_152 = icmp eq i64 %_150, %imm_store151
  br i1 %_152, label %then.body68, label %if.exit77
then.body68:
  br label %if.cond69
if.cond69:
  %board.d_auf155 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 3
  %_156 = load i64, i64* %board.d_auf155
  %imm_store157 = add i64 1, 0
  %_158 = icmp eq i64 %_156, %imm_store157
  br i1 %_158, label %then.body70, label %if.exit75
then.body70:
  br label %if.cond71
if.cond71:
  %board.g_auf161 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 6
  %_162 = load i64, i64* %board.g_auf161
  %imm_store163 = add i64 1, 0
  %_164 = icmp eq i64 %_162, %imm_store163
  br i1 %_164, label %then.body72, label %if.exit73
then.body72:
  %imm_store166 = add i64 0, 0
  br label %exit
if.exit73:
  br label %then.exit74
then.exit74:
  br label %if.exit75
if.exit75:
  br label %then.exit76
then.exit76:
  br label %if.exit77
if.exit77:
  br label %if.cond78
if.cond78:
  %board.a_auf173 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 0
  %_174 = load i64, i64* %board.a_auf173
  %imm_store175 = add i64 2, 0
  %_176 = icmp eq i64 %_174, %imm_store175
  br i1 %_176, label %then.body79, label %if.exit88
then.body79:
  br label %if.cond80
if.cond80:
  %board.d_auf179 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 3
  %_180 = load i64, i64* %board.d_auf179
  %imm_store181 = add i64 2, 0
  %_182 = icmp eq i64 %_180, %imm_store181
  br i1 %_182, label %then.body81, label %if.exit86
then.body81:
  br label %if.cond82
if.cond82:
  %board.g_auf185 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 6
  %_186 = load i64, i64* %board.g_auf185
  %imm_store187 = add i64 2, 0
  %_188 = icmp eq i64 %_186, %imm_store187
  br i1 %_188, label %then.body83, label %if.exit84
then.body83:
  %imm_store190 = add i64 1, 0
  br label %exit
if.exit84:
  br label %then.exit85
then.exit85:
  br label %if.exit86
if.exit86:
  br label %then.exit87
then.exit87:
  br label %if.exit88
if.exit88:
  br label %if.cond89
if.cond89:
  %board.b_auf197 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 1
  %_198 = load i64, i64* %board.b_auf197
  %imm_store199 = add i64 1, 0
  %_200 = icmp eq i64 %_198, %imm_store199
  br i1 %_200, label %then.body90, label %if.exit99
then.body90:
  br label %if.cond91
if.cond91:
  %board.e_auf203 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 4
  %_204 = load i64, i64* %board.e_auf203
  %imm_store205 = add i64 1, 0
  %_206 = icmp eq i64 %_204, %imm_store205
  br i1 %_206, label %then.body92, label %if.exit97
then.body92:
  br label %if.cond93
if.cond93:
  %board.h_auf209 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 7
  %_210 = load i64, i64* %board.h_auf209
  %imm_store211 = add i64 1, 0
  %_212 = icmp eq i64 %_210, %imm_store211
  br i1 %_212, label %then.body94, label %if.exit95
then.body94:
  %imm_store214 = add i64 0, 0
  br label %exit
if.exit95:
  br label %then.exit96
then.exit96:
  br label %if.exit97
if.exit97:
  br label %then.exit98
then.exit98:
  br label %if.exit99
if.exit99:
  br label %if.cond100
if.cond100:
  %board.b_auf221 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 1
  %_222 = load i64, i64* %board.b_auf221
  %imm_store223 = add i64 2, 0
  %_224 = icmp eq i64 %_222, %imm_store223
  br i1 %_224, label %then.body101, label %if.exit110
then.body101:
  br label %if.cond102
if.cond102:
  %board.e_auf227 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 4
  %_228 = load i64, i64* %board.e_auf227
  %imm_store229 = add i64 2, 0
  %_230 = icmp eq i64 %_228, %imm_store229
  br i1 %_230, label %then.body103, label %if.exit108
then.body103:
  br label %if.cond104
if.cond104:
  %board.h_auf233 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 7
  %_234 = load i64, i64* %board.h_auf233
  %imm_store235 = add i64 2, 0
  %_236 = icmp eq i64 %_234, %imm_store235
  br i1 %_236, label %then.body105, label %if.exit106
then.body105:
  %imm_store238 = add i64 1, 0
  br label %exit
if.exit106:
  br label %then.exit107
then.exit107:
  br label %if.exit108
if.exit108:
  br label %then.exit109
then.exit109:
  br label %if.exit110
if.exit110:
  br label %if.cond111
if.cond111:
  %board.c_auf245 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 2
  %_246 = load i64, i64* %board.c_auf245
  %imm_store247 = add i64 1, 0
  %_248 = icmp eq i64 %_246, %imm_store247
  br i1 %_248, label %then.body112, label %if.exit121
then.body112:
  br label %if.cond113
if.cond113:
  %board.f_auf251 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 5
  %_252 = load i64, i64* %board.f_auf251
  %imm_store253 = add i64 1, 0
  %_254 = icmp eq i64 %_252, %imm_store253
  br i1 %_254, label %then.body114, label %if.exit119
then.body114:
  br label %if.cond115
if.cond115:
  %board.i_auf257 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 8
  %_258 = load i64, i64* %board.i_auf257
  %imm_store259 = add i64 1, 0
  %_260 = icmp eq i64 %_258, %imm_store259
  br i1 %_260, label %then.body116, label %if.exit117
then.body116:
  %imm_store262 = add i64 0, 0
  br label %exit
if.exit117:
  br label %then.exit118
then.exit118:
  br label %if.exit119
if.exit119:
  br label %then.exit120
then.exit120:
  br label %if.exit121
if.exit121:
  br label %if.cond122
if.cond122:
  %board.c_auf269 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 2
  %_270 = load i64, i64* %board.c_auf269
  %imm_store271 = add i64 2, 0
  %_272 = icmp eq i64 %_270, %imm_store271
  br i1 %_272, label %then.body123, label %if.exit132
then.body123:
  br label %if.cond124
if.cond124:
  %board.f_auf275 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 5
  %_276 = load i64, i64* %board.f_auf275
  %imm_store277 = add i64 2, 0
  %_278 = icmp eq i64 %_276, %imm_store277
  br i1 %_278, label %then.body125, label %if.exit130
then.body125:
  br label %if.cond126
if.cond126:
  %board.i_auf281 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 8
  %_282 = load i64, i64* %board.i_auf281
  %imm_store283 = add i64 2, 0
  %_284 = icmp eq i64 %_282, %imm_store283
  br i1 %_284, label %then.body127, label %if.exit128
then.body127:
  %imm_store286 = add i64 1, 0
  br label %exit
if.exit128:
  br label %then.exit129
then.exit129:
  br label %if.exit130
if.exit130:
  br label %then.exit131
then.exit131:
  br label %if.exit132
if.exit132:
  %imm_store292 = add i64 1, 0
  %tmp.unop293 = sub i64 0, %imm_store292
  br label %exit
exit:
  %return_reg22 = phi i64 [ %imm_store21, %then.body6 ], [ %imm_store46, %then.body17 ], [ %imm_store70, %then.body28 ], [ %imm_store94, %then.body39 ], [ %imm_store118, %then.body50 ], [ %imm_store142, %then.body61 ], [ %imm_store166, %then.body72 ], [ %imm_store190, %then.body83 ], [ %imm_store214, %then.body94 ], [ %imm_store238, %then.body105 ], [ %imm_store262, %then.body116 ], [ %imm_store286, %then.body127 ], [ %tmp.unop293, %if.exit132 ]
  ret i64 %return_reg22
}

define i64 @main() {
entry:
  br label %body0
body0:
  %i17 = add i64 0, 0
  %turn18 = add i64 0, 0
  %space119 = add i64 0, 0
  %space220 = add i64 0, 0
  %imm_store21 = add i64 1, 0
  %winner22 = sub i64 0, %imm_store21
  %gameBoard.malloc23 = call i8* (i32) @malloc(i32 72)
  %board24 = bitcast i8* %gameBoard.malloc23 to %struct.gameBoard*
  call void (%struct.gameBoard*) @cleanBoard(%struct.gameBoard* %board24)
  br label %while.cond11
while.cond11:
  %imm_store27 = add i64 0, 0
  %tmp.binop28 = icmp slt i64 %winner22, %imm_store27
  %imm_store29 = add i64 8, 0
  %tmp.binop30 = icmp ne i64 %i17, %imm_store29
  %_31 = and i1 %tmp.binop28, %tmp.binop30
  br i1 %_31, label %while.body2, label %while.exit11
while.body2:
  %space12 = phi i64 [ %space119, %while.cond11 ], [ %space10, %while.fillback10 ]
  %space23 = phi i64 [ %space220, %while.cond11 ], [ %space25, %while.fillback10 ]
  %board6 = phi %struct.gameBoard* [ %board24, %while.cond11 ], [ %board6, %while.fillback10 ]
  %i8 = phi i64 [ %i17, %while.cond11 ], [ %i60, %while.fillback10 ]
  %winner10 = phi i64 [ %winner22, %while.cond11 ], [ %winner58, %while.fillback10 ]
  %turn14 = phi i64 [ %turn18, %while.cond11 ], [ %turn12, %while.fillback10 ]
  call void (%struct.gameBoard*) @printBoard(%struct.gameBoard* %board6)
  br label %if.cond3
if.cond3:
  %imm_store35 = add i64 0, 0
  %_36 = icmp eq i64 %turn14, %imm_store35
  br i1 %_36, label %then.body4, label %else.body6
then.body4:
  %imm_store38 = add i64 1, 0
  %turn39 = add i64 %turn14, %imm_store38
  %_40 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_41 = call i32 (i8*, ...) @scanf(i8* %_40, i32* @.read_scratch)
  %_42 = load i32, i32* @.read_scratch
  %space143 = sext i32 %_42 to i64
  %imm_store44 = add i64 1, 0
  call void (%struct.gameBoard*, i64, i64) @placePiece(%struct.gameBoard* %board6, i64 %imm_store44, i64 %space143)
  br label %then.exit5
then.exit5:
  br label %if.exit8
else.body6:
  %imm_store48 = add i64 1, 0
  %turn49 = sub i64 %turn14, %imm_store48
  %_50 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_51 = call i32 (i8*, ...) @scanf(i8* %_50, i32* @.read_scratch)
  %_52 = load i32, i32* @.read_scratch
  %space253 = sext i32 %_52 to i64
  %imm_store54 = add i64 2, 0
  call void (%struct.gameBoard*, i64, i64) @placePiece(%struct.gameBoard* %board6, i64 %imm_store54, i64 %space253)
  br label %else.exit7
else.exit7:
  br label %if.exit8
if.exit8:
  %space10 = phi i64 [ %space143, %then.exit5 ], [ %space12, %else.exit7 ]
  %space25 = phi i64 [ %space23, %then.exit5 ], [ %space253, %else.exit7 ]
  %turn12 = phi i64 [ %turn39, %then.exit5 ], [ %turn49, %else.exit7 ]
  %winner58 = call i64 (%struct.gameBoard*) @checkWinner(%struct.gameBoard* %board6)
  %imm_store59 = add i64 1, 0
  %i60 = add i64 %i8, %imm_store59
  br label %while.cond29
while.cond29:
  %imm_store62 = add i64 0, 0
  %tmp.binop63 = icmp slt i64 %winner58, %imm_store62
  %imm_store64 = add i64 8, 0
  %tmp.binop65 = icmp ne i64 %i60, %imm_store64
  %_66 = and i1 %tmp.binop63, %tmp.binop65
  br i1 %_66, label %while.fillback10, label %while.exit11
while.fillback10:
  br label %while.body2
while.exit11:
  %space11 = phi i64 [ %space119, %while.cond11 ], [ %space10, %while.cond29 ]
  %space24 = phi i64 [ %space220, %while.cond11 ], [ %space25, %while.cond29 ]
  %board7 = phi %struct.gameBoard* [ %board24, %while.cond11 ], [ %board6, %while.cond29 ]
  %i9 = phi i64 [ %i17, %while.cond11 ], [ %i60, %while.cond29 ]
  %winner11 = phi i64 [ %winner22, %while.cond11 ], [ %winner58, %while.cond29 ]
  %turn13 = phi i64 [ %turn18, %while.cond11 ], [ %turn12, %while.cond29 ]
  %imm_store69 = add i64 1, 0
  %tmp.binop70 = add i64 %winner11, %imm_store69
  %_71 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_72 = call i32 (i8*, ...) @printf(i8* %_71, i64 %tmp.binop70)
  %imm_store73 = add i64 0, 0
  br label %exit
exit:
  %return_reg74 = phi i64 [ %imm_store73, %while.exit11 ]
  ret i64 %return_reg74
}

