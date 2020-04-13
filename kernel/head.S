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
	
	mov	%ax,	%ds
	mov	%ax,	%es
	mov	%ax,	%fs
	mov	%ax,	%ss
	mov	%ax,	%gs
	mov	$0x7e00,	%rsp
	
	movq	$0x101000,	%rax
	movq	%rax,	%cr3
	movq	switch_seg(%rip),	%rax
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
	movq	$0xffff800000007E00,	%rsp
	
	movq	go_to_kernel(%rip),	%rax
	pushq	$0x08
	pushq	%rax
	lretq

go_to_kernel:
	.quad	Start_Kernel
	
	
	
	
.align	8
.org	0x1000
__PML4E:
	.quad	0x102007
	.fill	255,8,0
	.quad	0x102007
	.fill	255,8,0
	
.org	0x2000
__PDPTE:
	.quad	0x103003
	.fill	511,8,0
	
.org	0x3000
__PDE:
	.quad	0x000083	
	.quad	0x200083
	.quad	0x400083
	.quad	0x600083
	.quad	0x800083
	.quad	0xe0000083
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
	.fill	10,8,0			//2个TSS，128bit,16字节*8
	
	
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