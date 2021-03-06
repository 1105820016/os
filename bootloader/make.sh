#!/bin/bash

nasm boot.asm -o boot.bin
nasm loader.asm -o loader.bin

mv /root/bochs-2.6.9/boot.img ./

dd if=boot.bin of=boot.img bs=512 count=1 conv=notrunc

mount boot.img /media/ -t vfat -o loop
cp loader.bin /media/
sync
umount /media/

mv ./boot.img /root/bochs-2.6.9/boot.img

rm boot.bin -f
rm loader.bin -f
