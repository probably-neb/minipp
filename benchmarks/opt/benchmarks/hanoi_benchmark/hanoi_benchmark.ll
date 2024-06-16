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
  br label %if.cond1
if.cond1:
  %_8 = icmp eq i64 %from, 1
  br i1 %_8, label %then.body2, label %if.cond5
then.body2:
  %plateToMove10 = load %struct.plate*, %struct.plate** @peg1
  %load_global11 = load %struct.plate*, %struct.plate** @peg1
  %peg1.plateUnder_auf12 = getelementptr %struct.plate, %struct.plate* %load_global11, i1 0, i32 1
  %_13 = load %struct.plate*, %struct.plate** %peg1.plateUnder_auf12
  store %struct.plate* %_13, %struct.plate** @peg1
  br label %then.exit3
then.exit3:
  br label %if.exit12
if.cond5:
  %_19 = icmp eq i64 %from, 2
  br i1 %_19, label %then.body6, label %else.body8
then.body6:
  %plateToMove21 = load %struct.plate*, %struct.plate** @peg2
  %load_global22 = load %struct.plate*, %struct.plate** @peg2
  %peg2.plateUnder_auf23 = getelementptr %struct.plate, %struct.plate* %load_global22, i1 0, i32 1
  %_24 = load %struct.plate*, %struct.plate** %peg2.plateUnder_auf23
  store %struct.plate* %_24, %struct.plate** @peg2
  br label %then.exit7
then.exit7:
  br label %if.exit10
else.body8:
  %plateToMove28 = load %struct.plate*, %struct.plate** @peg3
  %load_global29 = load %struct.plate*, %struct.plate** @peg3
  %peg3.plateUnder_auf30 = getelementptr %struct.plate, %struct.plate* %load_global29, i1 0, i32 1
  %_31 = load %struct.plate*, %struct.plate** %peg3.plateUnder_auf30
  store %struct.plate* %_31, %struct.plate** @peg3
  br label %else.exit9
else.exit9:
  br label %if.exit10
if.exit10:
  %plateToMove3 = phi %struct.plate* [ %plateToMove21, %then.exit7 ], [ %plateToMove28, %else.exit9 ]
  br label %else.exit11
else.exit11:
  br label %if.exit12
if.exit12:
  %plateToMove2 = phi %struct.plate* [ %plateToMove10, %then.exit3 ], [ %plateToMove3, %else.exit11 ]
  br label %if.cond13
if.cond13:
  %_39 = icmp eq i64 %to, 1
  br i1 %_39, label %then.body14, label %if.cond17
then.body14:
  %load_global41 = load %struct.plate*, %struct.plate** @peg1
  %plateToMove.plateUnder_auf42 = getelementptr %struct.plate, %struct.plate* %plateToMove2, i1 0, i32 1
  store %struct.plate* %load_global41, %struct.plate** %plateToMove.plateUnder_auf42
  store %struct.plate* %plateToMove2, %struct.plate** @peg1
  br label %if.exit24
if.cond17:
  %_49 = icmp eq i64 %to, 2
  br i1 %_49, label %then.body18, label %else.body20
then.body18:
  %load_global51 = load %struct.plate*, %struct.plate** @peg2
  %plateToMove.plateUnder_auf52 = getelementptr %struct.plate, %struct.plate* %plateToMove2, i1 0, i32 1
  store %struct.plate* %load_global51, %struct.plate** %plateToMove.plateUnder_auf52
  store %struct.plate* %plateToMove2, %struct.plate** @peg2
  br label %if.exit22
else.body20:
  %load_global57 = load %struct.plate*, %struct.plate** @peg3
  %plateToMove.plateUnder_auf58 = getelementptr %struct.plate, %struct.plate* %plateToMove2, i1 0, i32 1
  store %struct.plate* %load_global57, %struct.plate** %plateToMove.plateUnder_auf58
  store %struct.plate* %plateToMove2, %struct.plate** @peg3
  br label %if.exit22
if.exit22:
  br label %if.exit24
if.exit24:
  %load_global65 = load i64, i64* @numMoves
  %tmp.binop67 = add i64 %load_global65, 1
  store i64 %tmp.binop67, i64* @numMoves
  br label %exit
exit:
  ret void
}

define void @hanoi(i64 %n, i64 %from, i64 %to, i64 %other) {
entry:
  br label %if.cond1
if.cond1:
  %_6 = icmp eq i64 %n, 1
  br i1 %_6, label %then.body2, label %else.body4
then.body2:
  call void (i64, i64) @move(i64 %from, i64 %to)
  br label %if.exit6
else.body4:
  %tmp.binop12 = sub i64 %n, 1
  call void (i64, i64, i64, i64) @hanoi(i64 %tmp.binop12, i64 %from, i64 %other, i64 %to)
  call void (i64, i64) @move(i64 %from, i64 %to)
  %tmp.binop16 = sub i64 %n, 1
  call void (i64, i64, i64, i64) @hanoi(i64 %tmp.binop16, i64 %other, i64 %to, i64 %from)
  br label %if.exit6
if.exit6:
  br label %exit
exit:
  ret void
}

define void @printPeg(%struct.plate* %peg) {
entry:
  br label %while.cond11
while.cond11:
  %_4 = icmp ne %struct.plate* %peg, null
  br i1 %_4, label %while.body2, label %while.exit5
while.body2:
  %aPlate1 = phi %struct.plate* [ %peg, %while.cond11 ], [ %aPlate11, %while.fillback4 ]
  %aPlate.size_auf6 = getelementptr %struct.plate, %struct.plate* %aPlate1, i1 0, i32 0
  %_7 = load i64, i64* %aPlate.size_auf6
  %_8 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_9 = call i32 (i8*, ...) @printf(i8* %_8, i64 %_7)
  %aPlate.plateUnder_auf10 = getelementptr %struct.plate, %struct.plate* %aPlate1, i1 0, i32 1
  %aPlate11 = load %struct.plate*, %struct.plate** %aPlate.plateUnder_auf10
  br label %while.cond23
while.cond23:
  %_13 = icmp ne %struct.plate* %aPlate11, null
  br i1 %_13, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  br label %exit
exit:
  ret void
}

define i64 @main() {
entry:
  %aPlate100 = alloca %struct.plate*
  %aPlate101 = load %struct.plate*, %struct.plate** %aPlate100
  %count102 = alloca i64
  %count103 = load i64, i64* %count102
  br label %body0
body0:
  store %struct.plate* null, %struct.plate** @peg1
  store %struct.plate* null, %struct.plate** @peg2
  store %struct.plate* null, %struct.plate** @peg3
  store i64 0, i64* @numMoves
  %_15 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_16 = call i32 (i8*, ...) @scanf(i8* %_15, i32* @.read_scratch)
  %_17 = load i32, i32* @.read_scratch
  %count18 = sext i32 %_17 to i64
  br label %if.cond1
if.cond1:
  %_21 = icmp sge i64 %count18, 1
  br i1 %_21, label %while.cond13, label %if.exit14
while.cond13:
  %_25 = icmp ne i64 %count18, 0
  br i1 %_25, label %while.body4, label %while.exit7
while.body4:
  %count6 = phi i64 [ %count18, %while.cond13 ], [ %count36, %while.fillback6 ]
  %plate.malloc27 = call i8* (i32) @malloc(i32 16)
  %aPlate28 = bitcast i8* %plate.malloc27 to %struct.plate*
  %aPlate.size_auf29 = getelementptr %struct.plate, %struct.plate* %aPlate28, i1 0, i32 0
  store i64 %count6, i64* %aPlate.size_auf29
  %load_global31 = load %struct.plate*, %struct.plate** @peg1
  %aPlate.plateUnder_auf32 = getelementptr %struct.plate, %struct.plate* %aPlate28, i1 0, i32 1
  store %struct.plate* %load_global31, %struct.plate** %aPlate.plateUnder_auf32
  store %struct.plate* %aPlate28, %struct.plate** @peg1
  %count36 = sub i64 %count6, 1
  br label %while.cond25
while.cond25:
  %_39 = icmp ne i64 %count36, 0
  br i1 %_39, label %while.fillback6, label %while.exit7
while.fillback6:
  br label %while.body4
while.exit7:
  %_43 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_44 = call i32 (i8*, ...) @printf(i8* %_43, i64 1)
  %load_global45 = load %struct.plate*, %struct.plate** @peg1
  call void (%struct.plate*) @printPeg(%struct.plate* %load_global45)
  %_48 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_49 = call i32 (i8*, ...) @printf(i8* %_48, i64 2)
  %load_global50 = load %struct.plate*, %struct.plate** @peg2
  call void (%struct.plate*) @printPeg(%struct.plate* %load_global50)
  %_53 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_54 = call i32 (i8*, ...) @printf(i8* %_53, i64 3)
  %load_global55 = load %struct.plate*, %struct.plate** @peg3
  call void (%struct.plate*) @printPeg(%struct.plate* %load_global55)
  call void (i64, i64, i64, i64) @hanoi(i64 %count18, i64 1, i64 3, i64 2)
  %_62 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_63 = call i32 (i8*, ...) @printf(i8* %_62, i64 1)
  %load_global64 = load %struct.plate*, %struct.plate** @peg1
  call void (%struct.plate*) @printPeg(%struct.plate* %load_global64)
  %_67 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_68 = call i32 (i8*, ...) @printf(i8* %_67, i64 2)
  %load_global69 = load %struct.plate*, %struct.plate** @peg2
  call void (%struct.plate*) @printPeg(%struct.plate* %load_global69)
  %_72 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_73 = call i32 (i8*, ...) @printf(i8* %_72, i64 3)
  %load_global74 = load %struct.plate*, %struct.plate** @peg3
  call void (%struct.plate*) @printPeg(%struct.plate* %load_global74)
  %load_global76 = load i64, i64* @numMoves
  %_77 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_78 = call i32 (i8*, ...) @printf(i8* %_77, i64 %load_global76)
  br label %while.cond18
while.cond18:
  %load_global80 = load %struct.plate*, %struct.plate** @peg3
  %_81 = icmp ne %struct.plate* %load_global80, null
  br i1 %_81, label %while.body9, label %while.exit12
while.body9:
  %aPlate83 = load %struct.plate*, %struct.plate** @peg3
  %load_global84 = load %struct.plate*, %struct.plate** @peg3
  %peg3.plateUnder_auf85 = getelementptr %struct.plate, %struct.plate* %load_global84, i1 0, i32 1
  %_86 = load %struct.plate*, %struct.plate** %peg3.plateUnder_auf85
  store %struct.plate* %_86, %struct.plate** @peg3
  %_88 = bitcast %struct.plate* %aPlate83 to i8*
  call void (i8*) @free(i8* %_88)
  br label %while.cond210
while.cond210:
  %load_global91 = load %struct.plate*, %struct.plate** @peg3
  %_92 = icmp ne %struct.plate* %load_global91, null
  br i1 %_92, label %while.body9, label %while.exit12
while.exit12:
  br label %if.exit14
if.exit14:
  br label %exit
exit:
  ret i64 0
}

