;******************************************************************************
; HELLO WORLD
;
;   In keeping with programming tradition, this is the classic Hello World
;   program.
;******************************************************************************

org 0x70000000              ; all user programs must originate at this address
bits 64                     ; must use 64 bit directive
jmp ENTRY                   ; jump to actual code, the name can be any name you like

;***********************************
;   PROGRAM DATA
;***********************************
msg         db 'Hello World!',0 ; a NULL terminated string to print

;***********************************
;   INCLUDE ADDITIONAL FILES
;***********************************
; This is a library file that has many common functions (e.g. clear, print, etc).
; Instead of doing raw INT system calls, this library is a wrapper for them
; and uses easy to remember names instead of numbers.
%include "lib_app.asm"

;***********************************
;   PROGRAM CODE
;***********************************
ENTRY:                      ; code start
call clrscr                 ; clears the screen

mov rsi,msg                 ; set parameter with string to print
call print_ln               ; prints the line

; The Exit routine stops the program. If you do not do this the CPU will
; continue to the next address in memory and try to execute it. This will
; cause a memory protection fault or a general protection fault (which
; would still stop your program). This is the clean way to end your program.
call Exit
      
