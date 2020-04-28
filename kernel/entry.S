
R15 =   0X00
R14 =   0X08
R13 =   0X10
R12 =   0X18
R11 =   0X20
R10 =   0X28
R9  =   0X30
R8  =   0X38
RBX =   0x40
RCX =   0x48
RDX =   0x50
RSI =   0x58
RDI =   0x60
RBP =   0x68
DS  =   0x70
ES  =   0x78
RAX =   0x80
FUNC    =   0x88
ERRCODE =   0x90
RIP =   0x98        //用于特权级切换
CS  =   0xa0
RFLAGS  =   0xa8
OLDRSP  =   0xb0
OLDSS   =   0xb8



//还原程序执行现场
RESTORE_ALL:
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %r11
    popq    %r10
    popq    %r9
    popq    %r8
    popq    %rbx
    popq    %rcx
    popq    %rdx
    popq    %rsi
    popq    %rdi
    popq    %rbp

    popq    %rax            //pop ds/es在64位汇编中无效
    movq    %rax,   %ds
    popq    %rax
    movq    %rax,   %es
    popq    %rax
    addq    $0x10,  %rsp   //将栈指针上移16B，弹出FUNC和ERRCODE
    iretq



ret_from_exception:
.global ret_from_intr
ret_from_intr:
    jmp RESTORE_ALL



//#DE除法处理模块
.global divide_error
divide_error:
    pushq   $0              //#DE错误不会产生错误码，压入0是为了保证所有异常处理程序压栈顺序一致
    pushq   %rax
    leaq    do_divide_error(%rip),  %rax    //将处理程序的地址存入rax
    xchgq   %rax,   (%rsp)  //rax与栈中的值交换，将处理程序地址压入栈，并恢复rax

//程序现场保存
error_code:
    pushq   %rax
    movq    %es,    %rax
    pushq   %rax
    movq    %ds,    %rax
    pushq   %rax
    xorq    %rax,   %rax

    pushq   %rbp
    pushq   %rdi
    pushq   %rsi
    pushq   %rdx
    pushq   %rcx
    pushq   %rbx
    pushq   %r8
    pushq   %r9
    pushq   %r10
    pushq   %r11
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15

    cld
    movq    ERRCODE(%rsp),  %rsi
    movq    FUNC(%rsp), %rdx

    movq    $16,    %rdi
    movq    %rdi,   %ds
    movq    %rdi,   %es

    movq    %rsp,   %rdi

    callq   *%rdx

    jmp ret_from_exception




//TS异常
.global invalid_TSS
invalid_TSS:
    pushq   %rax
    leaq    do_invalid_TSS(%rip),   %rax
    xchgq   %rax,   (%rsp)
    jmp error_code



//#DB异常，调试异常
.global debug
debug:
    pushq	$0
	pushq	%rax
	leaq	do_debug(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code



//#BP异常，断点异常，INT 3指令除法
.global int3
int3:
	pushq	$0
	pushq	%rax
	leaq	do_int3(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code


//#OF溢出异常，INTO指令触发
.global overflow
overflow:
    pushq	$0
	pushq	%rax
	leaq	do_overflow(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code


//#BR越界异常，bounds指令触发
.global bounds
bounds:
	pushq	$0
	pushq	%rax
	leaq	do_bounds(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code



//#UD无效机器码
.global undefined_opcode
undefined_opcode:
	pushq	$0
	pushq	%rax
	leaq	do_undefined_opcode(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code



//#NM设备异常
.global dev_not_available	/* need rewrite */
dev_not_available:
	pushq	$0
	pushq	%rax
	leaq	do_dev_not_available(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code



//#DF双重错误
.global double_fault
double_fault:
	pushq	%rax
	leaq	do_double_fault(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code



//协处理器越界
.global coprocessor_segment_overrun
coprocessor_segment_overrun:
	pushq	$0
	pushq	%rax
	leaq	do_coprocessor_segment_overrun(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code



//#NP段不存在
.global segment_not_present
segment_not_present:
	pushq	%rax
	leaq	do_segment_not_present(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code



//SS，ss段错误
.global stack_segment_fault
stack_segment_fault:
	pushq	%rax
	leaq	do_stack_segment_fault(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code



//#GP通用性保护异常
.global general_protection
general_protection:
	pushq	%rax
	leaq	do_general_protection(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code



//PF异常
.global page_fault
page_fault:
    push    %rax
    leaq    do_page_fault(%rip),    %rax
    xchgq   %rax,   (%rsp)
    jmp error_code



//#MF
.global x87_FPU_error
x87_FPU_error:
	pushq	$0
	pushq	%rax
	leaq	do_x87_FPU_error(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code



//#AC对齐错误
.global alignment_check
alignment_check:
	pushq	%rax
	leaq	do_alignment_check(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code



//#MC机器检测错误
.global machine_check
machine_check:
	pushq	$0
	pushq	%rax
	leaq	do_machine_check(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code


//#XM
.global SIMD_exception
SIMD_exception:
	pushq	$0
	pushq	%rax
	leaq	do_SIMD_exception(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code



//#VE虚拟化异常
.global virtualization_exception
virtualization_exception:
	pushq	$0
	pushq	%rax
	leaq	do_virtualization_exception(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code




//#NMI不可屏蔽中断，不是异常不会产生错误码是外部中断
.global nmi
nmi:
    pushq   %rax
    cld
    pushq   %rax

    pushq   %rax
    movq    %es,    %rax
    pushq   %rax
    movq    %ds,    %rax
    pushq   %rax
    xorq    %rax,   %rax

    pushq   %rbp
    pushq   %rdi
    pushq   %rsi
    pushq   %rdx
    pushq   %rcx
    pushq   %rbx
    pushq   %r8
    pushq   %r9
    pushq   %r10
    pushq   %r11
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15

    movq    $16,    %rdx
    movq    %rdx,   %ds
    movq    %rdx,   %es

    movq    $0, %rsi
    movq    %rsp,   %rdi
    callq   do_nmi

    jmp RESTORE_ALL





