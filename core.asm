	;内核代码
	
	;各个段的选择子，程序设计初已经固定
	core_code_seg_sel     equ  0x38		;内核代码段选择子
	core_data_seg_sel     equ  0x30		;内核数据段选择子 
	sys_routine_seg_sel   equ  0x28		;系统公共例程代码段的选择子 
	video_ram_seg_sel     equ  0x20		;视频显示缓冲区的段选择子
	core_stack_seg_sel    equ  0x18		;内核堆栈段选择子
	mem_0_4_gb_seg_sel    equ  0x08		;整个0-4GB内存的段的选择子
	
	;内核头
	core_length			dd core_end		;程序总长度;0x00
	
	sys_routine_seg		dd section.sys_routine.start	;0x04，公共程序地址
	
	core_data_seg		dd section.core_data.start		;0x08,内核数据段位置
	
	core_code_seg		dd section.core_code.start		;0x0c,内核代码段位置
	
	core_entry			dd start						;内核代码段入口
						dw core_code_seg_sel
	
	[bits 32]
SECTION sys_routine vstart=0
put_string:								;字符串显示程序
										;显示0终止的字符串，并移动光标
										;输入：DS:EBX=字符串地址
	
	
read_hard_disk_0:						;从硬盘中读取一个逻辑扇区
										;eax=逻辑扇区号
										;ds:ebx=数据存放区域
										;返回ebx=ebx+512
										
allocate_memory:                        ;分配内存
                                        ;输入：ECX=希望分配的字节数
                                        ;输出：ECX=起始线性地址
										
make_gdt_descriptor:					;构造描述符
										;输入eax=基地址
										;	ebx=段界限
										;	ecx=属性，都在原位置，没用到的位置放0
										;返回 edx:eax 描述符
	mov edx,eax
	shl eax,16
	or ax,bx
	
	and edx,0xffff0000
	rol edx,8
	bswap edx
	
	xor bx,bx
	or edx,ebx
	
	or edx,ecx
	
	retf
	
set_up_gdt_descriptor:                  ;在GDT内安装一个新的描述符
                                        ;输入：EDX:EAX=描述符 
                                        ;输出：CX=描述符的选择子
	push eax
	push ebx
	push edx
	
	push ds
	push es
	
	mov ebx,core_data_seg_sel
	mov ds,ebx
	
	sgdt [gdt]							;便于处理GDT
	
	mov ebx,mem_0_4_gb_seg_sel
	mov es,ebx
	
	movzx ebx,word [gdt]				;GDT界限,movzx将16位值传到32位里，多位补零
	inc bx
	add ebx,[gdt+2]						;下一个描述符的地址=gdt基地址+原本总共描述符字节
	
	mov [es:ebx],eax					;安装新描述符
	mov [es:ebx+4],edx
	
	add word [gdt],8
	lgdt [gdt]
	
	mov ax,[gdt]
	xor dx,dx
	mov bx,8
	div bx
	mov cx,ax
	shl cx,3
	
	pop es
	pop ds
	
	pop edx
	pop ebx
	pop eax
	
	
put_hex_dword:                          ;在当前光标处以十六进制形式显示
                                        ;一个双字并推进光标 
                                        ;输入：EDX=要转换并显示的数字
                                        ;输出：无
											

SECTION core_data vstart=0
	gdt			dw 0
				dd 0
				
	ram_alloc	dd 0x00100000			;下次分配内存时的起始地址

salt:
	salt_1		db '@PrintString'
				times 256-($-salt_1) db 0
				dd put_string			;put_string这个函数的位置
				dw sys_routine_seg_sel
				
	salt_2		db '@ReadDiskData'
				times 256-($-salt_2) db 0
				dd read_hard_disk_0
				dw sys_routine_seg_sel
				
	salt_3		db '@PrintDwordAsHexString'
				times 256-($-salt_3) db 0
				dd put_hex_dword
				dw sys_routine_seg_sel
				
	salt_4		db '@TerminateProgram'	;终止程序返回内核
				times 256-($-salt_4) db 0
				dd return_point
				dw core_code_seg_sel
	
	salt_item_len	equ $-salt_4		;262
	salt_times	equ ($-salt)/salt_item_len
	
	message_1	db  '  If you seen this message,that means we '
				db  'are now in protect mode,and the system '
                db  'core is loaded,and the video display '
                db  'routine works perfectly.',0x0d,0x0a,0
				
	message_5	db	'	Loading user program...',0
	
	message_6   db  0x0d,0x0a,0x0d,0x0a,0x0d,0x0a
                db  '  User program terminated,control returned.',0
	
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
	push ebx
	push ecx
	push edx
	push esi
	push edi
	
	push ds
	push es
	
	mov eax,core_data_seg_sel
	mov ds,eax
	
	mov eax,esi
	mov ebx,core_buf
	call sys_routine_seg_sel:read_hard_disk_0
	
	mov eax,[core_buf]					;程序大小
	mov ebx,eax
	and ebx,0xfffffe00
	add ebx,512							;使得ebx是512的倍数
	test eax,0x000001ff					;判断eax是否是512的倍数
	cmovnz eax,ebx
	
	mov ecx,eax
	call sys_routine_seg_sel:allocate_memory
	mov ebx,ecx
	push ebx							;保存申请到的内存的起始地址
	xor edx,edx
	mov ecx,512
	div ecx
	mov ecx,eax							;ecx用于循环读取用户程序
	
	mov eax,mem_0_4_gb_seg_sel			;准备加载用户程序徐
	mov ds,eax
	
	mov eax,esi							;起始扇区号，目标内存地址在ds:ebx中
load:
	call sys_routine_seg_sel:read_hard_disk_0
	inc eax
	loop load
	
	;创建用户头段描述符
	pop edi								;用户程序在内存中的地址
	mov eax,edi
	mov ebx,[edi+0x04]
	dec ebx
	mov ecx,0x00409200
	call sys_routine_seg_sel:make_gdt_descriptor
	call sys_routine_seg_sel:set_up_gdt_descriptor
	mov [edi+0x04],cx					;将选着子安装到用户程序头
	
	;创建用户代码段描述符
	mov eax,edi
	add eax,[edi+0x14]
	mov ebx,[edi+0x18]
	dec ebx
	mov ecx,0x00409800
	call sys_routine_seg_sel:make_gdt_descriptor
	call sys_routine_seg_sel:set_up_gdt_descriptor
	mov [edi+0x14],cx
	
	;创建用户数据段描述符
	mov eax,edi
	add eax,[edi+0x1c]
	mov ebx,[edo+0x20]
	dec ebx
	mov ecx,0x00409200
	call sys_routine_seg_sel:make_gdt_descriptor
	call sys_routine_seg_sel:set_up_gdt_descriptor
	mov [edi+0x1c],cx
	
	;创建用户程序堆栈段描述符
	mov ecx,[edi+0x0c]
	mov ebx,0x000fffff					;解释看P.237
	sub ebx,ecx
	mov eax,4096
	mul dword [edi+0x0c]
	mov ecx,eax
	call sys_routine_seg_sel:allocate_memory
	add eax,ecx
	mov ecx,0x00c09600
	call sys_routine_seg_sel:make_gdt_descriptor
	call sys_routine_seg_sel:set_up_gdt_descriptor
	mov [edi+0x08],cx
	
	
	;重定位SALT（链接？）
	mov eax,[edi+0x04]
	mov es,eax							;用户程序头选择子
	mov eax,core_data_seg_sel
	mov ds,eax
	
	cld	
	
	mov ecx,[es+0x24]					;有多少个函数循环多少遍
	mov edi,0x28						;函数所处的位置
loop1:									;ds:esi指向内核函数salt表,es:edi指向用户salt表
	push ecx
	;push edi
	
	mov ecx,salt_times
	mov esi,salt
loop2:
	push ecx
	push esi
	push edi
	
	mov ecx,64							;cmpsd每次比较四字节，需要比较256/4=54次
	repe cmpsd							;比较ds:esi和es:edi,比较完一次esi/edi+=4，repe若是为0则重复
	jnz continue						;不为0说明不相等直接进行下一次循环
	mov eax,[esi]						;将内核的函数地址传给用户程序的salt表
	mov [es:edi-256],eax
	mov ax,[esi+4]						;传选择子
	mov [es:edi-252],ax
continue:
	pop edi
	pop esi
	add esi,salt_item_len
	pop ecx
	loop loop2							;内循环
	
	;pop edi
	add edi,256							;指向下一个函数
	pop ecx
	loop loop1							;外循环
	
	mov ax,[es:0x04]
	
	pop es
	pop ds
	
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	
	ret
	
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

return_point:
	mov eax,core_data_seg_sel
	mov ds,eax
	
	mov eax,core_stack_seg_sel
	mov ss,eax
	mov esp,[esp_pointer]
	
	mov ebx,message_6
	call sys_routine_seg_sel:put_string
	
	hlt

SECTION core_trail
core_end: