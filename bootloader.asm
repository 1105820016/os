	;引导扇区代码
	
	org	0x7c00
	
	stack	equ	0x7c00
	
start:

	mov ax,	cx
	mov ds,	ax
	mov es,	ax
	mov ss,	ax
	mov sp,	stack
	
	mov	ax,	0600h
	mov	bx,	0700h
	mov	cx,	0
	mov	dx,	0184fh
	int	10h
	
	mov	ax,	0200h
	mov	bx,	0000h
	mov	dx,	0000h
	int	10h
	
	mov	ax,	1301h
	mov	bx,	000fh
	mov	dx,	0000h
	mov	cx,	10
	push	ax
	mov	ax,	ds
	mov	es,	ax
	pop	ax
	mov	bp,	StartBootMessage
	int	10h
	
	xor	ah,	ah
	xor	dl,	dl
	int	13h

	jmp	$
	
	StartBootMessage:	db	"Start Boot"
	
	times 510-($-$$) 	db 0
						db 0x55,0xaa
