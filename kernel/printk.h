#include <stdarg.h>
#include "font.h"
#include "linkage.h"

struct position
{
    int XResolution;            //屏幕分辨率
    int YPesolution;

    int XPosition;              //光标当前位置
    int YPosition;

    int XCharSize;              //字符像素矩阵大小
    int YCharSize;

    unsigned int * FB_addr;     //帧缓存起始地址
    unsigned long FB_length;    //帧缓存容量大小
} Pos;
