%struct.intList = type { i64, %struct.intList* }

declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

@intList = global i64 undef, align 8

define i64 @length(%struct.intList* %list) {
entry:
  br label %body0
body0:
  br label %if.cond1
if.cond1:
  %_4 = icmp eq %struct.intList* %list, null
  br i1 %_4, label %then.body2, label %if.exit3
then.body2:
  %imm_store6 = add i64 0, 0
  br label %exit
if.exit3:
  %imm_store9 = add i64 1, 0
  %list.rest_auf10 = getelementptr %struct.intList, %struct.intList* %list, i1 0, i32 1
  %_11 = load %struct.intList*, %struct.intList** %list.rest_auf10
  %aufrufen_length12 = call i64 (%struct.intList*) @length(%struct.intList* %_11)
  %tmp.binop13 = add i64 %imm_store9, %aufrufen_length12
  br label %exit
exit:
  %return_reg7 = phi i64 [ %imm_store6, %then.body2 ], [ %tmp.binop13, %if.exit3 ]
  ret i64 %return_reg7
}

define %struct.intList* @addToFront(%struct.intList* %list, i64 %element) {
entry:
  br label %body0
body0:
  br label %if.cond1
if.cond1:
  %_7 = icmp eq %struct.intList* %list, null
  br i1 %_7, label %then.body2, label %if.exit3
then.body2:
  %intList.malloc9 = call i8* (i32) @malloc(i32 16)
  %intList.bitcast10 = bitcast i8* %intList.malloc9 to %struct.intList*
  %list.data_auf11 = getelementptr %struct.intList, %struct.intList* %intList.bitcast10, i1 0, i32 0
  store i64 %element, i64* %list.data_auf11
  %list.rest_auf13 = getelementptr %struct.intList, %struct.intList* %intList.bitcast10, i1 0, i32 1
  store %struct.intList* null, %struct.intList** %list.rest_auf13
  br label %exit
if.exit3:
  %intList.malloc17 = call i8* (i32) @malloc(i32 16)
  %front18 = bitcast i8* %intList.malloc17 to %struct.intList*
  %front.data_auf19 = getelementptr %struct.intList, %struct.intList* %front18, i1 0, i32 0
  store i64 %element, i64* %front.data_auf19
  %front.rest_auf21 = getelementptr %struct.intList, %struct.intList* %front18, i1 0, i32 1
  store %struct.intList* %list, %struct.intList** %front.rest_auf21
  br label %exit
exit:
  %return_reg15 = phi %struct.intList* [ %intList.bitcast10, %then.body2 ], [ %front18, %if.exit3 ]
  ret %struct.intList* %return_reg15
}

define %struct.intList* @deleteFirst(%struct.intList* %list) {
entry:
  br label %body0
body0:
  br label %if.cond1
if.cond1:
  %_6 = icmp eq %struct.intList* %list, null
  br i1 %_6, label %then.body2, label %if.exit3
then.body2:
  br label %exit
if.exit3:
  %list.rest_auf10 = getelementptr %struct.intList, %struct.intList* %list, i1 0, i32 1
  %_11 = load %struct.intList*, %struct.intList** %list.rest_auf10
  %_12 = bitcast %struct.intList* %list to i8*
  call void (i8*) @free(i8* %_12)
  br label %exit
exit:
  %return_reg8 = phi %struct.intList* [ null, %then.body2 ], [ %_11, %if.exit3 ]
  ret %struct.intList* %return_reg8
}

define i64 @main() {
entry:
  br label %body0
body0:
  %_8 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_9 = call i32 (i8*, ...) @scanf(i8* %_8, i32* @.read_scratch)
  %_10 = load i32, i32* @.read_scratch
  %_11 = sext i32 %_10 to i64
  store i64 %_11, i64* @intList
  %sum13 = add i64 0, 0
  br label %while.cond11
while.cond11:
  %load_global15 = load i64, i64* @intList
  %imm_store16 = add i64 0, 0
  %_17 = icmp sgt i64 %load_global15, %imm_store16
  br i1 %_17, label %while.body2, label %while.exit5
while.body2:
  %list2 = phi %struct.intList* [ null, %while.cond11 ], [ %list20, %while.fillback4 ]
  %load_global19 = load i64, i64* @intList
  %list20 = call %struct.intList* (%struct.intList*, i64) @addToFront(%struct.intList* %list2, i64 %load_global19)
  %list.data_auf21 = getelementptr %struct.intList, %struct.intList* %list20, i1 0, i32 0
  %_22 = load i64, i64* %list.data_auf21
  %_23 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_24 = call i32 (i8*, ...) @printf(i8* %_23, i64 %_22)
  %load_global25 = load i64, i64* @intList
  %imm_store26 = add i64 1, 0
  %tmp.binop27 = sub i64 %load_global25, %imm_store26
  store i64 %tmp.binop27, i64* @intList
  br label %while.cond23
while.cond23:
  %load_global30 = load i64, i64* @intList
  %imm_store31 = add i64 0, 0
  %_32 = icmp sgt i64 %load_global30, %imm_store31
  br i1 %_32, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %list3 = phi %struct.intList* [ null, %while.cond11 ], [ %list20, %while.cond23 ]
  %aufrufen_length35 = call i64 (%struct.intList*) @length(%struct.intList* %list3)
  %_36 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_37 = call i32 (i8*, ...) @printf(i8* %_36, i64 %aufrufen_length35)
  br label %while.cond16
while.cond16:
  %aufrufen_length39 = call i64 (%struct.intList*) @length(%struct.intList* %list3)
  %imm_store40 = add i64 0, 0
  %_41 = icmp sgt i64 %aufrufen_length39, %imm_store40
  br i1 %_41, label %while.body7, label %while.exit10
while.body7:
  %list0 = phi %struct.intList* [ %list3, %while.cond16 ], [ %list49, %while.fillback9 ]
  %sum4 = phi i64 [ %sum13, %while.cond16 ], [ %sum45, %while.fillback9 ]
  %list.data_auf43 = getelementptr %struct.intList, %struct.intList* %list0, i1 0, i32 0
  %_44 = load i64, i64* %list.data_auf43
  %sum45 = add i64 %sum4, %_44
  %aufrufen_length46 = call i64 (%struct.intList*) @length(%struct.intList* %list0)
  %_47 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_48 = call i32 (i8*, ...) @printf(i8* %_47, i64 %aufrufen_length46)
  %list49 = call %struct.intList* (%struct.intList*) @deleteFirst(%struct.intList* %list0)
  br label %while.cond28
while.cond28:
  %aufrufen_length51 = call i64 (%struct.intList*) @length(%struct.intList* %list49)
  %imm_store52 = add i64 0, 0
  %_53 = icmp sgt i64 %aufrufen_length51, %imm_store52
  br i1 %_53, label %while.fillback9, label %while.exit10
while.fillback9:
  br label %while.body7
while.exit10:
  %list1 = phi %struct.intList* [ %list3, %while.cond16 ], [ %list49, %while.cond28 ]
  %sum5 = phi i64 [ %sum13, %while.cond16 ], [ %sum45, %while.cond28 ]
  %_56 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_57 = call i32 (i8*, ...) @printf(i8* %_56, i64 %sum5)
  %imm_store58 = add i64 0, 0
  br label %exit
exit:
  %return_reg59 = phi i64 [ %imm_store58, %while.exit10 ]
  ret i64 %return_reg59
}

