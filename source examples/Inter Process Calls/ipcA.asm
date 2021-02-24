;*******************************************************************************
; INTER PROCESS COMMUNICATIONS TEST - 'PROCESS A'
;
; This application is used to test IPC, both message passing and memory sharing.
; This will be known as 'Process A'. A second peer program 'Process B' will
; be used to create a connection and pass information.
;
; Copyright (c) 2016-2019 David Borsato
; Created: May 17, 2019 by David Borsato
;*******************************************************************************
org 0x70000000
bits 64
jmp entry							; jump to application entry point
nop
nop


;;
;; This section is needed for any user program that wants to use IPC.
;;
%include "ipc_h.asm"				; must include this file
%include "lib_app.asm"				; this must be after the IPC header section

Y		db 1

entry:

call gui_init 						; initialize GUI variables

Loop1:
	mov ax,[IPC.cmd]
	cmp ax,0
	jnz do_cmd
	call ipc_get_q_msg				; check if there is another message
jmp Loop1 		; endless loop, use 'stop <process_number>' to quit program


do_cmd:
	cmp ax,IPC_CMD_S_MEM
	jne .001
		call prt_sh_mem
		jmp End_cmd
	.001:

	cmp ax,IPC_CMD_TEST
	jne .002
		call prt_test
	.002:

End_cmd:
	mov word [IPC.cmd], 0x0
jmp Loop1 		; return to main loop


; IN:	 AL = X coordinate
; 		RSI = string to print
prt_ln:
	cmp byte [Y],0xA				; 0xA will clear the screen everytime ipcB is run
	jb .Cont1
		mov byte [Y],1				; reset line number
		call clear_screen
	.Cont1:

	inc byte [Y]
	mov ah,[Y]
	call print_cli_xy
ret

prt_sh_mem:
	mov rsi,.lbl
	xor al,al
	call prt_ln

	mov rax,[IPC.p1]
	mov rdi,.var1
	call hexToString
	mov rsi,.var1
	mov al,20
	call prt_ln

	mov rax,[IPC.p2]
	mov rdi,.var1
	call hexToString
	mov rsi,.var1
	mov al,20
	call prt_ln

	mov rax,[IPC.p3]
	mov rdi,.var1
	call intToString
	mov rsi,.var1
	mov al,20
	call prt_ln
ret
.var1	times 4 dq 0
.lbl:
db 'Memory shared with this process',10
db 'Location: ',10
db 'Record ID: ',10
db 'Size:',10
db 0

prt_test:
	mov rsi,.msgTest
	xor al,al
	call prt_ln
ret
.msgTest 	db 'IPC test message received.',0

exit:
