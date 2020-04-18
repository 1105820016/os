all: system
	objcopy -I elf64-x86-64 -S -R ".eh_frame" -R".comment" -O binary system kernel.bin
	
system: head.o main.o printk.o
	ld -b elf64-x86-64 -z muldefs head.o main.o printk.o -T kernel.lds -o system
	
head.o: head.S
	gcc -E head.S > head.s
	as head.s -o head.o --64

main.o: main.c
	gcc -mcmodel=large -fno-builtin -m64 -c main.c
	
printk.o: printk.c
	gcc -mcmodel=large -fno-builtin -m64 -c printk.c
	
clean:
	rm -rf *.o *.s system kernel.bin
