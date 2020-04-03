	;Boot代码，加载loader代码
	;使用FAT12文件系统
	;08000h处数据缓冲区
	
		org	0x7c00
	
		BaseOfStack	equ	0x7c00
		BaseOfLoader	equ	0x1000
		OffsetOfLoader	equ	0x00

		NumOfRootDirSector	equ	14	;根目录扇区数
		SectorNumOfRootDirStart	equ	19	;根目录起始实际扇区号
		SectorNumOfFAT1Start	equ	1
		SectorBalance	equ	17		;根目录起始逻辑扇区号

	
		jmp	short	START			;占两字节
		nop							;BS_jmpBoot
	
		BS_OEMName	db	'WXCfat12'	;生产商名
		BPB_BytesPerSec	dw	512		;每扇区字节数
		BPB_SecPerClus	db	1		;每簇扇区数
		BPB_RsvdSecCnt	dw	1		;保留扇区
		BPB_NumFATs	db	2		;FAT表份数
		BPB_RootEntCnt	dw	224		;根目录可容纳的目录项数
		BPB_TotSec16	dw	2880		;总扇区数
		BPB_Media	db	0xF0		;戒指描述符
		BPB_FATSz16	dw	9		;每FAT扇区数
		BPB_SecPerTrk	dw	18		;每磁道扇区数
		BPB_NumHeads	dw	2		;磁头数
		BPB_HiddSec	dd	0		;隐藏扇区数
		BPB_TotSec32	dd	0		;BPB_TotSec16为0时这里记录总扇区数
		BS_DrvNum	db	0		;int 13h的驱动号
		BS_Reserved1	db	0		;未使用
		BS_BootSig	db	0x29		;扩展引导标记 (29h)
		BS_VolID	dd	0		;卷序列号
		BS_VolLab	db	'boot loader'	;卷标
		BS_FileSysType	db	'FAT12   '	;文件系统类型
	
	START:

		mov	ax,	cs
		mov	ds,	ax
		mov 	es,	ax
		mov	ss,	ax
		mov	sp,	BaseOfStack

		;clear screen
		mov	ax,	0600h
		mov	bx,	0700h
		mov	cx,	0
		mov	dx,	184fh
		int	10h
	
		;set focus
		mov	al,	02h
		mov	dx,	0
		mov	bx,	0
		int	10h
	
		;dispaly on screen
		mov	ax,	1301h
		mov	bl,	00001111B
		mov	cx,	10
		mov	dx,	0000h		;坐标
		push	ax
		mov	ax,	ds
		mov	es,	ax
		pop	ax
		mov	bp,	StartBootMessage
		int 	10h
		
		mov	word	[SectorNo],	SectorNumOfRootDirStart
		
	Search_In_Root_Dir_Begin:
		cmp	word	[RootDirLoopSize],	0
		jz	NotFindLoader
		dec	word	[RootDirLoopSize]
		
		mov	ax,	00h
		mov	es,	ax
		mov	bx,	8000h
		mov	ax,	[SectorNo]
		mov	cl,	1
		call	Func_ReadOneSector
		mov	si,	LoaderName
		mov	di,	8000h
		cld
		mov	dx,	10h
		
	For_LoaderBin:

		cmp	dx,	0
		jz	Goto_Next_Sector_In_Root_Dir
		dec	dx
		mov	cx,	11

	Cmp_FileName:

		cmp	cx,	0
		jz	FindLoader
		dec	cx
		lodsb	
		cmp	al,	byte	[es:di]
		jz	Label_Go_On
		jmp	Label_Different

	Label_Go_On:
		
		inc	di
		jmp	Cmp_FileName

	Label_Different:

		and	di,	0ffe0h
		add	di,	20h
		mov	si,	LoaderName
		jmp	For_LoaderBin

	Goto_Next_Sector_In_Root_Dir:
		
		add	word	[SectorNo],	1
		jmp	Search_In_Root_Dir_Begin
		
	FindLoader:
		mov	ax,	NumOfRootDirSector
		and	di,	0ffe0h
		add	di,	01ah
		mov	cx,	word	[es:di]
		push	cx
		add	cx,	ax
		add	cx,	SectorBalance
		mov	ax,	BaseOfLoader
		mov	es,	ax
		mov	bx,	OffsetOfLoader
		mov	ax,	cx

	Go_On_Loading_File:
		push	ax
		push	bx
		mov	ah,	0eh
		mov	al,	'.'
		mov	bl,	0fh
		int	10h
		pop	bx
		pop	ax

		mov	cl,	1
		call	Func_ReadOneSector
		pop	ax
		call	Func_GetFATEntry
		cmp	ax,	0fffh
		jz	File_Loaded
		push	ax
		mov	dx,	NumOfRootDirSector
		add	ax,	dx
		add	ax,	SectorBalance
		add	bx,	[BPB_BytesPerSec]
		jmp	Go_On_Loading_File

	File_Loaded:
		
		jmp	BaseOfLoader:OffsetOfLoader
	
	NotFindLoader:
		mov	ax,	1301h
		mov	cx,	22
		mov	dx,	0100h
		;mov	bx,	008ch
		mov	bx,	00000000_10001100B
		push	ax
		mov	ax,	ds
		mov	es,	ax
		mov	bp,	NoLoaderMessage
		pop	ax
		int	10h
		jmp	$
		
		
		
;read one sector from floppy
Func_ReadOneSector:			;AX=待读取磁盘起始扇区
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
	Go_On_Reading:
		mov	ah,	2
		mov	al,	byte	[bp - 2]
		int	13h
		jc	Go_On_Reading
		add	esp,	2
		pop	bp
		ret

Func_GetFATEntry:
		push	es
		push	bx
		push	ax
		mov	ax,	00
		mov	es,	ax
		pop	ax
		mov	byte	[Odd],	0
		mov	bx,	3
		mul	bx
		mov	bx,	2
		div	bx
		cmp	dx,	0
		jz	Label_Even
		mov	byte	[Odd],	1
	Label_Even:
		xor	dx,	dx
		mov	bx,	[BPB_BytesPerSec]
		div	bx
		push	dx
		mov	bx,	8000h
		add	ax,	SectorNumOfFAT1Start
		mov	cl,	2
		call	Func_ReadOneSector
		
		pop	dx
		add	bx,	dx
		mov	ax,	[es:bx]
		cmp	byte	[Odd],	1
		jnz	Label_Even_2
		shr	ax,	4

	Label_Even_2:
		and	ax,	0fffh
		pop	bx
		pop	es
		ret
	
	SectorNo		dw	0
	RootDirLoopSize		dw	NumOfRootDirSector
	Odd			db	0
	
	LoaderName		db	"LOADER  BIN",0
	StartBootMessage:	db	"Start Boot"
	NoLoaderMessage		db	"ERROR:Not Found Loader"
	
		times 510-($-$$)	db	0
		db 0x55,0xaa
