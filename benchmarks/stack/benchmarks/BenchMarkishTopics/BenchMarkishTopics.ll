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
  %_0 = alloca i64
  %list1 = alloca %struct.intList*
  store %struct.intList* %list, %struct.intList** %list1
  br label %body1
body1:
  %list4 = load %struct.intList*, %struct.intList** %list1
  %list5 = icmp eq %struct.intList* %list4, null
  br i1 %list5, label %if.then2, label %if.end3
if.then2:
  store i64 0, i64* %_0
  br label %exit
if.end3:
  %list9 = load %struct.intList*, %struct.intList** %list1
  %rest10 = getelementptr %struct.intList, %struct.intList* %list9, i1 0, i32 1
  %rest11 = load %struct.intList*, %struct.intList** %rest10
  %length12 = call i64 (%struct.intList*) @length(%struct.intList* %rest11)
  %length13 = add i64 1, %length12
  store i64 %length13, i64* %_0
  br label %exit
exit:
  %_16 = load i64, i64* %_0
  ret i64 %_16
}

define %struct.intList* @addToFront(%struct.intList* %list, i64 %element) {
entry:
  %_0 = alloca %struct.intList*
  %front1 = alloca %struct.intList*
  %list2 = alloca %struct.intList*
  store %struct.intList* %list, %struct.intList** %list2
  %element4 = alloca i64
  store i64 %element, i64* %element4
  br label %body1
body1:
  %list7 = load %struct.intList*, %struct.intList** %list2
  %list8 = icmp eq %struct.intList* %list7, null
  br i1 %list8, label %if.then2, label %if.end3
if.then2:
  %intList9 = call i8* (i32) @malloc(i32 16)
  %intList10 = bitcast i8* %intList9 to %struct.intList*
  store %struct.intList* %intList10, %struct.intList** %list2
  %list12 = load %struct.intList*, %struct.intList** %list2
  %data13 = getelementptr %struct.intList, %struct.intList* %list12, i1 0, i32 0
  %element14 = load i64, i64* %element4
  store i64 %element14, i64* %data13
  %list16 = load %struct.intList*, %struct.intList** %list2
  %rest17 = getelementptr %struct.intList, %struct.intList* %list16, i1 0, i32 1
  store %struct.intList* null, %struct.intList** %rest17
  %list19 = load %struct.intList*, %struct.intList** %list2
  store %struct.intList* %list19, %struct.intList** %_0
  br label %exit
if.end3:
  %intList23 = call i8* (i32) @malloc(i32 16)
  %intList24 = bitcast i8* %intList23 to %struct.intList*
  store %struct.intList* %intList24, %struct.intList** %front1
  %front26 = load %struct.intList*, %struct.intList** %front1
  %data27 = getelementptr %struct.intList, %struct.intList* %front26, i1 0, i32 0
  %element28 = load i64, i64* %element4
  store i64 %element28, i64* %data27
  %front30 = load %struct.intList*, %struct.intList** %front1
  %rest31 = getelementptr %struct.intList, %struct.intList* %front30, i1 0, i32 1
  %list32 = load %struct.intList*, %struct.intList** %list2
  store %struct.intList* %list32, %struct.intList** %rest31
  %front34 = load %struct.intList*, %struct.intList** %front1
  store %struct.intList* %front34, %struct.intList** %_0
  br label %exit
exit:
  %_37 = load %struct.intList*, %struct.intList** %_0
  ret %struct.intList* %_37
}

define %struct.intList* @deleteFirst(%struct.intList* %list) {
entry:
  %_0 = alloca %struct.intList*
  %first1 = alloca %struct.intList*
  %list2 = alloca %struct.intList*
  store %struct.intList* %list, %struct.intList** %list2
  br label %body1
body1:
  %list5 = load %struct.intList*, %struct.intList** %list2
  %list6 = icmp eq %struct.intList* %list5, null
  br i1 %list6, label %if.then2, label %if.end3
if.then2:
  store %struct.intList* null, %struct.intList** %_0
  br label %exit
if.end3:
  %list10 = load %struct.intList*, %struct.intList** %list2
  store %struct.intList* %list10, %struct.intList** %first1
  %list12 = load %struct.intList*, %struct.intList** %list2
  %rest13 = getelementptr %struct.intList, %struct.intList* %list12, i1 0, i32 1
  %rest14 = load %struct.intList*, %struct.intList** %rest13
  store %struct.intList* %rest14, %struct.intList** %list2
  %first16 = load %struct.intList*, %struct.intList** %first1
  %_17 = bitcast %struct.intList* %first16 to i8*
  call void (i8*) @free(i8* %_17)
  %list19 = load %struct.intList*, %struct.intList** %list2
  store %struct.intList* %list19, %struct.intList** %_0
  br label %exit
exit:
  %_22 = load %struct.intList*, %struct.intList** %_0
  ret %struct.intList* %_22
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %list1 = alloca %struct.intList*
  %sum2 = alloca i64
  br label %body1
body1:
  %_4 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_5 = call i32 (i8*, ...) @scanf(i8* %_4, i32* @.read_scratch)
  %_6 = load i32, i32* @.read_scratch
  %_7 = sext i32 %_6 to i64
  store i64 %_7, i64* @intList
  store i64 0, i64* %sum2
  store %struct.intList* null, %struct.intList** %list1
  %intList11 = load i64, i64* @intList
  %intList12 = icmp sgt i64 %intList11, 0
  br i1 %intList12, label %while.body2, label %while.end3
while.body2:
  %list13 = load %struct.intList*, %struct.intList** %list1
  %intList14 = load i64, i64* @intList
  %addToFront15 = call %struct.intList* (%struct.intList*, i64) @addToFront(%struct.intList* %list13, i64 %intList14)
  store %struct.intList* %addToFront15, %struct.intList** %list1
  %list17 = load %struct.intList*, %struct.intList** %list1
  %data18 = getelementptr %struct.intList, %struct.intList* %list17, i1 0, i32 0
  %data19 = load i64, i64* %data18
  %_20 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_21 = call i32 (i8*, ...) @printf(i8* %_20, i64 %data19)
  %intList22 = load i64, i64* @intList
  %intList23 = sub i64 %intList22, 1
  store i64 %intList23, i64* @intList
  %intList25 = load i64, i64* @intList
  %intList26 = icmp sgt i64 %intList25, 0
  br i1 %intList26, label %while.body2, label %while.end3
while.end3:
  %list29 = load %struct.intList*, %struct.intList** %list1
  %length30 = call i64 (%struct.intList*) @length(%struct.intList* %list29)
  %_31 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_32 = call i32 (i8*, ...) @printf(i8* %_31, i64 %length30)
  %list33 = load %struct.intList*, %struct.intList** %list1
  %length34 = call i64 (%struct.intList*) @length(%struct.intList* %list33)
  %length35 = icmp sgt i64 %length34, 0
  br i1 %length35, label %while.body4, label %while.end5
while.body4:
  %sum36 = load i64, i64* %sum2
  %list37 = load %struct.intList*, %struct.intList** %list1
  %data38 = getelementptr %struct.intList, %struct.intList* %list37, i1 0, i32 0
  %data39 = load i64, i64* %data38
  %_40 = add i64 %sum36, %data39
  store i64 %_40, i64* %sum2
  %list42 = load %struct.intList*, %struct.intList** %list1
  %length43 = call i64 (%struct.intList*) @length(%struct.intList* %list42)
  %_44 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_45 = call i32 (i8*, ...) @printf(i8* %_44, i64 %length43)
  %list46 = load %struct.intList*, %struct.intList** %list1
  %deleteFirst47 = call %struct.intList* (%struct.intList*) @deleteFirst(%struct.intList* %list46)
  store %struct.intList* %deleteFirst47, %struct.intList** %list1
  %list49 = load %struct.intList*, %struct.intList** %list1
  %length50 = call i64 (%struct.intList*) @length(%struct.intList* %list49)
  %length51 = icmp sgt i64 %length50, 0
  br i1 %length51, label %while.body4, label %while.end5
while.end5:
  %sum54 = load i64, i64* %sum2
  %_55 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_56 = call i32 (i8*, ...) @printf(i8* %_55, i64 %sum54)
  store i64 0, i64* %_0
  br label %exit
exit:
  %_59 = load i64, i64* %_0
  ret i64 %_59
}

