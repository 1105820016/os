#include <stdarg.h>     //GUN C编译环境自带头文件，支持可变参数
#include "printk.h"
#include "lib.h"
#include "linkage.h"

/*
 *字符数字转数字
 *s 字符串指针
 */
int skip_atoi(const char **s)
{
    int i = 0;
    while (is_digit(**s))
        i = i * 10 + *((*s)++) - '0';
    return i;
}

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

static char *

/*
 *buf 存储输出的字符串
 *fmt 格式化输入字符串，%[flags][width][.precision][length][specifier]
 *args 一个表示可变参数列表的对象
 */
int vsprintf(char* buf,const char* fmt, va_list args)
{
    char* str;
    int flags;
    int field_width;
    int precision;
    int qualifier;

    for (str = buf; *fmt; fmt++)
    {
        if (*fmt != '%')
        {
            *str++ = *fmt;
            continue;
        }
        while((*fmt) == '-' || (*fmt) == '+' || (*fmt) == ' ' || (*fmt) == '#' || (*fmt) == '0')    //%符号后面可能是+- #0等符号
        {
            fmt++;
            switch(*fmt)
            {
            case '-':
                flags |= LEFT;      //左对齐
                break;
            case '+':
                flags |= PLUS;      //显示加
                break;
            case ' ':
                flags |= SPACE;
                break;
            case '#':
                flags |= SPECIAL;
                break;
            case '0':
                flags |= ZEROPAD;
                break;
            }
        }

        //获取字段宽度
        field_width = -1;
        if (is_digit(*fmt))
            field_width = skip_atoi(&fmt);
        else if (*fmt == '*')
        {
            fmt++;
            field_width = va_arg(args, int);
            if(field_width < 0)
            {
                field_width = -field_width;
                flags |= LEFT;
            }
        }

        //获取精度
        precision = -1;
        if (*fmt == '.')
        {
            fmt++;
            if (is_digit(*fmt))
                precision = skip_atoi(&fmt);
            else if (*fmt == '*')       //如果是*数据宽度由可变参数提供
            {
                fmt++;
                precision = va_arg(args, int);
            }
            if (precision < 0)
                precision = 0;
        }

        //检测数据显示规格，%ld
        qualifier = -1;
        if (*fmt == 'h' || *fmt == 'l' || *fmt == 'L' || *fmt == 'Z')
        {
            qualifier = *fmt;
            fmt++;
        }

        switch(*fmt)
        {
        //%c可变参数转换为字符
        case 'c':
            if (!(falgs & LEFT))    //右对齐
                while(--field_width > 0)
                    *str++ = ' ';
            *str++ = (unsigned char)va_arg(args, int);
            while(--field_width > 0)
                *str++ = ' ';
            break;

        //%s字符串显示
        case 's':
            s = va_arg(args,char *);
            if(!s)
                s = '\0';
            len = strlen(s);
            if(precision < 0)
                precision = len;
            else if(len > precision)
                len = precision;

            if(!(flags & LEFT))     //右对齐
                while(len < field_width--)
                    *str++ = ' ';
            for(i = 0; i < len ; i++)
                *str++ = *s++;
            while(len < field_width--)  //左对齐
                *str++ = ' ';
            break;

        //%o 无符号八进制
        case 'o':
            if(qualifier == 'l')
                str = number(str,va_arg(args,unsigned long),8,field_width,precision,flags);
            else
                str = number(str,va_arg(args,unsigned int),8,field_width,precision,flags);
            break;

        //%p
        case 'p':
            if(field_width == -1)
            {
                field_width = 2 * sizeof(void *);
                flags |= ZEROPAD;
            }

            str = number(str,(unsigned long)va_arg(args,void *),16,field_width,precision,flags);
            break;
        //%x无符号十六进制
        case 'x':
            flags |= SMALL;
        //%x无符号十六进制
        case 'X':
            if(qualifier == 'l')
                str = number(str,va_arg(args,unsigned long),16,field_width,precision,flags);
            else
                str = number(str,va_arg(args,unsigned int),16,field_width,precision,flags);
            break;
        //%d或%i 有符号十进制数
        case 'd':
        case 'i':
            flags |= SIGN;

        //无符号十进制数
        case 'u':
            if(qualifier == 'l')
                str = number(str,va_arg(args,unsigned long),10,field_width,precision,flags);
            else
                str = number(str,va_arg(args,unsigned int),10,field_width,precision,flags);
            break;

        //%n无输出,把目前已格式化的字符串长度返回给函数调用者
        case 'n':
            if(qualifier == 'l')
            {
                long *ip = va_arg(args,long *);
                *ip = (str - buf);
            }
            else
            {
                int *ip = va_arg(args,int *);
                *ip = (str - buf);
            }
            break;

        //%%，输出%字符
        case '%':
            *str++ = '%';
            break;

        default:
            *str++ = '%';
            if(*fmt)
                *str++ = *fmt;
            else
                fmt--;
            break;
        }
    }
    *str = '\0';
    return str - buf;
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


