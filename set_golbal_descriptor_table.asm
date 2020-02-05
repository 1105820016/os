         ;代码清单11-1
         ;文件名：c11_mbr.asm
         ;文件说明：硬盘主引导扇区代码 
         ;创建日期：2011-5-16 19:54

         ;设置堆栈段和栈指针 
         mov ax,cs      
         mov ss,ax
         mov sp,0x7c00
      
         ;计算GDT所在的逻辑段地址 
         mov ax,[cs:gdt_base+0x7c00]        ;低16位 访问cs代码段中的gdt_base标号，又因为代码是在0x0000:0x7c00所以gdt_base的偏移地址是gdt_base+0x7c00
         mov dx,[cs:gdt_base+0x7c00+0x02]   ;高16位 
         mov bx,16        
         div bx            					;DX:AX除以BX（16），商是逻辑地址，余数是偏移地址
         mov ds,ax                          ;令DS指向该段以进行操作（逻辑地址）
         mov bx,dx                          ;段内起始偏移地址 
      
         ;创建0#描述符，它是空描述符，这是处理器的要求
         mov dword [bx+0x00],0x00
         mov dword [bx+0x04],0x00  

         ;创建#1描述符，保护模式下的代码段描述符
         mov dword [bx+0x08],0x7c0001ff     ;线性基地址为0x00007c00,段界限为0x001ff,粒度为字节（G=0），该段长512字节
         mov dword [bx+0x0c],0x00409800     ;属于存储器的段（S=1),是32位的段（D/B=1),该段目前在内存中（P=1），特权级为0（DPL=00），是一个只能执行的代码段(TYPE=1000)

         ;创建#2描述符，保护模式下的数据段描述符（文本模式下的显示缓冲区） 
         mov dword [bx+0x10],0x8000ffff     ;线性基地址为0x000B8000,段界限为0X0FFFF，粒度为字节，该段长65536字节（64KB）
         mov dword [bx+0x14],0x0040920b     ;属于段存储器，32位，位于内存中，特权级为0，TYPE=0010可读可写向上扩展的数据段

         ;创建#3描述符，保护模式下的堆栈段描述符
         mov dword [bx+0x18],0x00007a00		;基地址为0x00000000,段界限为0x7A00,粒度为字节
         mov dword [bx+0x1c],0x00409600		;属于段存储器，32位，位于内存中，特权级为0，TYPE=0010可读可写向下扩展的栈段

         ;初始化描述符表寄存器GDTR
         mov word [cs: gdt_size+0x7c00],31  ;描述符表的界限（总字节数减一）  8字节*4（4个描述符）-1=31 
                                             
         lgdt [cs: gdt_size+0x7c00]			;lgdt m16&m32,该指令的操作数48位（6字节）。低16位是GDT的界限值，高32位是GDT的基地址。初始状态下是0x00000000FFFF.加载gdt_size处的6字节到GDTR寄存器，这里为0x00007C00001F
      
         in al,0x92                         ;南桥芯片内的端口 
         or al,0000_0010B
         out 0x92,al                        ;打开A20

         cli                                ;保护模式下中断机制尚未建立，应 
                                            ;禁止中断
         mov eax,cr0
         or eax,1
         mov cr0,eax                        ;设置PE位，打开保护模式
      
         ;以下进入保护模式... ...
         jmp dword 0x0008:flush             ;16位的描述符选择子：32位偏移  dword修饰偏移量，选择了索引号为1的描述符
                                            ;清流水线并串行化处理器，jmp指令会自动清流水线
         [bits 32] 

    flush:
         mov cx,00000000000_10_000B         ;加载数据段选择子(0x10)
         mov ds,cx

         ;以下在屏幕上显示"Protect mode OK." 
         mov byte [0x00],'P'  
         mov byte [0x02],'r'
         mov byte [0x04],'o'
         mov byte [0x06],'t'
         mov byte [0x08],'e'
         mov byte [0x0a],'c'
         mov byte [0x0c],'t'
         mov byte [0x0e],' '
         mov byte [0x10],'m'
         mov byte [0x12],'o'
         mov byte [0x14],'d'
         mov byte [0x16],'e'
         mov byte [0x18],' '
         mov byte [0x1a],'O'
         mov byte [0x1c],'K'

         ;以下用简单的示例来帮助阐述32位保护模式下的堆栈操作 
         mov cx,00000000000_11_000B         ;加载堆栈段选择子
         mov ss,cx
         mov esp,0x7c00

         mov ebp,esp                        ;保存堆栈指针 
         push byte '.'                      ;压入立即数（字节）
         
         sub ebp,4
         cmp ebp,esp                        ;判断压入立即数时，ESP是否减4 
         jnz ghalt                          
         pop eax
         mov [0x1e],al                      ;显示句点 
      
  ghalt:     
         hlt                                ;已经禁止中断，将不会被唤醒 

;-------------------------------------------------------------------------------
     
         gdt_size         dw 0
         gdt_base         dd 0x00007e00     ;GDT的物理地址 
                             
         times 510-($-$$) db 0
                          db 0x55,0xaa