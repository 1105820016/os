#ifndef __MEMORY_H__
#define __MEMORY_H__

#define PTRS_PER_PAGE   512         //  页表表项个数

#define PAGE_OFFSET ((unsigned long)0xffff800000000000) //内核层的起始线性地址，物理地址0

#define PAGE_GDT_SHIFT  39
#define PAGE_1G_SHIFT   30          //2的30次方，1GB
#define PAGE_2M_SHIFT   21          //2的21次方，2MB
#define PAGE_4K_SHIFT   12          //2的12次方，4KB

#define PAGE_2M_SIZE    (1UL << PAGE_2M_SHIFT)      //2MB页的容量，1UL表示无符号长整型1
#define PAGE_4K_SIZE    (1UL << PAGE_4K_SHIFT)

#define PAGE_2M_MASK    (~ (PAGE_2M_SIZE - 1))      //2MB数值屏蔽码，屏蔽低于2MB的数值
#define PAGE_4K_MASK    (~ (PAGE_4K_SIZE - 1))

#define PAGE_2M_ALIGN(addr) (((unsigned long)(addr) + PAGE_2M_SIZE - 1) & PAGE_2M_MASK) //将地址按2MB页的上边界对其
#define PAGE_4K_ALIGN(addr) (((unsigned long)(addr) + PAGE_4K_SIZE - 1) & PAGE_4K_MASK)

#define Virt_To_Phy(addr)   ((unsigned long)(addr) - PAGE_OFFSET)       //内核虚拟地址转换为物理地址
#define Phy_To_Virt(addr)   ((unsigned long*)((unsigned long)(addr) + PAGE_OFFSET))


struct Memory_E820_Formate      //存储内存信息，内存信息暂存在0x7e00,线性地址是0xffff800000007e00h
{
    unsigned int address1;
    unsigned int address2;
    unsigned int length1;
    unsigned int length2;
    unsigned int type;
};

struct E820
{
    unsigned long address;
    unsigned long length;
    unsigned int type;
}__attribute__((packed));       //__attribute__按实际字节数对齐紧凑模式，不优化对齐

struct Global_Memory_Descriptor
{
    struct E820 e820[32];
    unsigned long e820_length;
};

extern struct Global_Memory_Descriptor memory_management_struct;

#endif // __MEMORY_H__