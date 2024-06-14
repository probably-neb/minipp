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
  %_0 = alloca %struct.node*
  %input1 = alloca i64
  %i2 = alloca i64
  %n03 = alloca %struct.node*
  %n14 = alloca %struct.node*
  %n25 = alloca %struct.node*
  %n36 = alloca %struct.node*
  %n47 = alloca %struct.node*
  %n58 = alloca %struct.node*
  br label %body1
body1:
  %node10 = call i8* (i32) @malloc(i32 16)
  %node11 = bitcast i8* %node10 to %struct.node*
  store %struct.node* %node11, %struct.node** %n03
  %node13 = call i8* (i32) @malloc(i32 16)
  %node14 = bitcast i8* %node13 to %struct.node*
  store %struct.node* %node14, %struct.node** %n14
  %node16 = call i8* (i32) @malloc(i32 16)
  %node17 = bitcast i8* %node16 to %struct.node*
  store %struct.node* %node17, %struct.node** %n25
  %node19 = call i8* (i32) @malloc(i32 16)
  %node20 = bitcast i8* %node19 to %struct.node*
  store %struct.node* %node20, %struct.node** %n36
  %node22 = call i8* (i32) @malloc(i32 16)
  %node23 = bitcast i8* %node22 to %struct.node*
  store %struct.node* %node23, %struct.node** %n47
  %node25 = call i8* (i32) @malloc(i32 16)
  %node26 = bitcast i8* %node25 to %struct.node*
  store %struct.node* %node26, %struct.node** %n58
  %n028 = load %struct.node*, %struct.node** %n03
  %value29 = getelementptr %struct.node, %struct.node* %n028, i1 0, i32 0
  %_30 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_31 = call i32 (i8*, ...) @scanf(i8* %_30, i32* @.read_scratch)
  %_32 = load i32, i32* @.read_scratch
  %_33 = sext i32 %_32 to i64
  store i64 %_33, i64* %value29
  %n135 = load %struct.node*, %struct.node** %n14
  %value36 = getelementptr %struct.node, %struct.node* %n135, i1 0, i32 0
  %_37 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_38 = call i32 (i8*, ...) @scanf(i8* %_37, i32* @.read_scratch)
  %_39 = load i32, i32* @.read_scratch
  %_40 = sext i32 %_39 to i64
  store i64 %_40, i64* %value36
  %n242 = load %struct.node*, %struct.node** %n25
  %value43 = getelementptr %struct.node, %struct.node* %n242, i1 0, i32 0
  %_44 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_45 = call i32 (i8*, ...) @scanf(i8* %_44, i32* @.read_scratch)
  %_46 = load i32, i32* @.read_scratch
  %_47 = sext i32 %_46 to i64
  store i64 %_47, i64* %value43
  %n349 = load %struct.node*, %struct.node** %n36
  %value50 = getelementptr %struct.node, %struct.node* %n349, i1 0, i32 0
  %_51 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_52 = call i32 (i8*, ...) @scanf(i8* %_51, i32* @.read_scratch)
  %_53 = load i32, i32* @.read_scratch
  %_54 = sext i32 %_53 to i64
  store i64 %_54, i64* %value50
  %n456 = load %struct.node*, %struct.node** %n47
  %value57 = getelementptr %struct.node, %struct.node* %n456, i1 0, i32 0
  %_58 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_59 = call i32 (i8*, ...) @scanf(i8* %_58, i32* @.read_scratch)
  %_60 = load i32, i32* @.read_scratch
  %_61 = sext i32 %_60 to i64
  store i64 %_61, i64* %value57
  %n563 = load %struct.node*, %struct.node** %n58
  %value64 = getelementptr %struct.node, %struct.node* %n563, i1 0, i32 0
  %_65 = getelementptr [ 4 x i8 ], [ 4 x i8 ]* @.read, i1 0, i32 0
  %_66 = call i32 (i8*, ...) @scanf(i8* %_65, i32* @.read_scratch)
  %_67 = load i32, i32* @.read_scratch
  %_68 = sext i32 %_67 to i64
  store i64 %_68, i64* %value64
  %n070 = load %struct.node*, %struct.node** %n03
  %next71 = getelementptr %struct.node, %struct.node* %n070, i1 0, i32 1
  %n172 = load %struct.node*, %struct.node** %n14
  store %struct.node* %n172, %struct.node** %next71
  %n174 = load %struct.node*, %struct.node** %n14
  %next75 = getelementptr %struct.node, %struct.node* %n174, i1 0, i32 1
  %n276 = load %struct.node*, %struct.node** %n25
  store %struct.node* %n276, %struct.node** %next75
  %n278 = load %struct.node*, %struct.node** %n25
  %next79 = getelementptr %struct.node, %struct.node* %n278, i1 0, i32 1
  %n380 = load %struct.node*, %struct.node** %n36
  store %struct.node* %n380, %struct.node** %next79
  %n382 = load %struct.node*, %struct.node** %n36
  %next83 = getelementptr %struct.node, %struct.node* %n382, i1 0, i32 1
  %n484 = load %struct.node*, %struct.node** %n47
  store %struct.node* %n484, %struct.node** %next83
  %n486 = load %struct.node*, %struct.node** %n47
  %next87 = getelementptr %struct.node, %struct.node* %n486, i1 0, i32 1
  %n588 = load %struct.node*, %struct.node** %n58
  store %struct.node* %n588, %struct.node** %next87
  %n590 = load %struct.node*, %struct.node** %n58
  %next91 = getelementptr %struct.node, %struct.node* %n590, i1 0, i32 1
  store %struct.node* null, %struct.node** %next91
  %n093 = load %struct.node*, %struct.node** %n03
  store %struct.node* %n093, %struct.node** %_0
  br label %exit
exit:
  %_96 = load %struct.node*, %struct.node** %_0
  ret %struct.node* %_96
}

define i64 @multiple(%struct.node* %list) {
entry:
  %_0 = alloca i64
  %i1 = alloca i64
  %product2 = alloca i64
  %cur3 = alloca %struct.node*
  %list4 = alloca %struct.node*
  store %struct.node* %list, %struct.node** %list4
  br label %body1
body1:
  store i64 0, i64* %i1
  %list8 = load %struct.node*, %struct.node** %list4
  store %struct.node* %list8, %struct.node** %cur3
  %cur10 = load %struct.node*, %struct.node** %cur3
  %value11 = getelementptr %struct.node, %struct.node* %cur10, i1 0, i32 0
  %value12 = load i64, i64* %value11
  store i64 %value12, i64* %product2
  %cur14 = load %struct.node*, %struct.node** %cur3
  %next15 = getelementptr %struct.node, %struct.node* %cur14, i1 0, i32 1
  %next16 = load %struct.node*, %struct.node** %next15
  store %struct.node* %next16, %struct.node** %cur3
  %i18 = load i64, i64* %i1
  %i19 = icmp slt i64 %i18, 5
  br i1 %i19, label %while.body2, label %while.end3
while.body2:
  %product20 = load i64, i64* %product2
  %cur21 = load %struct.node*, %struct.node** %cur3
  %value22 = getelementptr %struct.node, %struct.node* %cur21, i1 0, i32 0
  %value23 = load i64, i64* %value22
  %_24 = mul i64 %product20, %value23
  store i64 %_24, i64* %product2
  %cur26 = load %struct.node*, %struct.node** %cur3
  %next27 = getelementptr %struct.node, %struct.node* %cur26, i1 0, i32 1
  %next28 = load %struct.node*, %struct.node** %next27
  store %struct.node* %next28, %struct.node** %cur3
  %product30 = load i64, i64* %product2
  %_31 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_32 = call i32 (i8*, ...) @printf(i8* %_31, i64 %product30)
  %i33 = load i64, i64* %i1
  %i34 = add i64 %i33, 1
  store i64 %i34, i64* %i1
  %i36 = load i64, i64* %i1
  %i37 = icmp slt i64 %i36, 5
  br i1 %i37, label %while.body2, label %while.end3
while.end3:
  %product40 = load i64, i64* %product2
  store i64 %product40, i64* %_0
  br label %exit
exit:
  %_43 = load i64, i64* %_0
  ret i64 %_43
}

define i64 @add(%struct.node* %list) {
entry:
  %_0 = alloca i64
  %i1 = alloca i64
  %sum2 = alloca i64
  %cur3 = alloca %struct.node*
  %list4 = alloca %struct.node*
  store %struct.node* %list, %struct.node** %list4
  br label %body1
body1:
  store i64 0, i64* %i1
  %list8 = load %struct.node*, %struct.node** %list4
  store %struct.node* %list8, %struct.node** %cur3
  %cur10 = load %struct.node*, %struct.node** %cur3
  %value11 = getelementptr %struct.node, %struct.node* %cur10, i1 0, i32 0
  %value12 = load i64, i64* %value11
  store i64 %value12, i64* %sum2
  %cur14 = load %struct.node*, %struct.node** %cur3
  %next15 = getelementptr %struct.node, %struct.node* %cur14, i1 0, i32 1
  %next16 = load %struct.node*, %struct.node** %next15
  store %struct.node* %next16, %struct.node** %cur3
  %i18 = load i64, i64* %i1
  %i19 = icmp slt i64 %i18, 5
  br i1 %i19, label %while.body2, label %while.end3
while.body2:
  %sum20 = load i64, i64* %sum2
  %cur21 = load %struct.node*, %struct.node** %cur3
  %value22 = getelementptr %struct.node, %struct.node* %cur21, i1 0, i32 0
  %value23 = load i64, i64* %value22
  %_24 = add i64 %sum20, %value23
  store i64 %_24, i64* %sum2
  %cur26 = load %struct.node*, %struct.node** %cur3
  %next27 = getelementptr %struct.node, %struct.node* %cur26, i1 0, i32 1
  %next28 = load %struct.node*, %struct.node** %next27
  store %struct.node* %next28, %struct.node** %cur3
  %sum30 = load i64, i64* %sum2
  %_31 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_32 = call i32 (i8*, ...) @printf(i8* %_31, i64 %sum30)
  %i33 = load i64, i64* %i1
  %i34 = add i64 %i33, 1
  store i64 %i34, i64* %i1
  %i36 = load i64, i64* %i1
  %i37 = icmp slt i64 %i36, 5
  br i1 %i37, label %while.body2, label %while.end3
while.end3:
  %sum40 = load i64, i64* %sum2
  store i64 %sum40, i64* %_0
  br label %exit
exit:
  %_43 = load i64, i64* %_0
  ret i64 %_43
}

define i64 @recurseList(%struct.node* %list) {
entry:
  %_0 = alloca i64
  %list1 = alloca %struct.node*
  store %struct.node* %list, %struct.node** %list1
  br label %body1
body1:
  %list4 = load %struct.node*, %struct.node** %list1
  %next5 = getelementptr %struct.node, %struct.node* %list4, i1 0, i32 1
  %next6 = load %struct.node*, %struct.node** %next5
  %next7 = icmp eq %struct.node* %next6, null
  br i1 %next7, label %if.then2, label %if.else3
if.then2:
  %list8 = load %struct.node*, %struct.node** %list1
  %value9 = getelementptr %struct.node, %struct.node* %list8, i1 0, i32 0
  %value10 = load i64, i64* %value9
  store i64 %value10, i64* %_0
  br label %exit
if.else3:
  %list13 = load %struct.node*, %struct.node** %list1
  %value14 = getelementptr %struct.node, %struct.node* %list13, i1 0, i32 0
  %value15 = load i64, i64* %value14
  %list16 = load %struct.node*, %struct.node** %list1
  %next17 = getelementptr %struct.node, %struct.node* %list16, i1 0, i32 1
  %next18 = load %struct.node*, %struct.node** %next17
  %recurseList19 = call i64 (%struct.node*) @recurseList(%struct.node* %next18)
  %_20 = mul i64 %value15, %recurseList19
  store i64 %_20, i64* %_0
  br label %exit
if.end4:
  br label %exit
exit:
  %_25 = load i64, i64* %_0
  ret i64 %_25
}

define i64 @main() {
entry:
  %_0 = alloca i64
  %list1 = alloca %struct.node*
  %product2 = alloca i64
  %sum3 = alloca i64
  %result4 = alloca i64
  %bigProduct5 = alloca i64
  %i6 = alloca i64
  br label %body1
body1:
  store i64 0, i64* %i6
  store i64 0, i64* %bigProduct5
  %buildList10 = call %struct.node* () @buildList()
  store %struct.node* %buildList10, %struct.node** %list1
  %list12 = load %struct.node*, %struct.node** %list1
  %multiple13 = call i64 (%struct.node*) @multiple(%struct.node* %list12)
  store i64 %multiple13, i64* %product2
  %list15 = load %struct.node*, %struct.node** %list1
  %add16 = call i64 (%struct.node*) @add(%struct.node* %list15)
  store i64 %add16, i64* %sum3
  %product18 = load i64, i64* %product2
  %sum19 = load i64, i64* %sum3
  %sum20 = sdiv i64 %sum19, 2
  %_21 = sub i64 %product18, %sum20
  store i64 %_21, i64* %result4
  %i23 = load i64, i64* %i6
  %i24 = icmp slt i64 %i23, 2
  br i1 %i24, label %while.body2, label %while.end3
while.body2:
  %bigProduct25 = load i64, i64* %bigProduct5
  %list26 = load %struct.node*, %struct.node** %list1
  %recurseList27 = call i64 (%struct.node*) @recurseList(%struct.node* %list26)
  %_28 = add i64 %bigProduct25, %recurseList27
  store i64 %_28, i64* %bigProduct5
  %i30 = load i64, i64* %i6
  %i31 = add i64 %i30, 1
  store i64 %i31, i64* %i6
  %i33 = load i64, i64* %i6
  %i34 = icmp slt i64 %i33, 2
  br i1 %i34, label %while.body2, label %while.end3
while.end3:
  %bigProduct37 = load i64, i64* %bigProduct5
  %_38 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_39 = call i32 (i8*, ...) @printf(i8* %_38, i64 %bigProduct37)
  %bigProduct40 = load i64, i64* %bigProduct5
  %bigProduct41 = icmp ne i64 %bigProduct40, 0
  br i1 %bigProduct41, label %while.body4, label %while.end5
while.body4:
  %bigProduct42 = load i64, i64* %bigProduct5
  %bigProduct43 = sub i64 %bigProduct42, 1
  store i64 %bigProduct43, i64* %bigProduct5
  %bigProduct45 = load i64, i64* %bigProduct5
  %bigProduct46 = icmp ne i64 %bigProduct45, 0
  br i1 %bigProduct46, label %while.body4, label %while.end5
while.end5:
  %result49 = load i64, i64* %result4
  %_50 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_51 = call i32 (i8*, ...) @printf(i8* %_50, i64 %result49)
  %bigProduct52 = load i64, i64* %bigProduct5
  %_53 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_54 = call i32 (i8*, ...) @printf(i8* %_53, i64 %bigProduct52)
  store i64 0, i64* %_0
  br label %exit
exit:
  %_57 = load i64, i64* %_0
  ret i64 %_57
}

