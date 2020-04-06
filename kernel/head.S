.section .text		;伪指令，.text表代码段，只读和可执行

.globl _start		;标记为全局符号，链接器会用到

_start:			;程序的入口
	mov	$0x10,	%ax
	mov	%ax,	%ds
	mov	%ax,	%es
	mov	%ax,	%fs
	mov	%ax,	%ss
	mov	%0x7e00,	%esp
	
.section .date
.globl	GDTTable
GDTTable:
	.quad	0x0000000000000000	;quard word伪指令，4字节