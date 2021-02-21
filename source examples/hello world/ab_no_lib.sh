#!/bin/bash
# Script file to assemble the hello world program.
NAME="hello_no_lib"
nasm $NAME.asm -f bin -l $NAME.lst -o $NAME.app
