;*******************************************************************************
; INTER PROCESS COMMUNICATIONS TEST APPLICATION - 'PROCESS B'
;
; This application is used to test IPC, both message passing and memory sharing.
; This will be known as 'Process B'. A second peer program 'Process A' will
; be used to create a connection and pass information.
;
; Process B will initiate the connection to Process A. Therefore, Process A
; must be running before Process B starts. When Process B is done it will
; exit.
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
%include "ipc_h.asm"				; must incldue this file


PrgName 	db 'ipcA',0
DST_PID 	dw 0

%include "lib_app.asm"				; this must be after the IPC header section

entry:
mov rsi,PrgName
call get_pid				; gets the program ID (PID) of ipcA
mov [DST_PID],bx

;
;	SEND MESSAGE TO ANOTHER PROGRAM
;
call ipc_clear				; clear IPC headers
call ipc_clear_dst
mov dword [IPCDST.p1],0xAAAA0001	; Setting parameters 1 - 4 to random values.
mov dword [IPCDST.p2],0x22222222	; IPC calls can use parameters any which way they want.
mov dword [IPCDST.p3],0x33333333	; There are 4 parameters to work with.
mov dword [IPCDST.p4],0x44444444

mov rcx,5					; send 5 IPC messages
Loop_snd:
	mov ax,IPC_CMD_TEST
	mov bx,[DST_PID]
	; IN:	AX = CMD to send
	;		BX = PID to send message to
	; OUT:	BX = return code
	call ipc_send_msg
	inc qword [IPCDST.p1]
loop Loop_snd

mov bx,[DST_PID]
call ipc_get_pend_msg		; OUT: BX=Number of pending messages

;
;	SHARE MEMORY WITH ANOTHER PROGRAM
;

;	Allocate some memory and populate it
mov rdx,0x221
mov rax,0x3000
int 0xFF

mov rdi,rax
mov rsi,rax
mov rcx,0x3000
mov al,0
Loop1:
	stosb
	inc ax
loop Loop1

mov cx,0x3000
mov bx,[DST_PID]
;	Share memory w/ipcA
; IN:	RSI = pointer to memory to share
;	 	 CX = size of memory to share (in 4K blocks)
;		 BX = PID to share memory with
; OUT:	RAX = DST virtual address, zero if an error occurs
;		 BX = return code
;		RCX = record ID, zero if error
call ipc_share_memory


call ipc_clear_dst
; When sharing memory, parameters have a specific use.
mov [IPCDST.p1],rax				; parameter 1 tells the remote program where the shared memory is
mov [IPCDST.p2],rcx				; parameter 2 is the record ID, used to identify the transaction
mov qword [IPCDST.p3],0x3000	; parameter 3 is the size of the shared memory

mov ax,IPC_CMD_S_MEM
mov bx,[DST_PID]
; IN:	AX = CMD to send
;		BX = PID to send message to
; OUT:	BX = return code
call ipc_send_msg

mov rdx,0x0
int 0xFF
