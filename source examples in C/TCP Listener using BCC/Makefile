# Standard Makefile for a BOS application using the BOS cross compiler
# and toolchain.
# Copyright (c) 2016-2022 David Borsato
# Created: Mar 31, 2021 by David Borsato


# Change this to the location where the cross compiler was placed.
PREFIX = ~/bcc2/bos/sysroot/bin

# Change this to the name of your application.
NAME = ctcplisten

#########################################################################
# The rest can be left as is. Change it if you know what you are doing. #
#########################################################################
GCC = $(PREFIX)/x86_64-bos-gcc
ASM = $(PREFIX)/x86_64-bos-as

$(NAME): $(NAME).o lib_bos.o lib_ipc.o
	$(GCC) -T bos.ld -o $(NAME).app lib_ipc.o lib_bos.o $(NAME).o -lgcc

$(NAME).o: $(NAME).c
	$(GCC) -c $(NAME).c -o $(NAME).o -Wall -Wextra

lib_bos.o: lib_bos.c
	$(GCC) -c lib_bos.c -o lib_bos.o -Wall -Wextra

lib_ipc.o: lib_ipc.asm
	nasm -f elf64 lib_ipc.asm -o lib_ipc.o

clean:
	rm -f *.o
	rm -f *.app
