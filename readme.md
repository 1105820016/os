# 毕设题目：基于intel x86-32平台的简易操作系统的设计与实现

### 参考资料：
《x86汇编语言 从实模式到保护模式》<br>
《Orange's一个操作系统的实现》<br>
[描述符表和描述符高速缓存器](https://blog.csdn.net/cos_sin_tan/article/details/8511453)

### 准备工作：
1. 一个windows系统的电脑
2. 准备一个.img镜像虚拟软盘文件 [制作软盘文件](https://blog.csdn.net/sunjing_/article/details/78781411)    [制作软盘文件](https://blog.csdn.net/apollon_krj/article/details/72026944)
3. 准备一个.vhd虚拟硬盘 (x86汇编配套工具中有)
4. 安装好各种工具


### 使用的工具：
##### 1. nasm汇编编译器
使用命令 nasm boot.asm -o boot.bin 将汇编编译成二进制文件
##### 2. FloppyWriter 软盘书写工具
运行 FloppyWriter.exe，选择 Writer File to Image 将二进制文件刻录成光盘文件（boot.img）
##### 3. fixvhdwr 硬盘写入工具
运行fixvhdwr.exe，选择vdh虚拟硬盘，选择二进制文件，选择LBA连续直写模式
##### 4. notepad 文本编辑器
##### 5. Typora markdown格式文本编辑器
##### 6. vmware 虚拟机
##### 7. Bochs x86硬件平台的开源模拟器
使用的是bochs安装目录下的bochsdbg程序，用于调试

##### 8. MinGW 安装G++、GCC、make

### 开发流程:
1. 用notepad写好代码,存为xx.asm
2. 用nasm将汇编代码编译为二进制文件xx.bin
3. 用FloppyWriter将二进制文件刻录成光盘文件 boot.img
4. 用bochsdbg调试boot.img(第一次需要配置安装目录下的bochsrc文档)
5. 如果是多个二进制文件，就不能使用FloppyWriter了，这里使用fixvhdwr工具，将数据写入指定扇区
6. 用bochsdbg调试boot.vdh
