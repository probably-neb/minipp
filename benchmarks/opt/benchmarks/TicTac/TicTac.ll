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
  %board.a_auf2 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 0
  store i64 0, i64* %board.a_auf2
  %board.b_auf5 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 1
  store i64 0, i64* %board.b_auf5
  %board.c_auf8 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 2
  store i64 0, i64* %board.c_auf8
  %board.d_auf11 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 3
  store i64 0, i64* %board.d_auf11
  %board.e_auf14 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 4
  store i64 0, i64* %board.e_auf14
  %board.f_auf17 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 5
  store i64 0, i64* %board.f_auf17
  %board.g_auf20 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 6
  store i64 0, i64* %board.g_auf20
  %board.h_auf23 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 7
  store i64 0, i64* %board.h_auf23
  %board.i_auf26 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 8
  store i64 0, i64* %board.i_auf26
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
  %_1 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_2 = call i32 (i8*, ...) @printf(i8* %_1, i64 123)
  %_4 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_5 = call i32 (i8*, ...) @printf(i8* %_4, i64 456)
  %_7 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_8 = call i32 (i8*, ...) @printf(i8* %_7, i64 789)
  br label %exit
exit:
  ret void
}

define void @placePiece(%struct.gameBoard* %board, i64 %turn, i64 %placement) {
entry:
  br label %if.cond1
if.cond1:
  %_14 = icmp eq i64 %placement, 1
  br i1 %_14, label %then.body2, label %if.cond5
then.body2:
  %board.a_auf16 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 0
  store i64 %turn, i64* %board.a_auf16
  br label %if.exit52
if.cond5:
  %_22 = icmp eq i64 %placement, 2
  br i1 %_22, label %then.body6, label %if.cond9
then.body6:
  %board.b_auf24 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 1
  store i64 %turn, i64* %board.b_auf24
  br label %if.exit50
if.cond9:
  %_30 = icmp eq i64 %placement, 3
  br i1 %_30, label %then.body10, label %if.cond13
then.body10:
  %board.c_auf32 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 2
  store i64 %turn, i64* %board.c_auf32
  br label %if.exit48
if.cond13:
  %_38 = icmp eq i64 %placement, 4
  br i1 %_38, label %then.body14, label %if.cond17
then.body14:
  %board.d_auf40 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 3
  store i64 %turn, i64* %board.d_auf40
  br label %if.exit46
if.cond17:
  %_46 = icmp eq i64 %placement, 5
  br i1 %_46, label %then.body18, label %if.cond21
then.body18:
  %board.e_auf48 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 4
  store i64 %turn, i64* %board.e_auf48
  br label %if.exit44
if.cond21:
  %_54 = icmp eq i64 %placement, 6
  br i1 %_54, label %then.body22, label %if.cond25
then.body22:
  %board.f_auf56 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 5
  store i64 %turn, i64* %board.f_auf56
  br label %if.exit42
if.cond25:
  %_62 = icmp eq i64 %placement, 7
  br i1 %_62, label %then.body26, label %if.cond29
then.body26:
  %board.g_auf64 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 6
  store i64 %turn, i64* %board.g_auf64
  br label %if.exit40
if.cond29:
  %_70 = icmp eq i64 %placement, 8
  br i1 %_70, label %then.body30, label %if.cond33
then.body30:
  %board.h_auf72 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 7
  store i64 %turn, i64* %board.h_auf72
  br label %if.exit38
if.cond33:
  %_78 = icmp eq i64 %placement, 9
  br i1 %_78, label %then.body34, label %if.exit36
then.body34:
  %board.i_auf80 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 8
  store i64 %turn, i64* %board.i_auf80
  br label %if.exit36
if.exit36:
  br label %if.exit38
if.exit38:
  br label %if.exit40
if.exit40:
  br label %if.exit42
if.exit42:
  br label %if.exit44
if.exit44:
  br label %if.exit46
if.exit46:
  br label %if.exit48
if.exit48:
  br label %if.exit50
if.exit50:
  br label %if.exit52
if.exit52:
  br label %exit
exit:
  ret void
}

define i64 @checkWinner(%struct.gameBoard* %board) {
entry:
  br label %if.cond1
if.cond1:
  %board.a_auf4 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 0
  %_5 = load i64, i64* %board.a_auf4
  %_7 = icmp eq i64 %_5, 1
  br i1 %_7, label %if.cond3, label %if.exit11
if.cond3:
  %board.b_auf10 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 1
  %_11 = load i64, i64* %board.b_auf10
  %_13 = icmp eq i64 %_11, 1
  br i1 %_13, label %if.cond5, label %if.exit9
if.cond5:
  %board.c_auf16 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 2
  %_17 = load i64, i64* %board.c_auf16
  %_19 = icmp eq i64 %_17, 1
  br i1 %_19, label %then.body6, label %if.exit9
then.body6:
  br label %exit
if.exit9:
  br label %if.exit11
if.exit11:
  br label %if.cond12
if.cond12:
  %board.a_auf29 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 0
  %_30 = load i64, i64* %board.a_auf29
  %_32 = icmp eq i64 %_30, 2
  br i1 %_32, label %if.cond14, label %if.exit22
if.cond14:
  %board.b_auf35 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 1
  %_36 = load i64, i64* %board.b_auf35
  %_38 = icmp eq i64 %_36, 2
  br i1 %_38, label %if.cond16, label %if.exit20
if.cond16:
  %board.c_auf41 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 2
  %_42 = load i64, i64* %board.c_auf41
  %_44 = icmp eq i64 %_42, 2
  br i1 %_44, label %then.body17, label %if.exit20
then.body17:
  br label %exit
if.exit20:
  br label %if.exit22
if.exit22:
  br label %if.cond23
if.cond23:
  %board.d_auf53 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 3
  %_54 = load i64, i64* %board.d_auf53
  %_56 = icmp eq i64 %_54, 1
  br i1 %_56, label %if.cond25, label %if.exit33
if.cond25:
  %board.e_auf59 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 4
  %_60 = load i64, i64* %board.e_auf59
  %_62 = icmp eq i64 %_60, 1
  br i1 %_62, label %if.cond27, label %if.exit31
if.cond27:
  %board.f_auf65 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 5
  %_66 = load i64, i64* %board.f_auf65
  %_68 = icmp eq i64 %_66, 1
  br i1 %_68, label %then.body28, label %if.exit31
then.body28:
  br label %exit
if.exit31:
  br label %if.exit33
if.exit33:
  br label %if.cond34
if.cond34:
  %board.d_auf77 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 3
  %_78 = load i64, i64* %board.d_auf77
  %_80 = icmp eq i64 %_78, 2
  br i1 %_80, label %if.cond36, label %if.exit44
if.cond36:
  %board.e_auf83 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 4
  %_84 = load i64, i64* %board.e_auf83
  %_86 = icmp eq i64 %_84, 2
  br i1 %_86, label %if.cond38, label %if.exit42
if.cond38:
  %board.f_auf89 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 5
  %_90 = load i64, i64* %board.f_auf89
  %_92 = icmp eq i64 %_90, 2
  br i1 %_92, label %then.body39, label %if.exit42
then.body39:
  br label %exit
if.exit42:
  br label %if.exit44
if.exit44:
  br label %if.cond45
if.cond45:
  %board.g_auf101 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 6
  %_102 = load i64, i64* %board.g_auf101
  %_104 = icmp eq i64 %_102, 1
  br i1 %_104, label %if.cond47, label %if.exit55
if.cond47:
  %board.h_auf107 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 7
  %_108 = load i64, i64* %board.h_auf107
  %_110 = icmp eq i64 %_108, 1
  br i1 %_110, label %if.cond49, label %if.exit53
if.cond49:
  %board.i_auf113 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 8
  %_114 = load i64, i64* %board.i_auf113
  %_116 = icmp eq i64 %_114, 1
  br i1 %_116, label %then.body50, label %if.exit53
then.body50:
  br label %exit
if.exit53:
  br label %if.exit55
if.exit55:
  br label %if.cond56
if.cond56:
  %board.g_auf125 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 6
  %_126 = load i64, i64* %board.g_auf125
  %_128 = icmp eq i64 %_126, 2
  br i1 %_128, label %if.cond58, label %if.exit66
if.cond58:
  %board.h_auf131 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 7
  %_132 = load i64, i64* %board.h_auf131
  %_134 = icmp eq i64 %_132, 2
  br i1 %_134, label %if.cond60, label %if.exit64
if.cond60:
  %board.i_auf137 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 8
  %_138 = load i64, i64* %board.i_auf137
  %_140 = icmp eq i64 %_138, 2
  br i1 %_140, label %then.body61, label %if.exit64
then.body61:
  br label %exit
if.exit64:
  br label %if.exit66
if.exit66:
  br label %if.cond67
if.cond67:
  %board.a_auf149 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 0
  %_150 = load i64, i64* %board.a_auf149
  %_152 = icmp eq i64 %_150, 1
  br i1 %_152, label %if.cond69, label %if.exit77
if.cond69:
  %board.d_auf155 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 3
  %_156 = load i64, i64* %board.d_auf155
  %_158 = icmp eq i64 %_156, 1
  br i1 %_158, label %if.cond71, label %if.exit75
if.cond71:
  %board.g_auf161 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 6
  %_162 = load i64, i64* %board.g_auf161
  %_164 = icmp eq i64 %_162, 1
  br i1 %_164, label %then.body72, label %if.exit75
then.body72:
  br label %exit
if.exit75:
  br label %if.exit77
if.exit77:
  br label %if.cond78
if.cond78:
  %board.a_auf173 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 0
  %_174 = load i64, i64* %board.a_auf173
  %_176 = icmp eq i64 %_174, 2
  br i1 %_176, label %if.cond80, label %if.exit88
if.cond80:
  %board.d_auf179 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 3
  %_180 = load i64, i64* %board.d_auf179
  %_182 = icmp eq i64 %_180, 2
  br i1 %_182, label %if.cond82, label %if.exit86
if.cond82:
  %board.g_auf185 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 6
  %_186 = load i64, i64* %board.g_auf185
  %_188 = icmp eq i64 %_186, 2
  br i1 %_188, label %then.body83, label %if.exit86
then.body83:
  br label %exit
if.exit86:
  br label %if.exit88
if.exit88:
  br label %if.cond89
if.cond89:
  %board.b_auf197 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 1
  %_198 = load i64, i64* %board.b_auf197
  %_200 = icmp eq i64 %_198, 1
  br i1 %_200, label %if.cond91, label %if.exit99
if.cond91:
  %board.e_auf203 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 4
  %_204 = load i64, i64* %board.e_auf203
  %_206 = icmp eq i64 %_204, 1
  br i1 %_206, label %if.cond93, label %if.exit97
if.cond93:
  %board.h_auf209 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 7
  %_210 = load i64, i64* %board.h_auf209
  %_212 = icmp eq i64 %_210, 1
  br i1 %_212, label %then.body94, label %if.exit97
then.body94:
  br label %exit
if.exit97:
  br label %if.exit99
if.exit99:
  br label %if.cond100
if.cond100:
  %board.b_auf221 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 1
  %_222 = load i64, i64* %board.b_auf221
  %_224 = icmp eq i64 %_222, 2
  br i1 %_224, label %if.cond102, label %if.exit110
if.cond102:
  %board.e_auf227 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 4
  %_228 = load i64, i64* %board.e_auf227
  %_230 = icmp eq i64 %_228, 2
  br i1 %_230, label %if.cond104, label %if.exit108
if.cond104:
  %board.h_auf233 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 7
  %_234 = load i64, i64* %board.h_auf233
  %_236 = icmp eq i64 %_234, 2
  br i1 %_236, label %then.body105, label %if.exit108
then.body105:
  br label %exit
if.exit108:
  br label %if.exit110
if.exit110:
  br label %if.cond111
if.cond111:
  %board.c_auf245 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 2
  %_246 = load i64, i64* %board.c_auf245
  %_248 = icmp eq i64 %_246, 1
  br i1 %_248, label %if.cond113, label %if.exit121
if.cond113:
  %board.f_auf251 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 5
  %_252 = load i64, i64* %board.f_auf251
  %_254 = icmp eq i64 %_252, 1
  br i1 %_254, label %if.cond115, label %if.exit119
if.cond115:
  %board.i_auf257 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 8
  %_258 = load i64, i64* %board.i_auf257
  %_260 = icmp eq i64 %_258, 1
  br i1 %_260, label %then.body116, label %if.exit119
then.body116:
  br label %exit
if.exit119:
  br label %if.exit121
if.exit121:
  br label %if.cond122
if.cond122:
  %board.c_auf269 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 2
  %_270 = load i64, i64* %board.c_auf269
  %_272 = icmp eq i64 %_270, 2
  br i1 %_272, label %if.cond124, label %if.exit132
if.cond124:
  %board.f_auf275 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 5
  %_276 = load i64, i64* %board.f_auf275
  %_278 = icmp eq i64 %_276, 2
  br i1 %_278, label %if.cond126, label %if.exit130
if.cond126:
  %board.i_auf281 = getelementptr %struct.gameBoard, %struct.gameBoard* %board, i1 0, i32 8
  %_282 = load i64, i64* %board.i_auf281
  %_284 = icmp eq i64 %_282, 2
  br i1 %_284, label %then.body127, label %if.exit130
then.body127:
  br label %exit
if.exit130:
  br label %if.exit132
if.exit132:
  br label %exit
exit:
  %return_reg22 = phi i64 [ 0, %then.body6 ], [ 1, %then.body17 ], [ 0, %then.body28 ], [ 1, %then.body39 ], [ 0, %then.body50 ], [ 1, %then.body61 ], [ 0, %then.body72 ], [ 1, %then.body83 ], [ 0, %then.body94 ], [ 1, %then.body105 ], [ 0, %then.body116 ], [ 1, %then.body127 ], [ -1, %if.exit132 ]
  ret i64 %return_reg22
}

define i64 @main() {
entry:
  br label %body0
body0:
  %gameBoard.malloc23 = call i8* (i32) @malloc(i32 72)
  %board24 = bitcast i8* %gameBoard.malloc23 to %struct.gameBoard*
  call void (%struct.gameBoard*) @cleanBoard(%struct.gameBoard* %board24)
  br label %while.cond11
while.cond11:
  br label %while.body2
while.body2:
  %board6 = phi %struct.gameBoard* [ %board24, %while.cond11 ], [ %board6, %while.fillback10 ]
  %i8 = phi i64 [ 0, %while.cond11 ], [ %i60, %while.fillback10 ]
  %turn14 = phi i64 [ 0, %while.cond11 ], [ %turn12, %while.fillback10 ]
  call void (%struct.gameBoard*) @printBoard(%struct.gameBoard* %board6)
  br label %if.cond3
if.cond3:
  %_36 = icmp eq i64 %turn14, 0
  br i1 %_36, label %then.body4, label %else.body6
then.body4:
  %turn39 = add i64 %turn14, 1
  %_40 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_41 = call i32 (i8*, ...) @scanf(i8* %_40, i32* @.read_scratch)
  %_42 = load i32, i32* @.read_scratch
  %space143 = sext i32 %_42 to i64
  call void (%struct.gameBoard*, i64, i64) @placePiece(%struct.gameBoard* %board6, i64 1, i64 %space143)
  br label %then.exit5
then.exit5:
  br label %if.exit8
else.body6:
  %turn49 = sub i64 %turn14, 1
  %_50 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_51 = call i32 (i8*, ...) @scanf(i8* %_50, i32* @.read_scratch)
  %_52 = load i32, i32* @.read_scratch
  %space253 = sext i32 %_52 to i64
  call void (%struct.gameBoard*, i64, i64) @placePiece(%struct.gameBoard* %board6, i64 2, i64 %space253)
  br label %else.exit7
else.exit7:
  br label %if.exit8
if.exit8:
  %turn12 = phi i64 [ %turn39, %then.exit5 ], [ %turn49, %else.exit7 ]
  %winner58 = call i64 (%struct.gameBoard*) @checkWinner(%struct.gameBoard* %board6)
  %i60 = add i64 %i8, 1
  br label %while.cond29
while.cond29:
  %tmp.binop63 = icmp slt i64 %winner58, 0
  %tmp.binop65 = icmp ne i64 %i60, 8
  %_66 = and i1 %tmp.binop63, %tmp.binop65
  br i1 %_66, label %while.fillback10, label %while.exit11
while.fillback10:
  br label %while.body2
while.exit11:
  %tmp.binop70 = add i64 %winner58, 1
  %_71 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_72 = call i32 (i8*, ...) @printf(i8* %_71, i64 %tmp.binop70)
  br label %exit
exit:
  ret i64 0
}

