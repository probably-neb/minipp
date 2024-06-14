%struct.thing = type { i64, i1, %struct.thing* }

declare i8* @malloc(i32)
declare void @free(i8*)
declare i32 @printf(i8*, ...)
declare i32 @scanf(i8*, ...)
@.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
@.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
@.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@.read_scratch = common global i32 0, align 4

@gi1 = global i64 undef, align 8
@gb1 = global i1 undef, align 8
@gs1 = global %struct.thing* undef, align 8
@counter = global i64 undef, align 8

define void @printgroup(i64 %groupnum) {
entry:
  br label %body0
body0:
  %_2 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_3 = call i32 (i8*, ...) @printf(i8* %_2, i64 1)
  %_5 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_6 = call i32 (i8*, ...) @printf(i8* %_5, i64 0)
  %_8 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_9 = call i32 (i8*, ...) @printf(i8* %_8, i64 1)
  %_11 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_12 = call i32 (i8*, ...) @printf(i8* %_11, i64 0)
  %_14 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_15 = call i32 (i8*, ...) @printf(i8* %_14, i64 1)
  %_17 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_18 = call i32 (i8*, ...) @printf(i8* %_17, i64 0)
  %_19 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_20 = call i32 (i8*, ...) @printf(i8* %_19, i64 %groupnum)
  br label %exit
exit:
  ret void
}

define i1 @setcounter(i64 %val) {
entry:
  br label %body0
body0:
  store i64 %val, i64* @counter
  br label %exit
exit:
  ret i1 1
}

define void @takealltypes(i64 %i, i1 %b, %struct.thing* %s) {
entry:
  br label %if.cond1
if.cond1:
  %_5 = icmp eq i64 %i, 3
  br i1 %_5, label %then.body2, label %else.body4
then.body2:
  %_8 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_9 = call i32 (i8*, ...) @printf(i8* %_8, i64 1)
  br label %if.exit6
else.body4:
  %_13 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_14 = call i32 (i8*, ...) @printf(i8* %_13, i64 0)
  br label %if.exit6
if.exit6:
  br label %if.cond7
if.cond7:
  br i1 %b, label %then.body8, label %else.body10
then.body8:
  %_20 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_21 = call i32 (i8*, ...) @printf(i8* %_20, i64 1)
  br label %if.exit12
else.body10:
  %_25 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_26 = call i32 (i8*, ...) @printf(i8* %_25, i64 0)
  br label %if.exit12
if.exit12:
  br label %if.cond13
if.cond13:
  %s.b_auf30 = getelementptr %struct.thing, %struct.thing* %s, i1 0, i32 1
  %_31 = load i1, i1* %s.b_auf30
  br i1 %_31, label %then.body14, label %else.body16
then.body14:
  %_34 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_35 = call i32 (i8*, ...) @printf(i8* %_34, i64 1)
  br label %if.exit18
else.body16:
  %_39 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_40 = call i32 (i8*, ...) @printf(i8* %_39, i64 0)
  br label %if.exit18
if.exit18:
  br label %exit
exit:
  ret void
}

define void @tonofargs(i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6, i64 %a7, i64 %a8) {
entry:
  br label %if.cond1
if.cond1:
  %_10 = icmp eq i64 %a5, 5
  br i1 %_10, label %then.body2, label %else.body4
then.body2:
  %_13 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_14 = call i32 (i8*, ...) @printf(i8* %_13, i64 1)
  br label %if.exit6
else.body4:
  %_18 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_19 = call i32 (i8*, ...) @printf(i8* %_18, i64 0)
  %_20 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_21 = call i32 (i8*, ...) @printf(i8* %_20, i64 %a5)
  br label %if.exit6
if.exit6:
  br label %if.cond7
if.cond7:
  %_26 = icmp eq i64 %a6, 6
  br i1 %_26, label %then.body8, label %else.body10
then.body8:
  %_29 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_30 = call i32 (i8*, ...) @printf(i8* %_29, i64 1)
  br label %if.exit12
else.body10:
  %_34 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_35 = call i32 (i8*, ...) @printf(i8* %_34, i64 0)
  %_36 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_37 = call i32 (i8*, ...) @printf(i8* %_36, i64 %a6)
  br label %if.exit12
if.exit12:
  br label %if.cond13
if.cond13:
  %_42 = icmp eq i64 %a7, 7
  br i1 %_42, label %then.body14, label %else.body16
then.body14:
  %_45 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_46 = call i32 (i8*, ...) @printf(i8* %_45, i64 1)
  br label %if.exit18
else.body16:
  %_50 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_51 = call i32 (i8*, ...) @printf(i8* %_50, i64 0)
  %_52 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_53 = call i32 (i8*, ...) @printf(i8* %_52, i64 %a7)
  br label %if.exit18
if.exit18:
  br label %if.cond19
if.cond19:
  %_58 = icmp eq i64 %a8, 8
  br i1 %_58, label %then.body20, label %else.body22
then.body20:
  %_61 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_62 = call i32 (i8*, ...) @printf(i8* %_61, i64 1)
  br label %if.exit24
else.body22:
  %_66 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_67 = call i32 (i8*, ...) @printf(i8* %_66, i64 0)
  %_68 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_69 = call i32 (i8*, ...) @printf(i8* %_68, i64 %a8)
  br label %if.exit24
if.exit24:
  br label %exit
exit:
  ret void
}

define i64 @returnint(i64 %ret) {
entry:
  br label %body0
body0:
  br label %exit
exit:
  %return_reg3 = phi i64 [ %ret, %body0 ]
  ret i64 %return_reg3
}

define i1 @returnbool(i1 %ret) {
entry:
  br label %body0
body0:
  br label %exit
exit:
  %return_reg3 = phi i1 [ %ret, %body0 ]
  ret i1 %return_reg3
}

define %struct.thing* @returnstruct(%struct.thing* %ret) {
entry:
  br label %body0
body0:
  br label %exit
exit:
  %return_reg3 = phi %struct.thing* [ %ret, %body0 ]
  ret %struct.thing* %return_reg3
}

define i64 @main() {
entry:
  %return_reg2 = alloca i64
  %_3 = load i64, i64* %return_reg2
  br label %body0
body0:
  store i64 0, i64* @counter
  call void (i64) @printgroup(i64 1)
  br label %else.body4
else.body4:
  %_19 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_20 = call i32 (i8*, ...) @printf(i8* %_19, i64 1)
  br label %else.body10
else.body10:
  %_34 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_35 = call i32 (i8*, ...) @printf(i8* %_34, i64 1)
  br label %else.body16
else.body16:
  %_49 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_50 = call i32 (i8*, ...) @printf(i8* %_49, i64 1)
  br label %then.body20
then.body20:
  %_59 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_60 = call i32 (i8*, ...) @printf(i8* %_59, i64 1)
  br label %if.exit24
if.exit24:
  store i64 0, i64* @counter
  call void (i64) @printgroup(i64 2)
  br label %then.body26
then.body26:
  %_78 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_79 = call i32 (i8*, ...) @printf(i8* %_78, i64 1)
  br label %then.body32
then.body32:
  %_93 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_94 = call i32 (i8*, ...) @printf(i8* %_93, i64 1)
  br label %then.body38
then.body38:
  %_108 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_109 = call i32 (i8*, ...) @printf(i8* %_108, i64 1)
  br label %else.body46
else.body46:
  %_128 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_129 = call i32 (i8*, ...) @printf(i8* %_128, i64 1)
  br label %if.exit48
if.exit48:
  call void (i64) @printgroup(i64 3)
  br label %then.body50
then.body50:
  %_140 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_141 = call i32 (i8*, ...) @printf(i8* %_140, i64 1)
  br label %then.body56
then.body56:
  %_155 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_156 = call i32 (i8*, ...) @printf(i8* %_155, i64 1)
  br label %else.body64
else.body64:
  %_175 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_176 = call i32 (i8*, ...) @printf(i8* %_175, i64 1)
  br label %else.body70
else.body70:
  %_190 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_191 = call i32 (i8*, ...) @printf(i8* %_190, i64 1)
  br label %else.body76
else.body76:
  %_205 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_206 = call i32 (i8*, ...) @printf(i8* %_205, i64 1)
  br label %then.body80
then.body80:
  %_215 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_216 = call i32 (i8*, ...) @printf(i8* %_215, i64 1)
  br label %then.body86
then.body86:
  %_228 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_229 = call i32 (i8*, ...) @printf(i8* %_228, i64 1)
  br label %else.body94
else.body94:
  %_247 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_248 = call i32 (i8*, ...) @printf(i8* %_247, i64 1)
  br label %else.body100
else.body100:
  %_260 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_261 = call i32 (i8*, ...) @printf(i8* %_260, i64 1)
  br label %then.body104
then.body104:
  %_269 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_270 = call i32 (i8*, ...) @printf(i8* %_269, i64 1)
  br label %then.body110
then.body110:
  %_283 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_284 = call i32 (i8*, ...) @printf(i8* %_283, i64 1)
  br label %if.exit114
if.exit114:
  call void (i64) @printgroup(i64 4)
  br label %then.body116
then.body116:
  %_302 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_303 = call i32 (i8*, ...) @printf(i8* %_302, i64 1)
  br label %then.body122
then.body122:
  %_324 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_325 = call i32 (i8*, ...) @printf(i8* %_324, i64 1)
  br label %then.body128
then.body128:
  %_346 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_347 = call i32 (i8*, ...) @printf(i8* %_346, i64 1)
  br label %then.body134
then.body134:
  %_368 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_369 = call i32 (i8*, ...) @printf(i8* %_368, i64 1)
  br label %then.body140
then.body140:
  %_389 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_390 = call i32 (i8*, ...) @printf(i8* %_389, i64 1)
  br label %if.exit144
if.exit144:
  call void (i64) @printgroup(i64 5)
  br label %then.body146
then.body146:
  %_406 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_407 = call i32 (i8*, ...) @printf(i8* %_406, i64 1)
  br label %then.body152
then.body152:
  %_423 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_424 = call i32 (i8*, ...) @printf(i8* %_423, i64 1)
  br label %then.body158
then.body158:
  %_436 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_437 = call i32 (i8*, ...) @printf(i8* %_436, i64 1)
  br label %else.body166
else.body166:
  %_454 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_455 = call i32 (i8*, ...) @printf(i8* %_454, i64 1)
  br label %else.body172
else.body172:
  %_467 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_468 = call i32 (i8*, ...) @printf(i8* %_467, i64 1)
  br label %then.body176
then.body176:
  %_475 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_476 = call i32 (i8*, ...) @printf(i8* %_475, i64 1)
  br label %else.body184
else.body184:
  %_492 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_493 = call i32 (i8*, ...) @printf(i8* %_492, i64 1)
  br label %if.exit186
if.exit186:
  call void (i64) @printgroup(i64 6)
  br label %while.cond1187
while.cond1187:
  br label %while.body188
while.body188:
  %i11 = phi i64 [ 0, %while.cond1187 ], [ %i1513, %while.fillback194 ]
  br label %if.cond189
if.cond189:
  %_505 = icmp sge i64 %i11, 5
  br i1 %_505, label %then.body190, label %if.exit192
then.body190:
  %_508 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_509 = call i32 (i8*, ...) @printf(i8* %_508, i64 0)
  br label %if.exit192
if.exit192:
  %i1513 = add i64 %i11, 5
  br label %while.cond2193
while.cond2193:
  %_516 = icmp slt i64 %i1513, 5
  br i1 %_516, label %while.fillback194, label %if.cond196
while.fillback194:
  br label %while.body188
if.cond196:
  %_521 = icmp eq i64 %i1513, 5
  br i1 %_521, label %then.body197, label %else.body199
then.body197:
  %_524 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_525 = call i32 (i8*, ...) @printf(i8* %_524, i64 1)
  br label %if.exit201
else.body199:
  %_529 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_530 = call i32 (i8*, ...) @printf(i8* %_529, i64 0)
  %_531 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_532 = call i32 (i8*, ...) @printf(i8* %_531, i64 %i1513)
  br label %if.exit201
if.exit201:
  call void (i64) @printgroup(i64 7)
  %thing.malloc537 = call i8* (i32) @malloc(i32 24)
  %s1538 = bitcast i8* %thing.malloc537 to %struct.thing*
  %s1.i_auf540 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 0
  store i64 42, i64* %s1.i_auf540
  %s1.b_auf543 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 1
  store i1 1, i1* %s1.b_auf543
  br label %if.cond202
if.cond202:
  %s1.i_auf546 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 0
  %_547 = load i64, i64* %s1.i_auf546
  %_549 = icmp eq i64 %_547, 42
  br i1 %_549, label %then.body203, label %else.body205
then.body203:
  %_552 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_553 = call i32 (i8*, ...) @printf(i8* %_552, i64 1)
  br label %if.exit207
else.body205:
  %_557 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_558 = call i32 (i8*, ...) @printf(i8* %_557, i64 0)
  %s1.i_auf559 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 0
  %_560 = load i64, i64* %s1.i_auf559
  %_561 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_562 = call i32 (i8*, ...) @printf(i8* %_561, i64 %_560)
  br label %if.exit207
if.exit207:
  br label %if.cond208
if.cond208:
  %s1.b_auf566 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 1
  %_567 = load i1, i1* %s1.b_auf566
  br i1 %_567, label %then.body209, label %else.body211
then.body209:
  %_570 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_571 = call i32 (i8*, ...) @printf(i8* %_570, i64 1)
  br label %if.exit213
else.body211:
  %_575 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_576 = call i32 (i8*, ...) @printf(i8* %_575, i64 0)
  br label %if.exit213
if.exit213:
  %thing.malloc579 = call i8* (i32) @malloc(i32 24)
  %thing.bitcast580 = bitcast i8* %thing.malloc579 to %struct.thing*
  %s1.s_auf581 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 2
  store %struct.thing* %thing.bitcast580, %struct.thing** %s1.s_auf581
  %s1.s_auf584 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 2
  %thing585 = load %struct.thing*, %struct.thing** %s1.s_auf584
  %s1.s.i_auf586 = getelementptr %struct.thing, %struct.thing* %thing585, i1 0, i32 0
  store i64 13, i64* %s1.s.i_auf586
  %s1.s_auf589 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 2
  %thing590 = load %struct.thing*, %struct.thing** %s1.s_auf589
  %s1.s.b_auf591 = getelementptr %struct.thing, %struct.thing* %thing590, i1 0, i32 1
  store i1 0, i1* %s1.s.b_auf591
  br label %if.cond214
if.cond214:
  %s1.s_auf594 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 2
  %thing595 = load %struct.thing*, %struct.thing** %s1.s_auf594
  %s1.s.i_auf596 = getelementptr %struct.thing, %struct.thing* %thing595, i1 0, i32 0
  %_597 = load i64, i64* %s1.s.i_auf596
  %_599 = icmp eq i64 %_597, 13
  br i1 %_599, label %then.body215, label %else.body217
then.body215:
  %_602 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_603 = call i32 (i8*, ...) @printf(i8* %_602, i64 1)
  br label %if.exit219
else.body217:
  %_607 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_608 = call i32 (i8*, ...) @printf(i8* %_607, i64 0)
  %s1.s_auf609 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 2
  %thing610 = load %struct.thing*, %struct.thing** %s1.s_auf609
  %s1.s.i_auf611 = getelementptr %struct.thing, %struct.thing* %thing610, i1 0, i32 0
  %_612 = load i64, i64* %s1.s.i_auf611
  %_613 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_614 = call i32 (i8*, ...) @printf(i8* %_613, i64 %_612)
  br label %if.exit219
if.exit219:
  br label %if.cond220
if.cond220:
  %s1.s_auf618 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 2
  %thing619 = load %struct.thing*, %struct.thing** %s1.s_auf618
  %s1.s.b_auf620 = getelementptr %struct.thing, %struct.thing* %thing619, i1 0, i32 1
  %_621 = load i1, i1* %s1.s.b_auf620
  %_622 = xor i1 %_621, 1
  br i1 %_622, label %then.body221, label %else.body223
then.body221:
  %_625 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_626 = call i32 (i8*, ...) @printf(i8* %_625, i64 1)
  br label %if.exit225
else.body223:
  %_630 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_631 = call i32 (i8*, ...) @printf(i8* %_630, i64 0)
  br label %if.exit225
if.exit225:
  br label %if.cond226
if.cond226:
  %_635 = icmp eq %struct.thing* %s1538, %s1538
  br i1 %_635, label %then.body227, label %else.body229
then.body227:
  %_638 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_639 = call i32 (i8*, ...) @printf(i8* %_638, i64 1)
  br label %if.exit231
else.body229:
  %_643 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_644 = call i32 (i8*, ...) @printf(i8* %_643, i64 0)
  br label %if.exit231
if.exit231:
  br label %if.cond232
if.cond232:
  %s1.s_auf648 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 2
  %_649 = load %struct.thing*, %struct.thing** %s1.s_auf648
  %_650 = icmp ne %struct.thing* %s1538, %_649
  br i1 %_650, label %then.body233, label %else.body235
then.body233:
  %_653 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_654 = call i32 (i8*, ...) @printf(i8* %_653, i64 1)
  br label %if.exit237
else.body235:
  %_658 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_659 = call i32 (i8*, ...) @printf(i8* %_658, i64 0)
  br label %if.exit237
if.exit237:
  %s1.s_auf662 = getelementptr %struct.thing, %struct.thing* %s1538, i1 0, i32 2
  %_663 = load %struct.thing*, %struct.thing** %s1.s_auf662
  %_664 = bitcast %struct.thing* %_663 to i8*
  call void (i8*) @free(i8* %_664)
  %_666 = bitcast %struct.thing* %s1538 to i8*
  call void (i8*) @free(i8* %_666)
  call void (i64) @printgroup(i64 8)
  store i64 7, i64* @gi1
  br label %if.cond238
if.cond238:
  %load_global673 = load i64, i64* @gi1
  %_675 = icmp eq i64 %load_global673, 7
  br i1 %_675, label %then.body239, label %else.body241
then.body239:
  %_678 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_679 = call i32 (i8*, ...) @printf(i8* %_678, i64 1)
  br label %if.exit243
else.body241:
  %_683 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_684 = call i32 (i8*, ...) @printf(i8* %_683, i64 0)
  %load_global685 = load i64, i64* @gi1
  %_686 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_687 = call i32 (i8*, ...) @printf(i8* %_686, i64 %load_global685)
  br label %if.exit243
if.exit243:
  store i1 1, i1* @gb1
  br label %if.cond244
if.cond244:
  %_693 = load i1, i1* @gb1
  br i1 %_693, label %then.body245, label %else.body247
then.body245:
  %_696 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_697 = call i32 (i8*, ...) @printf(i8* %_696, i64 1)
  br label %if.exit249
else.body247:
  %_701 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_702 = call i32 (i8*, ...) @printf(i8* %_701, i64 0)
  br label %if.exit249
if.exit249:
  %thing.malloc705 = call i8* (i32) @malloc(i32 24)
  %thing.bitcast706 = bitcast i8* %thing.malloc705 to %struct.thing*
  store %struct.thing* %thing.bitcast706, %struct.thing** @gs1
  %_709 = load %struct.thing*, %struct.thing** @gs1
  %gs1.i_auf710 = getelementptr %struct.thing, %struct.thing* %_709, i1 0, i32 0
  store i64 34, i64* %gs1.i_auf710
  %_713 = load %struct.thing*, %struct.thing** @gs1
  %gs1.b_auf714 = getelementptr %struct.thing, %struct.thing* %_713, i1 0, i32 1
  store i1 0, i1* %gs1.b_auf714
  br label %if.cond250
if.cond250:
  %load_global717 = load %struct.thing*, %struct.thing** @gs1
  %gs1.i_auf718 = getelementptr %struct.thing, %struct.thing* %load_global717, i1 0, i32 0
  %_719 = load i64, i64* %gs1.i_auf718
  %_721 = icmp eq i64 %_719, 34
  br i1 %_721, label %then.body251, label %else.body253
then.body251:
  %_724 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_725 = call i32 (i8*, ...) @printf(i8* %_724, i64 1)
  br label %if.exit255
else.body253:
  %_729 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_730 = call i32 (i8*, ...) @printf(i8* %_729, i64 0)
  %load_global731 = load %struct.thing*, %struct.thing** @gs1
  %gs1.i_auf732 = getelementptr %struct.thing, %struct.thing* %load_global731, i1 0, i32 0
  %_733 = load i64, i64* %gs1.i_auf732
  %_734 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_735 = call i32 (i8*, ...) @printf(i8* %_734, i64 %_733)
  br label %if.exit255
if.exit255:
  br label %if.cond256
if.cond256:
  %load_global739 = load %struct.thing*, %struct.thing** @gs1
  %gs1.b_auf740 = getelementptr %struct.thing, %struct.thing* %load_global739, i1 0, i32 1
  %_741 = load i1, i1* %gs1.b_auf740
  %_742 = xor i1 %_741, 1
  br i1 %_742, label %then.body257, label %else.body259
then.body257:
  %_745 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_746 = call i32 (i8*, ...) @printf(i8* %_745, i64 1)
  br label %if.exit261
else.body259:
  %_750 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_751 = call i32 (i8*, ...) @printf(i8* %_750, i64 0)
  br label %if.exit261
if.exit261:
  %thing.malloc754 = call i8* (i32) @malloc(i32 24)
  %thing.bitcast755 = bitcast i8* %thing.malloc754 to %struct.thing*
  %_756 = load %struct.thing*, %struct.thing** @gs1
  %gs1.s_auf757 = getelementptr %struct.thing, %struct.thing* %_756, i1 0, i32 2
  store %struct.thing* %thing.bitcast755, %struct.thing** %gs1.s_auf757
  %_760 = load %struct.thing*, %struct.thing** @gs1
  %gs1.s_auf761 = getelementptr %struct.thing, %struct.thing* %_760, i1 0, i32 2
  %thing762 = load %struct.thing*, %struct.thing** %gs1.s_auf761
  %gs1.s.i_auf763 = getelementptr %struct.thing, %struct.thing* %thing762, i1 0, i32 0
  store i64 16, i64* %gs1.s.i_auf763
  %_766 = load %struct.thing*, %struct.thing** @gs1
  %gs1.s_auf767 = getelementptr %struct.thing, %struct.thing* %_766, i1 0, i32 2
  %thing768 = load %struct.thing*, %struct.thing** %gs1.s_auf767
  %gs1.s.b_auf769 = getelementptr %struct.thing, %struct.thing* %thing768, i1 0, i32 1
  store i1 1, i1* %gs1.s.b_auf769
  br label %if.cond262
if.cond262:
  %load_global772 = load %struct.thing*, %struct.thing** @gs1
  %gs1.s_auf773 = getelementptr %struct.thing, %struct.thing* %load_global772, i1 0, i32 2
  %thing774 = load %struct.thing*, %struct.thing** %gs1.s_auf773
  %gs1.s.i_auf775 = getelementptr %struct.thing, %struct.thing* %thing774, i1 0, i32 0
  %_776 = load i64, i64* %gs1.s.i_auf775
  %_778 = icmp eq i64 %_776, 16
  br i1 %_778, label %then.body263, label %else.body265
then.body263:
  %_781 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_782 = call i32 (i8*, ...) @printf(i8* %_781, i64 1)
  br label %if.exit267
else.body265:
  %_786 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_787 = call i32 (i8*, ...) @printf(i8* %_786, i64 0)
  %load_global788 = load %struct.thing*, %struct.thing** @gs1
  %gs1.s_auf789 = getelementptr %struct.thing, %struct.thing* %load_global788, i1 0, i32 2
  %thing790 = load %struct.thing*, %struct.thing** %gs1.s_auf789
  %gs1.s.i_auf791 = getelementptr %struct.thing, %struct.thing* %thing790, i1 0, i32 0
  %_792 = load i64, i64* %gs1.s.i_auf791
  %_793 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_794 = call i32 (i8*, ...) @printf(i8* %_793, i64 %_792)
  br label %if.exit267
if.exit267:
  br label %if.cond268
if.cond268:
  %load_global798 = load %struct.thing*, %struct.thing** @gs1
  %gs1.s_auf799 = getelementptr %struct.thing, %struct.thing* %load_global798, i1 0, i32 2
  %thing800 = load %struct.thing*, %struct.thing** %gs1.s_auf799
  %gs1.s.b_auf801 = getelementptr %struct.thing, %struct.thing* %thing800, i1 0, i32 1
  %_802 = load i1, i1* %gs1.s.b_auf801
  br i1 %_802, label %then.body269, label %else.body271
then.body269:
  %_805 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_806 = call i32 (i8*, ...) @printf(i8* %_805, i64 1)
  br label %if.exit273
else.body271:
  %_810 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_811 = call i32 (i8*, ...) @printf(i8* %_810, i64 0)
  br label %if.exit273
if.exit273:
  %load_global814 = load %struct.thing*, %struct.thing** @gs1
  %gs1.s_auf815 = getelementptr %struct.thing, %struct.thing* %load_global814, i1 0, i32 2
  %_816 = load %struct.thing*, %struct.thing** %gs1.s_auf815
  %_817 = bitcast %struct.thing* %_816 to i8*
  call void (i8*) @free(i8* %_817)
  %load_global819 = load %struct.thing*, %struct.thing** @gs1
  %_820 = bitcast %struct.thing* %load_global819 to i8*
  call void (i8*) @free(i8* %_820)
  call void (i64) @printgroup(i64 9)
  %thing.malloc824 = call i8* (i32) @malloc(i32 24)
  %s1825 = bitcast i8* %thing.malloc824 to %struct.thing*
  %s1.b_auf827 = getelementptr %struct.thing, %struct.thing* %s1825, i1 0, i32 1
  store i1 1, i1* %s1.b_auf827
  call void (i64, i1, %struct.thing*) @takealltypes(i64 3, i1 1, %struct.thing* %s1825)
  %_833 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_834 = call i32 (i8*, ...) @printf(i8* %_833, i64 2)
  call void (i64, i64, i64, i64, i64, i64, i64, i64) @tonofargs(i64 1, i64 2, i64 3, i64 4, i64 5, i64 6, i64 7, i64 8)
  %_845 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_846 = call i32 (i8*, ...) @printf(i8* %_845, i64 3)
  %i1848 = call i64 (i64) @returnint(i64 3)
  br label %if.cond274
if.cond274:
  %_851 = icmp eq i64 %i1848, 3
  br i1 %_851, label %then.body275, label %else.body277
then.body275:
  %_854 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_855 = call i32 (i8*, ...) @printf(i8* %_854, i64 1)
  br label %if.exit279
else.body277:
  %_859 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.print, i1 0, i32 0
  %_860 = call i32 (i8*, ...) @printf(i8* %_859, i64 0)
  %_861 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_862 = call i32 (i8*, ...) @printf(i8* %_861, i64 %i1848)
  br label %if.exit279
if.exit279:
  %_866 = call i1 (i1) @returnbool(i1 1)
  br label %if.cond280
if.cond280:
  br i1 %_866, label %then.body281, label %else.body283
then.body281:
  %_870 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_871 = call i32 (i8*, ...) @printf(i8* %_870, i64 1)
  br label %if.exit285
else.body283:
  %_875 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_876 = call i32 (i8*, ...) @printf(i8* %_875, i64 0)
  br label %if.exit285
if.exit285:
  %thing.malloc879 = call i8* (i32) @malloc(i32 24)
  %s1880 = bitcast i8* %thing.malloc879 to %struct.thing*
  %s2881 = call %struct.thing* (%struct.thing*) @returnstruct(%struct.thing* %s1880)
  br label %if.cond286
if.cond286:
  %_883 = icmp eq %struct.thing* %s1880, %s2881
  br i1 %_883, label %then.body287, label %else.body289
then.body287:
  %_886 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_887 = call i32 (i8*, ...) @printf(i8* %_886, i64 1)
  br label %if.exit291
else.body289:
  %_891 = getelementptr [ 5 x i8 ], [ 5 x i8 ]* @.println, i1 0, i32 0
  %_892 = call i32 (i8*, ...) @printf(i8* %_891, i64 0)
  br label %if.exit291
if.exit291:
  call void (i64) @printgroup(i64 10)
  br label %exit
exit:
  ret i64 0
}

