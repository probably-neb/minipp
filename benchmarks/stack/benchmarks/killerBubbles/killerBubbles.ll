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
  %_0 = alloca i64
  %a1 = alloca %struct.Node*
  store %struct.Node* %a, %struct.Node** %a1
  %b3 = alloca %struct.Node*
  store %struct.Node* %b, %struct.Node** %b3
  br label %body1
body1:
  %a6 = load %struct.Node*, %struct.Node** %a1
  %val7 = getelementptr %struct.Node, %struct.Node* %a6, i1 0, i32 0
  %val8 = load i64, i64* %val7
  %b9 = load %struct.Node*, %struct.Node** %b3
  %val10 = getelementptr %struct.Node, %struct.Node* %b9, i1 0, i32 0
  %val11 = load i64, i64* %val10
  %_12 = sub i64 %val8, %val11
  store i64 %_12, i64* %_0
  br label %exit
exit:
  %_15 = load i64, i64* %_0
  ret i64 %_15
}

define void @deathSort(%struct.Node* %head) {
entry:
  %swapped0 = alloca i64
  %swap1 = alloca i64
  %currNode2 = alloca %struct.Node*
  %head3 = alloca %struct.Node*
  store %struct.Node* %head, %struct.Node** %head3
  br label %body1
body1:
  store i64 1, i64* %swapped0
  %swapped7 = load i64, i64* %swapped0
  %swapped8 = icmp eq i64 %swapped7, 1
  br i1 %swapped8, label %while.body2, label %while.end7
while.body2:
  store i64 0, i64* %swapped0
  %head10 = load %struct.Node*, %struct.Node** %head3
  store %struct.Node* %head10, %struct.Node** %currNode2
  %currNode12 = load %struct.Node*, %struct.Node** %currNode2
  %next13 = getelementptr %struct.Node, %struct.Node* %currNode12, i1 0, i32 2
  %next14 = load %struct.Node*, %struct.Node** %next13
  %head15 = load %struct.Node*, %struct.Node** %head3
  %_16 = icmp ne %struct.Node* %next14, %head15
  br i1 %_16, label %while.body3, label %while.end6
while.body3:
  %currNode17 = load %struct.Node*, %struct.Node** %currNode2
  %currNode18 = load %struct.Node*, %struct.Node** %currNode2
  %next19 = getelementptr %struct.Node, %struct.Node* %currNode18, i1 0, i32 2
  %next20 = load %struct.Node*, %struct.Node** %next19
  %compare21 = call i64 (%struct.Node*, %struct.Node*) @compare(%struct.Node* %currNode17, %struct.Node* %next20)
  %compare22 = icmp sgt i64 %compare21, 0
  br i1 %compare22, label %if.then4, label %if.end5
if.then4:
  %currNode23 = load %struct.Node*, %struct.Node** %currNode2
  %val24 = getelementptr %struct.Node, %struct.Node* %currNode23, i1 0, i32 0
  %val25 = load i64, i64* %val24
  store i64 %val25, i64* %swap1
  %currNode27 = load %struct.Node*, %struct.Node** %currNode2
  %val28 = getelementptr %struct.Node, %struct.Node* %currNode27, i1 0, i32 0
  %currNode29 = load %struct.Node*, %struct.Node** %currNode2
  %next30 = getelementptr %struct.Node, %struct.Node* %currNode29, i1 0, i32 2
  %Node31 = load %struct.Node*, %struct.Node** %next30
  %val32 = getelementptr %struct.Node, %struct.Node* %Node31, i1 0, i32 0
  %val33 = load i64, i64* %val32
  store i64 %val33, i64* %val28
  %currNode35 = load %struct.Node*, %struct.Node** %currNode2
  %next36 = getelementptr %struct.Node, %struct.Node* %currNode35, i1 0, i32 2
  %Node37 = load %struct.Node*, %struct.Node** %next36
  %val38 = getelementptr %struct.Node, %struct.Node* %Node37, i1 0, i32 0
  %swap39 = load i64, i64* %swap1
  store i64 %swap39, i64* %val38
  store i64 1, i64* %swapped0
  br label %if.end5
if.end5:
  %currNode44 = load %struct.Node*, %struct.Node** %currNode2
  %next45 = getelementptr %struct.Node, %struct.Node* %currNode44, i1 0, i32 2
  %next46 = load %struct.Node*, %struct.Node** %next45
  store %struct.Node* %next46, %struct.Node** %currNode2
  %currNode48 = load %struct.Node*, %struct.Node** %currNode2
  %next49 = getelementptr %struct.Node, %struct.Node* %currNode48, i1 0, i32 2
  %next50 = load %struct.Node*, %struct.Node** %next49
  %head51 = load %struct.Node*, %struct.Node** %head3
  %_52 = icmp ne %struct.Node* %next50, %head51
  br i1 %_52, label %while.body3, label %while.end6
while.end6:
  %swapped55 = load i64, i64* %swapped0
  %swapped56 = icmp eq i64 %swapped55, 1
  br i1 %swapped56, label %while.body2, label %while.end7
while.end7:
  br label %exit
exit:
  ret void
}

define void @printEVILList(%struct.Node* %head) {
entry:
  %currNode0 = alloca %struct.Node*
  %toFree1 = alloca %struct.Node*
  %head2 = alloca %struct.Node*
  store %struct.Node* %head, %struct.Node** %head2
  br label %body1
body1:
  %head5 = load %struct.Node*, %struct.Node** %head2
  %next6 = getelementptr %struct.Node, %struct.Node* %head5, i1 0, i32 2
  %next7 = load %struct.Node*, %struct.Node** %next6
  store %struct.Node* %next7, %struct.Node** %currNode0
  %head9 = load %struct.Node*, %struct.Node** %head2
  %val10 = getelementptr %struct.Node, %struct.Node* %head9, i1 0, i32 0
  %val11 = load i64, i64* %val10
  %_12 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_13 = call i32 (i8*, ...) @printf(i8* %_12, i64 %val11)
  %head14 = load %struct.Node*, %struct.Node** %head2
  %_15 = bitcast %struct.Node* %head14 to i8*
  call void (i8*) @free(i8* %_15)
  %currNode17 = load %struct.Node*, %struct.Node** %currNode0
  %head18 = load %struct.Node*, %struct.Node** %head2
  %_19 = icmp ne %struct.Node* %currNode17, %head18
  br i1 %_19, label %while.body2, label %while.end3
while.body2:
  %currNode20 = load %struct.Node*, %struct.Node** %currNode0
  store %struct.Node* %currNode20, %struct.Node** %toFree1
  %currNode22 = load %struct.Node*, %struct.Node** %currNode0
  %val23 = getelementptr %struct.Node, %struct.Node* %currNode22, i1 0, i32 0
  %val24 = load i64, i64* %val23
  %_25 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_26 = call i32 (i8*, ...) @printf(i8* %_25, i64 %val24)
  %currNode27 = load %struct.Node*, %struct.Node** %currNode0
  %next28 = getelementptr %struct.Node, %struct.Node* %currNode27, i1 0, i32 2
  %next29 = load %struct.Node*, %struct.Node** %next28
  store %struct.Node* %next29, %struct.Node** %currNode0
  %toFree31 = load %struct.Node*, %struct.Node** %toFree1
  %_32 = bitcast %struct.Node* %toFree31 to i8*
  call void (i8*) @free(i8* %_32)
  %currNode34 = load %struct.Node*, %struct.Node** %currNode0
  %head35 = load %struct.Node*, %struct.Node** %head2
  %_36 = icmp ne %struct.Node* %currNode34, %head35
  br i1 %_36, label %while.body2, label %while.end3
while.end3:
  br label %exit
exit:
  ret void
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %numNodes1 = alloca i64
  %counter2 = alloca i64
  %currNode3 = alloca %struct.Node*
  %head4 = alloca %struct.Node*
  %previous5 = alloca %struct.Node*
  br label %body1
body1:
  store i64 666, i64* @swapped
  %_8 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_9 = call i32 (i8*, ...) @scanf(i8* %_8, i32* @.read_scratch)
  %_10 = load i32, i32* @.read_scratch
  %_11 = sext i32 %_10 to i64
  store i64 %_11, i64* %numNodes1
  %numNodes13 = load i64, i64* %numNodes1
  %numNodes14 = icmp sle i64 %numNodes13, 0
  br i1 %numNodes14, label %if.then2, label %if.end3
if.then2:
  %_15 = sub i64 0, 1
  %_16 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_17 = call i32 (i8*, ...) @printf(i8* %_16, i64 %_15)
  %_18 = sub i64 0, 1
  store i64 %_18, i64* %_0
  br label %exit
if.end3:
  %numNodes22 = load i64, i64* %numNodes1
  %numNodes23 = mul i64 %numNodes22, 1000
  store i64 %numNodes23, i64* %numNodes1
  %numNodes25 = load i64, i64* %numNodes1
  store i64 %numNodes25, i64* %counter2
  %Node27 = call i8* (i32) @malloc(i32 24)
  %Node28 = bitcast i8* %Node27 to %struct.Node*
  store %struct.Node* %Node28, %struct.Node** %head4
  %head30 = load %struct.Node*, %struct.Node** %head4
  %val31 = getelementptr %struct.Node, %struct.Node* %head30, i1 0, i32 0
  %counter32 = load i64, i64* %counter2
  store i64 %counter32, i64* %val31
  %head34 = load %struct.Node*, %struct.Node** %head4
  %prev35 = getelementptr %struct.Node, %struct.Node* %head34, i1 0, i32 1
  %head36 = load %struct.Node*, %struct.Node** %head4
  store %struct.Node* %head36, %struct.Node** %prev35
  %head38 = load %struct.Node*, %struct.Node** %head4
  %next39 = getelementptr %struct.Node, %struct.Node* %head38, i1 0, i32 2
  %head40 = load %struct.Node*, %struct.Node** %head4
  store %struct.Node* %head40, %struct.Node** %next39
  %counter42 = load i64, i64* %counter2
  %counter43 = sub i64 %counter42, 1
  store i64 %counter43, i64* %counter2
  %head45 = load %struct.Node*, %struct.Node** %head4
  store %struct.Node* %head45, %struct.Node** %previous5
  %counter47 = load i64, i64* %counter2
  %counter48 = icmp sgt i64 %counter47, 0
  br i1 %counter48, label %while.body4, label %while.end5
while.body4:
  %Node49 = call i8* (i32) @malloc(i32 24)
  %Node50 = bitcast i8* %Node49 to %struct.Node*
  store %struct.Node* %Node50, %struct.Node** %currNode3
  %currNode52 = load %struct.Node*, %struct.Node** %currNode3
  %val53 = getelementptr %struct.Node, %struct.Node* %currNode52, i1 0, i32 0
  %counter54 = load i64, i64* %counter2
  store i64 %counter54, i64* %val53
  %currNode56 = load %struct.Node*, %struct.Node** %currNode3
  %prev57 = getelementptr %struct.Node, %struct.Node* %currNode56, i1 0, i32 1
  %previous58 = load %struct.Node*, %struct.Node** %previous5
  store %struct.Node* %previous58, %struct.Node** %prev57
  %currNode60 = load %struct.Node*, %struct.Node** %currNode3
  %next61 = getelementptr %struct.Node, %struct.Node* %currNode60, i1 0, i32 2
  %head62 = load %struct.Node*, %struct.Node** %head4
  store %struct.Node* %head62, %struct.Node** %next61
  %previous64 = load %struct.Node*, %struct.Node** %previous5
  %next65 = getelementptr %struct.Node, %struct.Node* %previous64, i1 0, i32 2
  %currNode66 = load %struct.Node*, %struct.Node** %currNode3
  store %struct.Node* %currNode66, %struct.Node** %next65
  %currNode68 = load %struct.Node*, %struct.Node** %currNode3
  store %struct.Node* %currNode68, %struct.Node** %previous5
  %counter70 = load i64, i64* %counter2
  %counter71 = sub i64 %counter70, 1
  store i64 %counter71, i64* %counter2
  %counter73 = load i64, i64* %counter2
  %counter74 = icmp sgt i64 %counter73, 0
  br i1 %counter74, label %while.body4, label %while.end5
while.end5:
  %head77 = load %struct.Node*, %struct.Node** %head4
  call void (%struct.Node*) @deathSort(%struct.Node* %head77)
  %head79 = load %struct.Node*, %struct.Node** %head4
  call void (%struct.Node*) @printEVILList(%struct.Node* %head79)
  store i64 0, i64* %_0
  br label %exit
exit:
  %_83 = load i64, i64* %_0
  ret i64 %_83
}

