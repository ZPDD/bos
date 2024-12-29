;*******************************************************************************
;*  HORIZTONAL BALL 1
;*******************************************************************************

org 0x70000000
bits 64
jmp ENTRY

FONT1.FULL.BLOCK 					equ 9608

;*******************************************************************************
;*  PROGRAM DATA
;*******************************************************************************
x dw 0
y dw 0
direction db 1              ; 1=right, 0=left
move_rate dw 1
start_x dw 300
start_y dw 400
floor dw 550
wait_time_ms    dq 5       ; millis to wait

;*******************************************************************************
;*  INCLUDED FILES
;*******************************************************************************
%include "../Apps/lib_app.asm"


ENTRY:
add rsp,8               ; clean stack from calling program parameters, pop 8 bytes off the stack
call gui_init

; set initial values
mov ax,[start_x]
mov [x],ax 
mov ax,[start_y]
mov [y],ax

main_loop:
    call draw_char
    call wait_time
    call clear_char
    call clear_values
    call move
jmp main_loop

;*******************************************************************************
;*  PROCEDURES
;*******************************************************************************
clear_char:
    mov ecx,0               ; set colour to black then draw character
    jmp draw

draw_char:
    mov ecx,0x54FFFF

draw:
    call print_values

;    Draw a character
;    Parameters:
;       RDX = 0x120
;		AX = X coordinate
;		BX = Y coordinate
;		ECX = color
;		R10 = character code
    mov ax,[x]
    mov bx,[y]
    mov r10, 'o'
    mov rdx, 0x120
    int 0xFF
ret

move:
    cmp byte [direction],0
    jz .going_left

.going_right:
    mov ax,[x]
    add ax,[move_rate]
    cmp ax,[floor]
    jl .Done

    mov ax,[floor]
    xor byte [direction],1

.going_left:
    mov ax, [x]
    sub ax, [move_rate]
    cmp ax, [start_x]
    jg .Done

    mov ax, [start_x]
    xor byte [direction],1

.Done:
    mov [x],ax
ret

clear_values:
    push rax 
    push rsi 

    mov rsi,.str
    mov al, [.start_x]
    mov ah,10
    call clear_screen_ch_w
    mov ah,11
    call clear_screen_ch_w

    pop rsi 
    pop rax 
ret 
.start_x        db 10
.str            dw 9608,9608,9608,9608,9608,0       ; print full blocks

print_values:
    push rax 
    push rdi 
    push rsi 

    mov rdi,var 

; Print X
    mov al,0
    mov ah,10
    mov rsi,t_x 
    call print_cli_xy

    movzx rax, word [x]
    call intToString

    mov al,10
    mov ah,10 
    mov rsi,rdi 
    call print_cli_xy

; Print Y
    mov al,0
    mov ah,11
    mov rsi,t_y
    call print_cli_xy

    movzx rax, word [y]
    call intToString

    mov al,10
    mov ah,11 
    mov rsi,rdi 
    call print_cli_xy

    pop rax 
    pop rdi 
    pop rsi 
ret 
t_x     db 'draw X:',0
t_y     db 'draw Y:',0
t_blank db '     ',0
var     times 100 db 0


wait_time:
    mov rcx,[wait_time_ms]
    call waitms
ret
