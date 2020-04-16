
void Start_Kernel(void)
{
	int *addr = (int *)0xffff800000a00000;		//帧缓存区被映射的线性地址
	int i;

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

	while(1);
}
