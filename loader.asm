		org	10000h
		jmp	Start
		
	%include	"fat12.inc"
	
	BaseTmpOfKernelAddr	equ	0x00
	OffsetTmpOfKernelAddr	equ	0x7E00
	
	BaseOfKernelAddr	equ	0x00
	OffsetOfKernelAddr	equ	0x100000
	
	MemoryStructBufferAddr	equ	0x7E00
	
[SECTION GDT]
	GdtTable:	dd	0,0
	CodeDescriptor：	dd	0x0000FFFF,0x00CF9A00	;段基址0x00,段长度0xffff,粒度4KB，可访问0-4GB内容,DPL=0
	DateDescriptor：	dd	0x0000FFFF,0x00CF9200	;段基址0x00,段长0xffff,粒度4KB,DPL=0
	
	gdt	dw	$ - GdtTable - 1
		dd	GdtTable
		
	CodeSelector	equ	CodeDescriptor - GdtTable	;8
	DateSelector	equ	DateDescriptor - GdtTable	;16

[SECTION START]
[BITS 16]
	Start:
		mov	ax,	cs
		mov	ds,	ax
		mov	es,	ax
		mov	ax,	0x00
		mov	ss,	ax
		mov	sp,	0x7c00
		
		;dispaly on screen
		mov	ax,	1301h
		mov	bx,	000fh
		mov	cx,	12
		mov	dx,	0200h
		mov	bp,	StartLoaderMessage
		int	10h

		;open address A20
		in	al,	92h
		or	al,	0000_0010b
		out	92h,	al
		
		;close int
		cli
		
		lgdt	[gdt]
		
		;打开保护模式开关
		mov	eax,	cr0
		or	eax,	1
		mov	cr0,	eax
		
		mov	ax,	DateSelector
		mov	fs,	ax
		mov	eax,	cr0
		and	eax,	1111_1110b
		mov	cr0,	eax
		
		;set int
		sti
		
		mov	word	[SectorNo],	SectorNumOfRootDirStart	;根目录在19扇区

	SearchBegin:
		cmp	word	[RootDirRectorNum],	0
		jz	NotFoundKernel
		dec	word	[RootDirRectorNum]
		
		mov	ax,	00h
		mov	es,	ax
		mov	bx,	8000h		;0x8000临时缓冲区
		mov	ax,	[SectorNo]
		mov	cl,	1
		call	ReadOneSector
		mov	si,	KernelFileName
		mov	di,	8000h		;es:di指向临时缓冲区
		cld				;clean df,df=0
		mov	dx,	16		;根目录项32字节，一个扇区512B，512/32=16项
		
	SearchKernelBin:
		cmp	dx,	0
		jz	LoadNextRootDirSector
		dec	dx
		mov	cx,	11		;文件名长11
		
	CmpFileName:
		cmp	cx,	0
		jz	FoundKernelFile
		dec	cx
		lodsb				;ds:si数据传入al(byte)，si根据df增加（或减少）
		cmp	al,	byte	[es:di]
		jz	GoOn
		jmp	FileNameDifferent
		
	GoOn:
		inc	di			;es:di指向下一个字符
		jmp	CmpFileName
	
	FileNameDifferent:
		and	di,	0FFE0h
		add	di,	32		;指向下一个根目录项
		mov	si,	KernelFileName
		jmp	SearchKernelBin
		
	LoadNextRootDirSector:
		add	word	[SectorNo],	1
		jmp	SearchBegin
		
		
		
	NotFoundKernel:
		mov	ax,	ds
		mov	es,	ax
		mov	ax,	1301h
		mov	bx,	008ch
		mov	dx,	0300h
		mov	cx,	24
		mov	bp,	NotFoundKernelMessage
		int	10h
		jmp	$



	FoundKernelFile:
		mov	ax,	NumOfRootDirSector
		and	di,	0FFE0h
		add	di,	01Ah		
		mov	cx,	word	[es:di]		;获取起始簇号，标号从2开始
		push	cx
		add	cx,	ax			
		add	cx,	SectorNumOfRootDirStart	;定位数据区位置
		sub	cx,	2			;减去2，因为FAT标号是从2开始
		mov	eax,	BaseTmpOfKernelAddr
		mov	es,	eax
		mov	bx,	OffsetTmpOfKernelAddr
		mov	ax,	cx

	LoadingFile:
		push	ax
		push	bx
		mov	ah,	0Eh
		mov	al,	'.'
		mov	bl,	0Fh
		int 	10h
		pop	ax
		pop	bx
		
		mov	cl,	1
		call	ReadOneSector
		pop	ax
		
		
		push	cx
		push	eax
		push	fs
		push	edi
		push	ds
		push	esi
		
		mov	cx,	200h
		mov	ax,	BaseOfKernelAddr
		mov	fs,	ax
		;todo
		mov	edi,	dword	[OffsetOfKernelFile]	;内核程序段偏移值
		
		mov	ax,	BaseTmpOfKernelAddr
		mov	ds,	ax
		mov	esi,	OffsetTmpOfKernelAddr
		
	MoveKernel:
		mov	al,	byte	[ds:esi]
		mov	byte	[fs:edi],	al
		inc	esi
		inc	edi
		
		loop	MoveKernel
		
		mov	eax,	0x1000
		mov	ds,	eax
		
		;todo
		mov	dword	[OffsetOfKernelFile],	edi
		
		pop	esi
		pop	ds
		pop	edi
		pop	fs
		pop	eax
		pop	cx
		
		call	GetFATEntry
		cmp	ax,	0FFFH
		jz	FileLoaded
		push	ax
		add	ax,	NumOfRootDirSector
		add	ax,	SectorNumOfRootDirStart
		sub	ax,	2
		
		jmp	LoadingFile
		
	FileLoaded:
		mov	ax,	0B800h
		mov	gs,	ax
		mov	ah,	0Fh
		mov	al,	'G'
		mov	[gs:(0 + 39) * 2],	ax
		
	KillMotor:	;关闭软盘驱动
		mov	dx,	03F2h
		out	dx,	0
		
		
		mov	ax,	ds
		mov	es,	ax
		mov	bp,	GetMemStructMessage
		mov	ax,	1301h
		mov	bx,	000Fh
		mov	dx,	0400h
		mov	cx,	23
		int	10h
		
		mov	ebx,	0
		mov	ax,	0x00
		mov	es,	ax
		mov	di,	MemoryStructBufferAddr
		
	GetMemStruct:
		mov	eax,	0x0E820		;获取内存信息
		mov	ecx,	20		;bios最多只填充20字节
		mov	edx,	0x534D4150	;bios会用到
		int	15h
		jc	GetMemFail
		add	di,	20
		
		cmp	ebx,	0
		jne	GetMemStruct
		jmp	GetMemOK
	
	GetMemFail:
		mov	ax,	ds
		mov	es,	ax
		mov	bp,	GetMemStructErrorMessage
		mov	ax,	1301h
		mov	bx,	000fh
		mov	dx,	0500h
		mov	cx,	23
		int	10h
		jmp	$
		
	GetMemOK:
		mov	ax,	ds
		mov	es,	ax
		mov	bp,	GetMemStructOKMessage
		mov	ax,	1301h
		mov	bx,	000fh
		mov	dx,	0600h
		mov	cx,	23
		int	10h
		
		mov	ax,
	
		
		
GetFATEntry:

		
ReadOneSector:					;AX=待读取磁盘起始扇区
						;CL=读入扇区数
						;ES:BX=目标缓冲区
	
		push	bp
		mov	bp,	sp
		sub	esp,	2
		mov	byte	[bp - 2],	cl
		push	bx
		mov	bl,	[BPB_SecPerTrk]
		div	bl
		inc	ah
		mov	cl,	ah
		mov	dh,	al
		shr	al,	1
		mov	ch,	al
		and	dh,	1
		pop	bx
		mov	dl,	[BS_DrvNum]
	Label_Go_On_Reading:
		mov	ah,	2
		mov	al,	byte	[bp - 2]
		int	13h
		jc	Label_Go_On_Reading
		add	esp,	2
		pop	bp
		ret

	SectorNo		dw	0
	RootDirRectorNum	dw	NumOfRootDirSector
	OffsetOfKernelFile	dw	0
	
	KernelFileName:		db	"KERNEL  BIN",0		;11个字节
	StartLoaderMessage:	db	"Start Loader"
	NotFoundKernelMessage:	db	"ERROR:No Kernel.bin file"
	GetMemStructMessage:	db	"Start get memery struct"	;23
	GetMemStructErrorMessage:	db	"Get memery struct error"	;23
	GetMemStructOKMessage	db	"Get memery struct OK"	;20


