#!/bin/bash
# Script file to assemble the program.
NAME="ball1"
nasm $NAME.asm -f bin -l $NAME.lst -o $NAME.app
