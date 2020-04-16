#ifndef __PRINTK_H__
#define __PRINTK_H__

#include <stdarg.h>
#include "font.h"
#include "linkage.h"

#define ZEROPAD 1       //零填充
#define SIGN    2       //无符号or有符号长
#define PLUS    4       //显示+
#define SPACE   8       //空格
#define LEFT    16      //左对齐
#define SPECIAL 32      //0x
#define SMALL   64      //使用小写

#define is_digit(c) ((c) >= '0' && (c) <= '9')

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

#endif // __PRINTK_H__
