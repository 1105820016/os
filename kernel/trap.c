#include "trap.h"
#include "gate.h"

void do_divide_error(unsigned long rsp, unsigned long error_code)
{
    unsigned long *p = NULL;
    p =(unsigned long *)(rsp + 0x98);
    color_printk(RED, BLACK, "do_divide_error(0), ERROR_CODE:%#0181x, RSP:%#0181x, RIP:%#0181x\n", error_code, rsp, *p);
    while(1);
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
