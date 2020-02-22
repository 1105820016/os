	;引导扇区代码
	;

	core_base_address equ 0x00040000	;程序加载到内存中的位置
	core_start_sector equ 0x00000001	;程序在磁盘中的位置
	
	mov eax,[cs:gdt+0x7c00+0x02]
	xor edx,edx
	mov ebx,16
	div ebx
	
	mov ds,eax
	mov ebx,edx
	
	mov dword [ebx+0x00],0
	mov dword [ebx+0x04],0
	
	;创建1#描述符，这是一个数据段，对应0~4GB的线性地址空间
	mov dword [ebx+0x08],0x0000ffff		;基地址为0，段界限为0xFFFFF
	mov dword [ebx+0x0c],0x00cf9200
	
	;创建保护模式下初始代码段描述符
    mov dword [ebx+0x10],0x7c0001ff		;基地址为0x00007c00，界限0x1FF 
    mov dword [ebx+0x14],0x00409800    	;粒度为1个字节，代码段描述符 

    ;建立保护模式下的堆栈段描述符  
    mov dword [ebx+0x18],0x7c00fffe 	;基地址为0x00007C00，界限0xFFFFE 
    mov dword [ebx+0x1c],0x00cf9600
         
    ;建立保护模式下的显示缓冲区描述符   
    mov dword [ebx+0x20],0x80007fff    	;基地址为0x000B8000，界限0x07FFF 
    mov dword [ebx+0x24],0x0040920b    	;粒度为字节
	
	mov word [cs:gdt+0x7c00],39			;5*8-1=39
	
	lgdt [cs:gdt+0x7c00]
	
	in al,0x92
	or al,0000_0010B					;打开A20地址线
	out 0x92,al

	cli
	
	mov eax,cr0							;开PE
	or eax,1
	mov cr0,eax

	jmp dword 0x0010:loding				;16位的描述符选择子：32位偏移

	[bits 32]
loding:
	mov eax,0x0008
	mov ds,eax							;ds指向0-4GB空间
	
	mov eax,0x0018
	mov ss,eax
	xor esp,esp
	
	mov edi,core_base_address
	
	mov ebx,edi							;ds:ebx=内核代码存放地址
	mov eax,core_start_sector
	call read_hard_disk_0
	
	mov eax,[edi]						;内核开头存放内核代码大小	
	xor edx,edx
	mov ecx,512
	div ecx								;内核总大小除以512计算需要多少个扇区
	
	or edx,edx							;如果余数不为0，则商eax就是剩余需要的扇区
	jnz @1
	dec eax								;如果余数为0，eax-1等于剩余需要的余数
@1:
	or eax,eax							;eax=0，内核<=512的情况
	jz setup_core_gdt
	
	mov ecx,eax
	mov eax,core_start_sector
	inc eax								;第一个扇区已经使用了
@2:
	call read_hard_disk_0
	inc eax
	loop @2
	
setup_core_gdt:
	mov esi,[0x7c00+gdt+0x02]			;mov esi,0x7e00
	
	;建立公用程序段描述符
	mov eax,[edi+0x04]					;获取公共程序偏移地址
	mov ebx,[edi+0x08]					;获取后面的数据段偏移地址
	sub ebx,eax							;相减获得公共程序长度
	dec ebx								;减一为段界限
	add eax,edi							;获得公共程序物理地址
	mov ecx,0x00409800
	call make_gdt_descriptor			;创建描述符
	mov [esi+0x28],eax					;描述符写入gdt表
	mov [esi+0x2c],edx
	
	;建立内核数据段描述符
	mov eax,[edi+0x08]
	mov ebx,[edi+0x0c]
	sub ebx,eax
	dec ebx
	add eax,edi
	mov ecx,0x00409200
	call make_gdt_descriptor
	mov [esi+0x30],eax
	mov [esi+0x34],edx
	
	;建立内核代码段描述符
	mov eax,[edi+0x0c]
	mov ebx,[edi+0x10]
	sub ebx,eax
	dec ebx
	add eax,edi
	mov ecx,0x00409800
	call make_gdt_descriptor
	mov [esi+0x38],eax
	mov [esi+0x3c],edx
	
	mov word [0x7c00+gdt],63
	
	lgdt [0x7c00+gdt]
	
	jmp far [edi+0x10]					;进入内核
	
read_hard_disk_0:						;从硬盘中读取一个逻辑扇区
										;eax=逻辑扇区号
										;ds:ebx=数据存放区域
										;返回ebx=ebx+512
	push eax
	push ecx
	push edx

	push eax
	
	mov dx,0x1f2
	mov al,1
	out dx,al
	
	inc dx
	pop eax
	out dx,al
	
	inc dx
	mov cl,8
	shr eax,al
	out dx,al
	
	inc dx
	shr eax,cl
	out dx,al
	
	inc dx
	shr eax,cl
	or al,0xe0
	out dx,al
	
	inc dx
	mov al,0x20
	out dx,al

.waits:
	in al,dx
	and al,0x88
	cmp al,0x08
	jnz .waits
	
	mov ecx,256
	mov dx,0x1f0
.readw
	in ax,dx
	mov [ebx],ax
	add ebx,2
	loop .readw
	
	pop edx
	pop ecx
	pop eax
	
	ret

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
	
	ret


	gdt dw 0x0000
		dd 0x00007e00
	times 510-($-$$) db 0
					 db 0x55,0xaa
