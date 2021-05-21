;*******************************************************************************
; INTER PROCESS COMMUNICATIONS - Header file
;
; Common header variables and routines that a user program would use.
;
; Copyright (c) 2016-2019 David Borsato
; Created: May 16, 2019 by David Borsato
;*******************************************************************************
bits 64

global ipc_clear
global ipc_get_msg
global ipc_get_p1
global ipc_get_p2
global ipc_get_p3
global ipc_get_p4


jmp ipc_start

;	GENERAL PARAMETERS
IPC_HDR_START		equ 0xB055 		; IPC starting marker
IPC_HDR_END			equ 0xB0FF 		; IPC end marker
IPC_MAX_SZ 			equ 0xFFFF		; max size of the IPC header
IPC_MAX_ADDR		equ 0x1000 		; max file offset to seek to
IPC_MIN_SZ			equ IPC_Size	; min size (bytes)

;	IPC COMMANDS
IPC_CMD_TEST		equ 0x001 		; send test message

IPC_CMD_P_MSG		equ 0x100 		; send a message
IPC_CMD_S_MEM		equ 0x101 		; share memory to DST_PID

IPC_CMD_S_START		equ 0x200 		; start a shared memeory IPC


;===============================================================================
;                        I P C   C O N S T R U C T S
;===============================================================================

;	IPC CONSTRUCT
;	Use this to receive messages from another PID
IPC:
	.start 	dw 0xB055				; start of IPC header marker
	.cmd 	dw 0					; the first 2 bytes are always for IPC command/response
	.org 	dw 0					; the calling program's PID
	; P1 - P4 are parameters that can be received.
	.p1		dq 0					; request/response space
	.p2		dq 0					; request/response space
	.p3		dq 0					; request/response space
	.p4		dq 0					; request/response space
	.end	dw 0xB0FF				; end of header marker
IPC_Size	equ $-IPC

;	IPC DESTINATION CONSTRUCT
;	Use this to create messages to send to another PID
IPCDST:
	.start 	dw 0xB055				; start of IPC header marker
	.cmd 	dw 0					; the first 2 bytes are always for IPC command/response
	.org 	dw 0					; the calling program's PID
	; P1 - P4 are parameters that can be received.
	.p1		dq 0					; request/response space
	.p2		dq 0					; request/response space
	.p3		dq 0					; request/response space
	.p4		dq 0					; request/response space
	.end	dw 0xB0FF				; end of header marker
IPCDST_Size	equ $-IPCDST


;===============================================================================
;                        I P C   C O M M A N D S
;===============================================================================
ipc_start:


;******************************************************************************
; Clears the IPC message header.
; IN:	---
; OUT:	---
;******************************************************************************
ipc_clear:
	push rax
	push rcx
	push rdx
	push rdi

; Clear memory
	xor rdx,rdx
	mov rax,IPC_Size
	mov rcx,8
	div ecx
	mov rcx,rax
	xor rax,rax
	mov rdi,IPC
	rep stosq
	mov rcx,rdx
	rep stosb

; Reset start and end markders
	mov word [IPC.start],IPC_HDR_START
	mov word [IPC.end],IPC_HDR_END

	pop rdi
	pop rdx
	pop rcx
	pop rax
ret


;******************************************************************************
; Clears the IPC destination message space.
; IN:	---
; OUT:	---
;******************************************************************************
ipc_clear_dst:
	push rax
	push rcx
	push rdx
	push rdi

; Clear memory
	xor rdx,rdx
	mov rax,IPCDST_Size
	mov rcx,8
	div ecx
	mov rcx,rax
	xor rax,rax
	mov rdi,IPCDST
	rep stosq
	mov rcx,rdx
	rep stosb

; Reset start and end markders
	mov word [IPCDST.start],IPC_HDR_START
	mov word [IPCDST.end],IPC_HDR_END

	pop rdi
	pop rdx
	pop rcx
	pop rax
ret

;******************************************************************************
; Returns a command to AX if there is either a message waiting in the IPC
; header or queued. If the header is empty but there is a queued message,
; then it will be copied to the IPC header.
; IN:	---
; OUT:	 AX = commond, or zero if there are no IPC messages.
;******************************************************************************
ipc_get_msg:
	movzx rax, word [IPC.cmd]
	cmp rax,0
	jnz .Return

	call ipc_get_q_msg				; check if there is another message
	movzx rax, word [IPC.cmd]
.Return:
ret
.Found:				; used to help debug
	xchg bx,bx
	jmp .Return

;******************************************************************************
; Returns a parameter 1 (P1) in the IPC header to RAX.
; IN:	---
; OUT:	 RAX = parameter value
;******************************************************************************
ipc_get_p1:
	mov rax, [IPC.p1]
ret

;******************************************************************************
; Returns a parameter 2 (P2) in the IPC header to RAX.
; IN:	---
; OUT:	 RAX = parameter value
;******************************************************************************
ipc_get_p2:
	mov rax, [IPC.p2]
ret

;******************************************************************************
; Returns a parameter 3 (P3) in the IPC header to RAX.
; IN:	---
; OUT:	 RAX = parameter value
;******************************************************************************
ipc_get_p3:
	mov rax, [IPC.p3]
ret

;******************************************************************************
; Returns a parameter 4 (P4) in the IPC header to RAX.
; IN:	---
; OUT:	 RAX = parameter value
;******************************************************************************
ipc_get_p4:
	mov rax, [IPC.p4]
ret

;******************************************************************************
; Returns the first orphaned record found for the currently running PID. An
; orphan is a record that only has 1 PID associated to a shared record. That
; is, when PID 'A' releases shared memory with PID 'B', PID 'B' will have
; an orphan record.
;
; This routine is used to clean up shared memory. If the memory needs to be
; cleared then the next statement should be ipc_release.
;
; IN:	---
; OUT:	RAX = PID's virtual memory location that is orphaned. Zero if
;			  nothing is found.
;		RCX = Size of memory or zero if nothing found.
;******************************************************************************
ipc_get_orphan:
	push rdx
	mov rdx,0x40C
	int 0xFF
	pop rdx
ret

;******************************************************************************
; Returns the number of messages pending in the Send Message queue for a
; specific destination PID.
; IN:	BX = DST PID
; OUT:	BX = Number of pending messages
;******************************************************************************
ipc_get_pend_msg:
	push rdx
	mov edx,0x40B
	int 0xFF
	pop rdx
ret

;******************************************************************************
; Checks the Send Message queue to see if the currently running process has
; a message to be sent to it. If so, then the message will be copied to the
; currently running process’ IPC header.
;
; If nothing is pending then the IPC header will be cleared .
;
; IN:	---
; OUT:	IPC header is updated accordingly.
;******************************************************************************
ipc_get_q_msg:
	push rdx
	mov edx,0x40A
	int 0xFF
	pop rdx
ret

;******************************************************************************
; Releases or deallocates shared memory from the currently running process.
; IN:	RAX = memory location to release
;		ECX = size of memory to release
; OUT:	 BX = return code
;******************************************************************************
ipc_release:
	push rdx
	mov edx,0x422
	int 0xFF
	pop rdx
ret

;******************************************************************************
; Releases or deallocates shared memory from the currently running process. But
; uses an IPCS ID as the search criteria.
; IN:	RBX = IPCS ID
; OUT:	 BL = return code; 0=success, 1=record not round
;******************************************************************************
ipc_release_id:
	push rdx
	mov edx,0x40D
	int 0xFF
	pop rdx
ret

;******************************************************************************
; Share memory with another process. NOTE: The destination PID will have
; read/write access to this memory.
; IN:	RSI = pointer to memory to share
;	 	 CX = size of memory to share (in 4K blocks)
;		 BX = PID to share memory with
; OUT:	RAX = DST virtual address, zero if an error occurs
;		 BX = return code
;		RCX = record ID, zero if error
;******************************************************************************
ipc_share_memory:
	push rdx
	mov rdx,0x405
	int 0xFF
	pop rdx
ret


;*******************************************************************************
; Sends an IPC message to a destination process ID. This routine will
; assume that IPCDST is being used.
; IN:	AX = CMD to send
;		BX = PID to send message to
; OUT:	BX = return code
;*******************************************************************************
ipc_send_msg:
	push rcx
	push rsi

	mov word [IPCDST.cmd], ax
	mov rsi,IPCDST
	mov cx, IPCDST_Size
	; IN:	RSI = pointer to message to send
	;		 CX = size of message to send (min 32)
	;		 BX = PID to send message to
	; OUT:	 BX = return code
	call ipc_send_message

	pop rsi
	pop rcx
ret

;*******************************************************************************
; Sends an IPC message to a destination process ID.
; IN:	RSI = pointer to message to send
;		 CX = size of message to send (min 32)
;		 BX = PID to send message to
; OUT:	 BX = return code
;*******************************************************************************
ipc_send_message:
	push rdx
	mov edx,0x404
	int 0xFF
	pop rdx
ret
