%struct.node = type { i64, %struct.node* }
%struct.tnode = type { i64, %struct.tnode*, %struct.tnode* }
%struct.i = type { i64 }
%struct.myCopy = type { i1 }

declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

@a = global i64 undef, align 8
@b = global i64 undef, align 8
@i = global %struct.i* undef, align 8

define %struct.node* @concatLists(%struct.node* %first, %struct.node* %second) {
entry:
  br label %if.cond1
if.cond1:
  %_8 = icmp eq %struct.node* %first, null
  br i1 %_8, label %then.body2, label %while.cond14
then.body2:
  br label %exit
while.cond14:
  %temp.next_auf13 = getelementptr %struct.node, %struct.node* %first, i1 0, i32 1
  %_14 = load %struct.node*, %struct.node** %temp.next_auf13
  %_15 = icmp ne %struct.node* %_14, null
  br i1 %_15, label %while.body5, label %while.exit8
while.body5:
  %temp3 = phi %struct.node* [ %first, %while.cond14 ], [ %temp18, %while.fillback7 ]
  %temp.next_auf17 = getelementptr %struct.node, %struct.node* %temp3, i1 0, i32 1
  %temp18 = load %struct.node*, %struct.node** %temp.next_auf17
  br label %while.cond26
while.cond26:
  %temp.next_auf20 = getelementptr %struct.node, %struct.node* %temp18, i1 0, i32 1
  %_21 = load %struct.node*, %struct.node** %temp.next_auf20
  %_22 = icmp ne %struct.node* %_21, null
  br i1 %_22, label %while.fillback7, label %while.exit8
while.fillback7:
  br label %while.body5
while.exit8:
  %temp2 = phi %struct.node* [ %first, %while.cond14 ], [ %temp18, %while.cond26 ]
  %temp.next_auf25 = getelementptr %struct.node, %struct.node* %temp2, i1 0, i32 1
  store %struct.node* %second, %struct.node** %temp.next_auf25
  br label %exit
exit:
  %return_reg10 = phi %struct.node* [ %second, %then.body2 ], [ %first, %while.exit8 ]
  ret %struct.node* %return_reg10
}

define %struct.node* @add(%struct.node* %list, i64 %toAdd) {
entry:
  br label %body0
body0:
  %node.malloc4 = call i8* (i32) @malloc(i32 16)
  %newNode5 = bitcast i8* %node.malloc4 to %struct.node*
  %newNode.data_auf6 = getelementptr %struct.node, %struct.node* %newNode5, i1 0, i32 0
  store i64 %toAdd, i64* %newNode.data_auf6
  %newNode.next_auf8 = getelementptr %struct.node, %struct.node* %newNode5, i1 0, i32 1
  store %struct.node* %list, %struct.node** %newNode.next_auf8
  br label %exit
exit:
  %return_reg10 = phi %struct.node* [ %newNode5, %body0 ]
  ret %struct.node* %return_reg10
}

define i64 @size(%struct.node* %list) {
entry:
  %return_reg1 = alloca i64
  %_2 = load i64, i64* %return_reg1
  br label %if.cond1
if.cond1:
  %_4 = icmp eq %struct.node* %list, null
  br i1 %_4, label %then.body2, label %if.exit3
then.body2:
  br label %exit
if.exit3:
  %list.next_auf10 = getelementptr %struct.node, %struct.node* %list, i1 0, i32 1
  %_11 = load %struct.node*, %struct.node** %list.next_auf10
  %aufrufen_size12 = call i64 (%struct.node*) @size(%struct.node* %_11)
  %tmp.binop13 = add i64 1, %aufrufen_size12
  br label %exit
exit:
  %return_reg7 = phi i64 [ 0, %then.body2 ], [ %tmp.binop13, %if.exit3 ]
  ret i64 %return_reg7
}

define i64 @get(%struct.node* %list, i64 %index) {
entry:
  %return_reg2 = alloca i64
  %_3 = load i64, i64* %return_reg2
  br label %if.cond1
if.cond1:
  %_6 = icmp eq i64 %index, 0
  br i1 %_6, label %then.body2, label %if.exit3
then.body2:
  %list.data_auf8 = getelementptr %struct.node, %struct.node* %list, i1 0, i32 0
  %_9 = load i64, i64* %list.data_auf8
  br label %exit
if.exit3:
  %list.next_auf12 = getelementptr %struct.node, %struct.node* %list, i1 0, i32 1
  %_13 = load %struct.node*, %struct.node** %list.next_auf12
  %tmp.binop15 = sub i64 %index, 1
  %aufrufen_get16 = call i64 (%struct.node*, i64) @get(%struct.node* %_13, i64 %tmp.binop15)
  br label %exit
exit:
  %return_reg10 = phi i64 [ %_9, %then.body2 ], [ %aufrufen_get16, %if.exit3 ]
  ret i64 %return_reg10
}

define %struct.node* @pop(%struct.node* %list) {
entry:
  br label %body0
body0:
  %list.next_auf3 = getelementptr %struct.node, %struct.node* %list, i1 0, i32 1
  %_4 = load %struct.node*, %struct.node** %list.next_auf3
  br label %exit
exit:
  %return_reg5 = phi %struct.node* [ %_4, %body0 ]
  ret %struct.node* %return_reg5
}

define void @printList(%struct.node* %list) {
entry:
  br label %if.cond1
if.cond1:
  %_2 = icmp ne %struct.node* %list, null
  br i1 %_2, label %then.body2, label %if.exit4
then.body2:
  %list.data_auf4 = getelementptr %struct.node, %struct.node* %list, i1 0, i32 0
  %_5 = load i64, i64* %list.data_auf4
  %_6 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_7 = call i32 (i8*, ...) @printf(i8* %_6, i64 %_5)
  %list.next_auf8 = getelementptr %struct.node, %struct.node* %list, i1 0, i32 1
  %_9 = load %struct.node*, %struct.node** %list.next_auf8
  call void (%struct.node*) @printList(%struct.node* %_9)
  br label %if.exit4
if.exit4:
  br label %exit
exit:
  ret void
}

define void @treeprint(%struct.tnode* %root) {
entry:
  br label %if.cond1
if.cond1:
  %_2 = icmp ne %struct.tnode* %root, null
  br i1 %_2, label %then.body2, label %if.exit4
then.body2:
  %root.left_auf4 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 1
  %_5 = load %struct.tnode*, %struct.tnode** %root.left_auf4
  call void (%struct.tnode*) @treeprint(%struct.tnode* %_5)
  %root.data_auf7 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 0
  %_8 = load i64, i64* %root.data_auf7
  %_9 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_10 = call i32 (i8*, ...) @printf(i8* %_9, i64 %_8)
  %root.right_auf11 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 2
  %_12 = load %struct.tnode*, %struct.tnode** %root.right_auf11
  call void (%struct.tnode*) @treeprint(%struct.tnode* %_12)
  br label %if.exit4
if.exit4:
  br label %exit
exit:
  ret void
}

define void @freeList(%struct.node* %list) {
entry:
  br label %if.cond1
if.cond1:
  %_2 = icmp ne %struct.node* %list, null
  br i1 %_2, label %then.body2, label %if.exit4
then.body2:
  %list.next_auf4 = getelementptr %struct.node, %struct.node* %list, i1 0, i32 1
  %_5 = load %struct.node*, %struct.node** %list.next_auf4
  call void (%struct.node*) @freeList(%struct.node* %_5)
  %_7 = bitcast %struct.node* %list to i8*
  call void (i8*) @free(i8* %_7)
  br label %if.exit4
if.exit4:
  br label %exit
exit:
  ret void
}

define void @freeTree(%struct.tnode* %root) {
entry:
  br label %if.cond1
if.cond1:
  %tmp.binop2 = icmp eq %struct.tnode* %root, null
  %_3 = xor i1 %tmp.binop2, 1
  br i1 %_3, label %then.body2, label %if.exit4
then.body2:
  %root.left_auf5 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 1
  %_6 = load %struct.tnode*, %struct.tnode** %root.left_auf5
  call void (%struct.tnode*) @freeTree(%struct.tnode* %_6)
  %root.right_auf8 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 2
  %_9 = load %struct.tnode*, %struct.tnode** %root.right_auf8
  call void (%struct.tnode*) @freeTree(%struct.tnode* %_9)
  %_11 = bitcast %struct.tnode* %root to i8*
  call void (i8*) @free(i8* %_11)
  br label %if.exit4
if.exit4:
  br label %exit
exit:
  ret void
}

define %struct.node* @postOrder(%struct.tnode* %root) {
entry:
  br label %if.cond1
if.cond1:
  %_5 = icmp ne %struct.tnode* %root, null
  br i1 %_5, label %then.body2, label %if.exit3
then.body2:
  %node.malloc7 = call i8* (i32) @malloc(i32 16)
  %temp8 = bitcast i8* %node.malloc7 to %struct.node*
  %root.data_auf9 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 0
  %_10 = load i64, i64* %root.data_auf9
  %temp.data_auf11 = getelementptr %struct.node, %struct.node* %temp8, i1 0, i32 0
  store i64 %_10, i64* %temp.data_auf11
  %temp.next_auf13 = getelementptr %struct.node, %struct.node* %temp8, i1 0, i32 1
  store %struct.node* null, %struct.node** %temp.next_auf13
  %root.left_auf15 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 1
  %_16 = load %struct.tnode*, %struct.tnode** %root.left_auf15
  %aufrufen_postOrder17 = call %struct.node* (%struct.tnode*) @postOrder(%struct.tnode* %_16)
  %root.right_auf18 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 2
  %_19 = load %struct.tnode*, %struct.tnode** %root.right_auf18
  %aufrufen_postOrder20 = call %struct.node* (%struct.tnode*) @postOrder(%struct.tnode* %_19)
  %aufrufen_concatLists21 = call %struct.node* (%struct.node*, %struct.node*) @concatLists(%struct.node* %aufrufen_postOrder17, %struct.node* %aufrufen_postOrder20)
  %aufrufen_concatLists22 = call %struct.node* (%struct.node*, %struct.node*) @concatLists(%struct.node* %aufrufen_concatLists21, %struct.node* %temp8)
  br label %exit
if.exit3:
  br label %exit
exit:
  %return_reg23 = phi %struct.node* [ %aufrufen_concatLists22, %then.body2 ], [ null, %if.exit3 ]
  ret %struct.node* %return_reg23
}

define %struct.tnode* @treeadd(%struct.tnode* %root, i64 %toAdd) {
entry:
  br label %if.cond1
if.cond1:
  %_8 = icmp eq %struct.tnode* %root, null
  br i1 %_8, label %then.body2, label %if.cond4
then.body2:
  %tnode.malloc10 = call i8* (i32) @malloc(i32 24)
  %temp11 = bitcast i8* %tnode.malloc10 to %struct.tnode*
  %temp.data_auf12 = getelementptr %struct.tnode, %struct.tnode* %temp11, i1 0, i32 0
  store i64 %toAdd, i64* %temp.data_auf12
  %temp.left_auf14 = getelementptr %struct.tnode, %struct.tnode* %temp11, i1 0, i32 1
  store %struct.tnode* null, %struct.tnode** %temp.left_auf14
  %temp.right_auf16 = getelementptr %struct.tnode, %struct.tnode* %temp11, i1 0, i32 2
  store %struct.tnode* null, %struct.tnode** %temp.right_auf16
  br label %exit
if.cond4:
  %root.data_auf21 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 0
  %_22 = load i64, i64* %root.data_auf21
  %_23 = icmp slt i64 %toAdd, %_22
  br i1 %_23, label %then.body5, label %else.body7
then.body5:
  %root.left_auf25 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 1
  %_26 = load %struct.tnode*, %struct.tnode** %root.left_auf25
  %aufrufen_treeadd27 = call %struct.tnode* (%struct.tnode*, i64) @treeadd(%struct.tnode* %_26, i64 %toAdd)
  %root.left_auf28 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 1
  store %struct.tnode* %aufrufen_treeadd27, %struct.tnode** %root.left_auf28
  br label %then.exit6
then.exit6:
  br label %if.exit9
else.body7:
  %root.right_auf32 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 2
  %_33 = load %struct.tnode*, %struct.tnode** %root.right_auf32
  %aufrufen_treeadd34 = call %struct.tnode* (%struct.tnode*, i64) @treeadd(%struct.tnode* %_33, i64 %toAdd)
  %root.right_auf35 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 2
  store %struct.tnode* %aufrufen_treeadd34, %struct.tnode** %root.right_auf35
  br label %else.exit8
else.exit8:
  br label %if.exit9
if.exit9:
  %root2 = phi %struct.tnode* [ %root, %then.exit6 ], [ %root, %else.exit8 ]
  br label %exit
exit:
  %return_reg18 = phi %struct.tnode* [ %temp11, %then.body2 ], [ %root2, %if.exit9 ]
  ret %struct.tnode* %return_reg18
}

define %struct.node* @quickSort(%struct.node* %list) {
entry:
  br label %if.cond1
if.cond1:
  %aufrufen_size24 = call i64 (%struct.node*) @size(%struct.node* %list)
  %_26 = icmp sle i64 %aufrufen_size24, 1
  br i1 %_26, label %then.body2, label %if.exit3
then.body2:
  br label %exit
if.exit3:
  %aufrufen_get31 = call i64 (%struct.node*, i64) @get(%struct.node* %list, i64 0)
  %aufrufen_size32 = call i64 (%struct.node*) @size(%struct.node* %list)
  %tmp.binop34 = sub i64 %aufrufen_size32, 1
  %aufrufen_get35 = call i64 (%struct.node*, i64) @get(%struct.node* %list, i64 %tmp.binop34)
  %tmp.binop36 = add i64 %aufrufen_get31, %aufrufen_get35
  %pivot38 = sdiv i64 %tmp.binop36, 2
  br label %while.cond14
while.cond14:
  %_41 = icmp ne %struct.node* %list, null
  br i1 %_41, label %while.body5, label %while.exit14
while.body5:
  %greater3 = phi %struct.node* [ null, %while.cond14 ], [ %greater1, %while.fillback13 ]
  %temp6 = phi %struct.node* [ %list, %while.cond14 ], [ %temp56, %while.fillback13 ]
  %pivot8 = phi i64 [ %pivot38, %while.cond14 ], [ %pivot8, %while.fillback13 ]
  %i12 = phi i64 [ 0, %while.cond14 ], [ %i58, %while.fillback13 ]
  %less16 = phi %struct.node* [ null, %while.cond14 ], [ %less14, %while.fillback13 ]
  %list18 = phi %struct.node* [ %list, %while.cond14 ], [ %list18, %while.fillback13 ]
  br label %if.cond6
if.cond6:
  %aufrufen_get44 = call i64 (%struct.node*, i64) @get(%struct.node* %list18, i64 %i12)
  %_45 = icmp sgt i64 %aufrufen_get44, %pivot8
  br i1 %_45, label %then.body7, label %else.body9
then.body7:
  %aufrufen_get47 = call i64 (%struct.node*, i64) @get(%struct.node* %list18, i64 %i12)
  %greater48 = call %struct.node* (%struct.node*, i64) @add(%struct.node* %greater3, i64 %aufrufen_get47)
  br label %then.exit8
then.exit8:
  br label %if.exit11
else.body9:
  %aufrufen_get51 = call i64 (%struct.node*, i64) @get(%struct.node* %list18, i64 %i12)
  %less52 = call %struct.node* (%struct.node*, i64) @add(%struct.node* %less16, i64 %aufrufen_get51)
  br label %else.exit10
else.exit10:
  br label %if.exit11
if.exit11:
  %greater1 = phi %struct.node* [ %greater48, %then.exit8 ], [ %greater3, %else.exit10 ]
  %less14 = phi %struct.node* [ %less16, %then.exit8 ], [ %less52, %else.exit10 ]
  %temp.next_auf55 = getelementptr %struct.node, %struct.node* %temp6, i1 0, i32 1
  %temp56 = load %struct.node*, %struct.node** %temp.next_auf55
  %i58 = add i64 %i12, 1
  br label %while.cond212
while.cond212:
  %_60 = icmp ne %struct.node* %temp56, null
  br i1 %_60, label %while.fillback13, label %while.exit14
while.fillback13:
  br label %while.body5
while.exit14:
  %greater2 = phi %struct.node* [ null, %while.cond14 ], [ %greater1, %while.cond212 ]
  %less15 = phi %struct.node* [ null, %while.cond14 ], [ %less14, %while.cond212 ]
  %list19 = phi %struct.node* [ %list, %while.cond14 ], [ %list18, %while.cond212 ]
  call void (%struct.node*) @freeList(%struct.node* %list19)
  %aufrufen_quickSort64 = call %struct.node* (%struct.node*) @quickSort(%struct.node* %less15)
  %aufrufen_quickSort65 = call %struct.node* (%struct.node*) @quickSort(%struct.node* %greater2)
  %aufrufen_concatLists66 = call %struct.node* (%struct.node*, %struct.node*) @concatLists(%struct.node* %aufrufen_quickSort64, %struct.node* %aufrufen_quickSort65)
  br label %exit
exit:
  %return_reg28 = phi %struct.node* [ %list, %then.body2 ], [ %aufrufen_concatLists66, %while.exit14 ]
  ret %struct.node* %return_reg28
}

define %struct.node* @quickSortMain(%struct.node* %list) {
entry:
  br label %body0
body0:
  call void (%struct.node*) @printList(%struct.node* %list)
  %_6 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_7 = call i32 (i8*, ...) @printf(i8* %_6, i64 -999)
  call void (%struct.node*) @printList(%struct.node* %list)
  %_11 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_12 = call i32 (i8*, ...) @printf(i8* %_11, i64 -999)
  call void (%struct.node*) @printList(%struct.node* %list)
  %_16 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_17 = call i32 (i8*, ...) @printf(i8* %_16, i64 -999)
  br label %exit
exit:
  ret %struct.node* null
}

define i64 @treesearch(%struct.tnode* %root, i64 %target) {
entry:
  br label %body0
body0:
  %_6 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_7 = call i32 (i8*, ...) @printf(i8* %_6, i64 -1)
  br label %if.cond1
if.cond1:
  %_9 = icmp ne %struct.tnode* %root, null
  br i1 %_9, label %if.cond3, label %if.exit12
if.cond3:
  %root.data_auf12 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 0
  %_13 = load i64, i64* %root.data_auf12
  %_14 = icmp eq i64 %_13, %target
  br i1 %_14, label %then.body4, label %if.cond6
then.body4:
  br label %exit
if.cond6:
  %root.left_auf20 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 1
  %_21 = load %struct.tnode*, %struct.tnode** %root.left_auf20
  %aufrufen_treesearch22 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %_21, i64 %target)
  %_24 = icmp eq i64 %aufrufen_treesearch22, 1
  br i1 %_24, label %then.body7, label %if.cond9
then.body7:
  br label %exit
if.cond9:
  %root.right_auf29 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 2
  %_30 = load %struct.tnode*, %struct.tnode** %root.right_auf29
  %aufrufen_treesearch31 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %_30, i64 %target)
  %_33 = icmp eq i64 %aufrufen_treesearch31, 1
  br i1 %_33, label %then.body10, label %else.body11
then.body10:
  br label %exit
else.body11:
  br label %exit
if.exit12:
  br label %exit
exit:
  %return_reg17 = phi i64 [ 1, %then.body4 ], [ 1, %then.body7 ], [ 1, %then.body10 ], [ 0, %else.body11 ], [ 0, %if.exit12 ]
  ret i64 %return_reg17
}

define %struct.node* @inOrder(%struct.tnode* %root) {
entry:
  br label %if.cond1
if.cond1:
  %_5 = icmp ne %struct.tnode* %root, null
  br i1 %_5, label %then.body2, label %else.body3
then.body2:
  %node.malloc7 = call i8* (i32) @malloc(i32 16)
  %temp8 = bitcast i8* %node.malloc7 to %struct.node*
  %root.data_auf9 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 0
  %_10 = load i64, i64* %root.data_auf9
  %temp.data_auf11 = getelementptr %struct.node, %struct.node* %temp8, i1 0, i32 0
  store i64 %_10, i64* %temp.data_auf11
  %temp.next_auf13 = getelementptr %struct.node, %struct.node* %temp8, i1 0, i32 1
  store %struct.node* null, %struct.node** %temp.next_auf13
  %root.left_auf15 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 1
  %_16 = load %struct.tnode*, %struct.tnode** %root.left_auf15
  %aufrufen_inOrder17 = call %struct.node* (%struct.tnode*) @inOrder(%struct.tnode* %_16)
  %root.right_auf18 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 2
  %_19 = load %struct.tnode*, %struct.tnode** %root.right_auf18
  %aufrufen_inOrder20 = call %struct.node* (%struct.tnode*) @inOrder(%struct.tnode* %_19)
  %aufrufen_concatLists21 = call %struct.node* (%struct.node*, %struct.node*) @concatLists(%struct.node* %temp8, %struct.node* %aufrufen_inOrder20)
  %aufrufen_concatLists22 = call %struct.node* (%struct.node*, %struct.node*) @concatLists(%struct.node* %aufrufen_inOrder17, %struct.node* %aufrufen_concatLists21)
  br label %exit
else.body3:
  br label %exit
exit:
  %return_reg23 = phi %struct.node* [ %aufrufen_concatLists22, %then.body2 ], [ null, %else.body3 ]
  ret %struct.node* %return_reg23
}

define i64 @bintreesearch(%struct.tnode* %root, i64 %target) {
entry:
  br label %body0
body0:
  %_6 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_7 = call i32 (i8*, ...) @printf(i8* %_6, i64 -1)
  br label %if.cond1
if.cond1:
  %_9 = icmp ne %struct.tnode* %root, null
  br i1 %_9, label %if.cond3, label %if.exit9
if.cond3:
  %root.data_auf12 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 0
  %_13 = load i64, i64* %root.data_auf12
  %_14 = icmp eq i64 %_13, %target
  br i1 %_14, label %then.body4, label %if.cond6
then.body4:
  br label %exit
if.cond6:
  %root.data_auf20 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 0
  %_21 = load i64, i64* %root.data_auf20
  %_22 = icmp slt i64 %target, %_21
  br i1 %_22, label %then.body7, label %else.body8
then.body7:
  %root.left_auf24 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 1
  %_25 = load %struct.tnode*, %struct.tnode** %root.left_auf24
  %aufrufen_bintreesearch26 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %_25, i64 %target)
  br label %exit
else.body8:
  %root.right_auf28 = getelementptr %struct.tnode, %struct.tnode* %root, i1 0, i32 2
  %_29 = load %struct.tnode*, %struct.tnode** %root.right_auf28
  %aufrufen_bintreesearch30 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %_29, i64 %target)
  br label %exit
if.exit9:
  br label %exit
exit:
  %return_reg17 = phi i64 [ 1, %then.body4 ], [ %aufrufen_bintreesearch26, %then.body7 ], [ %aufrufen_bintreesearch30, %else.body8 ], [ 0, %if.exit9 ]
  ret i64 %return_reg17
}

define %struct.tnode* @buildTree(%struct.node* %list) {
entry:
  br label %while.cond11
while.cond11:
  %aufrufen_size11 = call i64 (%struct.node*) @size(%struct.node* %list)
  %_12 = icmp slt i64 0, %aufrufen_size11
  br i1 %_12, label %while.body2, label %while.exit5
while.body2:
  %root1 = phi %struct.tnode* [ null, %while.cond11 ], [ %root15, %while.fillback4 ]
  %i3 = phi i64 [ 0, %while.cond11 ], [ %i17, %while.fillback4 ]
  %list5 = phi %struct.node* [ %list, %while.cond11 ], [ %list5, %while.fillback4 ]
  %aufrufen_get14 = call i64 (%struct.node*, i64) @get(%struct.node* %list5, i64 %i3)
  %root15 = call %struct.tnode* (%struct.tnode*, i64) @treeadd(%struct.tnode* %root1, i64 %aufrufen_get14)
  %i17 = add i64 %i3, 1
  br label %while.cond23
while.cond23:
  %aufrufen_size19 = call i64 (%struct.node*) @size(%struct.node* %list5)
  %_20 = icmp slt i64 %i17, %aufrufen_size19
  br i1 %_20, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %root2 = phi %struct.tnode* [ null, %while.cond11 ], [ %root15, %while.cond23 ]
  br label %exit
exit:
  ret %struct.tnode* %root2
}

define void @treeMain(%struct.node* %list) {
entry:
  br label %body0
body0:
  %root1 = call %struct.tnode* (%struct.node*) @buildTree(%struct.node* %list)
  call void (%struct.tnode*) @treeprint(%struct.tnode* %root1)
  %_5 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_6 = call i32 (i8*, ...) @printf(i8* %_5, i64 -999)
  %inList7 = call %struct.node* (%struct.tnode*) @inOrder(%struct.tnode* %root1)
  call void (%struct.node*) @printList(%struct.node* %inList7)
  %_11 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_12 = call i32 (i8*, ...) @printf(i8* %_11, i64 -999)
  call void (%struct.node*) @freeList(%struct.node* %inList7)
  %postList14 = call %struct.node* (%struct.tnode*) @postOrder(%struct.tnode* %root1)
  call void (%struct.node*) @printList(%struct.node* %postList14)
  %_18 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_19 = call i32 (i8*, ...) @printf(i8* %_18, i64 -999)
  call void (%struct.node*) @freeList(%struct.node* %postList14)
  %aufrufen_treesearch22 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %root1, i64 0)
  %_23 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_24 = call i32 (i8*, ...) @printf(i8* %_23, i64 %aufrufen_treesearch22)
  %_27 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_28 = call i32 (i8*, ...) @printf(i8* %_27, i64 -999)
  %aufrufen_treesearch30 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %root1, i64 10)
  %_31 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_32 = call i32 (i8*, ...) @printf(i8* %_31, i64 %aufrufen_treesearch30)
  %_35 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_36 = call i32 (i8*, ...) @printf(i8* %_35, i64 -999)
  %aufrufen_treesearch39 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %root1, i64 -2)
  %_40 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_41 = call i32 (i8*, ...) @printf(i8* %_40, i64 %aufrufen_treesearch39)
  %_44 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_45 = call i32 (i8*, ...) @printf(i8* %_44, i64 -999)
  %aufrufen_treesearch47 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %root1, i64 2)
  %_48 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_49 = call i32 (i8*, ...) @printf(i8* %_48, i64 %aufrufen_treesearch47)
  %_52 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_53 = call i32 (i8*, ...) @printf(i8* %_52, i64 -999)
  %aufrufen_treesearch55 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %root1, i64 3)
  %_56 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_57 = call i32 (i8*, ...) @printf(i8* %_56, i64 %aufrufen_treesearch55)
  %_60 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_61 = call i32 (i8*, ...) @printf(i8* %_60, i64 -999)
  %aufrufen_treesearch63 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %root1, i64 9)
  %_64 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_65 = call i32 (i8*, ...) @printf(i8* %_64, i64 %aufrufen_treesearch63)
  %_68 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_69 = call i32 (i8*, ...) @printf(i8* %_68, i64 -999)
  %aufrufen_treesearch71 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %root1, i64 1)
  %_72 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_73 = call i32 (i8*, ...) @printf(i8* %_72, i64 %aufrufen_treesearch71)
  %_76 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_77 = call i32 (i8*, ...) @printf(i8* %_76, i64 -999)
  %aufrufen_bintreesearch79 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %root1, i64 0)
  %_80 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_81 = call i32 (i8*, ...) @printf(i8* %_80, i64 %aufrufen_bintreesearch79)
  %_84 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_85 = call i32 (i8*, ...) @printf(i8* %_84, i64 -999)
  %aufrufen_bintreesearch87 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %root1, i64 10)
  %_88 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_89 = call i32 (i8*, ...) @printf(i8* %_88, i64 %aufrufen_bintreesearch87)
  %_92 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_93 = call i32 (i8*, ...) @printf(i8* %_92, i64 -999)
  %aufrufen_bintreesearch96 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %root1, i64 -2)
  %_97 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_98 = call i32 (i8*, ...) @printf(i8* %_97, i64 %aufrufen_bintreesearch96)
  %_101 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_102 = call i32 (i8*, ...) @printf(i8* %_101, i64 -999)
  %aufrufen_bintreesearch104 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %root1, i64 2)
  %_105 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_106 = call i32 (i8*, ...) @printf(i8* %_105, i64 %aufrufen_bintreesearch104)
  %_109 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_110 = call i32 (i8*, ...) @printf(i8* %_109, i64 -999)
  %aufrufen_bintreesearch112 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %root1, i64 3)
  %_113 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_114 = call i32 (i8*, ...) @printf(i8* %_113, i64 %aufrufen_bintreesearch112)
  %_117 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_118 = call i32 (i8*, ...) @printf(i8* %_117, i64 -999)
  %aufrufen_bintreesearch120 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %root1, i64 9)
  %_121 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_122 = call i32 (i8*, ...) @printf(i8* %_121, i64 %aufrufen_bintreesearch120)
  %_125 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_126 = call i32 (i8*, ...) @printf(i8* %_125, i64 -999)
  %aufrufen_bintreesearch128 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %root1, i64 1)
  %_129 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_130 = call i32 (i8*, ...) @printf(i8* %_129, i64 %aufrufen_bintreesearch128)
  %_133 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_134 = call i32 (i8*, ...) @printf(i8* %_133, i64 -999)
  call void (%struct.tnode*) @freeTree(%struct.tnode* %root1)
  br label %exit
exit:
  ret void
}

define %struct.node* @myCopy(%struct.node* %src) {
entry:
  br label %if.cond1
if.cond1:
  %_4 = icmp eq %struct.node* %src, null
  br i1 %_4, label %then.body2, label %if.exit3
then.body2:
  br label %exit
if.exit3:
  %src.data_auf8 = getelementptr %struct.node, %struct.node* %src, i1 0, i32 0
  %_9 = load i64, i64* %src.data_auf8
  %aufrufen_add10 = call %struct.node* (%struct.node*, i64) @add(%struct.node* null, i64 %_9)
  %src.next_auf11 = getelementptr %struct.node, %struct.node* %src, i1 0, i32 1
  %_12 = load %struct.node*, %struct.node** %src.next_auf11
  %aufrufen_myCopy13 = call %struct.node* (%struct.node*) @myCopy(%struct.node* %_12)
  %aufrufen_concatLists14 = call %struct.node* (%struct.node*, %struct.node*) @concatLists(%struct.node* %aufrufen_add10, %struct.node* %aufrufen_myCopy13)
  br label %exit
exit:
  %return_reg6 = phi %struct.node* [ null, %then.body2 ], [ %aufrufen_concatLists14, %if.exit3 ]
  ret %struct.node* %return_reg6
}

define i64 @main() {
entry:
  %element42 = alloca i64
  %element43 = load i64, i64* %element42
  %sortedList44 = alloca %struct.node*
  %sortedList45 = load %struct.node*, %struct.node** %sortedList44
  br label %while.cond11
while.cond11:
  br label %while.body2
while.body2:
  %i6 = phi i64 [ 0, %while.cond11 ], [ %i30, %while.fillback4 ]
  %myList10 = phi %struct.node* [ null, %while.cond11 ], [ %myList23, %while.fillback4 ]
  %_19 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_20 = call i32 (i8*, ...) @scanf(i8* %_19, i32* @.read_scratch)
  %_21 = load i32, i32* @.read_scratch
  %element22 = sext i32 %_21 to i64
  %myList23 = call %struct.node* (%struct.node*, i64) @add(%struct.node* %myList10, i64 %element22)
  %copyList124 = call %struct.node* (%struct.node*) @myCopy(%struct.node* %myList23)
  %copyList225 = call %struct.node* (%struct.node*) @myCopy(%struct.node* %myList23)
  %sortedList26 = call %struct.node* (%struct.node*) @quickSortMain(%struct.node* %copyList124)
  call void (%struct.node*) @freeList(%struct.node* %sortedList26)
  call void (%struct.node*) @treeMain(%struct.node* %copyList225)
  %i30 = add i64 %i6, 1
  br label %while.cond23
while.cond23:
  %_33 = icmp slt i64 %i30, 10
  br i1 %_33, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  call void (%struct.node*) @freeList(%struct.node* %myList23)
  call void (%struct.node*) @freeList(%struct.node* %copyList124)
  call void (%struct.node*) @freeList(%struct.node* %copyList225)
  br label %exit
exit:
  ret i64 0
}

