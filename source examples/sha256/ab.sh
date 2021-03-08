#!/bin/bash
# Script file to assemble the program.
NAME="sha256_example"
nasm $NAME.asm -f bin -l $NAME.lst -o $NAME.app
