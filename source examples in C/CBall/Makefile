# Makefile for a BOS application that will use standard 'gcc' and 'as' on Linux.
# Note:
#	You will need 'bos.ld' link file and program_loader.asm to build the
#	program to be compatible with BOS.
#
# Copyright (c) 2016-2022 David Borsato
# Created: Mar 31, 2021 by David Borsato

# Program name, change this as needed.
NAME = cball


# Defining variables for GCC and AS is to prepare for a future BOS specific
# cross compiler.
GCC = gcc
ASM = as

$(NAME): $(NAME).o lib_bos.o program_loader.o
	$(GCC) -T bos.ld -o $(NAME).app -ffreestanding -O2 -nostdlib program_loader.o lib_bos.o $(NAME).o -lgcc

$(NAME).o: $(NAME).c
	$(GCC) -c $(NAME).c -o $(NAME).o -ffreestanding -Wall -Wextra

lib_bos.o: lib_bos.c
	$(GCC) -c lib_bos.c -o lib_bos.o -ffreestanding -Wall -Wextra

program_loader.o: program_loader.asm
	$(ASM) program_loader.asm -o program_loader.o

clean:
	rm -f *.o
	rm -f *.app
