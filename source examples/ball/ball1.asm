org 0x70000000
bits 64
jmp ENTRY
nop
nop

;*******************************************************************************
;*  PROGRAM HEADER
;*******************************************************************************
dd 0x53534F42           ; magic number


;*******************************************************************************
;*  PROGRAM DATA
;*******************************************************************************
x dw 0
y dw 0
direction db 1      ; 1=down, 0=up
floor dw 0
move_rate dw 1
start_x dw 0
start_y dw 0
wait_time_ms    dq 25      ; millis to wait

;*******************************************************************************
;*  INCLUDED FILES
;*******************************************************************************
%include "lib_app.asm"


ENTRY:
add rsp,8
call gui_init

; set initial values
movzx rax, word [GUI_X]
mov rbx, 2
div ebx
mov [start_x],ax
mov [x],ax

movzx rax, word [GUI_Y]
div ebx
mov word [y],ax
mov word [start_y],ax
mov ax, [GUI_Y]
sub ax, 25
mov [floor],ax

main_loop:
    call draw_char
    call wait_time
    call clear_char
    call move
jmp main_loop

;*******************************************************************************
;*  PROCEDURES
;*******************************************************************************
clear_char:
    mov ecx,0
    jmp draw

draw_char:
    mov ecx,0x5467EE

draw:
    mov ax,[x]
    mov bx,[y]
    mov r10, 'o'
    mov rdx, 0x120

;    Draw a character
;    Parameters:
;       RDX = 0x120
;		AX = X coordinate
;		BX = Y coordinate
;		ECX = color
;		R10 = character code
    int 0xFF
ret

move:
    cmp byte [direction],0
    jz .going_up

.going_down:
    mov ax,[y]
    add ax,[move_rate]
    cmp ax,[floor]
    jl .Done

    mov ax,[floor]
    xor byte [direction],1

.going_up:
    mov ax, [y]
    sub ax, [move_rate]
    cmp ax, [start_y]
    jg .Done

    mov ax, [start_y]
    xor byte [direction],1

.Done:
    mov [y],ax
ret


wait_time:
    mov rcx,[wait_time_ms]
    call waitms
ret
