all: system
	objcopy -I elf64-x86-64 -S -R ".eh_frame" -R".comment" -O binary system kernel.bin
	
system: head.o entry.o main.o printk.o trap.o 
	ld -b elf64-x86-64 -z muldefs head.o entry.o main.o printk.o trap.o -T kernel.lds -o system
	
head.o: head.S
	gcc -E head.S > head.s
	as head.s -o head.o --64

entry.o: entry.S
	gcc -E entry.S > entry.s
	as entry.s -o entry.o --64

main.o: main.c
	gcc -mcmodel=large -fno-builtin -m64 -c main.c
	
printk.o: printk.c
	gcc -mcmodel=large -fno-builtin -m64 -c printk.c
	
trap.o: trap.c
	gcc -mcmodel=large -fno-builtin -m64 -c trap.c
	
clean:
	rm -rf *.o *.s system kernel.bin
