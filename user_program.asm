	;用户程序
	
SECTION header vstart=0
	program_len		dd program_end			;0x00
	head_len_seg	dd head_end				;0x04
	
	stack_seg		dd 0					;接收栈选择子,0x08
	stack_len		dd 1					;建议内核分配的堆栈大小，4KB为单位,0x0c
	
	program_start	dd start				;程序入口,0x10
	code_seg		dd section.code.start	;代码段位置,0x14,用户程序加载完毕创建完描述符后这里填充选择子
	code_len		dd code_end				;代码段长度,0x18
	
	data_seg		dd section.data.start	;数据段位置,0x1c
	data_len		dd data_end				;数据段长度,0x20
	
	;slat表，将用到的函数列出来
	slat_tiems		dd (head_end-salt)/256	;0x24有几个函数
salt:										;0x28
	PrintString		db '@PrintString'
					times 256-($-PrintString) db 0
	
	TerminateProgram	db '@TerminateProgram'
					times 256-($-TerminateProgram) db 0
	
	ReadDiskData	db '@ReadDiskData'
					times 256-($-ReadDiskData) db 0
	
head_end:

SECTION data vstart=0

data_end:

SECTION code vstart=0
start:

code_end:

SECTION trail
program_end: