
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
    popq    %rax,   %es
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




//PF异常
.global page_fault
page_fault:
    push    %rax
    leaq    do_page_fault(%rip),    %rax
    xchgq   %rax,   (%rsp)
    jmp error_code




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





