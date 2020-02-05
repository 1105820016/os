;从实模式进入保护模式
;GDT表设置在0x7e00

mov ax,0x7e0
mov bx,0
mov ds,ax

mov dword [0x00],0
mov dword [0x04],0

mov dword [0x08],0x7c0001ff
mov dword [0x0c],0x00409800

mov dword [0x10],0x8000ffff
mov dword [0x14],0x0040920b

mov dword [0x18],0x00007a00
mov dword [0x1c],0x00409600

;lgdt 0x00007e00001f
lgdt [cs: gdt+0x7c00]

cli								;关中断

in al,0x92
or al,0000_0010B				;打开A20地址线
out 0x92,al
	
mov eax,cr0						;开PE
or eax,1
mov cr0,eax

jmp dword 0x0008:print

[bits 32]

print:
	mov cx,00000000000_10_000B
	mov ds,cx
	
	mov byte [0x00],'H'			;显示一个字符占两个字节，低字节存字符，高字节存样式
	mov byte [0x02],'e'
	mov byte [0x04],'l'
	mov byte [0x06],'l'
	mov byte [0x08],'o'
	mov byte [0x0a],','
	mov byte [0x0c],'w'
	mov byte [0x0e],'o'
	mov byte [0x10],'r'
	mov byte [0x12],'l'
	mov byte [0x14],'d'
	
	hlt 						;暂停的中断

gdt:
	dw 0x001f
	dd 0x00007e00

times 510-($-$$) db 0
				 db 0x55,0xaa
