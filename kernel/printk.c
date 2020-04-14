#include <stdarg.h>     //GUN C编译环境自带头文件，支持可变参数
#include "printk.h"
#include "lib.h"
#include "linkage.h"

void putchar(unsigned int * fb, int Xsize, int x, int y, unsigned int FRcolor, unsigned int BKcolor, unsigned char font)
{
    int i = 0;
    int j = 0;
    unsigned int * addr = NULL;
    unsigned char * fontp = NULL;
    int testval = 0;
    fontp = font_ascii[font];

    for (i = 0; i < 16; i++)
    {
        addr = fb + Xsize * (y + i) + x;    //定位当前行的地址
        testval = 0x100;
        for (j = 0; j < 8; j++)
        {
            testval = testval >> 1;
            if (*fontp & testval)
                *addr = FRcolor;
            else
                *addr = BKcolor;
            addr++;
        }
        fontp++;
    }
}

int color_printk(unsigned FRcolor, unsigned int BKcolor, const char* fmt, ...)
{
    int i = 0;
    int count = 0;
    int line = 0;               //制表位需要填的空格
    va_list args;
    va_start(args, fmt);

    i = vsprintf(buf, fmt, args);   //解析字符串和参数，返回字符串长度

    va_end(args);

    for (count = 0; count < i || line; count++)
    {
        if (line > 0)
        {
            count--;
            line--;
            putchar(Pos.FB_addr, Pos.XResolution, Pos.XPosition * Pos.XCharSize, Pos.YPosition * Pos.YCharSize, FRcolor, BKcolor, ' ');
        }
        else if ((unsigned char*)(buf + count) == '\n')
        {
            Pos.YPosition++;
            Pos.XPosition = 0;
        }
        else if ((unsigned char*)(buf + count) == '\b') //退格符
        {
            Pos.XPosition--;
            if (Pos.XPosition < 0)
            {
                Pos.XPosition = (Pos.XResolution / Pos.XCharSize - 1) * Pos.XCharSize;
                Pos.YPosition--;
                if (Pos.YPosition < 0)
                    Pos.YPosition = (Pos.YResolution / Pos.YCharSize - 1) * Pos.YCharSize;
            }
            putchar(Pos.FB_addr, Pos.XResolution, Pos.XPosition * Pos.XCharSize, Pos.YPosition * Pos.YCharSize, FRcolor, BKcolor, ' '); //覆盖之前打印的字符
        }
        else if ((unsigned char*)(buf + count) == '\t')
        {
            line = ((Pos.XPosition + 8) & ~(8 - 1)) - Pos.XPosition;
            line--;
            putchar(Pos.FB_addr, Pos.XResolution, Pos.XPosition * Pos.XCharSize, Pos.YPosition * Pos.YCharSize, FRcolor, BKcolor, ' ');
        }
        else
        {
            putchar(Pos.FB_addr, Pos.XResolution, Pos.XPosition * Pos.XCharSize, Pos.YPosition * Pos.YCharSize, FRcolor, BKcolor, (unsigned char*)(buf + count));
            Pos.XPosition++;
        }

        if (Pos.XPosition >= (Pos.XResolution / Pos.XCharSize))     //调整当前光标位置
        {
            Pos.Yposition++;
            Pos.XPosition = 0;
        }
        if (Pos.YPosition >= (Pos.YResolution / Pos.YCharSize))
        {
            Pos.YPosition = 0;
        }
    }
    return i;
}


