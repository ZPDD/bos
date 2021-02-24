#!/bin/bash
# Script file to assemble the program.
NAME="ipcA"
nasm $NAME.asm -f bin -l $NAME.lst -o $NAME.app

NAME="ipcB"
nasm $NAME.asm -f bin -l $NAME.lst -o $NAME.app
