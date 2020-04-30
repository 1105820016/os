#include "memory.h"
#include "lib.h"

void init_memory()
{
    int i, j;
    unsigned long TotalMem = 0;
    struct Memory_E820_Formate *p = NULL;

    color_printk(BLUE, BLACK, "Dispaly Physics Address MAP, Type(1:RAM, 2:ROM or Reserved, 3:ACPI Reclaim Memory \
                 4:ACPI NVSS Memory, Others:Undefine)\n");

    p = (struct Memory_E820_Formate *)0xffff800000007e00;

    for (i = 0; i < 32; i++)        //显示物理内存分布信息
    {
        color_printk(ORANGE, BLACK, "Address:%#010x,%08x\tLength:%#010x,%08x\tType:%#010\n",
                     p->address2, p->address1, p->length2, p->length1, p->type);

        unsigned long tmp = 0;
        if (p->type == 1)
            TotalMem += p->length;

        memory_management_struct.e820[i].address += p->address;
        memory_management_struct.e820[i].length += p->length;
        memory_management_struct.e820[i].type = p->type;
        memory_management_struct.e820_length = i;

        p++;
        if (p->type > 4 || p->length == 0 || p->type < 1)   //type>4是脏数据
            break;
    }
    color_printk(ORANGE, BLACK, "OS Can Used Total RAM:%#0181x\n", TotalMem);

    TotalMem = 0;

    for (i = 0; i <= memory_management_struct.e820_length; i++)
    {
        unsigned long start, end;
        if (memory_management_struct.e820[i].type != 1)
            continue;
        start = PAGE_2M_ALIGN(memory_management_struct.e820[i].address);
        end = ((memory_management_struct.e820[i].address + memory_management_struct.e820[i].length) >> PAGE_2M_SHIFT) << PAGE_2M_SHIFT;
        if (end <= start)
            continue;
        TotalMem += (end - start) >> PAGE_2M_SHIFT;

        color_printk(ORANGE, BLACK, "OS Can Used Total 2M PAGEs:%#010x=%010d\n", TotalMem, TotalMem);
    }
}
