# 毕设题目：基于intel x86-32平台的简易操作系统的设计与实现

### 参考资料：
《x86汇编语言 从实模式到保护模式》<br>
《Orange's一个操作系统的实现》<br>
[描述符表和描述符高速缓存器](https://blog.csdn.net/cos_sin_tan/article/details/8511453)

### 准备工作：
1. 一个windows系统的电脑
2. 准备一个img镜像文件 [制作img镜像文件](https://blog.csdn.net/sunjing_/article/details/78781411)
3. 安装好各种工具


### 使用的工具：
##### 1. nasm汇编编译器
使用命令 nasm boot.asm -o boot.bin 将汇编编译成二进制文件

##### 2. FloppyWriter 软盘书写工具
运行 FloppyWriter.exe，选择 Writer File to Image 将二进制文件刻录成光盘文件（boot.img）

##### 3. notepad 文本编辑器
##### 4. Typora markdown格式文本编辑器
##### 5. vmware 虚拟机
##### 6. Bochs x86硬件平台的开源模拟器
使用的是bochs安装目录下的bochsdbg程序，用于调试

##### 7. MinGW 安装G++、GCC、make

### 开发流程:
1. 用notepad写好代码,存为xx.asm
2. 用nasm将汇编代码编译为二进制文件xx.bin
3. 用FloppyWriter将二进制文件刻录成光盘文件 boot.img
4. 用bochsdbg调试boot.img(第一次需要配置安装目录下的bochsrc文档)
