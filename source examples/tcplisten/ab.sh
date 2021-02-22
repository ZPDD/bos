#!/bin/bash
# Script file to assemble the program.
NAME="tcplisten"
nasm $NAME.asm -f bin -l $NAME.lst -o $NAME.app
