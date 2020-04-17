#ifndef __PRINTK_H__
#define __PRINTK_H__

#include <stdarg.h>
#include "font.h"
#include "linkage.h"

#define ZEROPAD 1       //零填充
#define SIGN    2       //有符号
#define PLUS    4       //显示+
#define SPACE   8       //空格
#define LEFT    16      //左对齐
#define SPECIAL 32      //0x
#define SMALL   64      //使用小写

#define is_digit(c) ((c) >= '0' && (c) <= '9')

#define do_div(n,base) ({int __res; __asm__ __volatile__("divq %%ecx":"=a"(n),"=d"(__res): "0"(n), "1"(0), "c"base); __res;})

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

inline int strlen(char * str)
{
    register int __res;
    __asm__ __volatile__ ("cld; repnz scasb; notl %0; decl %0;" :"=c"(__res): "D"(str), "a"(0), "0"(0xffffffff));
    return __res;
}

#endif // __PRINTK_H__
