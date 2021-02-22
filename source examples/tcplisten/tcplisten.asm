;*******************************************************************************
; TCP listener test application. Listens for data on a specified port and
; echos what was received to the screen. When the remote side closes the
; connection the program will exit.
;
; Follow the steps below to use this program:
; *  Use the 'ab.sh' script to assemble the code.
; *  Run BOS VM.
; *  Get the IP address of the BOS VM; ip show
; *  Load program into BOS using the command 'run load_app.bin' and a web
;	 browser.
; *  In the address bar of the web browser put in the IP address found using
;    the 'ip show' command.
; *  Drag and drop the flat binary file 'tcplisten.app' into the 'Drop files here'
;    box.
;    Refer to BOS Programmers guide for more information on loading a program.
; *  Goto BOS VM
; *  Run the program; 'run tcplisten.app'
; *  Use a program like 'nc' on your PC or another PC to connect and send
;    text messages.
; *  When done, press Control+C to exit the nc session, this will close the
;    connection.
;
; ** Example commands from a Linux terminal:
;    nc <IP_ADDRESS> 8888
;    hello there
;    [Ctrl+C]
;
;    Where <IP_ADDRESS> is taken from the 'ip show' command.
;    'hello there' will be displayed on the BOS VM screen.
;    [Ctrl+C] will exit the program on BOS.
;
;
; Copyright (c) 2016-2018 David Borsato
; Created: Jun 30, 2018 by David Borsato
;*******************************************************************************
org 0x70000000						; user mode
bits 64

jmp entry							; jump to application entry point
nop
nop

NET_RTN_TCP_NEW_CHLD_L	equ 0x30D 	; TCP new child listener connection
PORT 		equ 8888				; port to listen on
SG_HDR 		equ 32					; TCP signalling header size


;*******************************************************************************
;*  INCLUDED FILES
;*******************************************************************************
; This file is needed for any user program that wants to use IPC. IPC_H should
; always be the first include file and come before the data section.
; This is because the header section in that file needs to come before any
; data or include file.
%include "ipc_h.asm"				; must include this file


;*******************************************************************************
;*  PROGRAM DATA
;*******************************************************************************
CID 		dq 0 			; network connection ID
CH_NUM 		dw 2			;
LINE_NO 	dw 0			; tracks what line number to print on
BUFF_SND	dq 0			; memory location of send buffer
BUFF_SZ_SND	dd 0xFFFF		; size of send buffer
GUI			db 0			; GUI mode of system
GUI_X 		dw 0			; X res
GUI_Y 		dw 0 			; Y res
GUI_CH_W	dw 0			; char width
GUI_CH_H	dw 0			; char height
NET_BUFF 	dq 0			; network receive buffer
NET_BUFF_SZ dq 0x9000

;*******************************************************************************
;*  MESSAGES
;*******************************************************************************
msgClosing 	db 'Closing connection. . .',0
msgClosed	db 'Connection closed.',0
msgOpenPort	db 'Openning port. . .',0
msgRcv 		db 'Message received:',0
msgRst 		db 'Connection was reset.',0
msgWaiting	db 'Waiting for connection. . .',0


;*******************************************************************************
;*  PROGRAM ENTRY
;*******************************************************************************
entry:
; Get GUI MODE and GUI attributes
mov rdx,0x10D
int 0xFF
mov byte [GUI], al
mov rdx,0x104
int 0xFF
mov word [GUI_X],ax
mov rdx,0x105
int 0xFF
mov word [GUI_Y],ax
mov rdx,0x101
mov r10,' '
int 0xFF
mov [GUI_CH_W],ax
mov [GUI_CH_H],bx
mov ax,[GUI_Y]
sub ax,bx
sub ax,bx
mov [GUI_Y],ax				; reset Y so that CMD box is not cleared

call Clear_screen
mov word [LINE_NO],1		; start at line 1, skips 'Initializing interprocess . . . '

; Allocate space for network buffer
mov rdx,0x221
mov eax,[NET_BUFF_SZ]
int 0xFF
cmp bl,0
jnz Error_no_memory
mov [NET_BUFF],rax

; Allocate space for send buffer
mov rax,0
mov rdx,0x221
mov eax,[BUFF_SZ_SND]
int 0xFF
cmp bl,0
jnz  Error_no_memory
mov [BUFF_SND], rax

; Open listener port
mov rsi,msgOpenPort
call Print

mov ax,PORT
mov ecx,[NET_BUFF_SZ]
mov rdx,0x30				; starts a TCP listener on port AX
; IN:	 AX = Port
;		ECX = size of receive buffer
;		RDI = receive buffer location
; OUT:	RAX = return code; 0=success, refer to NET_RTN_ codes
; 		RCX = connection ID
int 0xFF

call prt_rtn_code

cmp rax,0
jnz Error_open_port

mov [CID],rcx 				; save connection ID
mov rsi,msgWaiting
call Print

xor rcx,rcx
wait1:
	mov rdx,0xF					; switch to another process, avoids a 'busy wait'
	int 0xFF

	mov ax,[IPC.cmd]
	cmp ax,0
	jz .Skip_ipc_cmd
		call process_ipc_cmd
	.Skip_ipc_cmd:

	mov rax,[NET_BUFF]
	cmp word [rax],0
	jz wait1

	mov rax,[NET_BUFF]
	cmp word [rax],0x3FE 		; remote side closed connection
	je  Rmt_closed

	cmp word [rax],0x3FF 		; remote side reset
	je  Rmt_rst

	mov rsi,msgRcv
	call Print

	mov rsi,[NET_BUFF]
	add rsi,SG_HDR				; move past signalling bytes
	call Print


	call reset_net_buff			; NULL buffer for re-use
jmp wait1						; loop until connection is closed


; local side close connection
Close:
	mov rsi,msgClosing
	call Print

	mov rcx,[CID]
	mov rdx,0x27					; close connection
	int 0xFF

	call prt_rtn_code
	jmp Exit

; Remote side closed connection
Rmt_closed:
	mov rsi,msgClosed
	call Print
	jmp Exit


; Remote side reset connection
Rmt_rst:
	mov rsi,msgRst
	call Print
	jmp Exit


;*******************************************************************************
;*                        E R R O R   H A N D L I N G
;*******************************************************************************
msgErrOpen			db 'ERROR: Could not open port.',0
msgNoMem			db 'ERROR: Not enough memory for send and receive buffers!',0


Error_no_memory:
	mov rsi,msgNoMem
	jmp Error_handler

Error_open_port:
	mov rsi,msgErrOpen
	jmp Error_handler


; IN:	RSI = Error message
Error_handler:
	;call Clear_screen		; LINE_NO set to zero
	xor ax,ax 				; to X to 0
	inc word [LINE_NO]
	call Print

Exit:
	mov rdx,0x0				; stop process
	int 0xFF


;*******************************************************************************
;*                          P R O C E D U R E S
;*******************************************************************************

Clear_screen:
	push rcx
	push rdx
	push r8
	push r9
	push r10
	push r11

	xor r10,r10
	xor r11,r11

	; Clear screen
	; IN:	 R8 = starting X (left)
	;		 R9 = starting Y (top)
	;		R10 = width
	;		R11 = height
	;		ECX = color
	; 		RDX = 0x126
	mov r8,0
	mov r9,0 ; 0xA
	mov r10w,[GUI_X] ;0x31F
	mov r11w,[GUI_Y] ;0x212
	;mov ecx, 0xC80				; blue
	mov ecx, 0x0				; black
	mov rdx, 0x126
	int 0xFF

	pop r11
	pop r10
	pop r9
	pop r8
	pop rdx
	pop rcx
ret



;******************************************************************************
;	hexToChar
;		- converts a HEX byte into character string.  BH will hold the high
;		  order byte and BL will hold the low order byte.
;	param/		BL = HEX byte to convert (e.g. DB)
;	returns/	BH = high order byte (e.g. D)
;	returns/	BL = low order byte (e.g. B)
;******************************************************************************
hexToChar:
	push rax

	xor eax, eax 					; initialize EAX for use
	xor bh, bh						; initialize BH

	mov al, bl	 					; copy BL to AL

	cmp al, 0x10 					; if less then 0x10h, then we don't need
	jb  .Convert_lower_bits			; to worry about the high order bits

	push rbx 						; store on stack for later
	xor ebx, ebx 					; initialize EBX for use

	shr al, 4						; move bits 5-8 over 1 nibble to get character
	cmp al, 0xA
	jl  .High_0_to_9
	add al, 0x37
	jmp .Add_to_BH
.High_0_to_9:
	add al, 0x30

.Add_to_BH:
	mov bh, al						; put in BH

	pop rax							; retrieve orignal number from stack
	and al, 1111b 					; mask out the upper nibble in AL

.Convert_lower_bits:
	cmp al, 0xA
	jb  .Lower_0_to_9
	add al, 0x37
	jmp .Add_to_BL

.Lower_0_to_9:
	add al, 0x30

.Add_to_BL:
	mov bl, al

.Done:
	pop rax
ret


;	Calls the function below, but allows the programmer to use EBX as
;	the parameter instead of EAX.
;	IN:	EBX = hex number
;		EDI = address pointer to put string
hexToString_ebx:
	push rax
	mov eax, ebx
	call hexToString
	pop rax
ret

;******************************************************************************
;	hexToString
;		- converts a hex number to string so that you can print it to the
;		  screen.
;	param/		EAX = hex number
;	param/		EDI = address pointer to put string
;******************************************************************************
hexToString:
	push rax
	push rbx
	push rdi

	cmp rax, 0					; first check if value is zero
	je  .Return_zero			; if so, then just return a zero and exit

	xor rbx, rbx				; initialize EBX to zeros
	push rbx 					; push zeros to stack to act as a terminator

.Loop1:
	cmp rax, 0					; if EAX=0 then there is nothing left to convert
	je .Save_string_to_var 		; exit and build string

	mov rbx, rax				; create a working copy
	and rbx, 1111b 				; get the last nibble
	call hexToChar				; convert to ASCII character
	push rbx					; save ASCII values on stack
	shr rax, 4
	jmp .Loop1

.Save_string_to_var:
	pop rbx

.Loop2:
	cmp rbx, 0					; terminator found, exit loop
	je  .Done
	mov [rdi], bl 				; copy to address pointer
	inc rdi						; move EDI forward
	pop rbx
	jmp .Loop2

.Return_zero:
	mov [rdi], byte '0'			; ASCII value of zero
	inc rdi

.Done:
	mov [rdi], byte 0			; add null terminator
	pop rdi
	pop rbx
	pop rax
ret


; Print a NULL terminated string to the screen
; IN:	LINE_NO = Y coordinate
;		RSI = String to print
Print:
	push rax
	push rbx
	push rcx
	push rdx

	cmp word [LINE_NO],21
	jb .Skip_clr_scr
		call Clear_screen
	.Skip_clr_scr:

	cmp word [CH_NUM],80
	jb .Skip_RTN
		mov word [CH_NUM],2
		inc word [LINE_NO]
	.Skip_RTN:


;	Draws a NULL terminated string
;	Parameters:	RDX = 0x121
;			AX = X coordinate
;			BX = Y coordinate
;			ECX = color
;			RSI = memory location of NULL terminated string
	call .Get_ch_no				; returns to AX
	call .Get_line_no			; returns to BX
	mov ecx, 0x00FFBB
	mov rdx,0x121
	int 0xFF

	inc word [LINE_NO]

	pop rdx
	pop rcx
	pop rbx
	pop rax
ret
; Returns the X coordinate for a character based on the current
; character counter CH_NUM. Then increments CH_NUM for next time.
; IN:	CH_NUM
; OUT:	AX = X coordinate
.Get_ch_no:
	push rbx
	push rdx

	xor rdx,rdx
	mov ax,[CH_NUM]
	mov bx,[GUI_CH_W]
	mul bx

	pop rdx
	pop rbx
ret

; Returns the BX value based on the current LINE_NO value.
; IN:	LINE_NO
; OUT:	BX = Y coordinate
.Get_line_no:
	push rax
	push rdx

	xor rax,rax
	xor rbx,rbx
	xor rdx,rdx

	mov ax,[LINE_NO]
	mov bx,[GUI_CH_H]
	mul ebx

	mov ebx,eax

	pop rdx
	pop rax
ret

prt_rtn_code:
	push rax
	push rbx
	push rdi
	push rsi

	mov rsi,.msgTitle
	mov rdi,.varBuff
	call str_cpy
	dec rdi 				; del NULL
	call hexToString

	mov rsi,.varBuff

	call Print

	pop rsi
	pop rdi
	pop rbx
	pop rax
ret
.msgTitle		db 'Network return code: ',0
.varBuff		times 80 db 0


process_ipc_cmd:
	cmp ax,NET_RTN_TCP_NEW_CHLD_L
	jne .30D
		call process_ipc_new_chld
		jmp .Done
	.30D:

.Done:
	call ipc_clear					; clear IPC HDR
ret

process_ipc_new_chld:
	push rax
	mov rax,[IPC.p1]				; address of buffer
	mov [NET_BUFF],rax
	mov ax, [IPC.p2]				; size of buffer
	mov [NET_BUFF_SZ],ax
	pop rax
ret

;******************************************************************************
; CLEAR NET_BUFF
;	Clears the signalling bits in NET_BUFF back to zeros. Clears the data
; 	portion back to zeros.
;******************************************************************************
reset_net_buff:
	push rax
	push rcx
	push rdi

	; Clear signalling bytes in NET_BUFF
	xor rax,rax
	mov rdi,[NET_BUFF]
	stosq
	stosq

	; Clear data portion
	mov rdi,[NET_BUFF]
	add rdi,SG_HDR				; move past signalling bytes
	mov rcx,[NET_BUFF_SZ]
	sub rcx,SG_HDR
	cld
	rep stosb					; using QWORDS would be faster 'stosq'

	pop rdi
	pop rcx
	pop rax
ret

;******************************************************************************
;	str_cpy
;		- copies a string from one memory location to another, terminates at
;		  NULL (0).
;	param/		RSI = address pointer to source
;	param/		RDI = address pointer to destination
;******************************************************************************
str_cpy:
	push rax
	xor  eax, eax

.Loop1:
	mov al, BYTE [esi]
	mov [edi], al
	inc esi
	inc edi
	cmp byte al, 0				; check for NULL
	jne .Loop1

.Done:
	pop  rax
ret
