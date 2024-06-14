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
  %_0 = alloca %struct.node*
  %temp1 = alloca %struct.node*
  %first2 = alloca %struct.node*
  store %struct.node* %first, %struct.node** %first2
  %second4 = alloca %struct.node*
  store %struct.node* %second, %struct.node** %second4
  br label %body1
body1:
  %first7 = load %struct.node*, %struct.node** %first2
  store %struct.node* %first7, %struct.node** %temp1
  %first9 = load %struct.node*, %struct.node** %first2
  %first10 = icmp eq %struct.node* %first9, null
  br i1 %first10, label %if.then2, label %if.end3
if.then2:
  %second11 = load %struct.node*, %struct.node** %second4
  store %struct.node* %second11, %struct.node** %_0
  br label %exit
if.end3:
  %temp15 = load %struct.node*, %struct.node** %temp1
  %next16 = getelementptr %struct.node, %struct.node* %temp15, i1 0, i32 1
  %next17 = load %struct.node*, %struct.node** %next16
  %next18 = icmp ne %struct.node* %next17, null
  br i1 %next18, label %while.body4, label %while.end5
while.body4:
  %temp19 = load %struct.node*, %struct.node** %temp1
  %next20 = getelementptr %struct.node, %struct.node* %temp19, i1 0, i32 1
  %next21 = load %struct.node*, %struct.node** %next20
  store %struct.node* %next21, %struct.node** %temp1
  %temp23 = load %struct.node*, %struct.node** %temp1
  %next24 = getelementptr %struct.node, %struct.node* %temp23, i1 0, i32 1
  %next25 = load %struct.node*, %struct.node** %next24
  %next26 = icmp ne %struct.node* %next25, null
  br i1 %next26, label %while.body4, label %while.end5
while.end5:
  %temp29 = load %struct.node*, %struct.node** %temp1
  %next30 = getelementptr %struct.node, %struct.node* %temp29, i1 0, i32 1
  %second31 = load %struct.node*, %struct.node** %second4
  store %struct.node* %second31, %struct.node** %next30
  %first33 = load %struct.node*, %struct.node** %first2
  store %struct.node* %first33, %struct.node** %_0
  br label %exit
exit:
  %_36 = load %struct.node*, %struct.node** %_0
  ret %struct.node* %_36
}

define %struct.node* @add(%struct.node* %list, i64 %toAdd) {
entry:
  %_0 = alloca %struct.node*
  %newNode1 = alloca %struct.node*
  %list2 = alloca %struct.node*
  store %struct.node* %list, %struct.node** %list2
  %toAdd4 = alloca i64
  store i64 %toAdd, i64* %toAdd4
  br label %body1
body1:
  %node7 = call i8* (i32) @malloc(i32 16)
  %node8 = bitcast i8* %node7 to %struct.node*
  store %struct.node* %node8, %struct.node** %newNode1
  %newNode10 = load %struct.node*, %struct.node** %newNode1
  %data11 = getelementptr %struct.node, %struct.node* %newNode10, i1 0, i32 0
  %toAdd12 = load i64, i64* %toAdd4
  store i64 %toAdd12, i64* %data11
  %newNode14 = load %struct.node*, %struct.node** %newNode1
  %next15 = getelementptr %struct.node, %struct.node* %newNode14, i1 0, i32 1
  %list16 = load %struct.node*, %struct.node** %list2
  store %struct.node* %list16, %struct.node** %next15
  %newNode18 = load %struct.node*, %struct.node** %newNode1
  store %struct.node* %newNode18, %struct.node** %_0
  br label %exit
exit:
  %_21 = load %struct.node*, %struct.node** %_0
  ret %struct.node* %_21
}

define i64 @size(%struct.node* %list) {
entry:
  %_0 = alloca i64
  %list1 = alloca %struct.node*
  store %struct.node* %list, %struct.node** %list1
  br label %body1
body1:
  %list4 = load %struct.node*, %struct.node** %list1
  %list5 = icmp eq %struct.node* %list4, null
  br i1 %list5, label %if.then2, label %if.end3
if.then2:
  store i64 0, i64* %_0
  br label %exit
if.end3:
  %list9 = load %struct.node*, %struct.node** %list1
  %next10 = getelementptr %struct.node, %struct.node* %list9, i1 0, i32 1
  %next11 = load %struct.node*, %struct.node** %next10
  %size12 = call i64 (%struct.node*) @size(%struct.node* %next11)
  %size13 = add i64 1, %size12
  store i64 %size13, i64* %_0
  br label %exit
exit:
  %_16 = load i64, i64* %_0
  ret i64 %_16
}

define i64 @get(%struct.node* %list, i64 %index) {
entry:
  %_0 = alloca i64
  %list1 = alloca %struct.node*
  store %struct.node* %list, %struct.node** %list1
  %index3 = alloca i64
  store i64 %index, i64* %index3
  br label %body1
body1:
  %index6 = load i64, i64* %index3
  %index7 = icmp eq i64 %index6, 0
  br i1 %index7, label %if.then2, label %if.end3
if.then2:
  %list8 = load %struct.node*, %struct.node** %list1
  %data9 = getelementptr %struct.node, %struct.node* %list8, i1 0, i32 0
  %data10 = load i64, i64* %data9
  store i64 %data10, i64* %_0
  br label %exit
if.end3:
  %list14 = load %struct.node*, %struct.node** %list1
  %next15 = getelementptr %struct.node, %struct.node* %list14, i1 0, i32 1
  %next16 = load %struct.node*, %struct.node** %next15
  %index17 = load i64, i64* %index3
  %index18 = sub i64 %index17, 1
  %get19 = call i64 (%struct.node*, i64) @get(%struct.node* %next16, i64 %index18)
  store i64 %get19, i64* %_0
  br label %exit
exit:
  %_22 = load i64, i64* %_0
  ret i64 %_22
}

define %struct.node* @pop(%struct.node* %list) {
entry:
  %_0 = alloca %struct.node*
  %list1 = alloca %struct.node*
  store %struct.node* %list, %struct.node** %list1
  br label %body1
body1:
  %list4 = load %struct.node*, %struct.node** %list1
  %next5 = getelementptr %struct.node, %struct.node* %list4, i1 0, i32 1
  %next6 = load %struct.node*, %struct.node** %next5
  store %struct.node* %next6, %struct.node** %list1
  %list8 = load %struct.node*, %struct.node** %list1
  store %struct.node* %list8, %struct.node** %_0
  br label %exit
exit:
  %_11 = load %struct.node*, %struct.node** %_0
  ret %struct.node* %_11
}

define void @printList(%struct.node* %list) {
entry:
  %list0 = alloca %struct.node*
  store %struct.node* %list, %struct.node** %list0
  br label %body1
body1:
  %list3 = load %struct.node*, %struct.node** %list0
  %list4 = icmp ne %struct.node* %list3, null
  br i1 %list4, label %if.then2, label %if.end3
if.then2:
  %list5 = load %struct.node*, %struct.node** %list0
  %data6 = getelementptr %struct.node, %struct.node* %list5, i1 0, i32 0
  %data7 = load i64, i64* %data6
  %_8 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_9 = call i32 (i8*, ...) @printf(i8* %_8, i64 %data7)
  %list10 = load %struct.node*, %struct.node** %list0
  %next11 = getelementptr %struct.node, %struct.node* %list10, i1 0, i32 1
  %next12 = load %struct.node*, %struct.node** %next11
  call void (%struct.node*) @printList(%struct.node* %next12)
  br label %if.end3
if.end3:
  br label %exit
exit:
  ret void
}

define void @treeprint(%struct.tnode* %root) {
entry:
  %root0 = alloca %struct.tnode*
  store %struct.tnode* %root, %struct.tnode** %root0
  br label %body1
body1:
  %root3 = load %struct.tnode*, %struct.tnode** %root0
  %root4 = icmp ne %struct.tnode* %root3, null
  br i1 %root4, label %if.then2, label %if.end3
if.then2:
  %root5 = load %struct.tnode*, %struct.tnode** %root0
  %left6 = getelementptr %struct.tnode, %struct.tnode* %root5, i1 0, i32 1
  %left7 = load %struct.tnode*, %struct.tnode** %left6
  call void (%struct.tnode*) @treeprint(%struct.tnode* %left7)
  %root9 = load %struct.tnode*, %struct.tnode** %root0
  %data10 = getelementptr %struct.tnode, %struct.tnode* %root9, i1 0, i32 0
  %data11 = load i64, i64* %data10
  %_12 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_13 = call i32 (i8*, ...) @printf(i8* %_12, i64 %data11)
  %root14 = load %struct.tnode*, %struct.tnode** %root0
  %right15 = getelementptr %struct.tnode, %struct.tnode* %root14, i1 0, i32 2
  %right16 = load %struct.tnode*, %struct.tnode** %right15
  call void (%struct.tnode*) @treeprint(%struct.tnode* %right16)
  br label %if.end3
if.end3:
  br label %exit
exit:
  ret void
}

define void @freeList(%struct.node* %list) {
entry:
  %list0 = alloca %struct.node*
  store %struct.node* %list, %struct.node** %list0
  br label %body1
body1:
  %list3 = load %struct.node*, %struct.node** %list0
  %list4 = icmp ne %struct.node* %list3, null
  br i1 %list4, label %if.then2, label %if.end3
if.then2:
  %list5 = load %struct.node*, %struct.node** %list0
  %next6 = getelementptr %struct.node, %struct.node* %list5, i1 0, i32 1
  %next7 = load %struct.node*, %struct.node** %next6
  call void (%struct.node*) @freeList(%struct.node* %next7)
  %list9 = load %struct.node*, %struct.node** %list0
  %_10 = bitcast %struct.node* %list9 to i8*
  call void (i8*) @free(i8* %_10)
  br label %if.end3
if.end3:
  br label %exit
exit:
  ret void
}

define void @freeTree(%struct.tnode* %root) {
entry:
  %root0 = alloca %struct.tnode*
  store %struct.tnode* %root, %struct.tnode** %root0
  br label %body1
body1:
  %root3 = load %struct.tnode*, %struct.tnode** %root0
  %root4 = icmp eq %struct.tnode* %root3, null
  %root5 = xor i1 %root4, 1
  br i1 %root5, label %if.then2, label %if.end3
if.then2:
  %root6 = load %struct.tnode*, %struct.tnode** %root0
  %left7 = getelementptr %struct.tnode, %struct.tnode* %root6, i1 0, i32 1
  %left8 = load %struct.tnode*, %struct.tnode** %left7
  call void (%struct.tnode*) @freeTree(%struct.tnode* %left8)
  %root10 = load %struct.tnode*, %struct.tnode** %root0
  %right11 = getelementptr %struct.tnode, %struct.tnode* %root10, i1 0, i32 2
  %right12 = load %struct.tnode*, %struct.tnode** %right11
  call void (%struct.tnode*) @freeTree(%struct.tnode* %right12)
  %root14 = load %struct.tnode*, %struct.tnode** %root0
  %_15 = bitcast %struct.tnode* %root14 to i8*
  call void (i8*) @free(i8* %_15)
  br label %if.end3
if.end3:
  br label %exit
exit:
  ret void
}

define %struct.node* @postOrder(%struct.tnode* %root) {
entry:
  %_0 = alloca %struct.node*
  %temp1 = alloca %struct.node*
  %root2 = alloca %struct.tnode*
  store %struct.tnode* %root, %struct.tnode** %root2
  br label %body1
body1:
  %root5 = load %struct.tnode*, %struct.tnode** %root2
  %root6 = icmp ne %struct.tnode* %root5, null
  br i1 %root6, label %if.then2, label %if.end3
if.then2:
  %node7 = call i8* (i32) @malloc(i32 16)
  %node8 = bitcast i8* %node7 to %struct.node*
  store %struct.node* %node8, %struct.node** %temp1
  %temp10 = load %struct.node*, %struct.node** %temp1
  %data11 = getelementptr %struct.node, %struct.node* %temp10, i1 0, i32 0
  %root12 = load %struct.tnode*, %struct.tnode** %root2
  %data13 = getelementptr %struct.tnode, %struct.tnode* %root12, i1 0, i32 0
  %data14 = load i64, i64* %data13
  store i64 %data14, i64* %data11
  %temp16 = load %struct.node*, %struct.node** %temp1
  %next17 = getelementptr %struct.node, %struct.node* %temp16, i1 0, i32 1
  store %struct.node* null, %struct.node** %next17
  %root19 = load %struct.tnode*, %struct.tnode** %root2
  %left20 = getelementptr %struct.tnode, %struct.tnode* %root19, i1 0, i32 1
  %left21 = load %struct.tnode*, %struct.tnode** %left20
  %postOrder22 = call %struct.node* (%struct.tnode*) @postOrder(%struct.tnode* %left21)
  %root23 = load %struct.tnode*, %struct.tnode** %root2
  %right24 = getelementptr %struct.tnode, %struct.tnode* %root23, i1 0, i32 2
  %right25 = load %struct.tnode*, %struct.tnode** %right24
  %postOrder26 = call %struct.node* (%struct.tnode*) @postOrder(%struct.tnode* %right25)
  %concatLists27 = call %struct.node* (%struct.node*, %struct.node*) @concatLists(%struct.node* %postOrder22, %struct.node* %postOrder26)
  %temp28 = load %struct.node*, %struct.node** %temp1
  %concatLists29 = call %struct.node* (%struct.node*, %struct.node*) @concatLists(%struct.node* %concatLists27, %struct.node* %temp28)
  store %struct.node* %concatLists29, %struct.node** %_0
  br label %exit
if.end3:
  store %struct.node* null, %struct.node** %_0
  br label %exit
exit:
  %_35 = load %struct.node*, %struct.node** %_0
  ret %struct.node* %_35
}

define %struct.tnode* @treeadd(%struct.tnode* %root, i64 %toAdd) {
entry:
  %_0 = alloca %struct.tnode*
  %temp1 = alloca %struct.tnode*
  %root2 = alloca %struct.tnode*
  store %struct.tnode* %root, %struct.tnode** %root2
  %toAdd4 = alloca i64
  store i64 %toAdd, i64* %toAdd4
  br label %body1
body1:
  %root7 = load %struct.tnode*, %struct.tnode** %root2
  %root8 = icmp eq %struct.tnode* %root7, null
  br i1 %root8, label %if.then2, label %if.end3
if.then2:
  %tnode9 = call i8* (i32) @malloc(i32 24)
  %tnode10 = bitcast i8* %tnode9 to %struct.tnode*
  store %struct.tnode* %tnode10, %struct.tnode** %temp1
  %temp12 = load %struct.tnode*, %struct.tnode** %temp1
  %data13 = getelementptr %struct.tnode, %struct.tnode* %temp12, i1 0, i32 0
  %toAdd14 = load i64, i64* %toAdd4
  store i64 %toAdd14, i64* %data13
  %temp16 = load %struct.tnode*, %struct.tnode** %temp1
  %left17 = getelementptr %struct.tnode, %struct.tnode* %temp16, i1 0, i32 1
  store %struct.tnode* null, %struct.tnode** %left17
  %temp19 = load %struct.tnode*, %struct.tnode** %temp1
  %right20 = getelementptr %struct.tnode, %struct.tnode* %temp19, i1 0, i32 2
  store %struct.tnode* null, %struct.tnode** %right20
  %temp22 = load %struct.tnode*, %struct.tnode** %temp1
  store %struct.tnode* %temp22, %struct.tnode** %_0
  br label %exit
if.end3:
  %toAdd26 = load i64, i64* %toAdd4
  %root27 = load %struct.tnode*, %struct.tnode** %root2
  %data28 = getelementptr %struct.tnode, %struct.tnode* %root27, i1 0, i32 0
  %data29 = load i64, i64* %data28
  %_30 = icmp slt i64 %toAdd26, %data29
  br i1 %_30, label %if.then4, label %if.else5
if.then4:
  %root31 = load %struct.tnode*, %struct.tnode** %root2
  %left32 = getelementptr %struct.tnode, %struct.tnode* %root31, i1 0, i32 1
  %root33 = load %struct.tnode*, %struct.tnode** %root2
  %left34 = getelementptr %struct.tnode, %struct.tnode* %root33, i1 0, i32 1
  %left35 = load %struct.tnode*, %struct.tnode** %left34
  %toAdd36 = load i64, i64* %toAdd4
  %treeadd37 = call %struct.tnode* (%struct.tnode*, i64) @treeadd(%struct.tnode* %left35, i64 %toAdd36)
  store %struct.tnode* %treeadd37, %struct.tnode** %left32
  br label %if.end6
if.else5:
  %root39 = load %struct.tnode*, %struct.tnode** %root2
  %right40 = getelementptr %struct.tnode, %struct.tnode* %root39, i1 0, i32 2
  %root41 = load %struct.tnode*, %struct.tnode** %root2
  %right42 = getelementptr %struct.tnode, %struct.tnode* %root41, i1 0, i32 2
  %right43 = load %struct.tnode*, %struct.tnode** %right42
  %toAdd44 = load i64, i64* %toAdd4
  %treeadd45 = call %struct.tnode* (%struct.tnode*, i64) @treeadd(%struct.tnode* %right43, i64 %toAdd44)
  store %struct.tnode* %treeadd45, %struct.tnode** %right40
  br label %if.end6
if.end6:
  %root50 = load %struct.tnode*, %struct.tnode** %root2
  store %struct.tnode* %root50, %struct.tnode** %_0
  br label %exit
exit:
  %_53 = load %struct.tnode*, %struct.tnode** %_0
  ret %struct.tnode* %_53
}

define %struct.node* @quickSort(%struct.node* %list) {
entry:
  %_0 = alloca %struct.node*
  %pivot1 = alloca i64
  %i2 = alloca i64
  %less3 = alloca %struct.node*
  %greater4 = alloca %struct.node*
  %temp5 = alloca %struct.node*
  %list6 = alloca %struct.node*
  store %struct.node* %list, %struct.node** %list6
  br label %body1
body1:
  store %struct.node* null, %struct.node** %less3
  store %struct.node* null, %struct.node** %greater4
  %list11 = load %struct.node*, %struct.node** %list6
  %size12 = call i64 (%struct.node*) @size(%struct.node* %list11)
  %size13 = icmp sle i64 %size12, 1
  br i1 %size13, label %if.then2, label %if.end3
if.then2:
  %list14 = load %struct.node*, %struct.node** %list6
  store %struct.node* %list14, %struct.node** %_0
  br label %exit
if.end3:
  %list18 = load %struct.node*, %struct.node** %list6
  %get19 = call i64 (%struct.node*, i64) @get(%struct.node* %list18, i64 0)
  %list20 = load %struct.node*, %struct.node** %list6
  %list21 = load %struct.node*, %struct.node** %list6
  %size22 = call i64 (%struct.node*) @size(%struct.node* %list21)
  %size23 = sub i64 %size22, 1
  %get24 = call i64 (%struct.node*, i64) @get(%struct.node* %list20, i64 %size23)
  %_25 = add i64 %get19, %get24
  %_26 = sdiv i64 %_25, 2
  store i64 %_26, i64* %pivot1
  %list28 = load %struct.node*, %struct.node** %list6
  store %struct.node* %list28, %struct.node** %temp5
  store i64 0, i64* %i2
  %temp31 = load %struct.node*, %struct.node** %temp5
  %temp32 = icmp ne %struct.node* %temp31, null
  br i1 %temp32, label %while.body4, label %while.end8
while.body4:
  %list33 = load %struct.node*, %struct.node** %list6
  %i34 = load i64, i64* %i2
  %get35 = call i64 (%struct.node*, i64) @get(%struct.node* %list33, i64 %i34)
  %pivot36 = load i64, i64* %pivot1
  %_37 = icmp sgt i64 %get35, %pivot36
  br i1 %_37, label %if.then5, label %if.else6
if.then5:
  %greater38 = load %struct.node*, %struct.node** %greater4
  %list39 = load %struct.node*, %struct.node** %list6
  %i40 = load i64, i64* %i2
  %get41 = call i64 (%struct.node*, i64) @get(%struct.node* %list39, i64 %i40)
  %add42 = call %struct.node* (%struct.node*, i64) @add(%struct.node* %greater38, i64 %get41)
  store %struct.node* %add42, %struct.node** %greater4
  br label %if.end7
if.else6:
  %less44 = load %struct.node*, %struct.node** %less3
  %list45 = load %struct.node*, %struct.node** %list6
  %i46 = load i64, i64* %i2
  %get47 = call i64 (%struct.node*, i64) @get(%struct.node* %list45, i64 %i46)
  %add48 = call %struct.node* (%struct.node*, i64) @add(%struct.node* %less44, i64 %get47)
  store %struct.node* %add48, %struct.node** %less3
  br label %if.end7
if.end7:
  %temp53 = load %struct.node*, %struct.node** %temp5
  %next54 = getelementptr %struct.node, %struct.node* %temp53, i1 0, i32 1
  %next55 = load %struct.node*, %struct.node** %next54
  store %struct.node* %next55, %struct.node** %temp5
  %i57 = load i64, i64* %i2
  %i58 = add i64 %i57, 1
  store i64 %i58, i64* %i2
  %temp60 = load %struct.node*, %struct.node** %temp5
  %temp61 = icmp ne %struct.node* %temp60, null
  br i1 %temp61, label %while.body4, label %while.end8
while.end8:
  %list64 = load %struct.node*, %struct.node** %list6
  call void (%struct.node*) @freeList(%struct.node* %list64)
  %less66 = load %struct.node*, %struct.node** %less3
  %quickSort67 = call %struct.node* (%struct.node*) @quickSort(%struct.node* %less66)
  %greater68 = load %struct.node*, %struct.node** %greater4
  %quickSort69 = call %struct.node* (%struct.node*) @quickSort(%struct.node* %greater68)
  %concatLists70 = call %struct.node* (%struct.node*, %struct.node*) @concatLists(%struct.node* %quickSort67, %struct.node* %quickSort69)
  store %struct.node* %concatLists70, %struct.node** %_0
  br label %exit
exit:
  %_73 = load %struct.node*, %struct.node** %_0
  ret %struct.node* %_73
}

define %struct.node* @quickSortMain(%struct.node* %list) {
entry:
  %_0 = alloca %struct.node*
  %list1 = alloca %struct.node*
  store %struct.node* %list, %struct.node** %list1
  br label %body1
body1:
  %list4 = load %struct.node*, %struct.node** %list1
  call void (%struct.node*) @printList(%struct.node* %list4)
  %_6 = sub i64 0, 999
  %_7 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_8 = call i32 (i8*, ...) @printf(i8* %_7, i64 %_6)
  %list9 = load %struct.node*, %struct.node** %list1
  call void (%struct.node*) @printList(%struct.node* %list9)
  %_11 = sub i64 0, 999
  %_12 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_13 = call i32 (i8*, ...) @printf(i8* %_12, i64 %_11)
  %list14 = load %struct.node*, %struct.node** %list1
  call void (%struct.node*) @printList(%struct.node* %list14)
  %_16 = sub i64 0, 999
  %_17 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_18 = call i32 (i8*, ...) @printf(i8* %_17, i64 %_16)
  store %struct.node* null, %struct.node** %_0
  br label %exit
exit:
  %_21 = load %struct.node*, %struct.node** %_0
  ret %struct.node* %_21
}

define i64 @treesearch(%struct.tnode* %root, i64 %target) {
entry:
  %_0 = alloca i64
  %root1 = alloca %struct.tnode*
  store %struct.tnode* %root, %struct.tnode** %root1
  %target3 = alloca i64
  store i64 %target, i64* %target3
  br label %body1
body1:
  %_6 = sub i64 0, 1
  %_7 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_8 = call i32 (i8*, ...) @printf(i8* %_7, i64 %_6)
  %root9 = load %struct.tnode*, %struct.tnode** %root1
  %root10 = icmp ne %struct.tnode* %root9, null
  br i1 %root10, label %if.then2, label %if.end10
if.then2:
  %root11 = load %struct.tnode*, %struct.tnode** %root1
  %data12 = getelementptr %struct.tnode, %struct.tnode* %root11, i1 0, i32 0
  %data13 = load i64, i64* %data12
  %target14 = load i64, i64* %target3
  %_15 = icmp eq i64 %data13, %target14
  br i1 %_15, label %if.then3, label %if.end4
if.then3:
  store i64 1, i64* %_0
  br label %exit
if.end4:
  %root19 = load %struct.tnode*, %struct.tnode** %root1
  %left20 = getelementptr %struct.tnode, %struct.tnode* %root19, i1 0, i32 1
  %left21 = load %struct.tnode*, %struct.tnode** %left20
  %target22 = load i64, i64* %target3
  %treesearch23 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %left21, i64 %target22)
  %treesearch24 = icmp eq i64 %treesearch23, 1
  br i1 %treesearch24, label %if.then5, label %if.end6
if.then5:
  store i64 1, i64* %_0
  br label %exit
if.end6:
  %root28 = load %struct.tnode*, %struct.tnode** %root1
  %right29 = getelementptr %struct.tnode, %struct.tnode* %root28, i1 0, i32 2
  %right30 = load %struct.tnode*, %struct.tnode** %right29
  %target31 = load i64, i64* %target3
  %treesearch32 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %right30, i64 %target31)
  %treesearch33 = icmp eq i64 %treesearch32, 1
  br i1 %treesearch33, label %if.then7, label %if.else8
if.then7:
  store i64 1, i64* %_0
  br label %exit
if.else8:
  store i64 0, i64* %_0
  br label %exit
if.end9:
  br label %if.end10
if.end10:
  store i64 0, i64* %_0
  br label %exit
exit:
  %_43 = load i64, i64* %_0
  ret i64 %_43
}

define %struct.node* @inOrder(%struct.tnode* %root) {
entry:
  %_0 = alloca %struct.node*
  %temp1 = alloca %struct.node*
  %root2 = alloca %struct.tnode*
  store %struct.tnode* %root, %struct.tnode** %root2
  br label %body1
body1:
  %root5 = load %struct.tnode*, %struct.tnode** %root2
  %root6 = icmp ne %struct.tnode* %root5, null
  br i1 %root6, label %if.then2, label %if.else3
if.then2:
  %node7 = call i8* (i32) @malloc(i32 16)
  %node8 = bitcast i8* %node7 to %struct.node*
  store %struct.node* %node8, %struct.node** %temp1
  %temp10 = load %struct.node*, %struct.node** %temp1
  %data11 = getelementptr %struct.node, %struct.node* %temp10, i1 0, i32 0
  %root12 = load %struct.tnode*, %struct.tnode** %root2
  %data13 = getelementptr %struct.tnode, %struct.tnode* %root12, i1 0, i32 0
  %data14 = load i64, i64* %data13
  store i64 %data14, i64* %data11
  %temp16 = load %struct.node*, %struct.node** %temp1
  %next17 = getelementptr %struct.node, %struct.node* %temp16, i1 0, i32 1
  store %struct.node* null, %struct.node** %next17
  %root19 = load %struct.tnode*, %struct.tnode** %root2
  %left20 = getelementptr %struct.tnode, %struct.tnode* %root19, i1 0, i32 1
  %left21 = load %struct.tnode*, %struct.tnode** %left20
  %inOrder22 = call %struct.node* (%struct.tnode*) @inOrder(%struct.tnode* %left21)
  %temp23 = load %struct.node*, %struct.node** %temp1
  %root24 = load %struct.tnode*, %struct.tnode** %root2
  %right25 = getelementptr %struct.tnode, %struct.tnode* %root24, i1 0, i32 2
  %right26 = load %struct.tnode*, %struct.tnode** %right25
  %inOrder27 = call %struct.node* (%struct.tnode*) @inOrder(%struct.tnode* %right26)
  %concatLists28 = call %struct.node* (%struct.node*, %struct.node*) @concatLists(%struct.node* %temp23, %struct.node* %inOrder27)
  %concatLists29 = call %struct.node* (%struct.node*, %struct.node*) @concatLists(%struct.node* %inOrder22, %struct.node* %concatLists28)
  store %struct.node* %concatLists29, %struct.node** %_0
  br label %exit
if.else3:
  store %struct.node* null, %struct.node** %_0
  br label %exit
if.end4:
  br label %exit
exit:
  %_36 = load %struct.node*, %struct.node** %_0
  ret %struct.node* %_36
}

define i64 @bintreesearch(%struct.tnode* %root, i64 %target) {
entry:
  %_0 = alloca i64
  %root1 = alloca %struct.tnode*
  store %struct.tnode* %root, %struct.tnode** %root1
  %target3 = alloca i64
  store i64 %target, i64* %target3
  br label %body1
body1:
  %_6 = sub i64 0, 1
  %_7 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_8 = call i32 (i8*, ...) @printf(i8* %_7, i64 %_6)
  %root9 = load %struct.tnode*, %struct.tnode** %root1
  %root10 = icmp ne %struct.tnode* %root9, null
  br i1 %root10, label %if.then2, label %if.end8
if.then2:
  %root11 = load %struct.tnode*, %struct.tnode** %root1
  %data12 = getelementptr %struct.tnode, %struct.tnode* %root11, i1 0, i32 0
  %data13 = load i64, i64* %data12
  %target14 = load i64, i64* %target3
  %_15 = icmp eq i64 %data13, %target14
  br i1 %_15, label %if.then3, label %if.end4
if.then3:
  store i64 1, i64* %_0
  br label %exit
if.end4:
  %target19 = load i64, i64* %target3
  %root20 = load %struct.tnode*, %struct.tnode** %root1
  %data21 = getelementptr %struct.tnode, %struct.tnode* %root20, i1 0, i32 0
  %data22 = load i64, i64* %data21
  %_23 = icmp slt i64 %target19, %data22
  br i1 %_23, label %if.then5, label %if.else6
if.then5:
  %root24 = load %struct.tnode*, %struct.tnode** %root1
  %left25 = getelementptr %struct.tnode, %struct.tnode* %root24, i1 0, i32 1
  %left26 = load %struct.tnode*, %struct.tnode** %left25
  %target27 = load i64, i64* %target3
  %bintreesearch28 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %left26, i64 %target27)
  store i64 %bintreesearch28, i64* %_0
  br label %exit
if.else6:
  %root31 = load %struct.tnode*, %struct.tnode** %root1
  %right32 = getelementptr %struct.tnode, %struct.tnode* %root31, i1 0, i32 2
  %right33 = load %struct.tnode*, %struct.tnode** %right32
  %target34 = load i64, i64* %target3
  %bintreesearch35 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %right33, i64 %target34)
  store i64 %bintreesearch35, i64* %_0
  br label %exit
if.end7:
  br label %if.end8
if.end8:
  store i64 0, i64* %_0
  br label %exit
exit:
  %_43 = load i64, i64* %_0
  ret i64 %_43
}

define %struct.tnode* @buildTree(%struct.node* %list) {
entry:
  %_0 = alloca %struct.tnode*
  %i1 = alloca i64
  %root2 = alloca %struct.tnode*
  %list3 = alloca %struct.node*
  store %struct.node* %list, %struct.node** %list3
  br label %body1
body1:
  store %struct.tnode* null, %struct.tnode** %root2
  store i64 0, i64* %i1
  %i8 = load i64, i64* %i1
  %list9 = load %struct.node*, %struct.node** %list3
  %size10 = call i64 (%struct.node*) @size(%struct.node* %list9)
  %_11 = icmp slt i64 %i8, %size10
  br i1 %_11, label %while.body2, label %while.end3
while.body2:
  %root12 = load %struct.tnode*, %struct.tnode** %root2
  %list13 = load %struct.node*, %struct.node** %list3
  %i14 = load i64, i64* %i1
  %get15 = call i64 (%struct.node*, i64) @get(%struct.node* %list13, i64 %i14)
  %treeadd16 = call %struct.tnode* (%struct.tnode*, i64) @treeadd(%struct.tnode* %root12, i64 %get15)
  store %struct.tnode* %treeadd16, %struct.tnode** %root2
  %i18 = load i64, i64* %i1
  %i19 = add i64 %i18, 1
  store i64 %i19, i64* %i1
  %i21 = load i64, i64* %i1
  %list22 = load %struct.node*, %struct.node** %list3
  %size23 = call i64 (%struct.node*) @size(%struct.node* %list22)
  %_24 = icmp slt i64 %i21, %size23
  br i1 %_24, label %while.body2, label %while.end3
while.end3:
  %root27 = load %struct.tnode*, %struct.tnode** %root2
  store %struct.tnode* %root27, %struct.tnode** %_0
  br label %exit
exit:
  %_30 = load %struct.tnode*, %struct.tnode** %_0
  ret %struct.tnode* %_30
}

define void @treeMain(%struct.node* %list) {
entry:
  %root0 = alloca %struct.tnode*
  %inList1 = alloca %struct.node*
  %postList2 = alloca %struct.node*
  %list3 = alloca %struct.node*
  store %struct.node* %list, %struct.node** %list3
  br label %body1
body1:
  %list6 = load %struct.node*, %struct.node** %list3
  %buildTree7 = call %struct.tnode* (%struct.node*) @buildTree(%struct.node* %list6)
  store %struct.tnode* %buildTree7, %struct.tnode** %root0
  %root9 = load %struct.tnode*, %struct.tnode** %root0
  call void (%struct.tnode*) @treeprint(%struct.tnode* %root9)
  %_11 = sub i64 0, 999
  %_12 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_13 = call i32 (i8*, ...) @printf(i8* %_12, i64 %_11)
  %root14 = load %struct.tnode*, %struct.tnode** %root0
  %inOrder15 = call %struct.node* (%struct.tnode*) @inOrder(%struct.tnode* %root14)
  store %struct.node* %inOrder15, %struct.node** %inList1
  %inList17 = load %struct.node*, %struct.node** %inList1
  call void (%struct.node*) @printList(%struct.node* %inList17)
  %_19 = sub i64 0, 999
  %_20 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_21 = call i32 (i8*, ...) @printf(i8* %_20, i64 %_19)
  %inList22 = load %struct.node*, %struct.node** %inList1
  call void (%struct.node*) @freeList(%struct.node* %inList22)
  %root24 = load %struct.tnode*, %struct.tnode** %root0
  %postOrder25 = call %struct.node* (%struct.tnode*) @postOrder(%struct.tnode* %root24)
  store %struct.node* %postOrder25, %struct.node** %postList2
  %postList27 = load %struct.node*, %struct.node** %postList2
  call void (%struct.node*) @printList(%struct.node* %postList27)
  %_29 = sub i64 0, 999
  %_30 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_31 = call i32 (i8*, ...) @printf(i8* %_30, i64 %_29)
  %postList32 = load %struct.node*, %struct.node** %postList2
  call void (%struct.node*) @freeList(%struct.node* %postList32)
  %root34 = load %struct.tnode*, %struct.tnode** %root0
  %treesearch35 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %root34, i64 0)
  %_36 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_37 = call i32 (i8*, ...) @printf(i8* %_36, i64 %treesearch35)
  %_38 = sub i64 0, 999
  %_39 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_40 = call i32 (i8*, ...) @printf(i8* %_39, i64 %_38)
  %root41 = load %struct.tnode*, %struct.tnode** %root0
  %treesearch42 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %root41, i64 10)
  %_43 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_44 = call i32 (i8*, ...) @printf(i8* %_43, i64 %treesearch42)
  %_45 = sub i64 0, 999
  %_46 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_47 = call i32 (i8*, ...) @printf(i8* %_46, i64 %_45)
  %root48 = load %struct.tnode*, %struct.tnode** %root0
  %_49 = sub i64 0, 2
  %treesearch50 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %root48, i64 %_49)
  %_51 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_52 = call i32 (i8*, ...) @printf(i8* %_51, i64 %treesearch50)
  %_53 = sub i64 0, 999
  %_54 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_55 = call i32 (i8*, ...) @printf(i8* %_54, i64 %_53)
  %root56 = load %struct.tnode*, %struct.tnode** %root0
  %treesearch57 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %root56, i64 2)
  %_58 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_59 = call i32 (i8*, ...) @printf(i8* %_58, i64 %treesearch57)
  %_60 = sub i64 0, 999
  %_61 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_62 = call i32 (i8*, ...) @printf(i8* %_61, i64 %_60)
  %root63 = load %struct.tnode*, %struct.tnode** %root0
  %treesearch64 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %root63, i64 3)
  %_65 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_66 = call i32 (i8*, ...) @printf(i8* %_65, i64 %treesearch64)
  %_67 = sub i64 0, 999
  %_68 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_69 = call i32 (i8*, ...) @printf(i8* %_68, i64 %_67)
  %root70 = load %struct.tnode*, %struct.tnode** %root0
  %treesearch71 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %root70, i64 9)
  %_72 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_73 = call i32 (i8*, ...) @printf(i8* %_72, i64 %treesearch71)
  %_74 = sub i64 0, 999
  %_75 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_76 = call i32 (i8*, ...) @printf(i8* %_75, i64 %_74)
  %root77 = load %struct.tnode*, %struct.tnode** %root0
  %treesearch78 = call i64 (%struct.tnode*, i64) @treesearch(%struct.tnode* %root77, i64 1)
  %_79 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_80 = call i32 (i8*, ...) @printf(i8* %_79, i64 %treesearch78)
  %_81 = sub i64 0, 999
  %_82 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_83 = call i32 (i8*, ...) @printf(i8* %_82, i64 %_81)
  %root84 = load %struct.tnode*, %struct.tnode** %root0
  %bintreesearch85 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %root84, i64 0)
  %_86 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_87 = call i32 (i8*, ...) @printf(i8* %_86, i64 %bintreesearch85)
  %_88 = sub i64 0, 999
  %_89 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_90 = call i32 (i8*, ...) @printf(i8* %_89, i64 %_88)
  %root91 = load %struct.tnode*, %struct.tnode** %root0
  %bintreesearch92 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %root91, i64 10)
  %_93 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_94 = call i32 (i8*, ...) @printf(i8* %_93, i64 %bintreesearch92)
  %_95 = sub i64 0, 999
  %_96 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_97 = call i32 (i8*, ...) @printf(i8* %_96, i64 %_95)
  %root98 = load %struct.tnode*, %struct.tnode** %root0
  %_99 = sub i64 0, 2
  %bintreesearch100 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %root98, i64 %_99)
  %_101 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_102 = call i32 (i8*, ...) @printf(i8* %_101, i64 %bintreesearch100)
  %_103 = sub i64 0, 999
  %_104 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_105 = call i32 (i8*, ...) @printf(i8* %_104, i64 %_103)
  %root106 = load %struct.tnode*, %struct.tnode** %root0
  %bintreesearch107 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %root106, i64 2)
  %_108 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_109 = call i32 (i8*, ...) @printf(i8* %_108, i64 %bintreesearch107)
  %_110 = sub i64 0, 999
  %_111 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_112 = call i32 (i8*, ...) @printf(i8* %_111, i64 %_110)
  %root113 = load %struct.tnode*, %struct.tnode** %root0
  %bintreesearch114 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %root113, i64 3)
  %_115 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_116 = call i32 (i8*, ...) @printf(i8* %_115, i64 %bintreesearch114)
  %_117 = sub i64 0, 999
  %_118 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_119 = call i32 (i8*, ...) @printf(i8* %_118, i64 %_117)
  %root120 = load %struct.tnode*, %struct.tnode** %root0
  %bintreesearch121 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %root120, i64 9)
  %_122 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_123 = call i32 (i8*, ...) @printf(i8* %_122, i64 %bintreesearch121)
  %_124 = sub i64 0, 999
  %_125 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_126 = call i32 (i8*, ...) @printf(i8* %_125, i64 %_124)
  %root127 = load %struct.tnode*, %struct.tnode** %root0
  %bintreesearch128 = call i64 (%struct.tnode*, i64) @bintreesearch(%struct.tnode* %root127, i64 1)
  %_129 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_130 = call i32 (i8*, ...) @printf(i8* %_129, i64 %bintreesearch128)
  %_131 = sub i64 0, 999
  %_132 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_133 = call i32 (i8*, ...) @printf(i8* %_132, i64 %_131)
  %root134 = load %struct.tnode*, %struct.tnode** %root0
  call void (%struct.tnode*) @freeTree(%struct.tnode* %root134)
  br label %exit
exit:
  ret void
}

define %struct.node* @myCopy(%struct.node* %src) {
entry:
  %_0 = alloca %struct.node*
  %src1 = alloca %struct.node*
  store %struct.node* %src, %struct.node** %src1
  br label %body1
body1:
  %src4 = load %struct.node*, %struct.node** %src1
  %src5 = icmp eq %struct.node* %src4, null
  br i1 %src5, label %if.then2, label %if.end3
if.then2:
  store %struct.node* null, %struct.node** %_0
  br label %exit
if.end3:
  %src9 = load %struct.node*, %struct.node** %src1
  %data10 = getelementptr %struct.node, %struct.node* %src9, i1 0, i32 0
  %data11 = load i64, i64* %data10
  %add12 = call %struct.node* (%struct.node*, i64) @add(%struct.node* null, i64 %data11)
  %src13 = load %struct.node*, %struct.node** %src1
  %next14 = getelementptr %struct.node, %struct.node* %src13, i1 0, i32 1
  %next15 = load %struct.node*, %struct.node** %next14
  %myCopy16 = call %struct.node* (%struct.node*) @myCopy(%struct.node* %next15)
  %concatLists17 = call %struct.node* (%struct.node*, %struct.node*) @concatLists(%struct.node* %add12, %struct.node* %myCopy16)
  store %struct.node* %concatLists17, %struct.node** %_0
  br label %exit
exit:
  %_20 = load %struct.node*, %struct.node** %_0
  ret %struct.node* %_20
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %i1 = alloca i64
  %element2 = alloca i64
  %myList3 = alloca %struct.node*
  %copyList14 = alloca %struct.node*
  %copyList25 = alloca %struct.node*
  %sortedList6 = alloca %struct.node*
  br label %body1
body1:
  store %struct.node* null, %struct.node** %myList3
  store %struct.node* null, %struct.node** %copyList14
  store %struct.node* null, %struct.node** %copyList25
  store i64 0, i64* %i1
  %i12 = load i64, i64* %i1
  %i13 = icmp slt i64 %i12, 10
  br i1 %i13, label %while.body2, label %while.end3
while.body2:
  %_14 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_15 = call i32 (i8*, ...) @scanf(i8* %_14, i32* @.read_scratch)
  %_16 = load i32, i32* @.read_scratch
  %_17 = sext i32 %_16 to i64
  store i64 %_17, i64* %element2
  %myList19 = load %struct.node*, %struct.node** %myList3
  %element20 = load i64, i64* %element2
  %add21 = call %struct.node* (%struct.node*, i64) @add(%struct.node* %myList19, i64 %element20)
  store %struct.node* %add21, %struct.node** %myList3
  %myList23 = load %struct.node*, %struct.node** %myList3
  %myCopy24 = call %struct.node* (%struct.node*) @myCopy(%struct.node* %myList23)
  store %struct.node* %myCopy24, %struct.node** %copyList14
  %myList26 = load %struct.node*, %struct.node** %myList3
  %myCopy27 = call %struct.node* (%struct.node*) @myCopy(%struct.node* %myList26)
  store %struct.node* %myCopy27, %struct.node** %copyList25
  %copyList129 = load %struct.node*, %struct.node** %copyList14
  %quickSortMain30 = call %struct.node* (%struct.node*) @quickSortMain(%struct.node* %copyList129)
  store %struct.node* %quickSortMain30, %struct.node** %sortedList6
  %sortedList32 = load %struct.node*, %struct.node** %sortedList6
  call void (%struct.node*) @freeList(%struct.node* %sortedList32)
  %copyList234 = load %struct.node*, %struct.node** %copyList25
  call void (%struct.node*) @treeMain(%struct.node* %copyList234)
  %i36 = load i64, i64* %i1
  %i37 = add i64 %i36, 1
  store i64 %i37, i64* %i1
  %i39 = load i64, i64* %i1
  %i40 = icmp slt i64 %i39, 10
  br i1 %i40, label %while.body2, label %while.end3
while.end3:
  %myList43 = load %struct.node*, %struct.node** %myList3
  call void (%struct.node*) @freeList(%struct.node* %myList43)
  %copyList145 = load %struct.node*, %struct.node** %copyList14
  call void (%struct.node*) @freeList(%struct.node* %copyList145)
  %copyList247 = load %struct.node*, %struct.node** %copyList25
  call void (%struct.node*) @freeList(%struct.node* %copyList247)
  store i64 0, i64* %_0
  br label %exit
exit:
  %_51 = load i64, i64* %_0
  ret i64 %_51
}

