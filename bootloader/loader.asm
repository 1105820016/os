		;0x8000临时缓冲区
		
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
	CodeDescriptor:	dd	0x0000FFFF,0x00CF9A00	;段基址0x00,段长度0xffff,粒度4KB，可访问0-4GB内容,DPL=0
	DateDescriptor:	dd	0x0000FFFF,0x00CF9200	;段基址0x00,段长0xffff,粒度4KB,DPL=0
	
	gdt	dw	$ - GdtTable - 1
		dd	GdtTable
		
	CodeSelector	equ	CodeDescriptor - GdtTable	;8
	DateSelector	equ	DateDescriptor - GdtTable	;16
	
[SECTION GDT64]
	GdtTable64:		dq	0x00
	CodeDescriptor64:	dq	0x0020980000000000
	DateDescriptor64:	dq	0x0000920000000000
	
	gdt64	dw	$ - GdtTable64 - 1
		dd	GdtTable64
		
	CodeSelector64	equ	16
	DateSelector64	equ	32
	

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
		pop	bx
		pop	ax
		
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
		mov	al,	0
		out	dx,	al
		
		
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
		
		;get SGVA information
		mov	ax,	ds
		mov	es,	ax
		mov	bp,	GetSGVAInformationMessage
		mov	ax,	1301h
		mov	bx,	000fh
		mov	dx,	0800h
		mov	cx,	26
		int	10h
		
		mov	ax,	0x00
		mov	es,	ax
		mov	di,	0x8000
		mov	ax,	4f00h
		int	10h
		
		cmp	ax,	004fh
		jz	KO
		
		;FAIL
		mov	ax,	ds
		mov	es,	ax
		mov	bp,	GetSVGAVBEInfoErrorMessage
		mov	ax,	1301h
		mov	bx,	000fh
		mov	dx,	0900h
		mov	cx,	26
		int	10h
		
		jmp	$
		
	KO:
		mov	ax,	ds
		mov	es,	ax
		mov	bp,	GetSVGAVBEInfoOKMessage
		mov	ax,	1301h
		mov	bx,	000fh
		mov	dx,	0a00h
		mov	cx,	23
		int	10h
		
		;get SVGA mode information
		mov	ax,	ds
		mov	es,	ax
		mov	bp,	GetSVGAModeInformationMessage
		mov	ax,	1301h
		mov	bx,	000fh
		mov	dx,	0c00h
		mov	cx,	31
		int	10h
		
		mov	ax,	0x00
		mov	es,	ax
		mov	si,	0x800e
		
		mov	esi,	dword	[es:si]
		mov	edi,	0x8200
		
	SVGAModeInfoGet:
		mov	cx,	word	[es:esi]
		
		mov	ax,	00h
		mov	al,	ch
		call	DispAL
		
		mov	ax,	0
		mov	al,	cl
		call	DispAL
		
		cmp	cx,	0FFFFh
		jz	SVGAModeInfoFinish
		
		mov	ax,	4f01h
		int	10h
		
		cmp	ax,	004fh
		jnz	SVGAModeInfoFail
		
		add	esi,	2
		add	edi,	0x1000
		
		jmp	SVGAModeInfoGet
		
	SVGAModeInfoFail:
		mov	ax,	ds
		mov	es,	ax
		mov	bp,	GetSVGAModeInfoErrorMessage
		mov	ax,	1301h
		mov	bx,	000fh
		mov	dx,	0d00h
		mov	cx,	31
		int	10h
		
	SetSVGAModeFail:
		jmp	$
		
	SVGAModeInfoFinish:
		mov	ax,	ds
		mov	es,	ax
		mov	bp,	GetSVGAModeInfoOKMessage
		mov	ax,	1301h
		mov	bx,	000fh
		mov	dx,	0e00h
		mov	cx,	28
		int	10h
		
	;set SVGA mode
		mov	ax,	4f02h
		mov	bx,	4180h		;设置SVGA芯片的显示模式，180-》1440*900的分辨率
		int	10h
		
		cmp	ax,	004fh
		jnz	SetSVGAModeFail
		
		cli
		
		db	0x66
		lgdt	[gdt]
		
		mov	eax,	cr0
		or	eax,	1
		mov	cr0,	eax
		
		jmp	dword	CodeSelector:GoToTMPProtect	;进入保护模式
	
	
[SECTION .s32]
[BITS 32]
	GoToTMPProtect:
		mov	ax,	0x10
		mov	ds,	ax
		mov	es,	ax
		mov	fs,	ax
		mov	ss,	ax
		mov	esp,	7e00h
		
		call	SupportLongMode
		test	eax,	eax
		jz	NoSupport
		
		;init temporary page table 0x90000
		mov	dword	[0x90000],	0x91007
		mov	dword	[0x90800],	0x91007
		
		mov	dword	[0x91000],	0x92007
		mov	dword	[0x92000],	0x000083
		mov	dword	[0x92008],	0x200083
		mov	dword	[0x92010],	0x400083
		mov	dword	[0x92018],	0x600083
		mov	dword	[0x92020],	0x800083
		mov	dword	[0x92028],	0xa00083
		
		db	0x66
		lgdt	[gdt64]
		
		mov	ax,	0x10
		mov	ds,	ax
		mov	es,	ax
		mov	fs,	ax
		mov	gs,	ax
		mov	ss,	ax
		mov	esp,	7e00h
		
		;open	PAE,开启物理地址扩展功能
		mov	eax,	cr4
		bts	eax,	5		;从eax中取第5位放入CF，该位置1
		mov	cr4,	eax
		
		;load	cr3，将页目录加载到cr3
		mov	eax,	0x90000
		mov	cr3,	eax
		
		;置位IA32_EFER的LME标志位，开启IA-32e模式
		mov	ecx,	0C0000080h
		rdmsr				;读取msr寄存器组，结果在EDX:EAX
		bts	eax,	8
		wrmsr
		
		mov	eax,	cr0
		bts	eax,	0
		bts	eax,	31		;置位CR0.PG，开启分页机制
		mov	cr0,	eax		;进入IA-32e模式（兼容模式）
		
		jmp	CodeSelector64:OffsetOfKernelFile
	
	SupportLongMode:
		mov	eax,	0x80000000
		cpuid
		cmp	eax,	0x80000001	;检测CPUID是否支持大于0x80000000的功能号
		setnb	al			;不低于置位
		jb	SupportLongModeDone
		mov	eax,	0x80000001
		cpuid
		bt	eax,	29		;检测是否支持IA-32e模式
		setc	al
	SupportLongModeDone:
		movzx	eax,	al		;无符号扩展传送，0扩展然后传送
		ret
	
	NoSupport:
		jmp	$
	
		

[SECTION .s16]
[BITS 16]	
	
GetFATEntry:					;AX=FAT表项号
						;输出：AX=FAT表项号（根据当前FAT表项号索引出下一个表项）
		push	es
		push	bx
		
		push	ax
		mov	ax,	0
		mov	es,	ax
		pop	ax
		
		mov	byte	[Odd],	0
		mov	bx,	3
		mul	bx
		mov	bx,	2
		div	bx
		cmp	dx,	0
		jz	LabelEven
		mov	byte	[Odd],	1
		
	LabelEven:
		xor	dx,	dx
		mov	bx,	[BPB_BytesPerSec]
		div	bx
		push	dx
		mov	bx,	8000h
		add	ax,	SectorNumOfFAT1Start
		mov	cl,	2
		call	ReadOneSector
		
		pop	dx
		add	bx,	dx
		mov	ax,	[es:bx]
		cmp	byte	[Odd],	1
		jnz	LabelEven2
		shr	ax,	4

	LabelEven2:
		and	ax,	0FFFh
		pop	bx
		pop	es
		ret
		
		
		
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
		
		
DispAL:
		push	ecx
		push	edx
		push	edi
		
		mov	edi,	[DisplayPosition]
		mov	ah,	0Fh
		mov	dl,	al
		shr	al,	4
		mov	ecx,	2
	.begin:

		and	al,	0Fh
		cmp	al,	9
		ja	.1
		add	al,	'0'
		jmp	.2
	.1:

		sub	al,	0Ah
		add	al,	'A'
	.2:

		mov	[gs:edi],	ax
		add	edi,	2
		
		mov	al,	dl
		loop	.begin

		mov	[DisplayPosition],	edi

		pop	edi
		pop	edx
		pop	ecx
		
		ret
		

	SectorNo		dw	0
	RootDirRectorNum	dw	NumOfRootDirSector
	OffsetOfKernelFile	dd	0x100000
	DisplayPosition		dd	0
	Odd			db	0
	
	KernelFileName:		db	"KERNEL  BIN",0		;11个字节
	StartLoaderMessage:	db	"Start Loader"
	NotFoundKernelMessage:	db	"ERROR:No Kernel.bin file"
	GetMemStructMessage:	db	"Start get memery struct"	;23
	GetMemStructErrorMessage:	db	"Get memery struct error"	;23
	GetMemStructOKMessage	db	"Get memery struct OK"	;20
	
	GetSGVAInformationMessage	db	"Start Get SVGA	Information"	;26
	GetSVGAVBEInfoErrorMessage	db	"Get SVGA Information Error"	;26
	GetSVGAVBEInfoOKMessage		db	"Get SVGA Information OK"	;23
	GetSVGAModeInformationMessage	db	"Start Get SVGA Mode Information"	;31
	GetSVGAModeInfoErrorMessage	db	"Get SVGA Mode Information Error"
	GetSVGAModeInfoOKMessage	db	"Get SVGA Mode Information OK"	;28