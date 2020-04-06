		NumOfRootDirSector	equ	14	;根目录所占扇区数
		SectorNumOfRootDirStart	equ	19	;根目录起始实际扇区号
		SectorNumOfFAT1Start	equ	1
	
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
	