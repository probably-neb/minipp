%struct.Node = type { i64, %struct.Node*, %struct.Node* }

declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

@swapped = global i64 undef, align 8

define i64 @compare(%struct.Node* %a, %struct.Node* %b) {
entry:
  br label %body0
body0:
  %a.val_auf4 = getelementptr %struct.Node, %struct.Node* %a, i1 0, i32 0
  %_5 = load i64, i64* %a.val_auf4
  %b.val_auf6 = getelementptr %struct.Node, %struct.Node* %b, i1 0, i32 0
  %_7 = load i64, i64* %b.val_auf6
  %tmp.binop8 = sub i64 %_5, %_7
  br label %exit
exit:
  %return_reg9 = phi i64 [ %tmp.binop8, %body0 ]
  ret i64 %return_reg9
}

define void @deathSort(%struct.Node* %head) {
entry:
  %currNode67 = alloca %struct.Node*
  %currNode68 = load %struct.Node*, %struct.Node** %currNode67
  %swap69 = alloca i64
  %swap70 = load i64, i64* %swap69
  br label %while.cond11
while.cond11:
  br label %while.body2
while.body2:
  %currNode19 = phi %struct.Node* [ %head, %while.cond11 ], [ %head17, %while.fillback13 ]
  br label %while.cond13
while.cond13:
  %currNode.next_auf27 = getelementptr %struct.Node, %struct.Node* %currNode19, i1 0, i32 2
  %_28 = load %struct.Node*, %struct.Node** %currNode.next_auf27
  %_29 = icmp ne %struct.Node* %_28, %currNode19
  br i1 %_29, label %while.body4, label %while.exit11
while.body4:
  %currNode1 = phi %struct.Node* [ %currNode19, %while.cond13 ], [ %currNode54, %while.fillback10 ]
  %swapped12 = phi i64 [ 0, %while.cond13 ], [ %swapped15, %while.fillback10 ]
  %head16 = phi %struct.Node* [ %currNode19, %while.cond13 ], [ %head16, %while.fillback10 ]
  br label %if.cond5
if.cond5:
  %currNode.next_auf32 = getelementptr %struct.Node, %struct.Node* %currNode1, i1 0, i32 2
  %_33 = load %struct.Node*, %struct.Node** %currNode.next_auf32
  %aufrufen_compare34 = call i64 (%struct.Node*, %struct.Node*) @compare(%struct.Node* %currNode1, %struct.Node* %_33)
  %_36 = icmp sgt i64 %aufrufen_compare34, 0
  br i1 %_36, label %then.body6, label %if.exit8
then.body6:
  %currNode.val_auf38 = getelementptr %struct.Node, %struct.Node* %currNode1, i1 0, i32 0
  %swap39 = load i64, i64* %currNode.val_auf38
  %currNode.next_auf40 = getelementptr %struct.Node, %struct.Node* %currNode1, i1 0, i32 2
  %Node41 = load %struct.Node*, %struct.Node** %currNode.next_auf40
  %currNode.next.val_auf42 = getelementptr %struct.Node, %struct.Node* %Node41, i1 0, i32 0
  %_43 = load i64, i64* %currNode.next.val_auf42
  %currNode.val_auf44 = getelementptr %struct.Node, %struct.Node* %currNode1, i1 0, i32 0
  store i64 %_43, i64* %currNode.val_auf44
  %currNode.next_auf46 = getelementptr %struct.Node, %struct.Node* %currNode1, i1 0, i32 2
  %Node47 = load %struct.Node*, %struct.Node** %currNode.next_auf46
  %currNode.next.val_auf48 = getelementptr %struct.Node, %struct.Node* %Node47, i1 0, i32 0
  store i64 %swap39, i64* %currNode.next.val_auf48
  br label %then.exit7
then.exit7:
  br label %if.exit8
if.exit8:
  %currNode5 = phi %struct.Node* [ %currNode1, %if.cond5 ], [ %currNode1, %then.exit7 ]
  %swapped15 = phi i64 [ %swapped12, %if.cond5 ], [ 1, %then.exit7 ]
  %currNode.next_auf53 = getelementptr %struct.Node, %struct.Node* %currNode5, i1 0, i32 2
  %currNode54 = load %struct.Node*, %struct.Node** %currNode.next_auf53
  br label %while.cond29
while.cond29:
  %currNode.next_auf56 = getelementptr %struct.Node, %struct.Node* %currNode54, i1 0, i32 2
  %_57 = load %struct.Node*, %struct.Node** %currNode.next_auf56
  %_58 = icmp ne %struct.Node* %_57, %head16
  br i1 %_58, label %while.fillback10, label %while.exit11
while.fillback10:
  br label %while.body4
while.exit11:
  %swapped13 = phi i64 [ 0, %while.cond13 ], [ %swapped15, %while.cond29 ]
  %head17 = phi %struct.Node* [ %currNode19, %while.cond13 ], [ %head16, %while.cond29 ]
  br label %while.cond212
while.cond212:
  %_63 = icmp eq i64 %swapped13, 1
  br i1 %_63, label %while.fillback13, label %exit
while.fillback13:
  br label %while.body2
exit:
  ret void
}

define void @printEVILList(%struct.Node* %head) {
entry:
  %toFree31 = alloca %struct.Node*
  %toFree32 = load %struct.Node*, %struct.Node** %toFree31
  br label %body0
body0:
  %head.next_auf7 = getelementptr %struct.Node, %struct.Node* %head, i1 0, i32 2
  %currNode8 = load %struct.Node*, %struct.Node** %head.next_auf7
  %head.val_auf9 = getelementptr %struct.Node, %struct.Node* %head, i1 0, i32 0
  %_10 = load i64, i64* %head.val_auf9
  %_11 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_12 = call i32 (i8*, ...) @printf(i8* %_11, i64 %_10)
  %_13 = bitcast %struct.Node* %head to i8*
  call void (i8*) @free(i8* %_13)
  br label %while.cond11
while.cond11:
  %_16 = icmp ne %struct.Node* %currNode8, %head
  br i1 %_16, label %while.body2, label %while.exit5
while.body2:
  %toFree1 = phi %struct.Node* [ %currNode8, %while.cond11 ], [ %currNode23, %while.fillback4 ]
  %head3 = phi %struct.Node* [ %head, %while.cond11 ], [ %head3, %while.fillback4 ]
  %currNode.val_auf18 = getelementptr %struct.Node, %struct.Node* %toFree1, i1 0, i32 0
  %_19 = load i64, i64* %currNode.val_auf18
  %_20 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_21 = call i32 (i8*, ...) @printf(i8* %_20, i64 %_19)
  %currNode.next_auf22 = getelementptr %struct.Node, %struct.Node* %toFree1, i1 0, i32 2
  %currNode23 = load %struct.Node*, %struct.Node** %currNode.next_auf22
  %_24 = bitcast %struct.Node* %toFree1 to i8*
  call void (i8*) @free(i8* %_24)
  br label %while.cond23
while.cond23:
  %_27 = icmp ne %struct.Node* %currNode23, %head3
  br i1 %_27, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  br label %exit
exit:
  ret void
}

define i64 @main() {
entry:
  %currNode70 = alloca %struct.Node*
  %currNode71 = load %struct.Node*, %struct.Node** %currNode70
  br label %body0
body0:
  store i64 666, i64* @swapped
  %_17 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_18 = call i32 (i8*, ...) @scanf(i8* %_17, i32* @.read_scratch)
  %_19 = load i32, i32* @.read_scratch
  %numNodes20 = sext i32 %_19 to i64
  br label %if.cond1
if.cond1:
  %_23 = icmp sle i64 %numNodes20, 0
  br i1 %_23, label %then.body2, label %if.exit3
then.body2:
  %_27 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_28 = call i32 (i8*, ...) @printf(i8* %_27, i64 -1)
  br label %exit
if.exit3:
  %counter34 = mul i64 %numNodes20, 1000
  %Node.malloc35 = call i8* (i32) @malloc(i32 24)
  %previous36 = bitcast i8* %Node.malloc35 to %struct.Node*
  %head.val_auf37 = getelementptr %struct.Node, %struct.Node* %previous36, i1 0, i32 0
  store i64 %counter34, i64* %head.val_auf37
  %head.prev_auf39 = getelementptr %struct.Node, %struct.Node* %previous36, i1 0, i32 1
  store %struct.Node* %previous36, %struct.Node** %head.prev_auf39
  %head.next_auf41 = getelementptr %struct.Node, %struct.Node* %previous36, i1 0, i32 2
  store %struct.Node* %previous36, %struct.Node** %head.next_auf41
  %counter44 = sub i64 %counter34, 1
  br label %while.cond14
while.cond14:
  %_47 = icmp sgt i64 %counter44, 0
  br i1 %_47, label %while.body5, label %while.exit8
while.body5:
  %previous4 = phi %struct.Node* [ %previous36, %while.cond14 ], [ %previous50, %while.fillback7 ]
  %head8 = phi %struct.Node* [ %previous36, %while.cond14 ], [ %head8, %while.fillback7 ]
  %counter11 = phi i64 [ %counter44, %while.cond14 ], [ %counter60, %while.fillback7 ]
  %Node.malloc49 = call i8* (i32) @malloc(i32 24)
  %previous50 = bitcast i8* %Node.malloc49 to %struct.Node*
  %currNode.val_auf51 = getelementptr %struct.Node, %struct.Node* %previous50, i1 0, i32 0
  store i64 %counter11, i64* %currNode.val_auf51
  %currNode.prev_auf53 = getelementptr %struct.Node, %struct.Node* %previous50, i1 0, i32 1
  store %struct.Node* %previous4, %struct.Node** %currNode.prev_auf53
  %currNode.next_auf55 = getelementptr %struct.Node, %struct.Node* %previous50, i1 0, i32 2
  store %struct.Node* %head8, %struct.Node** %currNode.next_auf55
  %previous.next_auf57 = getelementptr %struct.Node, %struct.Node* %previous4, i1 0, i32 2
  store %struct.Node* %previous50, %struct.Node** %previous.next_auf57
  %counter60 = sub i64 %counter11, 1
  br label %while.cond26
while.cond26:
  %_63 = icmp sgt i64 %counter60, 0
  br i1 %_63, label %while.fillback7, label %while.exit8
while.fillback7:
  br label %while.body5
while.exit8:
  %head9 = phi %struct.Node* [ %previous36, %while.cond14 ], [ %head8, %while.cond26 ]
  call void (%struct.Node*) @deathSort(%struct.Node* %head9)
  call void (%struct.Node*) @printEVILList(%struct.Node* %head9)
  br label %exit
exit:
  %return_reg31 = phi i64 [ -1, %then.body2 ], [ 0, %while.exit8 ]
  ret i64 %return_reg31
}

