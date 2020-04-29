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

    for (i = 0; i < 32; i++)
    {
        color_printk(ORANGE, BLACK, "Address:%#010x,%08x\tLength:%#010x,%08x\tType:%#010\n",
                     p->address2, p->address1, p->length2, p->length1, p->type);

        unsigned long tmp = 0;
        if (p->type == 1)
        {
            tmp = p->length2;
            TotalMem += p->length1;
            TotalMem += tmp << 32;
        }

        p++;
        if (p->type > 4)            //type>4是脏数据
            break;
    }
    color_printk(ORANGE, BLACK, "OS Can Used Total RAM:%#0181x\n", TotalMem);
}
