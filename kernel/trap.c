#include "trap.h"
#include "gate.h"

//#DE异常处理函数
void do_divide_error(unsigned long rsp, unsigned long error_code)
{
    unsigned long *p = NULL;
    p = (unsigned long *)(rsp + 0x98);
    color_printk(RED, BLACK, "do_divide_error(0), ERROR_CODE:%#0181x, RSP:%#0181x, RIP:%#0181x\n", error_code, rsp, *p);
    while(1);
}

//NMI异常处理函数
void do_nmi(unsigned long rsp, unsigned long error_code)
{
    unsigned long *p = NULL;
    p = (unsigned long *)(rsp + 0x98);       //0x98是entry.S中的RIP距rsp的距离，p指向中断程序执行现场的RIP
    color_printk(RED, BLACK, "do_nmi(2), ERROR_CODE:%#0181x, RSP:%#0181x, RIP:%#0181x\n", error_code, rsp, *p);
    while(1);
}

//#TS异常
//#TS异常和#PF异常关系到一个段选择子或IDT向量，处理器会在异常处理程序栈中存入错误码
//所以#TS异常和#PF异常现场保护不需要压入错误码
void do_invalid_TSS(unsigned long rsp, unsigned long error_code)
{
    unsigned long *p = NULL;
    p = (unsigned long *)(rsp + 0x98);
    color_printk(RED, BLACK, "do_invalid_TSS(10), ERROR_CODE:%#0181x, RSP:%#0181x, RIP:%#0181x\n", error_code, rsp, *p);

    if (error_code & 1)         //EXT置位，说明中断时外部事件触发的
        color_printk(RED, BLACK, "An interrupt or an earlier exception.\n");

    if (error_code & 2)         //IDT置位，说明错误码中的段选择子是IDT内的门描述符
        color_printk(RED, BLACK, "Refers to a gate descriptor in the IDT.\n");
    else
        color_printk(RED, BLACK, "Refers to a descriptor in the GDT or the current LDT.\n");

    if (!(error_code & 2))
    {
        if (error_code & 4)     //IDT复位，TI置位，说明错误码中的段选择子是LDT内的段描述符或门描述符
            color_printk(RED, BLACK, "Refers to a segment or a gate descriptor in the LDT.\n");
        else                    //IDT复位，TI复位，说明错误码中的段选择子是GDT中的描述符
            color_printk(RED, BLACK, "Refers to a descriptor in the current GDT.\n");
    }

    color_printk(RED, BLACK, "Refers to a descriptor in the current GDT.\n");
}

void sys_vector_init()
{
	set_trap_gate(0, 1, divide_error);
	set_trap_gate(1, 1, debug);
	set_intr_gate(2, 1, nmi);
	set_system_gate(3, 1, int3);
	set_system_gate(4, 1, overflow);
	set_system_gate(5, 1, bounds);
	set_trap_gate(6, 1, undefined_opcode);
	set_trap_gate(7, 1, dev_not_available);
	set_trap_gate(8, 1, double_fault);
	set_trap_gate(9, 1, coprocessor_segment_overrun);
	set_trap_gate(10, 1, invalid_TSS);
	set_trap_gate(11, 1, segment_not_present);
	set_trap_gate(12, 1, stack_segment_fault);
	set_trap_gate(13, 1, general_protection);
	set_trap_gate(14, 1, page_fault);
	//15 INTEL reserved.
	set_trap_gate(16, 1, x87_FPU_error);
	set_trap_gate(17, 1, alignment_check);
	set_trap_gate(18, 1, machine_check);
	set_trap_gate(19, 1, SIMD_exception);
	set_trap_gate(20, 1, virtualization_exception);
}
