#ifndef __PRINTK_H__
#define __PRINTK_H__

#include <stdarg.h>
#include "font.h"

#define ZEROPAD 1       //零填充
#define SIGN    2       //有符号
#define PLUS    4       //显示+
#define SPACE   8       //空格
#define LEFT    16      //左对齐
#define SPECIAL 32      //0x
#define SMALL   64      //使用小写

#define WHITE   0x00ffffff      //白
#define BLACK   0x00000000      //黑
#define RED     0x00ff0000      //红
#define ORANGE  0x00ff8000      //橙
#define YELLOW  0x00ffff00      //黄
#define GREEN   0x0000ff00      //绿
#define BLUE    0x000000ff      //蓝
#define INDIGO  0x0000ffff      //靛
#define PURPLE  0x008000ff      //紫

#define is_digit(c) ((c) >= '0' && (c) <= '9')

#define do_div(n,base) ({int __res; __asm__("divq %%rcx":"=a"(n),"=d"(__res): "0"(n), "1"(0), "c"(base)); __res;})

struct position
{
    int XResolution;            //屏幕分辨率
    int YResolution;

    int XPosition;              //光标当前位置
    int YPosition;

    int XCharSize;              //字符像素矩阵大小
    int YCharSize;

    unsigned int * FB_addr;     //帧缓存起始地址
    unsigned long FB_length;    //帧缓存容量大小
} Pos;

char buf[4096] = {0};

int color_printk(unsigned FRcolor, unsigned int BKcolor, const char* fmt, ...);

inline int strlen(char * str)
{
    register int __res;
    __asm__ __volatile__ ("cld; repnz scasb; notl %0; decl %0;" :"=c"(__res): "D"(str), "a"(0), "0"(0xffffffff));
    return __res;
}

#endif // __PRINTK_H__
