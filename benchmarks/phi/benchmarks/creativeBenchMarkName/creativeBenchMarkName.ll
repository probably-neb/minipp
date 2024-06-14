%struct.node = type { i64, %struct.node* }

declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

define %struct.node* @buildList() {
entry:
  br label %body0
body0:
  %node.malloc2 = call i8* (i32) @malloc(i32 16)
  %n03 = bitcast i8* %node.malloc2 to %struct.node*
  %node.malloc4 = call i8* (i32) @malloc(i32 16)
  %n15 = bitcast i8* %node.malloc4 to %struct.node*
  %node.malloc6 = call i8* (i32) @malloc(i32 16)
  %n27 = bitcast i8* %node.malloc6 to %struct.node*
  %node.malloc8 = call i8* (i32) @malloc(i32 16)
  %n39 = bitcast i8* %node.malloc8 to %struct.node*
  %node.malloc10 = call i8* (i32) @malloc(i32 16)
  %n411 = bitcast i8* %node.malloc10 to %struct.node*
  %node.malloc12 = call i8* (i32) @malloc(i32 16)
  %n513 = bitcast i8* %node.malloc12 to %struct.node*
  %_14 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_15 = call i32 (i8*, ...) @scanf(i8* %_14, i32* @.read_scratch)
  %_16 = load i32, i32* @.read_scratch
  %_17 = sext i32 %_16 to i64
  %n0.value_auf18 = getelementptr %struct.node, %struct.node* %n03, i1 0, i32 0
  store i64 %_17, i64* %n0.value_auf18
  %_20 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_21 = call i32 (i8*, ...) @scanf(i8* %_20, i32* @.read_scratch)
  %_22 = load i32, i32* @.read_scratch
  %_23 = sext i32 %_22 to i64
  %n1.value_auf24 = getelementptr %struct.node, %struct.node* %n15, i1 0, i32 0
  store i64 %_23, i64* %n1.value_auf24
  %_26 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_27 = call i32 (i8*, ...) @scanf(i8* %_26, i32* @.read_scratch)
  %_28 = load i32, i32* @.read_scratch
  %_29 = sext i32 %_28 to i64
  %n2.value_auf30 = getelementptr %struct.node, %struct.node* %n27, i1 0, i32 0
  store i64 %_29, i64* %n2.value_auf30
  %_32 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_33 = call i32 (i8*, ...) @scanf(i8* %_32, i32* @.read_scratch)
  %_34 = load i32, i32* @.read_scratch
  %_35 = sext i32 %_34 to i64
  %n3.value_auf36 = getelementptr %struct.node, %struct.node* %n39, i1 0, i32 0
  store i64 %_35, i64* %n3.value_auf36
  %_38 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_39 = call i32 (i8*, ...) @scanf(i8* %_38, i32* @.read_scratch)
  %_40 = load i32, i32* @.read_scratch
  %_41 = sext i32 %_40 to i64
  %n4.value_auf42 = getelementptr %struct.node, %struct.node* %n411, i1 0, i32 0
  store i64 %_41, i64* %n4.value_auf42
  %_44 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_45 = call i32 (i8*, ...) @scanf(i8* %_44, i32* @.read_scratch)
  %_46 = load i32, i32* @.read_scratch
  %_47 = sext i32 %_46 to i64
  %n5.value_auf48 = getelementptr %struct.node, %struct.node* %n513, i1 0, i32 0
  store i64 %_47, i64* %n5.value_auf48
  %n0.next_auf50 = getelementptr %struct.node, %struct.node* %n03, i1 0, i32 1
  store %struct.node* %n15, %struct.node** %n0.next_auf50
  %n1.next_auf52 = getelementptr %struct.node, %struct.node* %n15, i1 0, i32 1
  store %struct.node* %n27, %struct.node** %n1.next_auf52
  %n2.next_auf54 = getelementptr %struct.node, %struct.node* %n27, i1 0, i32 1
  store %struct.node* %n39, %struct.node** %n2.next_auf54
  %n3.next_auf56 = getelementptr %struct.node, %struct.node* %n39, i1 0, i32 1
  store %struct.node* %n411, %struct.node** %n3.next_auf56
  %n4.next_auf58 = getelementptr %struct.node, %struct.node* %n411, i1 0, i32 1
  store %struct.node* %n513, %struct.node** %n4.next_auf58
  %n5.next_auf60 = getelementptr %struct.node, %struct.node* %n513, i1 0, i32 1
  store %struct.node* null, %struct.node** %n5.next_auf60
  br label %exit
exit:
  %return_reg62 = phi %struct.node* [ %n03, %body0 ]
  ret %struct.node* %return_reg62
}

define i64 @multiple(%struct.node* %list) {
entry:
  br label %body0
body0:
  %i9 = add i64 0, 0
  %cur.value_auf10 = getelementptr %struct.node, %struct.node* %list, i1 0, i32 0
  %product11 = load i64, i64* %cur.value_auf10
  %cur.next_auf12 = getelementptr %struct.node, %struct.node* %list, i1 0, i32 1
  %_13 = load %struct.node*, %struct.node** %cur.next_auf12
  br label %while.cond11
while.cond11:
  %imm_store15 = add i64 5, 0
  %_16 = icmp slt i64 %i9, %imm_store15
  br i1 %_16, label %while.body2, label %while.exit5
while.body2:
  %i1 = phi i64 [ %i9, %while.cond11 ], [ %i26, %while.fillback4 ]
  %cur3 = phi %struct.node* [ %_13, %while.cond11 ], [ %cur22, %while.fillback4 ]
  %product5 = phi i64 [ %product11, %while.cond11 ], [ %product20, %while.fillback4 ]
  %cur.value_auf18 = getelementptr %struct.node, %struct.node* %cur3, i1 0, i32 0
  %_19 = load i64, i64* %cur.value_auf18
  %product20 = mul i64 %product5, %_19
  %cur.next_auf21 = getelementptr %struct.node, %struct.node* %cur3, i1 0, i32 1
  %cur22 = load %struct.node*, %struct.node** %cur.next_auf21
  %_23 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_24 = call i32 (i8*, ...) @printf(i8* %_23, i64 %product20)
  %imm_store25 = add i64 1, 0
  %i26 = add i64 %i1, %imm_store25
  br label %while.cond23
while.cond23:
  %imm_store28 = add i64 5, 0
  %_29 = icmp slt i64 %i26, %imm_store28
  br i1 %_29, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %i2 = phi i64 [ %i9, %while.cond11 ], [ %i26, %while.cond23 ]
  %cur4 = phi %struct.node* [ %_13, %while.cond11 ], [ %cur22, %while.cond23 ]
  %product6 = phi i64 [ %product11, %while.cond11 ], [ %product20, %while.cond23 ]
  br label %exit
exit:
  %return_reg32 = phi i64 [ %product6, %while.exit5 ]
  ret i64 %return_reg32
}

define i64 @add(%struct.node* %list) {
entry:
  br label %body0
body0:
  %i9 = add i64 0, 0
  %cur.value_auf10 = getelementptr %struct.node, %struct.node* %list, i1 0, i32 0
  %sum11 = load i64, i64* %cur.value_auf10
  %cur.next_auf12 = getelementptr %struct.node, %struct.node* %list, i1 0, i32 1
  %_13 = load %struct.node*, %struct.node** %cur.next_auf12
  br label %while.cond11
while.cond11:
  %imm_store15 = add i64 5, 0
  %_16 = icmp slt i64 %i9, %imm_store15
  br i1 %_16, label %while.body2, label %while.exit5
while.body2:
  %i1 = phi i64 [ %i9, %while.cond11 ], [ %i26, %while.fillback4 ]
  %cur3 = phi %struct.node* [ %_13, %while.cond11 ], [ %cur22, %while.fillback4 ]
  %sum5 = phi i64 [ %sum11, %while.cond11 ], [ %sum20, %while.fillback4 ]
  %cur.value_auf18 = getelementptr %struct.node, %struct.node* %cur3, i1 0, i32 0
  %_19 = load i64, i64* %cur.value_auf18
  %sum20 = add i64 %sum5, %_19
  %cur.next_auf21 = getelementptr %struct.node, %struct.node* %cur3, i1 0, i32 1
  %cur22 = load %struct.node*, %struct.node** %cur.next_auf21
  %_23 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_24 = call i32 (i8*, ...) @printf(i8* %_23, i64 %sum20)
  %imm_store25 = add i64 1, 0
  %i26 = add i64 %i1, %imm_store25
  br label %while.cond23
while.cond23:
  %imm_store28 = add i64 5, 0
  %_29 = icmp slt i64 %i26, %imm_store28
  br i1 %_29, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %i2 = phi i64 [ %i9, %while.cond11 ], [ %i26, %while.cond23 ]
  %cur4 = phi %struct.node* [ %_13, %while.cond11 ], [ %cur22, %while.cond23 ]
  %sum6 = phi i64 [ %sum11, %while.cond11 ], [ %sum20, %while.cond23 ]
  br label %exit
exit:
  %return_reg32 = phi i64 [ %sum6, %while.exit5 ]
  ret i64 %return_reg32
}

define i64 @recurseList(%struct.node* %list) {
entry:
  br label %body0
body0:
  br label %if.cond1
if.cond1:
  %list.next_auf4 = getelementptr %struct.node, %struct.node* %list, i1 0, i32 1
  %_5 = load %struct.node*, %struct.node** %list.next_auf4
  %_6 = icmp eq %struct.node* %_5, null
  br i1 %_6, label %then.body2, label %else.body3
then.body2:
  %list.value_auf8 = getelementptr %struct.node, %struct.node* %list, i1 0, i32 0
  %_9 = load i64, i64* %list.value_auf8
  br label %exit
else.body3:
  %list.value_auf12 = getelementptr %struct.node, %struct.node* %list, i1 0, i32 0
  %_13 = load i64, i64* %list.value_auf12
  %list.next_auf14 = getelementptr %struct.node, %struct.node* %list, i1 0, i32 1
  %_15 = load %struct.node*, %struct.node** %list.next_auf14
  %aufrufen_recurseList16 = call i64 (%struct.node*) @recurseList(%struct.node* %_15)
  %tmp.binop17 = mul i64 %_13, %aufrufen_recurseList16
  br label %exit
exit:
  %return_reg10 = phi i64 [ %_9, %then.body2 ], [ %tmp.binop17, %else.body3 ]
  ret i64 %return_reg10
}

define i64 @main() {
entry:
  br label %body0
body0:
  %i10 = add i64 0, 0
  %bigProduct11 = add i64 0, 0
  %list12 = call %struct.node* () @buildList()
  %product13 = call i64 (%struct.node*) @multiple(%struct.node* %list12)
  %sum14 = call i64 (%struct.node*) @add(%struct.node* %list12)
  %imm_store15 = add i64 2, 0
  %tmp.binop16 = sdiv i64 %sum14, %imm_store15
  %result17 = sub i64 %product13, %tmp.binop16
  br label %while.cond11
while.cond11:
  %imm_store19 = add i64 2, 0
  %_20 = icmp slt i64 %i10, %imm_store19
  br i1 %_20, label %while.body2, label %while.exit5
while.body2:
  %i0 = phi i64 [ %i10, %while.cond11 ], [ %i25, %while.fillback4 ]
  %list2 = phi %struct.node* [ %list12, %while.cond11 ], [ %list2, %while.fillback4 ]
  %bigProduct6 = phi i64 [ %bigProduct11, %while.cond11 ], [ %bigProduct23, %while.fillback4 ]
  %aufrufen_recurseList22 = call i64 (%struct.node*) @recurseList(%struct.node* %list2)
  %bigProduct23 = add i64 %bigProduct6, %aufrufen_recurseList22
  %imm_store24 = add i64 1, 0
  %i25 = add i64 %i0, %imm_store24
  br label %while.cond23
while.cond23:
  %imm_store27 = add i64 2, 0
  %_28 = icmp slt i64 %i25, %imm_store27
  br i1 %_28, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %i1 = phi i64 [ %i10, %while.cond11 ], [ %i25, %while.cond23 ]
  %list3 = phi %struct.node* [ %list12, %while.cond11 ], [ %list2, %while.cond23 ]
  %bigProduct7 = phi i64 [ %bigProduct11, %while.cond11 ], [ %bigProduct23, %while.cond23 ]
  %_31 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_32 = call i32 (i8*, ...) @printf(i8* %_31, i64 %bigProduct7)
  br label %while.cond16
while.cond16:
  %imm_store34 = add i64 0, 0
  %_35 = icmp ne i64 %bigProduct7, %imm_store34
  br i1 %_35, label %while.body7, label %while.exit10
while.body7:
  %bigProduct4 = phi i64 [ %bigProduct7, %while.cond16 ], [ %bigProduct38, %while.fillback9 ]
  %imm_store37 = add i64 1, 0
  %bigProduct38 = sub i64 %bigProduct4, %imm_store37
  br label %while.cond28
while.cond28:
  %imm_store40 = add i64 0, 0
  %_41 = icmp ne i64 %bigProduct38, %imm_store40
  br i1 %_41, label %while.fillback9, label %while.exit10
while.fillback9:
  br label %while.body7
while.exit10:
  %bigProduct5 = phi i64 [ %bigProduct7, %while.cond16 ], [ %bigProduct38, %while.cond28 ]
  %_44 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_45 = call i32 (i8*, ...) @printf(i8* %_44, i64 %result17)
  %_46 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_47 = call i32 (i8*, ...) @printf(i8* %_46, i64 %bigProduct5)
  %imm_store48 = add i64 0, 0
  br label %exit
exit:
  %return_reg49 = phi i64 [ %imm_store48, %while.exit10 ]
  ret i64 %return_reg49
}

