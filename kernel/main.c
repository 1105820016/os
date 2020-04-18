#include "printk.h"

void Start_Kernel(void)
{
	int *addr = (int *)0xffff800000a00000;		//帧缓存区被映射的线性地址
	int i;

	Pos.XResolution = 1440;
	Pos.YResolution = 900;

	Pos.XPosition = 0;
	Pos.YPosition = 0;

	Pos.XCharSize = 8;
	Pos.YCharSize = 16;

	Pos.FB_addr = (int*)0xffff800000a00000;
	Pos.FB_length = (Pos.XResolution * Pos.YResolution * 4);

	for (i = 0; i < 1440*20; i++)
	{
		*addr = 0x00ff0000;
		addr += 1;
	}

	for (i = 0; i < 1440*20; i++)
	{
		*addr = 0x0000ff00;
		addr += 1;
	}

	for (i = 0; i < 1440*20; i++)
	{
		*addr = 0x00ff00ff;
		addr += 1;
	}

	for (i = 0; i < 1440*20; i++)
	{
		*addr = 0x00ffffff;
		addr += 1;
	}

	color_printk(YELLOW, GREEN, "Hello world.\n");

	while(1);
}
