var data = {lines:[
{"lineNum":"    1","line":"const builtin = @import(\"builtin\");"},
{"lineNum":"    2","line":"const std = @import(\"../std.zig\");"},
{"lineNum":"    3","line":"const os = std.os;"},
{"lineNum":"    4","line":"const mem = std.mem;"},
{"lineNum":"    5","line":""},
{"lineNum":"    6","line":"pub fn supportsUnwinding(target: std.Target) bool {"},
{"lineNum":"    7","line":"    return switch (target.cpu.arch) {"},
{"lineNum":"    8","line":"        .x86 => switch (target.os.tag) {"},
{"lineNum":"    9","line":"            .linux, .netbsd, .solaris => true,"},
{"lineNum":"   10","line":"            else => false,"},
{"lineNum":"   11","line":"        },"},
{"lineNum":"   12","line":"        .x86_64 => switch (target.os.tag) {"},
{"lineNum":"   13","line":"            .linux, .netbsd, .freebsd, .openbsd, .macos, .solaris => true,"},
{"lineNum":"   14","line":"            else => false,"},
{"lineNum":"   15","line":"        },"},
{"lineNum":"   16","line":"        .arm => switch (target.os.tag) {"},
{"lineNum":"   17","line":"            .linux => true,"},
{"lineNum":"   18","line":"            else => false,"},
{"lineNum":"   19","line":"        },"},
{"lineNum":"   20","line":"        .aarch64 => switch (target.os.tag) {"},
{"lineNum":"   21","line":"            .linux, .netbsd, .freebsd, .macos => true,"},
{"lineNum":"   22","line":"            else => false,"},
{"lineNum":"   23","line":"        },"},
{"lineNum":"   24","line":"        else => false,"},
{"lineNum":"   25","line":"    };"},
{"lineNum":"   26","line":"}"},
{"lineNum":"   27","line":""},
{"lineNum":"   28","line":"pub fn ipRegNum() u8 {","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"   29","line":"    return switch (builtin.cpu.arch) {","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"   30","line":"        .x86 => 8,"},
{"lineNum":"   31","line":"        .x86_64 => 16,"},
{"lineNum":"   32","line":"        .arm => 15,"},
{"lineNum":"   33","line":"        .aarch64 => 32,"},
{"lineNum":"   34","line":"        else => unreachable,"},
{"lineNum":"   35","line":"    };"},
{"lineNum":"   36","line":"}"},
{"lineNum":"   37","line":""},
{"lineNum":"   38","line":"pub fn fpRegNum(reg_context: RegisterContext) u8 {","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"   39","line":"    return switch (builtin.cpu.arch) {","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"   40","line":"        // GCC on OS X historicaly did the opposite of ELF for these registers (only in .eh_frame), and that is now the convention for MachO"},
{"lineNum":"   41","line":"        .x86 => if (reg_context.eh_frame and reg_context.is_macho) 4 else 5,"},
{"lineNum":"   42","line":"        .x86_64 => 6,"},
{"lineNum":"   43","line":"        .arm => 11,"},
{"lineNum":"   44","line":"        .aarch64 => 29,"},
{"lineNum":"   45","line":"        else => unreachable,"},
{"lineNum":"   46","line":"    };"},
{"lineNum":"   47","line":"}"},
{"lineNum":"   48","line":""},
{"lineNum":"   49","line":"pub fn spRegNum(reg_context: RegisterContext) u8 {","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"   50","line":"    return switch (builtin.cpu.arch) {","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"   51","line":"        .x86 => if (reg_context.eh_frame and reg_context.is_macho) 5 else 4,"},
{"lineNum":"   52","line":"        .x86_64 => 7,"},
{"lineNum":"   53","line":"        .arm => 13,"},
{"lineNum":"   54","line":"        .aarch64 => 31,"},
{"lineNum":"   55","line":"        else => unreachable,"},
{"lineNum":"   56","line":"    };"},
{"lineNum":"   57","line":"}"},
{"lineNum":"   58","line":""},
{"lineNum":"   59","line":"/// Some platforms use pointer authentication - the upper bits of instruction pointers contain a signature."},
{"lineNum":"   60","line":"/// This function clears these signature bits to make the pointer usable."},
{"lineNum":"   61","line":"pub inline fn stripInstructionPtrAuthCode(ptr: usize) usize {"},
{"lineNum":"   62","line":"    if (builtin.cpu.arch == .aarch64) {"},
{"lineNum":"   63","line":"        // `hint 0x07` maps to `xpaclri` (or `nop` if the hardware doesn\'t support it)"},
{"lineNum":"   64","line":"        // The save / restore is because `xpaclri` operates on x30 (LR)"},
{"lineNum":"   65","line":"        return asm ("},
{"lineNum":"   66","line":"            \\\\mov x16, x30"},
{"lineNum":"   67","line":"            \\\\mov x30, x15"},
{"lineNum":"   68","line":"            \\\\hint 0x07"},
{"lineNum":"   69","line":"            \\\\mov x15, x30"},
{"lineNum":"   70","line":"            \\\\mov x30, x16"},
{"lineNum":"   71","line":"            : [ret] \"={x15}\" (-> usize),"},
{"lineNum":"   72","line":"            : [ptr] \"{x15}\" (ptr),"},
{"lineNum":"   73","line":"            : \"x16\""},
{"lineNum":"   74","line":"        );"},
{"lineNum":"   75","line":"    }"},
{"lineNum":"   76","line":""},
{"lineNum":"   77","line":"    return ptr;","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"   78","line":"}"},
{"lineNum":"   79","line":""},
{"lineNum":"   80","line":"pub const RegisterContext = struct {"},
{"lineNum":"   81","line":"    eh_frame: bool,"},
{"lineNum":"   82","line":"    is_macho: bool,"},
{"lineNum":"   83","line":"};"},
{"lineNum":"   84","line":""},
{"lineNum":"   85","line":"pub const AbiError = error{"},
{"lineNum":"   86","line":"    InvalidRegister,"},
{"lineNum":"   87","line":"    UnimplementedArch,"},
{"lineNum":"   88","line":"    UnimplementedOs,"},
{"lineNum":"   89","line":"    RegisterContextRequired,"},
{"lineNum":"   90","line":"    ThreadContextNotSupported,"},
{"lineNum":"   91","line":"};"},
{"lineNum":"   92","line":""},
{"lineNum":"   93","line":"fn RegValueReturnType(comptime ContextPtrType: type, comptime T: type) type {"},
{"lineNum":"   94","line":"    const reg_bytes_type = comptime RegBytesReturnType(ContextPtrType);"},
{"lineNum":"   95","line":"    const info = @typeInfo(reg_bytes_type).Pointer;"},
{"lineNum":"   96","line":"    return @Type(.{"},
{"lineNum":"   97","line":"        .Pointer = .{"},
{"lineNum":"   98","line":"            .size = .One,"},
{"lineNum":"   99","line":"            .is_const = info.is_const,"},
{"lineNum":"  100","line":"            .is_volatile = info.is_volatile,"},
{"lineNum":"  101","line":"            .is_allowzero = info.is_allowzero,"},
{"lineNum":"  102","line":"            .alignment = info.alignment,"},
{"lineNum":"  103","line":"            .address_space = info.address_space,"},
{"lineNum":"  104","line":"            .child = T,"},
{"lineNum":"  105","line":"            .sentinel = null,"},
{"lineNum":"  106","line":"        },"},
{"lineNum":"  107","line":"    });"},
{"lineNum":"  108","line":"}"},
{"lineNum":"  109","line":""},
{"lineNum":"  110","line":"/// Returns a pointer to a register stored in a ThreadContext, preserving the pointer attributes of the context."},
{"lineNum":"  111","line":"pub fn regValueNative("},
{"lineNum":"  112","line":"    comptime T: type,"},
{"lineNum":"  113","line":"    thread_context_ptr: anytype,"},
{"lineNum":"  114","line":"    reg_number: u8,"},
{"lineNum":"  115","line":"    reg_context: ?RegisterContext,"},
{"lineNum":"  116","line":") !RegValueReturnType(@TypeOf(thread_context_ptr), T) {","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  117","line":"    const reg_bytes = try regBytes(thread_context_ptr, reg_number, reg_context);","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  118","line":"    if (@sizeOf(T) != reg_bytes.len) return error.IncompatibleRegisterSize;","class":"lineNoCov","hits":"0","possible_hits":"4",},
{"lineNum":"  119","line":"    return mem.bytesAsValue(T, reg_bytes[0..@sizeOf(T)]);","class":"lineNoCov","hits":"0","possible_hits":"4",},
{"lineNum":"  120","line":"}"},
{"lineNum":"  121","line":""},
{"lineNum":"  122","line":"fn RegBytesReturnType(comptime ContextPtrType: type) type {"},
{"lineNum":"  123","line":"    const info = @typeInfo(ContextPtrType);"},
{"lineNum":"  124","line":"    if (info != .Pointer or info.Pointer.child != std.debug.ThreadContext) {"},
{"lineNum":"  125","line":"        @compileError(\"Expected a pointer to std.debug.ThreadContext, got \" ++ @typeName(@TypeOf(ContextPtrType)));"},
{"lineNum":"  126","line":"    }"},
{"lineNum":"  127","line":""},
{"lineNum":"  128","line":"    return if (info.Pointer.is_const) return []const u8 else []u8;"},
{"lineNum":"  129","line":"}"},
{"lineNum":"  130","line":""},
{"lineNum":"  131","line":"/// Returns a slice containing the backing storage for `reg_number`."},
{"lineNum":"  132","line":"///"},
{"lineNum":"  133","line":"/// `reg_context` describes in what context the register number is used, as it can have different"},
{"lineNum":"  134","line":"/// meanings depending on the DWARF container. It is only required when getting the stack or"},
{"lineNum":"  135","line":"/// frame pointer register on some architectures."},
{"lineNum":"  136","line":"pub fn regBytes("},
{"lineNum":"  137","line":"    thread_context_ptr: anytype,"},
{"lineNum":"  138","line":"    reg_number: u8,"},
{"lineNum":"  139","line":"    reg_context: ?RegisterContext,"},
{"lineNum":"  140","line":") AbiError!RegBytesReturnType(@TypeOf(thread_context_ptr)) {","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  141","line":"    if (builtin.os.tag == .windows) {"},
{"lineNum":"  142","line":"        return switch (builtin.cpu.arch) {"},
{"lineNum":"  143","line":"            .x86 => switch (reg_number) {"},
{"lineNum":"  144","line":"                0 => mem.asBytes(&thread_context_ptr.Eax),"},
{"lineNum":"  145","line":"                1 => mem.asBytes(&thread_context_ptr.Ecx),"},
{"lineNum":"  146","line":"                2 => mem.asBytes(&thread_context_ptr.Edx),"},
{"lineNum":"  147","line":"                3 => mem.asBytes(&thread_context_ptr.Ebx),"},
{"lineNum":"  148","line":"                4 => mem.asBytes(&thread_context_ptr.Esp),"},
{"lineNum":"  149","line":"                5 => mem.asBytes(&thread_context_ptr.Ebp),"},
{"lineNum":"  150","line":"                6 => mem.asBytes(&thread_context_ptr.Esi),"},
{"lineNum":"  151","line":"                7 => mem.asBytes(&thread_context_ptr.Edi),"},
{"lineNum":"  152","line":"                8 => mem.asBytes(&thread_context_ptr.Eip),"},
{"lineNum":"  153","line":"                9 => mem.asBytes(&thread_context_ptr.EFlags),"},
{"lineNum":"  154","line":"                10 => mem.asBytes(&thread_context_ptr.SegCs),"},
{"lineNum":"  155","line":"                11 => mem.asBytes(&thread_context_ptr.SegSs),"},
{"lineNum":"  156","line":"                12 => mem.asBytes(&thread_context_ptr.SegDs),"},
{"lineNum":"  157","line":"                13 => mem.asBytes(&thread_context_ptr.SegEs),"},
{"lineNum":"  158","line":"                14 => mem.asBytes(&thread_context_ptr.SegFs),"},
{"lineNum":"  159","line":"                15 => mem.asBytes(&thread_context_ptr.SegGs),"},
{"lineNum":"  160","line":"                else => error.InvalidRegister,"},
{"lineNum":"  161","line":"            },"},
{"lineNum":"  162","line":"            .x86_64 => switch (reg_number) {"},
{"lineNum":"  163","line":"                0 => mem.asBytes(&thread_context_ptr.Rax),"},
{"lineNum":"  164","line":"                1 => mem.asBytes(&thread_context_ptr.Rdx),"},
{"lineNum":"  165","line":"                2 => mem.asBytes(&thread_context_ptr.Rcx),"},
{"lineNum":"  166","line":"                3 => mem.asBytes(&thread_context_ptr.Rbx),"},
{"lineNum":"  167","line":"                4 => mem.asBytes(&thread_context_ptr.Rsi),"},
{"lineNum":"  168","line":"                5 => mem.asBytes(&thread_context_ptr.Rdi),"},
{"lineNum":"  169","line":"                6 => mem.asBytes(&thread_context_ptr.Rbp),"},
{"lineNum":"  170","line":"                7 => mem.asBytes(&thread_context_ptr.Rsp),"},
{"lineNum":"  171","line":"                8 => mem.asBytes(&thread_context_ptr.R8),"},
{"lineNum":"  172","line":"                9 => mem.asBytes(&thread_context_ptr.R9),"},
{"lineNum":"  173","line":"                10 => mem.asBytes(&thread_context_ptr.R10),"},
{"lineNum":"  174","line":"                11 => mem.asBytes(&thread_context_ptr.R11),"},
{"lineNum":"  175","line":"                12 => mem.asBytes(&thread_context_ptr.R12),"},
{"lineNum":"  176","line":"                13 => mem.asBytes(&thread_context_ptr.R13),"},
{"lineNum":"  177","line":"                14 => mem.asBytes(&thread_context_ptr.R14),"},
{"lineNum":"  178","line":"                15 => mem.asBytes(&thread_context_ptr.R15),"},
{"lineNum":"  179","line":"                16 => mem.asBytes(&thread_context_ptr.Rip),"},
{"lineNum":"  180","line":"                else => error.InvalidRegister,"},
{"lineNum":"  181","line":"            },"},
{"lineNum":"  182","line":"            .aarch64 => switch (reg_number) {"},
{"lineNum":"  183","line":"                0...30 => mem.asBytes(&thread_context_ptr.DUMMYUNIONNAME.X[reg_number]),"},
{"lineNum":"  184","line":"                31 => mem.asBytes(&thread_context_ptr.Sp),"},
{"lineNum":"  185","line":"                32 => mem.asBytes(&thread_context_ptr.Pc),"},
{"lineNum":"  186","line":"                else => error.InvalidRegister,"},
{"lineNum":"  187","line":"            },"},
{"lineNum":"  188","line":"            else => error.UnimplementedArch,"},
{"lineNum":"  189","line":"        };"},
{"lineNum":"  190","line":"    }"},
{"lineNum":"  191","line":""},
{"lineNum":"  192","line":"    if (!std.debug.have_ucontext) return error.ThreadContextNotSupported;"},
{"lineNum":"  193","line":""},
{"lineNum":"  194","line":"    const ucontext_ptr = thread_context_ptr;","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  195","line":"    return switch (builtin.cpu.arch) {","class":"lineNoCov","hits":"0","possible_hits":"4",},
{"lineNum":"  196","line":"        .x86 => switch (builtin.os.tag) {"},
{"lineNum":"  197","line":"            .linux, .netbsd, .solaris => switch (reg_number) {"},
{"lineNum":"  198","line":"                0 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.EAX]),"},
{"lineNum":"  199","line":"                1 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.ECX]),"},
{"lineNum":"  200","line":"                2 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.EDX]),"},
{"lineNum":"  201","line":"                3 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.EBX]),"},
{"lineNum":"  202","line":"                4...5 => if (reg_context) |r| bytes: {"},
{"lineNum":"  203","line":"                    if (reg_number == 4) {"},
{"lineNum":"  204","line":"                        break :bytes if (r.eh_frame and r.is_macho)"},
{"lineNum":"  205","line":"                            mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.EBP])"},
{"lineNum":"  206","line":"                        else"},
{"lineNum":"  207","line":"                            mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.ESP]);"},
{"lineNum":"  208","line":"                    } else {"},
{"lineNum":"  209","line":"                        break :bytes if (r.eh_frame and r.is_macho)"},
{"lineNum":"  210","line":"                            mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.ESP])"},
{"lineNum":"  211","line":"                        else"},
{"lineNum":"  212","line":"                            mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.EBP]);"},
{"lineNum":"  213","line":"                    }"},
{"lineNum":"  214","line":"                } else error.RegisterContextRequired,"},
{"lineNum":"  215","line":"                6 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.ESI]),"},
{"lineNum":"  216","line":"                7 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.EDI]),"},
{"lineNum":"  217","line":"                8 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.EIP]),"},
{"lineNum":"  218","line":"                9 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.EFL]),"},
{"lineNum":"  219","line":"                10 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.CS]),"},
{"lineNum":"  220","line":"                11 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.SS]),"},
{"lineNum":"  221","line":"                12 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.DS]),"},
{"lineNum":"  222","line":"                13 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.ES]),"},
{"lineNum":"  223","line":"                14 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.FS]),"},
{"lineNum":"  224","line":"                15 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.GS]),"},
{"lineNum":"  225","line":"                16...23 => error.InvalidRegister, // TODO: Support loading ST0-ST7 from mcontext.fpregs"},
{"lineNum":"  226","line":"                32...39 => error.InvalidRegister, // TODO: Support loading XMM0-XMM7 from mcontext.fpregs"},
{"lineNum":"  227","line":"                else => error.InvalidRegister,"},
{"lineNum":"  228","line":"            },"},
{"lineNum":"  229","line":"            else => error.UnimplementedOs,"},
{"lineNum":"  230","line":"        },"},
{"lineNum":"  231","line":"        .x86_64 => switch (builtin.os.tag) {"},
{"lineNum":"  232","line":"            .linux, .netbsd, .solaris => switch (reg_number) {","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  233","line":"                0 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RAX]),","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  234","line":"                1 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RDX]),","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  235","line":"                2 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RCX]),","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  236","line":"                3 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RBX]),","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  237","line":"                4 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RSI]),","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  238","line":"                5 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RDI]),","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  239","line":"                6 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RBP]),","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  240","line":"                7 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RSP]),","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  241","line":"                8 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.R8]),","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  242","line":"                9 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.R9]),","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  243","line":"                10 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.R10]),","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  244","line":"                11 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.R11]),","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  245","line":"                12 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.R12]),","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  246","line":"                13 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.R13]),","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  247","line":"                14 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.R14]),","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  248","line":"                15 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.R15]),","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  249","line":"                16 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RIP]),","class":"lineNoCov","hits":"0","possible_hits":"4",},
{"lineNum":"  250","line":"                17...32 => |i| mem.asBytes(&ucontext_ptr.mcontext.fpregs.xmm[i - 17]),","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"  251","line":"                else => error.InvalidRegister,"},
{"lineNum":"  252","line":"            },"},
{"lineNum":"  253","line":"            .freebsd => switch (reg_number) {"},
{"lineNum":"  254","line":"                0 => mem.asBytes(&ucontext_ptr.mcontext.rax),"},
{"lineNum":"  255","line":"                1 => mem.asBytes(&ucontext_ptr.mcontext.rdx),"},
{"lineNum":"  256","line":"                2 => mem.asBytes(&ucontext_ptr.mcontext.rcx),"},
{"lineNum":"  257","line":"                3 => mem.asBytes(&ucontext_ptr.mcontext.rbx),"},
{"lineNum":"  258","line":"                4 => mem.asBytes(&ucontext_ptr.mcontext.rsi),"},
{"lineNum":"  259","line":"                5 => mem.asBytes(&ucontext_ptr.mcontext.rdi),"},
{"lineNum":"  260","line":"                6 => mem.asBytes(&ucontext_ptr.mcontext.rbp),"},
{"lineNum":"  261","line":"                7 => mem.asBytes(&ucontext_ptr.mcontext.rsp),"},
{"lineNum":"  262","line":"                8 => mem.asBytes(&ucontext_ptr.mcontext.r8),"},
{"lineNum":"  263","line":"                9 => mem.asBytes(&ucontext_ptr.mcontext.r9),"},
{"lineNum":"  264","line":"                10 => mem.asBytes(&ucontext_ptr.mcontext.r10),"},
{"lineNum":"  265","line":"                11 => mem.asBytes(&ucontext_ptr.mcontext.r11),"},
{"lineNum":"  266","line":"                12 => mem.asBytes(&ucontext_ptr.mcontext.r12),"},
{"lineNum":"  267","line":"                13 => mem.asBytes(&ucontext_ptr.mcontext.r13),"},
{"lineNum":"  268","line":"                14 => mem.asBytes(&ucontext_ptr.mcontext.r14),"},
{"lineNum":"  269","line":"                15 => mem.asBytes(&ucontext_ptr.mcontext.r15),"},
{"lineNum":"  270","line":"                16 => mem.asBytes(&ucontext_ptr.mcontext.rip),"},
{"lineNum":"  271","line":"                // TODO: Extract xmm state from mcontext.fpstate?"},
{"lineNum":"  272","line":"                else => error.InvalidRegister,"},
{"lineNum":"  273","line":"            },"},
{"lineNum":"  274","line":"            .openbsd => switch (reg_number) {"},
{"lineNum":"  275","line":"                0 => mem.asBytes(&ucontext_ptr.sc_rax),"},
{"lineNum":"  276","line":"                1 => mem.asBytes(&ucontext_ptr.sc_rdx),"},
{"lineNum":"  277","line":"                2 => mem.asBytes(&ucontext_ptr.sc_rcx),"},
{"lineNum":"  278","line":"                3 => mem.asBytes(&ucontext_ptr.sc_rbx),"},
{"lineNum":"  279","line":"                4 => mem.asBytes(&ucontext_ptr.sc_rsi),"},
{"lineNum":"  280","line":"                5 => mem.asBytes(&ucontext_ptr.sc_rdi),"},
{"lineNum":"  281","line":"                6 => mem.asBytes(&ucontext_ptr.sc_rbp),"},
{"lineNum":"  282","line":"                7 => mem.asBytes(&ucontext_ptr.sc_rsp),"},
{"lineNum":"  283","line":"                8 => mem.asBytes(&ucontext_ptr.sc_r8),"},
{"lineNum":"  284","line":"                9 => mem.asBytes(&ucontext_ptr.sc_r9),"},
{"lineNum":"  285","line":"                10 => mem.asBytes(&ucontext_ptr.sc_r10),"},
{"lineNum":"  286","line":"                11 => mem.asBytes(&ucontext_ptr.sc_r11),"},
{"lineNum":"  287","line":"                12 => mem.asBytes(&ucontext_ptr.sc_r12),"},
{"lineNum":"  288","line":"                13 => mem.asBytes(&ucontext_ptr.sc_r13),"},
{"lineNum":"  289","line":"                14 => mem.asBytes(&ucontext_ptr.sc_r14),"},
{"lineNum":"  290","line":"                15 => mem.asBytes(&ucontext_ptr.sc_r15),"},
{"lineNum":"  291","line":"                16 => mem.asBytes(&ucontext_ptr.sc_rip),"},
{"lineNum":"  292","line":"                // TODO: Extract xmm state from sc_fpstate?"},
{"lineNum":"  293","line":"                else => error.InvalidRegister,"},
{"lineNum":"  294","line":"            },"},
{"lineNum":"  295","line":"            .macos => switch (reg_number) {"},
{"lineNum":"  296","line":"                0 => mem.asBytes(&ucontext_ptr.mcontext.ss.rax),"},
{"lineNum":"  297","line":"                1 => mem.asBytes(&ucontext_ptr.mcontext.ss.rdx),"},
{"lineNum":"  298","line":"                2 => mem.asBytes(&ucontext_ptr.mcontext.ss.rcx),"},
{"lineNum":"  299","line":"                3 => mem.asBytes(&ucontext_ptr.mcontext.ss.rbx),"},
{"lineNum":"  300","line":"                4 => mem.asBytes(&ucontext_ptr.mcontext.ss.rsi),"},
{"lineNum":"  301","line":"                5 => mem.asBytes(&ucontext_ptr.mcontext.ss.rdi),"},
{"lineNum":"  302","line":"                6 => mem.asBytes(&ucontext_ptr.mcontext.ss.rbp),"},
{"lineNum":"  303","line":"                7 => mem.asBytes(&ucontext_ptr.mcontext.ss.rsp),"},
{"lineNum":"  304","line":"                8 => mem.asBytes(&ucontext_ptr.mcontext.ss.r8),"},
{"lineNum":"  305","line":"                9 => mem.asBytes(&ucontext_ptr.mcontext.ss.r9),"},
{"lineNum":"  306","line":"                10 => mem.asBytes(&ucontext_ptr.mcontext.ss.r10),"},
{"lineNum":"  307","line":"                11 => mem.asBytes(&ucontext_ptr.mcontext.ss.r11),"},
{"lineNum":"  308","line":"                12 => mem.asBytes(&ucontext_ptr.mcontext.ss.r12),"},
{"lineNum":"  309","line":"                13 => mem.asBytes(&ucontext_ptr.mcontext.ss.r13),"},
{"lineNum":"  310","line":"                14 => mem.asBytes(&ucontext_ptr.mcontext.ss.r14),"},
{"lineNum":"  311","line":"                15 => mem.asBytes(&ucontext_ptr.mcontext.ss.r15),"},
{"lineNum":"  312","line":"                16 => mem.asBytes(&ucontext_ptr.mcontext.ss.rip),"},
{"lineNum":"  313","line":"                else => error.InvalidRegister,"},
{"lineNum":"  314","line":"            },"},
{"lineNum":"  315","line":"            else => error.UnimplementedOs,"},
{"lineNum":"  316","line":"        },"},
{"lineNum":"  317","line":"        .arm => switch (builtin.os.tag) {"},
{"lineNum":"  318","line":"            .linux => switch (reg_number) {"},
{"lineNum":"  319","line":"                0 => mem.asBytes(&ucontext_ptr.mcontext.arm_r0),"},
{"lineNum":"  320","line":"                1 => mem.asBytes(&ucontext_ptr.mcontext.arm_r1),"},
{"lineNum":"  321","line":"                2 => mem.asBytes(&ucontext_ptr.mcontext.arm_r2),"},
{"lineNum":"  322","line":"                3 => mem.asBytes(&ucontext_ptr.mcontext.arm_r3),"},
{"lineNum":"  323","line":"                4 => mem.asBytes(&ucontext_ptr.mcontext.arm_r4),"},
{"lineNum":"  324","line":"                5 => mem.asBytes(&ucontext_ptr.mcontext.arm_r5),"},
{"lineNum":"  325","line":"                6 => mem.asBytes(&ucontext_ptr.mcontext.arm_r6),"},
{"lineNum":"  326","line":"                7 => mem.asBytes(&ucontext_ptr.mcontext.arm_r7),"},
{"lineNum":"  327","line":"                8 => mem.asBytes(&ucontext_ptr.mcontext.arm_r8),"},
{"lineNum":"  328","line":"                9 => mem.asBytes(&ucontext_ptr.mcontext.arm_r9),"},
{"lineNum":"  329","line":"                10 => mem.asBytes(&ucontext_ptr.mcontext.arm_r10),"},
{"lineNum":"  330","line":"                11 => mem.asBytes(&ucontext_ptr.mcontext.arm_fp),"},
{"lineNum":"  331","line":"                12 => mem.asBytes(&ucontext_ptr.mcontext.arm_ip),"},
{"lineNum":"  332","line":"                13 => mem.asBytes(&ucontext_ptr.mcontext.arm_sp),"},
{"lineNum":"  333","line":"                14 => mem.asBytes(&ucontext_ptr.mcontext.arm_lr),"},
{"lineNum":"  334","line":"                15 => mem.asBytes(&ucontext_ptr.mcontext.arm_pc),"},
{"lineNum":"  335","line":"                // CPSR is not allocated a register number (See: https://github.com/ARM-software/abi-aa/blob/main/aadwarf32/aadwarf32.rst, Section 4.1)"},
{"lineNum":"  336","line":"                else => error.InvalidRegister,"},
{"lineNum":"  337","line":"            },"},
{"lineNum":"  338","line":"            else => error.UnimplementedOs,"},
{"lineNum":"  339","line":"        },"},
{"lineNum":"  340","line":"        .aarch64 => switch (builtin.os.tag) {"},
{"lineNum":"  341","line":"            .macos => switch (reg_number) {"},
{"lineNum":"  342","line":"                0...28 => mem.asBytes(&ucontext_ptr.mcontext.ss.regs[reg_number]),"},
{"lineNum":"  343","line":"                29 => mem.asBytes(&ucontext_ptr.mcontext.ss.fp),"},
{"lineNum":"  344","line":"                30 => mem.asBytes(&ucontext_ptr.mcontext.ss.lr),"},
{"lineNum":"  345","line":"                31 => mem.asBytes(&ucontext_ptr.mcontext.ss.sp),"},
{"lineNum":"  346","line":"                32 => mem.asBytes(&ucontext_ptr.mcontext.ss.pc),"},
{"lineNum":"  347","line":""},
{"lineNum":"  348","line":"                // TODO: Find storage for this state"},
{"lineNum":"  349","line":"                //34 => mem.asBytes(&ucontext_ptr.ra_sign_state),"},
{"lineNum":"  350","line":""},
{"lineNum":"  351","line":"                // V0-V31"},
{"lineNum":"  352","line":"                64...95 => mem.asBytes(&ucontext_ptr.mcontext.ns.q[reg_number - 64]),"},
{"lineNum":"  353","line":"                else => error.InvalidRegister,"},
{"lineNum":"  354","line":"            },"},
{"lineNum":"  355","line":"            .netbsd => switch (reg_number) {"},
{"lineNum":"  356","line":"                0...34 => mem.asBytes(&ucontext_ptr.mcontext.gregs[reg_number]),"},
{"lineNum":"  357","line":"                else => error.InvalidRegister,"},
{"lineNum":"  358","line":"            },"},
{"lineNum":"  359","line":"            .freebsd => switch (reg_number) {"},
{"lineNum":"  360","line":"                0...29 => mem.asBytes(&ucontext_ptr.mcontext.gpregs.x[reg_number]),"},
{"lineNum":"  361","line":"                30 => mem.asBytes(&ucontext_ptr.mcontext.gpregs.lr),"},
{"lineNum":"  362","line":"                31 => mem.asBytes(&ucontext_ptr.mcontext.gpregs.sp),"},
{"lineNum":"  363","line":""},
{"lineNum":"  364","line":"                // TODO: This seems wrong, but it was in the previous debug.zig code for mapping PC, check this"},
{"lineNum":"  365","line":"                32 => mem.asBytes(&ucontext_ptr.mcontext.gpregs.elr),"},
{"lineNum":"  366","line":""},
{"lineNum":"  367","line":"                else => error.InvalidRegister,"},
{"lineNum":"  368","line":"            },"},
{"lineNum":"  369","line":"            else => switch (reg_number) {"},
{"lineNum":"  370","line":"                0...30 => mem.asBytes(&ucontext_ptr.mcontext.regs[reg_number]),"},
{"lineNum":"  371","line":"                31 => mem.asBytes(&ucontext_ptr.mcontext.sp),"},
{"lineNum":"  372","line":"                32 => mem.asBytes(&ucontext_ptr.mcontext.pc),"},
{"lineNum":"  373","line":"                else => error.InvalidRegister,"},
{"lineNum":"  374","line":"            },"},
{"lineNum":"  375","line":"        },"},
{"lineNum":"  376","line":"        else => error.UnimplementedArch,"},
{"lineNum":"  377","line":"    };"},
{"lineNum":"  378","line":"}"},
{"lineNum":"  379","line":""},
{"lineNum":"  380","line":"/// Returns the ABI-defined default value this register has in the unwinding table"},
{"lineNum":"  381","line":"/// before running any of the CIE instructions. The DWARF spec defines these as having"},
{"lineNum":"  382","line":"/// the .undefined rule by default, but allows ABI authors to override that."},
{"lineNum":"  383","line":"pub fn getRegDefaultValue(reg_number: u8, context: *std.dwarf.UnwindContext, out: []u8) !void {","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"  384","line":"    switch (builtin.cpu.arch) {"},
{"lineNum":"  385","line":"        .aarch64 => {"},
{"lineNum":"  386","line":"            // Callee-saved registers are initialized as if they had the .same_value rule"},
{"lineNum":"  387","line":"            if (reg_number >= 19 and reg_number <= 28) {"},
{"lineNum":"  388","line":"                const src = try regBytes(context.thread_context, reg_number, context.reg_context);"},
{"lineNum":"  389","line":"                if (src.len != out.len) return error.RegisterSizeMismatch;"},
{"lineNum":"  390","line":"                @memcpy(out, src);"},
{"lineNum":"  391","line":"                return;"},
{"lineNum":"  392","line":"            }"},
{"lineNum":"  393","line":"        },"},
{"lineNum":"  394","line":"        else => {},"},
{"lineNum":"  395","line":"    }"},
{"lineNum":"  396","line":""},
{"lineNum":"  397","line":"    @memset(out, undefined);","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"  398","line":"}"},
]};
var percent_low = 25;var percent_high = 75;
var header = { "command" : "test", "date" : "2024-04-26 16:14:49", "instrumented" : 35, "covered" : 0,};
var merged_data = [];
