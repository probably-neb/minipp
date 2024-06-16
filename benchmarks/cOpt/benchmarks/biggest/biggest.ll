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
  %_0 = alloca %struct.IntList*
  %list1 = alloca %struct.IntList*
  %next2 = alloca i64
  br label %body1
body1:
  %IntList4 = call i8* (i32) @malloc(i32 16)
  %IntList5 = bitcast i8* %IntList4 to %struct.IntList*
  store %struct.IntList* %IntList5, %struct.IntList** %list1
  %_7 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_8 = call i32 (i8*, ...) @scanf(i8* %_7, i32* @.read_scratch)
  %_9 = load i32, i32* @.read_scratch
  %_10 = sext i32 %_9 to i64
  store i64 %_10, i64* %next2
  %next12 = load i64, i64* %next2
  %_13 = sub i64 0, 1
  %next14 = icmp eq i64 %next12, %_13
  br i1 %next14, label %if.then2, label %if.else3
if.then2:
  %list15 = load %struct.IntList*, %struct.IntList** %list1
  %head16 = getelementptr %struct.IntList, %struct.IntList* %list15, i1 0, i32 0
  %next17 = load i64, i64* %next2
  store i64 %next17, i64* %head16
  %list19 = load %struct.IntList*, %struct.IntList** %list1
  %tail20 = getelementptr %struct.IntList, %struct.IntList* %list19, i1 0, i32 1
  store %struct.IntList* null, %struct.IntList** %tail20
  %list22 = load %struct.IntList*, %struct.IntList** %list1
  store %struct.IntList* %list22, %struct.IntList** %_0
  br label %exit
if.else3:
  %list25 = load %struct.IntList*, %struct.IntList** %list1
  %head26 = getelementptr %struct.IntList, %struct.IntList* %list25, i1 0, i32 0
  %next27 = load i64, i64* %next2
  store i64 %next27, i64* %head26
  %list29 = load %struct.IntList*, %struct.IntList** %list1
  %tail30 = getelementptr %struct.IntList, %struct.IntList* %list29, i1 0, i32 1
  %getIntList31 = call %struct.IntList* () @getIntList()
  store %struct.IntList* %getIntList31, %struct.IntList** %tail30
  %list33 = load %struct.IntList*, %struct.IntList** %list1
  store %struct.IntList* %list33, %struct.IntList** %_0
  br label %exit
if.end4:
  br label %exit
exit:
  %_38 = load %struct.IntList*, %struct.IntList** %_0
  ret %struct.IntList* %_38
}

define i64 @biggest(i64 %num1, i64 %num2) {
entry:
  %_0 = alloca i64
  %num11 = alloca i64
  store i64 %num1, i64* %num11
  %num23 = alloca i64
  store i64 %num2, i64* %num23
  br label %body1
body1:
  %num16 = load i64, i64* %num11
  %num27 = load i64, i64* %num23
  %_8 = icmp sgt i64 %num16, %num27
  br i1 %_8, label %if.then2, label %if.else3
if.then2:
  %num19 = load i64, i64* %num11
  store i64 %num19, i64* %_0
  br label %exit
if.else3:
  %num212 = load i64, i64* %num23
  store i64 %num212, i64* %_0
  br label %exit
if.end4:
  br label %exit
exit:
  %_17 = load i64, i64* %_0
  ret i64 %_17
}

define i64 @biggestInList(%struct.IntList* %list) {
entry:
  %_0 = alloca i64
  %big1 = alloca i64
  %list2 = alloca %struct.IntList*
  store %struct.IntList* %list, %struct.IntList** %list2
  br label %body1
body1:
  %list5 = load %struct.IntList*, %struct.IntList** %list2
  %head6 = getelementptr %struct.IntList, %struct.IntList* %list5, i1 0, i32 0
  %head7 = load i64, i64* %head6
  store i64 %head7, i64* %big1
  %list9 = load %struct.IntList*, %struct.IntList** %list2
  %tail10 = getelementptr %struct.IntList, %struct.IntList* %list9, i1 0, i32 1
  %tail11 = load %struct.IntList*, %struct.IntList** %tail10
  %tail12 = icmp ne %struct.IntList* %tail11, null
  br i1 %tail12, label %while.body2, label %while.end3
while.body2:
  %big13 = load i64, i64* %big1
  %list14 = load %struct.IntList*, %struct.IntList** %list2
  %head15 = getelementptr %struct.IntList, %struct.IntList* %list14, i1 0, i32 0
  %head16 = load i64, i64* %head15
  %biggest17 = call i64 (i64, i64) @biggest(i64 %big13, i64 %head16)
  store i64 %biggest17, i64* %big1
  %list19 = load %struct.IntList*, %struct.IntList** %list2
  %tail20 = getelementptr %struct.IntList, %struct.IntList* %list19, i1 0, i32 1
  %tail21 = load %struct.IntList*, %struct.IntList** %tail20
  store %struct.IntList* %tail21, %struct.IntList** %list2
  %list23 = load %struct.IntList*, %struct.IntList** %list2
  %tail24 = getelementptr %struct.IntList, %struct.IntList* %list23, i1 0, i32 1
  %tail25 = load %struct.IntList*, %struct.IntList** %tail24
  %tail26 = icmp ne %struct.IntList* %tail25, null
  br i1 %tail26, label %while.body2, label %while.end3
while.end3:
  %big29 = load i64, i64* %big1
  store i64 %big29, i64* %_0
  br label %exit
exit:
  %_32 = load i64, i64* %_0
  ret i64 %_32
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %list1 = alloca %struct.IntList*
  br label %body1
body1:
  %getIntList3 = call %struct.IntList* () @getIntList()
  store %struct.IntList* %getIntList3, %struct.IntList** %list1
  %list5 = load %struct.IntList*, %struct.IntList** %list1
  %biggestInList6 = call i64 (%struct.IntList*) @biggestInList(%struct.IntList* %list5)
  %_7 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_8 = call i32 (i8*, ...) @printf(i8* %_7, i64 %biggestInList6)
  store i64 0, i64* %_0
  br label %exit
exit:
  %_11 = load i64, i64* %_0
  ret i64 %_11
}

