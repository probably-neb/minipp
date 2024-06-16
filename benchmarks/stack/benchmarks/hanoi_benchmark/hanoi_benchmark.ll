%struct.plate = type { i64, %struct.plate* }

declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

@peg1 = global %struct.plate* undef, align 8
@peg2 = global %struct.plate* undef, align 8
@peg3 = global %struct.plate* undef, align 8
@numMoves = global i64 undef, align 8

define void @move(i64 %from, i64 %to) {
entry:
  %plateToMove0 = alloca %struct.plate*
  %from1 = alloca i64
  store i64 %from, i64* %from1
  %to3 = alloca i64
  store i64 %to, i64* %to3
  br label %body1
body1:
  %from6 = load i64, i64* %from1
  %from7 = icmp eq i64 %from6, 1
  br i1 %from7, label %if.then2, label %if.else3
if.then2:
  %peg18 = load %struct.plate*, %struct.plate** @peg1
  store %struct.plate* %peg18, %struct.plate** %plateToMove0
  %peg110 = load %struct.plate*, %struct.plate** @peg1
  %plateUnder11 = getelementptr %struct.plate, %struct.plate* %peg110, i1 0, i32 1
  %plateUnder12 = load %struct.plate*, %struct.plate** %plateUnder11
  store %struct.plate* %plateUnder12, %struct.plate** @peg1
  br label %if.end7
if.else3:
  %from14 = load i64, i64* %from1
  %from15 = icmp eq i64 %from14, 2
  br i1 %from15, label %if.then4, label %if.else5
if.then4:
  %peg216 = load %struct.plate*, %struct.plate** @peg2
  store %struct.plate* %peg216, %struct.plate** %plateToMove0
  %peg218 = load %struct.plate*, %struct.plate** @peg2
  %plateUnder19 = getelementptr %struct.plate, %struct.plate* %peg218, i1 0, i32 1
  %plateUnder20 = load %struct.plate*, %struct.plate** %plateUnder19
  store %struct.plate* %plateUnder20, %struct.plate** @peg2
  br label %if.end6
if.else5:
  %peg322 = load %struct.plate*, %struct.plate** @peg3
  store %struct.plate* %peg322, %struct.plate** %plateToMove0
  %peg324 = load %struct.plate*, %struct.plate** @peg3
  %plateUnder25 = getelementptr %struct.plate, %struct.plate* %peg324, i1 0, i32 1
  %plateUnder26 = load %struct.plate*, %struct.plate** %plateUnder25
  store %struct.plate* %plateUnder26, %struct.plate** @peg3
  br label %if.end6
if.end6:
  br label %if.end7
if.end7:
  %to34 = load i64, i64* %to3
  %to35 = icmp eq i64 %to34, 1
  br i1 %to35, label %if.then8, label %if.else9
if.then8:
  %plateToMove36 = load %struct.plate*, %struct.plate** %plateToMove0
  %plateUnder37 = getelementptr %struct.plate, %struct.plate* %plateToMove36, i1 0, i32 1
  %peg138 = load %struct.plate*, %struct.plate** @peg1
  store %struct.plate* %peg138, %struct.plate** %plateUnder37
  %plateToMove40 = load %struct.plate*, %struct.plate** %plateToMove0
  store %struct.plate* %plateToMove40, %struct.plate** @peg1
  br label %if.end13
if.else9:
  %to42 = load i64, i64* %to3
  %to43 = icmp eq i64 %to42, 2
  br i1 %to43, label %if.then10, label %if.else11
if.then10:
  %plateToMove44 = load %struct.plate*, %struct.plate** %plateToMove0
  %plateUnder45 = getelementptr %struct.plate, %struct.plate* %plateToMove44, i1 0, i32 1
  %peg246 = load %struct.plate*, %struct.plate** @peg2
  store %struct.plate* %peg246, %struct.plate** %plateUnder45
  %plateToMove48 = load %struct.plate*, %struct.plate** %plateToMove0
  store %struct.plate* %plateToMove48, %struct.plate** @peg2
  br label %if.end12
if.else11:
  %plateToMove50 = load %struct.plate*, %struct.plate** %plateToMove0
  %plateUnder51 = getelementptr %struct.plate, %struct.plate* %plateToMove50, i1 0, i32 1
  %peg352 = load %struct.plate*, %struct.plate** @peg3
  store %struct.plate* %peg352, %struct.plate** %plateUnder51
  %plateToMove54 = load %struct.plate*, %struct.plate** %plateToMove0
  store %struct.plate* %plateToMove54, %struct.plate** @peg3
  br label %if.end12
if.end12:
  br label %if.end13
if.end13:
  %numMoves62 = load i64, i64* @numMoves
  %numMoves63 = add i64 %numMoves62, 1
  store i64 %numMoves63, i64* @numMoves
  br label %exit
exit:
  ret void
}

define void @hanoi(i64 %n, i64 %from, i64 %to, i64 %other) {
entry:
  %n0 = alloca i64
  store i64 %n, i64* %n0
  %from2 = alloca i64
  store i64 %from, i64* %from2
  %to4 = alloca i64
  store i64 %to, i64* %to4
  %other6 = alloca i64
  store i64 %other, i64* %other6
  br label %body1
body1:
  %n9 = load i64, i64* %n0
  %n10 = icmp eq i64 %n9, 1
  br i1 %n10, label %if.then2, label %if.else3
if.then2:
  %from11 = load i64, i64* %from2
  %to12 = load i64, i64* %to4
  call void (i64, i64) @move(i64 %from11, i64 %to12)
  br label %if.end4
if.else3:
  %n14 = load i64, i64* %n0
  %n15 = sub i64 %n14, 1
  %from16 = load i64, i64* %from2
  %other17 = load i64, i64* %other6
  %to18 = load i64, i64* %to4
  call void (i64, i64, i64, i64) @hanoi(i64 %n15, i64 %from16, i64 %other17, i64 %to18)
  %from20 = load i64, i64* %from2
  %to21 = load i64, i64* %to4
  call void (i64, i64) @move(i64 %from20, i64 %to21)
  %n23 = load i64, i64* %n0
  %n24 = sub i64 %n23, 1
  %other25 = load i64, i64* %other6
  %to26 = load i64, i64* %to4
  %from27 = load i64, i64* %from2
  call void (i64, i64, i64, i64) @hanoi(i64 %n24, i64 %other25, i64 %to26, i64 %from27)
  br label %if.end4
if.end4:
  br label %exit
exit:
  ret void
}

define void @printPeg(%struct.plate* %peg) {
entry:
  %aPlate0 = alloca %struct.plate*
  %peg1 = alloca %struct.plate*
  store %struct.plate* %peg, %struct.plate** %peg1
  br label %body1
body1:
  %peg4 = load %struct.plate*, %struct.plate** %peg1
  store %struct.plate* %peg4, %struct.plate** %aPlate0
  %aPlate6 = load %struct.plate*, %struct.plate** %aPlate0
  %aPlate7 = icmp ne %struct.plate* %aPlate6, null
  br i1 %aPlate7, label %while.body2, label %while.end3
while.body2:
  %aPlate8 = load %struct.plate*, %struct.plate** %aPlate0
  %size9 = getelementptr %struct.plate, %struct.plate* %aPlate8, i1 0, i32 0
  %size10 = load i64, i64* %size9
  %_11 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_12 = call i32 (i8*, ...) @printf(i8* %_11, i64 %size10)
  %aPlate13 = load %struct.plate*, %struct.plate** %aPlate0
  %plateUnder14 = getelementptr %struct.plate, %struct.plate* %aPlate13, i1 0, i32 1
  %plateUnder15 = load %struct.plate*, %struct.plate** %plateUnder14
  store %struct.plate* %plateUnder15, %struct.plate** %aPlate0
  %aPlate17 = load %struct.plate*, %struct.plate** %aPlate0
  %aPlate18 = icmp ne %struct.plate* %aPlate17, null
  br i1 %aPlate18, label %while.body2, label %while.end3
while.end3:
  br label %exit
exit:
  ret void
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %count1 = alloca i64
  %numPlates2 = alloca i64
  %aPlate3 = alloca %struct.plate*
  br label %body1
body1:
  store %struct.plate* null, %struct.plate** @peg1
  store %struct.plate* null, %struct.plate** @peg2
  store %struct.plate* null, %struct.plate** @peg3
  store i64 0, i64* @numMoves
  %_9 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_10 = call i32 (i8*, ...) @scanf(i8* %_9, i32* @.read_scratch)
  %_11 = load i32, i32* @.read_scratch
  %_12 = sext i32 %_11 to i64
  store i64 %_12, i64* %numPlates2
  %numPlates14 = load i64, i64* %numPlates2
  %numPlates15 = icmp sge i64 %numPlates14, 1
  br i1 %numPlates15, label %if.then2, label %if.end7
if.then2:
  %numPlates16 = load i64, i64* %numPlates2
  store i64 %numPlates16, i64* %count1
  %count18 = load i64, i64* %count1
  %count19 = icmp ne i64 %count18, 0
  br i1 %count19, label %while.body3, label %while.end4
while.body3:
  %plate20 = call i8* (i32) @malloc(i32 16)
  %plate21 = bitcast i8* %plate20 to %struct.plate*
  store %struct.plate* %plate21, %struct.plate** %aPlate3
  %aPlate23 = load %struct.plate*, %struct.plate** %aPlate3
  %size24 = getelementptr %struct.plate, %struct.plate* %aPlate23, i1 0, i32 0
  %count25 = load i64, i64* %count1
  store i64 %count25, i64* %size24
  %aPlate27 = load %struct.plate*, %struct.plate** %aPlate3
  %plateUnder28 = getelementptr %struct.plate, %struct.plate* %aPlate27, i1 0, i32 1
  %peg129 = load %struct.plate*, %struct.plate** @peg1
  store %struct.plate* %peg129, %struct.plate** %plateUnder28
  %aPlate31 = load %struct.plate*, %struct.plate** %aPlate3
  store %struct.plate* %aPlate31, %struct.plate** @peg1
  %count33 = load i64, i64* %count1
  %count34 = sub i64 %count33, 1
  store i64 %count34, i64* %count1
  %count36 = load i64, i64* %count1
  %count37 = icmp ne i64 %count36, 0
  br i1 %count37, label %while.body3, label %while.end4
while.end4:
  %_40 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_41 = call i32 (i8*, ...) @printf(i8* %_40, i64 1)
  %peg142 = load %struct.plate*, %struct.plate** @peg1
  call void (%struct.plate*) @printPeg(%struct.plate* %peg142)
  %_44 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_45 = call i32 (i8*, ...) @printf(i8* %_44, i64 2)
  %peg246 = load %struct.plate*, %struct.plate** @peg2
  call void (%struct.plate*) @printPeg(%struct.plate* %peg246)
  %_48 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_49 = call i32 (i8*, ...) @printf(i8* %_48, i64 3)
  %peg350 = load %struct.plate*, %struct.plate** @peg3
  call void (%struct.plate*) @printPeg(%struct.plate* %peg350)
  %numPlates52 = load i64, i64* %numPlates2
  call void (i64, i64, i64, i64) @hanoi(i64 %numPlates52, i64 1, i64 3, i64 2)
  %_54 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_55 = call i32 (i8*, ...) @printf(i8* %_54, i64 1)
  %peg156 = load %struct.plate*, %struct.plate** @peg1
  call void (%struct.plate*) @printPeg(%struct.plate* %peg156)
  %_58 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_59 = call i32 (i8*, ...) @printf(i8* %_58, i64 2)
  %peg260 = load %struct.plate*, %struct.plate** @peg2
  call void (%struct.plate*) @printPeg(%struct.plate* %peg260)
  %_62 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_63 = call i32 (i8*, ...) @printf(i8* %_62, i64 3)
  %peg364 = load %struct.plate*, %struct.plate** @peg3
  call void (%struct.plate*) @printPeg(%struct.plate* %peg364)
  %numMoves66 = load i64, i64* @numMoves
  %_67 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_68 = call i32 (i8*, ...) @printf(i8* %_67, i64 %numMoves66)
  %peg369 = load %struct.plate*, %struct.plate** @peg3
  %peg370 = icmp ne %struct.plate* %peg369, null
  br i1 %peg370, label %while.body5, label %while.end6
while.body5:
  %peg371 = load %struct.plate*, %struct.plate** @peg3
  store %struct.plate* %peg371, %struct.plate** %aPlate3
  %peg373 = load %struct.plate*, %struct.plate** @peg3
  %plateUnder74 = getelementptr %struct.plate, %struct.plate* %peg373, i1 0, i32 1
  %plateUnder75 = load %struct.plate*, %struct.plate** %plateUnder74
  store %struct.plate* %plateUnder75, %struct.plate** @peg3
  %aPlate77 = load %struct.plate*, %struct.plate** %aPlate3
  %_78 = bitcast %struct.plate* %aPlate77 to i8*
  call void (i8*) @free(i8* %_78)
  %peg380 = load %struct.plate*, %struct.plate** @peg3
  %peg381 = icmp ne %struct.plate* %peg380, null
  br i1 %peg381, label %while.body5, label %while.end6
while.end6:
  br label %if.end7
if.end7:
  store i64 0, i64* %_0
  br label %exit
exit:
  %_88 = load i64, i64* %_0
  ret i64 %_88
}

