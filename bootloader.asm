;从实模式进入保护模式
;GDT表设置在0x7e00

	mov ax,0x7e0
	mov ds,ax

	mov dword [0x00],0
	mov dword [0x04],0

	mov dword [0x08],0x0000ffff		;基地址为0，段界限为0xfffff
	mov dword [0x0c],0x00cf9200		;粒度为4KB，存储器段描述符

	mov dword [0x10],0x7c0001ff		;基地址为0x00007c00，512字节 
	mov dword [0x14],0x00409800		;粒度为1个字节，代码段描述符 

	mov dword [0x18],0x7c0001ff		;基地址为0x00007c00，512字节
	mov dword [0x1c],0x00409200		;粒度为1个字节，数据段描述符

	mov dword [0x20],0x7c00fffe		;基地址为0x00007c00,段界限为0xffffe，(0x6BFF)
	mov dword [0x24],0x00cf9600		;粒度为4KB，数据段描述符（栈区）

	lgdt [cs:gdt + 0x7c00]

	in al,0x92
	or al,0000_0010B				;打开A20地址线
	out 0x92,al

	cli
	
	mov eax,cr0						;开PE
	or eax,1
	mov cr0,eax

	jmp dword 0x0010:flush          ;16位的描述符选择子：32位偏移

	[bits 32]
flush:
	mov eax,0x0018
	mov ds,eax

	mov eax,0x0008
	mov es,eax
	mov fs,eax
	mov gs,eax

	mov word [gs:0x0b8000],0x0748
	mov word [gs:0x0b8002],0x0765
	mov word [gs:0x0b8004],0x076c
	mov word [gs:0x0b8006],0x076c
	mov word [gs:0x0b8008],0x076f

	mov ecx,gdt-string-1
@1:
	push ecx
	xor bx,bx

@2:
	mov ax,[string+bx]
	cmp ah,al
	jge @3
	xchg al,ah
	mov [string+bx],ax
	
@3:
	inc bx
	loop @2
	pop ecx
	loop @1
	
	mov ecx,gdt-string
	xor ebx,ebx

@4:
	mov ah,0x07
	mov al,[string+ebx]
	mov [fs:0xb80a0+ebx*2],ax
	inc ebx
	loop @4

hlt

string:	db 's0ke4or92xap3fv8giuzjcy5l1m7hd6bnqtw.'

gdt:	dw	0x0027
		dd	0x00007e00

times 510-($-$$)	db 0
					db 0x55,0xaa

