.section .text		//伪指令，.text表代码段，只读和可执行

.globl _start		//标记为全局符号，链接器会用到

_start:			//程序的入口
	mov	$0x10,	%ax
	mov	%ax,	%ds
	mov	%ax,	%es
	mov	%ax,	%fs
	mov	%ax,	%ss
	mov	$0x7e00,	%esp

	lgdt	GDT_Pointer(%rip)

	lidt	IDT_Pointer(%rip)

	mov	$0x10,	%ax
	mov	%ax,	%ds
	mov	%ax,	%es
	mov	%ax,	%fs
	mov	%ax,	%ss
	mov	%ax,	%gs
	mov	$0x7e00,	%rsp

	movq	$0x101000,	%rax
	movq	%rax,	%cr3
	movq	switch_seg(%rip),	%rax
	pushq	$0x08
	pushq	%rax
	lretq

switch_seg:
	.quad	entry64

entry64:
	movq	$0x10,	%rax
	movq	%rax,	%ds
	movq	%rax,	%es
	movq	%rax,	%gs
	movq	%rax,	%ss
	movq	_stack_start(%rip),	%rsp
	
setup_IDT:		//中断门描述符和陷阱门描述符128位，格式化放入rdx:rax
	leaq	ignore_int(%rip),	%rdx	//Load effective address,不解引用，直接将ignore_int+rip的值给rdx，而不是ignore_int+rip处的值
	movq	$(0x08 << 16),	%rax
	movw	%dx,	%ax
	movq	$(0x8E00 << 32),	%rcx
	addq	%rcx,	%rax
	movl	%edx,	%ecx
	shrl	$16,	%eax
	shlq	$48,	%rcx
	addq	%rcx,	%rax
	shrq	$32,	%rdx
	leaq	IDT(%rip),	%rdi
	mov	$256,	%rcx
rp_sidt:		//初始化256个idt项
	movq	%rax,	(%rdi)
	movq	%rdx,	8(%rdi)
	addq	$0x10,	%rdi
	dec	%rcx
	jne	rp_sidt

setup_TSS64:			//初始化GDT内的TSS描述符,TSS描述符128位
	leaq	TSS64_Table(%rip),	%rdx
	xorq	%rax,	%rax
	xorq	%rcx,	%rcx
	movq	$0x89,	%rax
	shlq	$40,	%rax
	movl	%edx,	%ecx
	shrl	$24,	%ecx
	shlq	$56,	%rcx
	addq	%rcx,	%rax
	xorq	%rcx,	%rcx
	movl	%edx,	%ecx
	addl	$0xffffff,	%ecx
	shlq	$16,	%rcx
	addq	%rcx,	%rax
	addq	$103,	%rax
	leaq	GDT(%rip),	%rdi
	movq	%rax,	64(%rdi)
	shrq	$32,	%rdx
	movq	%rdx,	72(%rdi)
	
	mov	$0x40,	%ax
	ltr	%ax		//加载到gdt

	movq	go_to_kernel(%rip),	%rax
	pushq	$0x08
	pushq	%rax
	lretq

go_to_kernel:
	.quad	Start_Kernel



ignore_int:			//显示信息
	cld
	pushq   %rax
        pushq   %rbx
        pushq   %rcx
        pushq   %rdx
        pushq   %rbp
        pushq   %rdi
        pushq   %rsi

        pushq   %r8
        pushq   %r9
        pushq   %r10
        pushq   %r11
        pushq   %r12
        pushq   %r13
        pushq   %r14
        pushq   %r15
	
	movq    %es,    %rax
        pushq   %rax
        movq    %ds,    %rax
        pushq   %rax
	
	movq    $0x10,  %rax
        movq    %rax,   %ds
        movq    %rax,   %es
	
	leaq    int_msg(%rip),  %rax
        pushq   %rax
        movq    %rax,   %rdx
        movq    $0x00000000,    %rsi
        movq    $0x00ff0000,    %rdi
        movq    $0,     %rax
        callq   color_printk		//寄存器传参，顺序为rdi,rsi,rdx,rcx,r8,r9
        addq    $0x8,   %rsp
	
Loop:
        jmp     Loop

        popq    %rax
        movq    %rax,   %ds
        popq    %rax
        movq    %rax,   %es

        popq    %r15
        popq    %r14
        popq    %r13
        popq    %r12
        popq    %r11
        popq    %r10
        popq    %r9
        popq    %r8

        popq    %rsi
        popq    %rdi
        popq    %rbp
        popq    %rdx
        popq    %rcx
        popq    %rbx
        popq    %rax
        iretq
	
int_msg:
	.asciz	"Unknown interrupt or fault at RIP\n"
	
ENTRY(_stack_start)
        .quad   init_task_union + 32768


.align	8
.org	0x1000              //内核定位在0x100000处，PML4T定位在0x101000处
__PML4E:
	.quad	0x102007
	.fill	255,8,0
	.quad	0x102007        //PDPT在0x102000处
	.fill	255,8,0

.org	0x2000              //PDPT在0x102000处
__PDPTE:
	.quad	0x103003        //PDT在0x103000处
	.fill	511,8,0

.org	0x3000
__PDE:
	.quad	0x000083
	.quad	0x200083
	.quad	0x400083
	.quad	0x600083
	.quad	0x800083
	.quad	0xe0000083      //物理地址基地址0xa00000，root模式/可读可写/存在
	.quad	0xe0200083
	.quad	0xe0400083
	.quad	0xe0600083
	.quad	0xe0800083
	.quad	0xe0a00083
	.quad	0xe0c00083
	.quad	0xe0e00083
	.fill	499,8,0



.section .data

.globl	GDT

GDT:
	.quad	0x0000000000000000	//quard word伪指令，4字节,IA-32e模式的GDT项沿用保护模式的GDT项，但忽略段基址和段长度
	.quad	0x0020980000000000	//D/B=0
                                //L=1	64位模式，默认位宽32位
                                //P=1	段存在
                                //DPL=00	描述符特权级=0
                                //S=1	代码段or数据段
                                //TYPE=1000	代码段，非一致性（依从代码），不可读，未访问

	.quad	0x0000920000000000	//P=1	段存在内存中
                                //DPL=0
                                //S=1	代码段or数据段
                                //TYPE=0010	数据段（数据段忽略D/B和L），非一致性（依从）,可读，未访问

	.quad	0x0020f80000000000	//代码段，64位模式，DPL=3，非一致性（依从），不可读，未访问
	.quad	0x0000f20000000000	//数据段,DPL=3
	.quad	0x00cf9a000000ffff	//代码段，32位,DPL=0,段基址 0x0，段长度 0xfffff,粒度4kb
	.quad	0x00cf92000000ffff	//数据段，32位,DPL=0,段基址 0x0，段长度 0xfffff,粒度4kb
	.fill	10,8,0			    //2个TSS，128bit,16字节*8


GDT_Pointer:
	.word	GDT_Pointer - GDT - 1
	.quad	GDT



.globl	IDT

IDT:
	.fill	512,8,0			//重复512次设置8个字节的值为0

IDT_Pointer:
	.word	IDT_Pointer - IDT - 1
	.quad	IDT



.globl	TSS64_Table

TSS64_Table:
	.fill	13,8,0

TSS64_Pointer:
	.word	TSS64_Pointer - TSS64_Table - 1
	.quad	TSS64_Table
