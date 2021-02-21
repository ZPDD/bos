;******************************************************************************
; HELLO WORLD
;
;   In keeping with programming tradition, this is the classic Hello World
;   program.
;
;   This version does not use the lib_app.asm library, instead this program
;   will do direct system calls. The main advantage of doing it this way is
;   to create a VERY small program (64 bytes vs 2516 bytes).
;******************************************************************************

org 0x70000000              ; all user programs must originate at this address
bits 64                     ; must use 64 bit directive
jmp ENTRY                   ; jump to actual code, the name can be any name you like

;***********************************
;   PROGRAM DATA
;***********************************
msg         db 'Hello World!',0 ; a NULL terminated string to print
x           dw 20
y           dw 50

ENTRY:
;	Parameters:	RDX = 0x121
;			AX = X coordinate
;			BX = Y coordinate
;			ECX = color
;			RSI = memory location of NULL terminated string
mov rsi,msg
mov ax,[x]
mov bx,[y]
mov ecx, 0x00FF00
mov rdx,0x121
int 0xFF

; Exit program
mov rdx,0x0
int 0xFF
