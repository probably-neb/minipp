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
  %board0 = alloca %struct.gameBoard*
  store %struct.gameBoard* %board, %struct.gameBoard** %board0
  br label %body1
body1:
  %board3 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %a4 = getelementptr %struct.gameBoard, %struct.gameBoard* %board3, i1 0, i32 0
  store i64 0, i64* %a4
  %board6 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %b7 = getelementptr %struct.gameBoard, %struct.gameBoard* %board6, i1 0, i32 1
  store i64 0, i64* %b7
  %board9 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %c10 = getelementptr %struct.gameBoard, %struct.gameBoard* %board9, i1 0, i32 2
  store i64 0, i64* %c10
  %board12 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %d13 = getelementptr %struct.gameBoard, %struct.gameBoard* %board12, i1 0, i32 3
  store i64 0, i64* %d13
  %board15 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %e16 = getelementptr %struct.gameBoard, %struct.gameBoard* %board15, i1 0, i32 4
  store i64 0, i64* %e16
  %board18 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %f19 = getelementptr %struct.gameBoard, %struct.gameBoard* %board18, i1 0, i32 5
  store i64 0, i64* %f19
  %board21 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %g22 = getelementptr %struct.gameBoard, %struct.gameBoard* %board21, i1 0, i32 6
  store i64 0, i64* %g22
  %board24 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %h25 = getelementptr %struct.gameBoard, %struct.gameBoard* %board24, i1 0, i32 7
  store i64 0, i64* %h25
  %board27 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %i28 = getelementptr %struct.gameBoard, %struct.gameBoard* %board27, i1 0, i32 8
  store i64 0, i64* %i28
  br label %exit
exit:
  ret void
}

define void @printBoard(%struct.gameBoard* %board) {
entry:
  %board0 = alloca %struct.gameBoard*
  store %struct.gameBoard* %board, %struct.gameBoard** %board0
  br label %body1
body1:
  %board3 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %a4 = getelementptr %struct.gameBoard, %struct.gameBoard* %board3, i1 0, i32 0
  %a5 = load i64, i64* %a4
  %_6 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_7 = call i32 (i8*, ...) @printf(i8* %_6, i64 %a5)
  %board8 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %b9 = getelementptr %struct.gameBoard, %struct.gameBoard* %board8, i1 0, i32 1
  %b10 = load i64, i64* %b9
  %_11 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_12 = call i32 (i8*, ...) @printf(i8* %_11, i64 %b10)
  %board13 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %c14 = getelementptr %struct.gameBoard, %struct.gameBoard* %board13, i1 0, i32 2
  %c15 = load i64, i64* %c14
  %_16 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_17 = call i32 (i8*, ...) @printf(i8* %_16, i64 %c15)
  %board18 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %d19 = getelementptr %struct.gameBoard, %struct.gameBoard* %board18, i1 0, i32 3
  %d20 = load i64, i64* %d19
  %_21 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_22 = call i32 (i8*, ...) @printf(i8* %_21, i64 %d20)
  %board23 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %e24 = getelementptr %struct.gameBoard, %struct.gameBoard* %board23, i1 0, i32 4
  %e25 = load i64, i64* %e24
  %_26 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_27 = call i32 (i8*, ...) @printf(i8* %_26, i64 %e25)
  %board28 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %f29 = getelementptr %struct.gameBoard, %struct.gameBoard* %board28, i1 0, i32 5
  %f30 = load i64, i64* %f29
  %_31 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_32 = call i32 (i8*, ...) @printf(i8* %_31, i64 %f30)
  %board33 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %g34 = getelementptr %struct.gameBoard, %struct.gameBoard* %board33, i1 0, i32 6
  %g35 = load i64, i64* %g34
  %_36 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_37 = call i32 (i8*, ...) @printf(i8* %_36, i64 %g35)
  %board38 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %h39 = getelementptr %struct.gameBoard, %struct.gameBoard* %board38, i1 0, i32 7
  %h40 = load i64, i64* %h39
  %_41 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_42 = call i32 (i8*, ...) @printf(i8* %_41, i64 %h40)
  %board43 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %i44 = getelementptr %struct.gameBoard, %struct.gameBoard* %board43, i1 0, i32 8
  %i45 = load i64, i64* %i44
  %_46 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_47 = call i32 (i8*, ...) @printf(i8* %_46, i64 %i45)
  br label %exit
exit:
  ret void
}

define void @printMoveBoard() {
entry:
  br label %body1
body1:
  %_1 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_2 = call i32 (i8*, ...) @printf(i8* %_1, i64 123)
  %_3 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_4 = call i32 (i8*, ...) @printf(i8* %_3, i64 456)
  %_5 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_6 = call i32 (i8*, ...) @printf(i8* %_5, i64 789)
  br label %exit
exit:
  ret void
}

define void @placePiece(%struct.gameBoard* %board, i64 %turn, i64 %placement) {
entry:
  %board0 = alloca %struct.gameBoard*
  store %struct.gameBoard* %board, %struct.gameBoard** %board0
  %turn2 = alloca i64
  store i64 %turn, i64* %turn2
  %placement4 = alloca i64
  store i64 %placement, i64* %placement4
  br label %body1
body1:
  %placement7 = load i64, i64* %placement4
  %placement8 = icmp eq i64 %placement7, 1
  br i1 %placement8, label %if.then2, label %if.else3
if.then2:
  %board9 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %a10 = getelementptr %struct.gameBoard, %struct.gameBoard* %board9, i1 0, i32 0
  %turn11 = load i64, i64* %turn2
  store i64 %turn11, i64* %a10
  br label %if.end27
if.else3:
  %placement13 = load i64, i64* %placement4
  %placement14 = icmp eq i64 %placement13, 2
  br i1 %placement14, label %if.then4, label %if.else5
if.then4:
  %board15 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %b16 = getelementptr %struct.gameBoard, %struct.gameBoard* %board15, i1 0, i32 1
  %turn17 = load i64, i64* %turn2
  store i64 %turn17, i64* %b16
  br label %if.end26
if.else5:
  %placement19 = load i64, i64* %placement4
  %placement20 = icmp eq i64 %placement19, 3
  br i1 %placement20, label %if.then6, label %if.else7
if.then6:
  %board21 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %c22 = getelementptr %struct.gameBoard, %struct.gameBoard* %board21, i1 0, i32 2
  %turn23 = load i64, i64* %turn2
  store i64 %turn23, i64* %c22
  br label %if.end25
if.else7:
  %placement25 = load i64, i64* %placement4
  %placement26 = icmp eq i64 %placement25, 4
  br i1 %placement26, label %if.then8, label %if.else9
if.then8:
  %board27 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %d28 = getelementptr %struct.gameBoard, %struct.gameBoard* %board27, i1 0, i32 3
  %turn29 = load i64, i64* %turn2
  store i64 %turn29, i64* %d28
  br label %if.end24
if.else9:
  %placement31 = load i64, i64* %placement4
  %placement32 = icmp eq i64 %placement31, 5
  br i1 %placement32, label %if.then10, label %if.else11
if.then10:
  %board33 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %e34 = getelementptr %struct.gameBoard, %struct.gameBoard* %board33, i1 0, i32 4
  %turn35 = load i64, i64* %turn2
  store i64 %turn35, i64* %e34
  br label %if.end23
if.else11:
  %placement37 = load i64, i64* %placement4
  %placement38 = icmp eq i64 %placement37, 6
  br i1 %placement38, label %if.then12, label %if.else13
if.then12:
  %board39 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %f40 = getelementptr %struct.gameBoard, %struct.gameBoard* %board39, i1 0, i32 5
  %turn41 = load i64, i64* %turn2
  store i64 %turn41, i64* %f40
  br label %if.end22
if.else13:
  %placement43 = load i64, i64* %placement4
  %placement44 = icmp eq i64 %placement43, 7
  br i1 %placement44, label %if.then14, label %if.else15
if.then14:
  %board45 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %g46 = getelementptr %struct.gameBoard, %struct.gameBoard* %board45, i1 0, i32 6
  %turn47 = load i64, i64* %turn2
  store i64 %turn47, i64* %g46
  br label %if.end21
if.else15:
  %placement49 = load i64, i64* %placement4
  %placement50 = icmp eq i64 %placement49, 8
  br i1 %placement50, label %if.then16, label %if.else17
if.then16:
  %board51 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %h52 = getelementptr %struct.gameBoard, %struct.gameBoard* %board51, i1 0, i32 7
  %turn53 = load i64, i64* %turn2
  store i64 %turn53, i64* %h52
  br label %if.end20
if.else17:
  %placement55 = load i64, i64* %placement4
  %placement56 = icmp eq i64 %placement55, 9
  br i1 %placement56, label %if.then18, label %if.end19
if.then18:
  %board57 = load %struct.gameBoard*, %struct.gameBoard** %board0
  %i58 = getelementptr %struct.gameBoard, %struct.gameBoard* %board57, i1 0, i32 8
  %turn59 = load i64, i64* %turn2
  store i64 %turn59, i64* %i58
  br label %if.end19
if.end19:
  br label %if.end20
if.end20:
  br label %if.end21
if.end21:
  br label %if.end22
if.end22:
  br label %if.end23
if.end23:
  br label %if.end24
if.end24:
  br label %if.end25
if.end25:
  br label %if.end26
if.end26:
  br label %if.end27
if.end27:
  br label %exit
exit:
  ret void
}

define i64 @checkWinner(%struct.gameBoard* %board) {
entry:
  %_0 = alloca i64
  %board1 = alloca %struct.gameBoard*
  store %struct.gameBoard* %board, %struct.gameBoard** %board1
  br label %body1
body1:
  %board4 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %a5 = getelementptr %struct.gameBoard, %struct.gameBoard* %board4, i1 0, i32 0
  %a6 = load i64, i64* %a5
  %a7 = icmp eq i64 %a6, 1
  br i1 %a7, label %if.then2, label %if.end7
if.then2:
  %board8 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %b9 = getelementptr %struct.gameBoard, %struct.gameBoard* %board8, i1 0, i32 1
  %b10 = load i64, i64* %b9
  %b11 = icmp eq i64 %b10, 1
  br i1 %b11, label %if.then3, label %if.end6
if.then3:
  %board12 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %c13 = getelementptr %struct.gameBoard, %struct.gameBoard* %board12, i1 0, i32 2
  %c14 = load i64, i64* %c13
  %c15 = icmp eq i64 %c14, 1
  br i1 %c15, label %if.then4, label %if.end5
if.then4:
  store i64 0, i64* %_0
  br label %exit
if.end5:
  br label %if.end6
if.end6:
  br label %if.end7
if.end7:
  %board23 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %a24 = getelementptr %struct.gameBoard, %struct.gameBoard* %board23, i1 0, i32 0
  %a25 = load i64, i64* %a24
  %a26 = icmp eq i64 %a25, 2
  br i1 %a26, label %if.then8, label %if.end13
if.then8:
  %board27 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %b28 = getelementptr %struct.gameBoard, %struct.gameBoard* %board27, i1 0, i32 1
  %b29 = load i64, i64* %b28
  %b30 = icmp eq i64 %b29, 2
  br i1 %b30, label %if.then9, label %if.end12
if.then9:
  %board31 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %c32 = getelementptr %struct.gameBoard, %struct.gameBoard* %board31, i1 0, i32 2
  %c33 = load i64, i64* %c32
  %c34 = icmp eq i64 %c33, 2
  br i1 %c34, label %if.then10, label %if.end11
if.then10:
  store i64 1, i64* %_0
  br label %exit
if.end11:
  br label %if.end12
if.end12:
  br label %if.end13
if.end13:
  %board42 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %d43 = getelementptr %struct.gameBoard, %struct.gameBoard* %board42, i1 0, i32 3
  %d44 = load i64, i64* %d43
  %d45 = icmp eq i64 %d44, 1
  br i1 %d45, label %if.then14, label %if.end19
if.then14:
  %board46 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %e47 = getelementptr %struct.gameBoard, %struct.gameBoard* %board46, i1 0, i32 4
  %e48 = load i64, i64* %e47
  %e49 = icmp eq i64 %e48, 1
  br i1 %e49, label %if.then15, label %if.end18
if.then15:
  %board50 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %f51 = getelementptr %struct.gameBoard, %struct.gameBoard* %board50, i1 0, i32 5
  %f52 = load i64, i64* %f51
  %f53 = icmp eq i64 %f52, 1
  br i1 %f53, label %if.then16, label %if.end17
if.then16:
  store i64 0, i64* %_0
  br label %exit
if.end17:
  br label %if.end18
if.end18:
  br label %if.end19
if.end19:
  %board61 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %d62 = getelementptr %struct.gameBoard, %struct.gameBoard* %board61, i1 0, i32 3
  %d63 = load i64, i64* %d62
  %d64 = icmp eq i64 %d63, 2
  br i1 %d64, label %if.then20, label %if.end25
if.then20:
  %board65 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %e66 = getelementptr %struct.gameBoard, %struct.gameBoard* %board65, i1 0, i32 4
  %e67 = load i64, i64* %e66
  %e68 = icmp eq i64 %e67, 2
  br i1 %e68, label %if.then21, label %if.end24
if.then21:
  %board69 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %f70 = getelementptr %struct.gameBoard, %struct.gameBoard* %board69, i1 0, i32 5
  %f71 = load i64, i64* %f70
  %f72 = icmp eq i64 %f71, 2
  br i1 %f72, label %if.then22, label %if.end23
if.then22:
  store i64 1, i64* %_0
  br label %exit
if.end23:
  br label %if.end24
if.end24:
  br label %if.end25
if.end25:
  %board80 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %g81 = getelementptr %struct.gameBoard, %struct.gameBoard* %board80, i1 0, i32 6
  %g82 = load i64, i64* %g81
  %g83 = icmp eq i64 %g82, 1
  br i1 %g83, label %if.then26, label %if.end31
if.then26:
  %board84 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %h85 = getelementptr %struct.gameBoard, %struct.gameBoard* %board84, i1 0, i32 7
  %h86 = load i64, i64* %h85
  %h87 = icmp eq i64 %h86, 1
  br i1 %h87, label %if.then27, label %if.end30
if.then27:
  %board88 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %i89 = getelementptr %struct.gameBoard, %struct.gameBoard* %board88, i1 0, i32 8
  %i90 = load i64, i64* %i89
  %i91 = icmp eq i64 %i90, 1
  br i1 %i91, label %if.then28, label %if.end29
if.then28:
  store i64 0, i64* %_0
  br label %exit
if.end29:
  br label %if.end30
if.end30:
  br label %if.end31
if.end31:
  %board99 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %g100 = getelementptr %struct.gameBoard, %struct.gameBoard* %board99, i1 0, i32 6
  %g101 = load i64, i64* %g100
  %g102 = icmp eq i64 %g101, 2
  br i1 %g102, label %if.then32, label %if.end37
if.then32:
  %board103 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %h104 = getelementptr %struct.gameBoard, %struct.gameBoard* %board103, i1 0, i32 7
  %h105 = load i64, i64* %h104
  %h106 = icmp eq i64 %h105, 2
  br i1 %h106, label %if.then33, label %if.end36
if.then33:
  %board107 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %i108 = getelementptr %struct.gameBoard, %struct.gameBoard* %board107, i1 0, i32 8
  %i109 = load i64, i64* %i108
  %i110 = icmp eq i64 %i109, 2
  br i1 %i110, label %if.then34, label %if.end35
if.then34:
  store i64 1, i64* %_0
  br label %exit
if.end35:
  br label %if.end36
if.end36:
  br label %if.end37
if.end37:
  %board118 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %a119 = getelementptr %struct.gameBoard, %struct.gameBoard* %board118, i1 0, i32 0
  %a120 = load i64, i64* %a119
  %a121 = icmp eq i64 %a120, 1
  br i1 %a121, label %if.then38, label %if.end43
if.then38:
  %board122 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %d123 = getelementptr %struct.gameBoard, %struct.gameBoard* %board122, i1 0, i32 3
  %d124 = load i64, i64* %d123
  %d125 = icmp eq i64 %d124, 1
  br i1 %d125, label %if.then39, label %if.end42
if.then39:
  %board126 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %g127 = getelementptr %struct.gameBoard, %struct.gameBoard* %board126, i1 0, i32 6
  %g128 = load i64, i64* %g127
  %g129 = icmp eq i64 %g128, 1
  br i1 %g129, label %if.then40, label %if.end41
if.then40:
  store i64 0, i64* %_0
  br label %exit
if.end41:
  br label %if.end42
if.end42:
  br label %if.end43
if.end43:
  %board137 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %a138 = getelementptr %struct.gameBoard, %struct.gameBoard* %board137, i1 0, i32 0
  %a139 = load i64, i64* %a138
  %a140 = icmp eq i64 %a139, 2
  br i1 %a140, label %if.then44, label %if.end49
if.then44:
  %board141 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %d142 = getelementptr %struct.gameBoard, %struct.gameBoard* %board141, i1 0, i32 3
  %d143 = load i64, i64* %d142
  %d144 = icmp eq i64 %d143, 2
  br i1 %d144, label %if.then45, label %if.end48
if.then45:
  %board145 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %g146 = getelementptr %struct.gameBoard, %struct.gameBoard* %board145, i1 0, i32 6
  %g147 = load i64, i64* %g146
  %g148 = icmp eq i64 %g147, 2
  br i1 %g148, label %if.then46, label %if.end47
if.then46:
  store i64 1, i64* %_0
  br label %exit
if.end47:
  br label %if.end48
if.end48:
  br label %if.end49
if.end49:
  %board156 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %b157 = getelementptr %struct.gameBoard, %struct.gameBoard* %board156, i1 0, i32 1
  %b158 = load i64, i64* %b157
  %b159 = icmp eq i64 %b158, 1
  br i1 %b159, label %if.then50, label %if.end55
if.then50:
  %board160 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %e161 = getelementptr %struct.gameBoard, %struct.gameBoard* %board160, i1 0, i32 4
  %e162 = load i64, i64* %e161
  %e163 = icmp eq i64 %e162, 1
  br i1 %e163, label %if.then51, label %if.end54
if.then51:
  %board164 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %h165 = getelementptr %struct.gameBoard, %struct.gameBoard* %board164, i1 0, i32 7
  %h166 = load i64, i64* %h165
  %h167 = icmp eq i64 %h166, 1
  br i1 %h167, label %if.then52, label %if.end53
if.then52:
  store i64 0, i64* %_0
  br label %exit
if.end53:
  br label %if.end54
if.end54:
  br label %if.end55
if.end55:
  %board175 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %b176 = getelementptr %struct.gameBoard, %struct.gameBoard* %board175, i1 0, i32 1
  %b177 = load i64, i64* %b176
  %b178 = icmp eq i64 %b177, 2
  br i1 %b178, label %if.then56, label %if.end61
if.then56:
  %board179 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %e180 = getelementptr %struct.gameBoard, %struct.gameBoard* %board179, i1 0, i32 4
  %e181 = load i64, i64* %e180
  %e182 = icmp eq i64 %e181, 2
  br i1 %e182, label %if.then57, label %if.end60
if.then57:
  %board183 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %h184 = getelementptr %struct.gameBoard, %struct.gameBoard* %board183, i1 0, i32 7
  %h185 = load i64, i64* %h184
  %h186 = icmp eq i64 %h185, 2
  br i1 %h186, label %if.then58, label %if.end59
if.then58:
  store i64 1, i64* %_0
  br label %exit
if.end59:
  br label %if.end60
if.end60:
  br label %if.end61
if.end61:
  %board194 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %c195 = getelementptr %struct.gameBoard, %struct.gameBoard* %board194, i1 0, i32 2
  %c196 = load i64, i64* %c195
  %c197 = icmp eq i64 %c196, 1
  br i1 %c197, label %if.then62, label %if.end67
if.then62:
  %board198 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %f199 = getelementptr %struct.gameBoard, %struct.gameBoard* %board198, i1 0, i32 5
  %f200 = load i64, i64* %f199
  %f201 = icmp eq i64 %f200, 1
  br i1 %f201, label %if.then63, label %if.end66
if.then63:
  %board202 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %i203 = getelementptr %struct.gameBoard, %struct.gameBoard* %board202, i1 0, i32 8
  %i204 = load i64, i64* %i203
  %i205 = icmp eq i64 %i204, 1
  br i1 %i205, label %if.then64, label %if.end65
if.then64:
  store i64 0, i64* %_0
  br label %exit
if.end65:
  br label %if.end66
if.end66:
  br label %if.end67
if.end67:
  %board213 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %c214 = getelementptr %struct.gameBoard, %struct.gameBoard* %board213, i1 0, i32 2
  %c215 = load i64, i64* %c214
  %c216 = icmp eq i64 %c215, 2
  br i1 %c216, label %if.then68, label %if.end73
if.then68:
  %board217 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %f218 = getelementptr %struct.gameBoard, %struct.gameBoard* %board217, i1 0, i32 5
  %f219 = load i64, i64* %f218
  %f220 = icmp eq i64 %f219, 2
  br i1 %f220, label %if.then69, label %if.end72
if.then69:
  %board221 = load %struct.gameBoard*, %struct.gameBoard** %board1
  %i222 = getelementptr %struct.gameBoard, %struct.gameBoard* %board221, i1 0, i32 8
  %i223 = load i64, i64* %i222
  %i224 = icmp eq i64 %i223, 2
  br i1 %i224, label %if.then70, label %if.end71
if.then70:
  store i64 1, i64* %_0
  br label %exit
if.end71:
  br label %if.end72
if.end72:
  br label %if.end73
if.end73:
  %_232 = sub i64 0, 1
  store i64 %_232, i64* %_0
  br label %exit
exit:
  %_235 = load i64, i64* %_0
  ret i64 %_235
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %turn1 = alloca i64
  %space12 = alloca i64
  %space23 = alloca i64
  %winner4 = alloca i64
  %i5 = alloca i64
  %board6 = alloca %struct.gameBoard*
  br label %body1
body1:
  store i64 0, i64* %i5
  store i64 0, i64* %turn1
  store i64 0, i64* %space12
  store i64 0, i64* %space23
  %_12 = sub i64 0, 1
  store i64 %_12, i64* %winner4
  %gameBoard14 = call i8* (i32) @malloc(i32 72)
  %gameBoard15 = bitcast i8* %gameBoard14 to %struct.gameBoard*
  store %struct.gameBoard* %gameBoard15, %struct.gameBoard** %board6
  %board17 = load %struct.gameBoard*, %struct.gameBoard** %board6
  call void (%struct.gameBoard*) @cleanBoard(%struct.gameBoard* %board17)
  %winner19 = load i64, i64* %winner4
  %winner20 = icmp slt i64 %winner19, 0
  %i21 = load i64, i64* %i5
  %i22 = icmp ne i64 %i21, 8
  %_23 = and i1 %winner20, %i22
  br i1 %_23, label %while.body2, label %while.end6
while.body2:
  %board24 = load %struct.gameBoard*, %struct.gameBoard** %board6
  call void (%struct.gameBoard*) @printBoard(%struct.gameBoard* %board24)
  %turn26 = load i64, i64* %turn1
  %turn27 = icmp eq i64 %turn26, 0
  br i1 %turn27, label %if.then3, label %if.else4
if.then3:
  %turn28 = load i64, i64* %turn1
  %turn29 = add i64 %turn28, 1
  store i64 %turn29, i64* %turn1
  %_31 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_32 = call i32 (i8*, ...) @scanf(i8* %_31, i32* @.read_scratch)
  %_33 = load i32, i32* @.read_scratch
  %_34 = sext i32 %_33 to i64
  store i64 %_34, i64* %space12
  %board36 = load %struct.gameBoard*, %struct.gameBoard** %board6
  %space137 = load i64, i64* %space12
  call void (%struct.gameBoard*, i64, i64) @placePiece(%struct.gameBoard* %board36, i64 1, i64 %space137)
  br label %if.end5
if.else4:
  %turn39 = load i64, i64* %turn1
  %turn40 = sub i64 %turn39, 1
  store i64 %turn40, i64* %turn1
  %_42 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_43 = call i32 (i8*, ...) @scanf(i8* %_42, i32* @.read_scratch)
  %_44 = load i32, i32* @.read_scratch
  %_45 = sext i32 %_44 to i64
  store i64 %_45, i64* %space23
  %board47 = load %struct.gameBoard*, %struct.gameBoard** %board6
  %space248 = load i64, i64* %space23
  call void (%struct.gameBoard*, i64, i64) @placePiece(%struct.gameBoard* %board47, i64 2, i64 %space248)
  br label %if.end5
if.end5:
  %board53 = load %struct.gameBoard*, %struct.gameBoard** %board6
  %checkWinner54 = call i64 (%struct.gameBoard*) @checkWinner(%struct.gameBoard* %board53)
  store i64 %checkWinner54, i64* %winner4
  %i56 = load i64, i64* %i5
  %i57 = add i64 %i56, 1
  store i64 %i57, i64* %i5
  %winner59 = load i64, i64* %winner4
  %winner60 = icmp slt i64 %winner59, 0
  %i61 = load i64, i64* %i5
  %i62 = icmp ne i64 %i61, 8
  %_63 = and i1 %winner60, %i62
  br i1 %_63, label %while.body2, label %while.end6
while.end6:
  %winner66 = load i64, i64* %winner4
  %winner67 = add i64 %winner66, 1
  %_68 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_69 = call i32 (i8*, ...) @printf(i8* %_68, i64 %winner67)
  store i64 0, i64* %_0
  br label %exit
exit:
  %_72 = load i64, i64* %_0
  ret i64 %_72
}

