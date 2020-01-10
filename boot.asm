;在CPU加电后如果硬盘是首选启动设备，ROM-BIOS会读取0面0道1扇区（主引导扇区）
;主引导扇区有512字节（一个扇区512字节），ROM-BIOS将主引导扇区加载到0x0000:7c00地址处（历史原因）,然后判断是否有效
;有效的主引导扇区最后两字节是0x55和0xAA.ROM-BIOS先判断是否有效再跳转到0x0000:7c00执行

	org 07c00h

	mov ax,cs
	mov ds,ax
	mov es,ax
	call DispStr
	jmp $
DispStr:
	mov ax,BootMessage
	mov bp,ax
	mov cx,16
	mov ax,01301h
	mov bx,000ch
	mov dl,0
	int 10h
	ret
BootMessage:		db "hello, os world!"
times 510-($-$$)	db 0
dw	  0xaa55			;