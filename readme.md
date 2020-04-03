# 毕设题目：基于intel x86-32平台的简易操作系统的设计与实现

### 参考资料：
《英特尔® 64 和 IA-32 架构开发人员手册》<br>
《x86汇编语言 从实模式到保护模式》<br>
《一个64位操作系统的设计与实现》<br>
《Orange's一个操作系统的实现》<br>
[描述符表和描述符高速缓存器](https://blog.csdn.net/cos_sin_tan/article/details/8511453)

### 准备工作：
1. 一个windows系统的电脑
2. vmware 虚拟机安装centos系统
2. 准备一个.img镜像虚拟软盘文件(bochs可制作) [制作软盘文件](https://blog.csdn.net/sunjing_/article/details/78781411)    [制作软盘文件](https://blog.csdn.net/apollon_krj/article/details/72026944)
3. 安装好各种工具


### 使用的工具：
##### 1. nasm汇编编译器
使用命令 nasm boot.asm -o boot.bin 将汇编编译成二进制文件
##### 2. dd 转换复制文件
dd if=boot.bin of=boot.img bs=512 count=1 conv=notrunc
##### 3. git版本管理工具
##### 4. G++、GCC、make
##### 5. Typora markdown格式文本编辑器
##### 6. Bochs x86硬件平台的开源模拟器
##### 7. notepad 文本编辑器
##### 8. MobaXterm 远程工具

### 开发流程:
1. 用notepad写好代码,存为xx.asm
2. 用nasm将汇编代码编译为二进制文件xx.bin
3. 用dd命令将二进制文件刻录成光盘文件 boot.img
4. 用bochsdbg调试boot.img(第一次需要配置安装目录下的bochsrc文档)
