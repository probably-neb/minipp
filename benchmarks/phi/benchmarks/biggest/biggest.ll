%struct.IntList = type { i64, %struct.IntList* }

declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

define %struct.IntList* @getIntList() {
entry:
  br label %body0
body0:
  %IntList.malloc3 = call i8* (i32) @malloc(i32 16)
  %list4 = bitcast i8* %IntList.malloc3 to %struct.IntList*
  %_5 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_6 = call i32 (i8*, ...) @scanf(i8* %_5, i32* @.read_scratch)
  %_7 = load i32, i32* @.read_scratch
  %next8 = sext i32 %_7 to i64
  br label %if.cond1
if.cond1:
  %imm_store10 = add i64 1, 0
  %tmp.unop11 = sub i64 0, %imm_store10
  %_12 = icmp eq i64 %next8, %tmp.unop11
  br i1 %_12, label %then.body2, label %else.body3
then.body2:
  %list.head_auf14 = getelementptr %struct.IntList, %struct.IntList* %list4, i1 0, i32 0
  store i64 %next8, i64* %list.head_auf14
  %list.tail_auf16 = getelementptr %struct.IntList, %struct.IntList* %list4, i1 0, i32 1
  store %struct.IntList* null, %struct.IntList** %list.tail_auf16
  br label %exit
else.body3:
  %list.head_auf20 = getelementptr %struct.IntList, %struct.IntList* %list4, i1 0, i32 0
  store i64 %next8, i64* %list.head_auf20
  %aufrufen_getIntList22 = call %struct.IntList* () @getIntList()
  %list.tail_auf23 = getelementptr %struct.IntList, %struct.IntList* %list4, i1 0, i32 1
  store %struct.IntList* %aufrufen_getIntList22, %struct.IntList** %list.tail_auf23
  br label %exit
exit:
  %return_reg18 = phi %struct.IntList* [ %list4, %then.body2 ], [ %list4, %else.body3 ]
  ret %struct.IntList* %return_reg18
}

define i64 @biggest(i64 %num1, i64 %num2) {
entry:
  br label %body0
body0:
  br label %if.cond1
if.cond1:
  %_5 = icmp sgt i64 %num1, %num2
  br i1 %_5, label %then.body2, label %else.body3
then.body2:
  br label %exit
else.body3:
  br label %exit
exit:
  %return_reg7 = phi i64 [ %num1, %then.body2 ], [ %num2, %else.body3 ]
  ret i64 %return_reg7
}

define i64 @biggestInList(%struct.IntList* %list) {
entry:
  br label %body0
body0:
  %list.head_auf7 = getelementptr %struct.IntList, %struct.IntList* %list, i1 0, i32 0
  %big8 = load i64, i64* %list.head_auf7
  br label %while.cond11
while.cond11:
  %list.tail_auf10 = getelementptr %struct.IntList, %struct.IntList* %list, i1 0, i32 1
  %_11 = load %struct.IntList*, %struct.IntList** %list.tail_auf10
  %_12 = icmp ne %struct.IntList* %_11, null
  br i1 %_12, label %while.body2, label %while.exit5
while.body2:
  %big1 = phi i64 [ %big8, %while.cond11 ], [ %big16, %while.fillback4 ]
  %list4 = phi %struct.IntList* [ %list, %while.cond11 ], [ %list18, %while.fillback4 ]
  %list.head_auf14 = getelementptr %struct.IntList, %struct.IntList* %list4, i1 0, i32 0
  %_15 = load i64, i64* %list.head_auf14
  %big16 = call i64 (i64, i64) @biggest(i64 %big1, i64 %_15)
  %list.tail_auf17 = getelementptr %struct.IntList, %struct.IntList* %list4, i1 0, i32 1
  %list18 = load %struct.IntList*, %struct.IntList** %list.tail_auf17
  br label %while.cond23
while.cond23:
  %list.tail_auf20 = getelementptr %struct.IntList, %struct.IntList* %list18, i1 0, i32 1
  %_21 = load %struct.IntList*, %struct.IntList** %list.tail_auf20
  %_22 = icmp ne %struct.IntList* %_21, null
  br i1 %_22, label %while.fillback4, label %while.exit5
while.fillback4:
  br label %while.body2
while.exit5:
  %big2 = phi i64 [ %big8, %while.cond11 ], [ %big16, %while.cond23 ]
  %list3 = phi %struct.IntList* [ %list, %while.cond11 ], [ %list18, %while.cond23 ]
  br label %exit
exit:
  %return_reg25 = phi i64 [ %big2, %while.exit5 ]
  ret i64 %return_reg25
}

define i64 @main() {
entry:
  br label %body0
body0:
  %list2 = call %struct.IntList* () @getIntList()
  %aufrufen_biggestInList3 = call i64 (%struct.IntList*) @biggestInList(%struct.IntList* %list2)
  %_4 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_5 = call i32 (i8*, ...) @printf(i8* %_4, i64 %aufrufen_biggestInList3)
  %imm_store6 = add i64 0, 0
  br label %exit
exit:
  %return_reg7 = phi i64 [ %imm_store6, %body0 ]
  ret i64 %return_reg7
}

