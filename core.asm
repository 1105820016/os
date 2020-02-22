	;内核代码
	
	core_code_seg_sel     equ  0x38    ;内核代码段选择子
	core_data_seg_sel     equ  0x30    ;内核数据段选择子 
	sys_routine_seg_sel   equ  0x28    ;系统公共例程代码段的选择子 
	video_ram_seg_sel     equ  0x20    ;视频显示缓冲区的段选择子
	core_stack_seg_sel    equ  0x18    ;内核堆栈段选择子
	mem_0_4_gb_seg_sel    equ  0x08    ;整个0-4GB内存的段的选择子

	
	
	[bits 32]
SECTION sys_routine vstart=0
put_string:								;字符串显示程序
										;显示0终止的字符串，并移动光标
										;输入：DS:EBX=字符串地址
	

SECTION core_data vstart=0
	message_1	db  '  If you seen this message,that means we '
				db  'are now in protect mode,and the system '
                db  'core is loaded,and the video display '
                db  'routine works perfectly.',0x0d,0x0a,0
				
	message_5	db	'	Loading user program...',0
	
	do_status	db	'Done.'0x0d,0x0a,0
	
	core_buf 	times 2048 db 0
	
	esp_pointer	dd	0
	
	cpu_brand	db	0x0d,0x0a,'  ',0
	cpu_brand0	times 52 db 0
	cpu_brand1	db 0x0d,0x0a,0x0d,0x0a,0

SECTION core_code vstart=0
load_relocate_program:					;加载并重定位用户程序
										;输入：ESI=起始逻辑扇区
										;返回:AX=用户程序的头部选择子


start:									;内核程序的入口
	mov ecx,core_data_seg_sel
	mov ds,ecx

	mov ebx,message_1
	call sys_routine_seg_sel:put_string
	
	mov eax,0x80000002
	cpuid
	mov [cpu_brand+0x00],eax
	mov [cpu_brand+0x04],ebx
	mov [cpu_brand+0x08],ecx
	mov [cpu_brand+0x0c],edx
	mov eax,0x80000003
	cpuid
	mov [cpu_brand+0x10],eax
	mov [cpu_brand+0x14],ebx
	mov [cpu_brand+0x18],ecx
	mov [cpu_brand+0x1c],edx
	mov eax,0x80000004
	cpuid
	mov [cpu_brand+0x20],eax
	mov [cpu_brand+0x24],ebx
	mov [cpu_brand+0x28],ecx
	mov [cpu_brand+0x2c],edx
	
	mov ebx,cpu_brand0
	call sys_routine_seg_sel:put_string
	mov ebx,cpu_brand
	call sys_routine_seg_sel:put_string
	mov ebx,cpu_brand1
	call sys_routine_seg_sel:put_string
	
	mov ebx,message_5
	call sys_routine_seg_sel:put_string
	mov esi,50								;用户程序位于逻辑扇区50扇区
	call load_relocate_program
	
	mov ebx,do_status
	call sys_routine_seg_sel:put_string
	
	mov [esp_pointer],esp
	
	mov ds,ax								;ax存放的是load_relocate_program后的选择子
	
	jmp far [0x10]

SECTION core_trail
core_end: