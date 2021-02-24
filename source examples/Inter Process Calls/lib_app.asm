;*******************************************************************************
;	LIBRARY - FOR APPLICATIONS
;
; A library file with common routines that would be used in applications.
;
; Copyright (c) 2016-2020, David Borsato
; Created: Nov 7, 2018 by David Borsato
;*******************************************************************************

FONT1.FULL.BLOCK 	equ 9608
TCP_SIG_HDR_Size	equ 32

;;
;; GLOBAL VARIABLES
;;
PAGE_SZ 		dq 0x1000 		; system page size (4K)

; GUI
BPP 			dw 0			; bits per pixel
BytesPP			dw 0			; bytes per pixel
CH_NUM 			dw 2			;
GUI				db 0			; GUI mode of system
GUI_X 			dw 0			; X res
GUI_Y 			dw 0 			; Y res
GUI_CH_W		dw 0			; char width
GUI_CH_H		dw 0			; char height
LINE_NO 		dw 0			; tracks what line number to print on
LINE_MAX_TXT	dw 21			; maximum lines in text mode (21 default)
LINE_MAX_GUI	dw 21			; maximum lines in gui mode (21 default)
YPITCH 			dw 0
VID_ADDR		dq 0			; base video memory address

; Network config
CID 			dq 0			; connection ID
PORT 			dw 0
RCV_BUFF		dq 0			; memory receive buffer
RCV_BUFF_SZ		dd 0 			; size of receive buffer (1,040,675)
RCV_BUFF_PTR	dd 0			; memory pointer into RCV_BUFF


;*******************************************************************************
;*                        E R R O R   H A N D L I N G
;*******************************************************************************
msgErrOpen			db 'ERROR: Could not open network port.',0
msgNoMem			db 'ERROR: Not enough memory!',0
msgNoMemNet			db 'ERROR: Not enough memory for send and receive buffers!',0

Error_no_memory_network:
	mov rsi,msgNoMemNet
	jmp Error_handler

Error_no_memory:
	mov rsi,msgNoMem
	jmp Error_handler

Error_open_port:
	mov rsi,msgErrOpen
	jmp Error_handler


; IN:	RSI = Error message
Error_handler:
	xor ax,ax 				; to X to 0
	inc word [LINE_NO]
	call print_ln

Exit:
	mov rdx,0x0				; stop process
	int 0xFF


;*******************************************************************************
;*                          P R O C E D U R E S
;*******************************************************************************

;*******************************************************************************
; Allocates memory from system.
; IN:	RAX:	memory size, in bytes, to allocate
; OUT:	 BL:	return code; 0=success, anything else is an error
;		RAX:	memory address of memory allocated
;*******************************************************************************
alloc:
	push rdx
	mov rdx,0x221
	int 0xFF
	pop rdx
	cmp bl,0
	jnz Error_no_memory_network
ret

clrscr:
clr_scr:
clear_screen:
	push rcx
	push rdx
	push r8
	push r9
	push r10
	push r11

	mov word [LINE_NO],0x0		; reset line number

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
	mov r9,0
	mov r10w,[GUI_X]
	mov r11w,[GUI_Y]
	mov ecx, 0x0				; black
	mov rdx, 0x126				; draw full box
	int 0xFF

	pop r11
	pop r10
	pop r9
	pop r8
	pop rdx
	pop rcx
ret


;******************************************************************************
; Clears one character on the screen. NOTE: This only works in GUI mode.
; IN:	AL = X
;		AH = Y
;******************************************************************************
clear_screen_ch:
cmp byte [GUI],0
jz .Return

;;
;; NOTE: rework this routine to use CH_W & CH_H instead, then draw a small box.
;;
	push rdx
	mov ecx,0x000000 		; black
	mov rdx,0x402
	int 0xFF
	pop rdx
.Return:
ret
.char 		dw 9608,0


;******************************************************************************
; Copies physical memory from one location to another. Leaves RDI and RSI intact.
; IN:	RSI = source location
;		RDI = destination location
; 		RAX = number of bytes to copy
; OUT:	RSI & RDI updated with number of bytes.
;******************************************************************************
cpymem:
cpy_mem:
	push rax
	push rcx
	push rdx

	mov rcx,8
	xor rdx,rdx
	div rcx
	mov rcx,rax
	cld
	rep movsq
	mov rcx,rdx
	rep movsb

	pop rdx
	pop rcx
	pop rax
ret


;******************************************************************************
; Deallocates memory.
; IN:	RAX = memory location
; 		RCX = number of bytes to deallocate
; OUT:	---
;******************************************************************************
dalloc:
	push rdx
	mov rdx,0x222
	int 0xFF
	pop rdx
ret


;******************************************************************************
; Returns the PID of the currently running program.
; IN:	---
; OUT:	 AX = PID
;******************************************************************************
get_curr_pid:
	push rdx
	xor rax,rax
	mov rdx, 0x200
	pop rdx
ret


;******************************************************************************
; Checks if system is in GUI mode or not. If in GUI mode then initializes
; environment and variables.
;
; IN:	---
; OUT:	GUI; 0=text mode, 1=graphic mode (aka GUI)
;			 ::  If GUI is enabled, then ::
;		GUI_X; 		X resolution of screen
;		GUI_Y; 		Y resolution of screen
;		GUI_CH_W;	width of a character
;		GUI_CH_H;	height of a character
;******************************************************************************
get_gui_mode:
	push rax
	push rdx

	mov rdx,0x10D
	int 0xFF
	mov byte [GUI], al

; If GUI is enabled then get; screen resolution, character sizes, max. lines,
; bits per pixel, bytes per pixel.
	cmp al,0
	jz .Done
		push rbx
		push r10

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

			xor eax,eax
			mov rdx, 0x106 				; get bits per pixel, returns to AX
			int 0xFF
			mov word [BPP], ax

			mov ebx,8					; get bytes per pixel
			xor edx,edx
			div bx
			mov word [BytesPP],ax

			mov edx, 0x102				; get YPITCH
			int 0xFF
			mov word [YPITCH], ax

			; Calc max. printed lines on screen
			mov ax,[GUI_Y]
			mov bx,[GUI_CH_H]
			sub ax,bx
			sub ax,bx
			xor rdx,rdx
			div bx
			mov [LINE_MAX_GUI],ax

			mov edx,0x10F 				; get base video address
			int 0xFF
			mov [VID_ADDR],rax
		pop r10
		pop rbx

.Done:
	pop rdx
	pop rax
ret


;******************************************************************************
; Converts X coordinate into a GUI X coordinate.
; IN:	AL = X coordinate
;		GUI_CH_W
; OUT:	AX = X coordinate
;******************************************************************************
get_gui_x:
	push rbx
	push rdx
	xor rdx,rdx
	xor rbx,rbx
	and ax,0x00FF 			; isolate X coordinate
	mov bx,[GUI_CH_W]
	mul bx
	pop rdx
	pop rbx
ret


;******************************************************************************
; Converts Y coordinate into a GUI Y coordinate.
; IN:	BL = Y coordinate
;		GUI_CH_H
; OUT:	BX = Y coordinate
;******************************************************************************
get_gui_y:
	push rax
	xor rax,rax
	xor rdx,rdx
	mov ax,[GUI_CH_H]
	mul bx
	mov bx,ax					; return Y
	pop rax
ret


;******************************************************************************
; Returns a PID for a specified program name
; IN:	RSI = program name
; OUT:	 BX = PID
;******************************************************************************
get_pid:
	push rdx
	mov rdx,0x403
	int 0xFF
	pop rdx
ret

;******************************************************************************
; Returns current tick counter.
; IN:	---
; OUT:	RAX = tick counter
;******************************************************************************
get_tick_ctr:
	push rdx
	mov rdx,0xE
	int 0xFF
	pop rdx
ret

;******************************************************************************
; Returns millisecond and sub-millisecond time since the system has been up.
; IN:	---
; OUT:	RAX = ms (upper QWORD), sub ms (lower QWORD)
;******************************************************************************
get_time_exact:
	push rbx
	push rdx
	mov rdx,0xC
	int 0xFF
	shl rax,32
	or rax,rbx
	pop rdx
	pop rbx
ret

;******************************************************************************
; Returns the current value of the processor’s time-stamp counter. The counter
; is cycles, not time!!
; IN:	---
; OUT:	RAX = cycles
;******************************************************************************
get_rdt_cycle:
	push rdx
	xor eax, eax
	cpuid
	xor eax, eax
	cpuid
	xor eax, eax
	cpuid
	rdtsc
	shl rdx,32
	or rax,rdx
	pop rdx
ret


;******************************************************************************
;	Initialize GUI environment.
;******************************************************************************
gui_init:
	jmp get_gui_mode


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


;******************************************************************************
; Converts a 4 bytes hex number to an IP address string.
; NOTES:
;		* This does not do any error checking, that is up to the programmer.
;		* This will increment RDI.
; IN:	EAX = hex number
; 		RDI = memory location of string
;******************************************************************************
hexToIPString:
	push rax
	push rbx
	;
	xor rbx,rbx
	mov bl, al	 	; fourth octet
	call intToString_incr_rbx
	mov byte [rdi], '.'
	inc rdi
	shr rax,8

	mov bl, al		; third octet
	call intToString_incr_rbx
	mov byte [rdi], '.'
	inc rdi
	shr rax,8

	mov bl, al		; second octet
	call intToString_incr_rbx
	mov byte [rdi], '.'
	inc rdi
	shr rax,8

	mov bl, al		; first octet
	call intToString_incr_rbx

	pop rbx
	pop rax
ret

;	Same as hexToIPString but uses EBX instead
hexToIPString_ebx:
	push rax
	mov eax,ebx
	call hexToIPString
	pop rax
ret


;	Calls the function below, but allows the programmer to use EBX as
;	the parameter instead of EAX.
;	IN:	EBX = hex number
;		EDI = address pointer to put string
hexToString_ebx:
	push rax
	mov rax, rbx
	call hexToString
	pop rax
ret

;******************************************************************************
;	hexToString
;		- converts a hex number to string so that you can print it to the
;		  screen.
;	param/		RAX = hex number
;	param/		RDI = address pointer to put string
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


inc_line:
	push rax

	inc word [LINE_NO]

; Check if at end of the screen
	cmp byte [GUI],0
	jnz .GUI
		mov ax,[LINE_MAX_TXT]
		jmp .Chk_line
	.GUI:
		mov ax,[LINE_MAX_GUI]
	.Chk_line:

	cmp word [LINE_NO],ax
	ja .Reset

.Done:
	pop rax
ret
.Reset:
	mov word [LINE_NO],0
	call clear_screen
	jmp .Done

init_line:
	call inc_line
	mov ax,[LINE_NO]
	shl ax,8
ret

;******************************************************************************
; Initialize environment.
;******************************************************************************
initialize:
	call get_gui_mode
ret


;******************************************************************************
;	IntToHex
;		- converts a decimal number to a hex number
;	IN:		RBX = original decimal number
;	OUT:	RBX = converted hex number
;******************************************************************************
IntToHex:
	push rax 				; working digit
	push rcx 				; multiplier
	push rdx
	push r8 				; running number

	xor rax, rax
	xor rdx, rdx
	mov rax, rbx
	mov rcx, 0xA

	and rax, 0xF 			; first digit is easy
	mov r8, rax 			; save running number
	shr rbx, 4				; strip off 1st digit

.Loop1:
	cmp rbx, 0
	jz .Done
	mov rax, rbx
	and rax, 0xF 			; strip off last digit
	mul rcx
	add rax, r8				; add to running total
	mov r8, rax 			; store in memory

	mov rax, rcx
	mov rcx, 0xA
	mul rcx
	mov rcx, rax 			; update multiplier

	xor rax, rax
	xor rdx, rdx
	shr rbx, 4
	jmp .Loop1

.Done:
	mov rbx, r8				; move results back to EBX

	pop r8
	pop rdx
	pop rcx
	pop rax
ret
; Uses RCX as the parameter for intToHex.
;	IN:		RCX = original decimal number
;	OUT:	RCX = converted hex number
IntToHex_rcx:
	push rbx
	mov rbx,rcx
	call IntToHex
	mov rcx,rbx
	pop rbx
ret



;	This is call lets the user use EBX instead of EAX
;	IN:	RBX = number to convert
;	OUT:	---   this version does not return anything, not wasting EAX
intToString_ebx:
intToString_rbx:
	push rax
	mov rax, rbx
	call intToString
	pop rax
ret
;******************************************************************************
;	intToString
;		- converts an integer to a string, adds a NULL terminator (0) at the end.
;	param/		RAX = number to convert
;	param/		RDI = pointer location of buffer to put string
;	returns/	RAX = number of bytes written
;******************************************************************************
intToString:
	push rax
	push rbx
	push rcx
	push rdx
	push rdi
	push rbp

	mov rbp, rsp
	mov rcx, 10

.pushDigits:
	xor rdx, rdx		; zero extend eax
	div rcx				; divide RAX by 10, RDX is now the next digit
	add rdx, 0x30		; convert to ASCII digit
	push rdx 			; push back onto stack and store it to be popped off
	test rax, rax 		; remove leading zeros
	jnz .pushDigits

.popDigits:
	pop rax
	stosb				; only write the lower byte, not the whole word
	cmp rsp, rbp		; if RSP==RBP, all digits popped
	jne .popDigits

	xor rax, rax 		; add trailing NULL
	stosb

	mov rax, rdi

	pop rbp
	pop rdi
	pop rdx
	pop rcx
	pop rbx
	;pop rax
	add rsp,8			; pop off original value of RAX
	sub rax, rdi 		; return number of bytes written
ret


; Same as intToString_incr below except it uses RBX instead of RAX
;	param/		RBX = number to convert
;	param/		RDI = pointer location of buffer to put string
;	returns/	RBX = number of bytes written
intToString_incr_rbx:
	push rax
	mov rax,rbx
	call intToString_incr
	pop rax
ret
;******************************************************************************
;	intToString_incr
;		- Converts an integer to a string, adds a NULL terminator (0) at the end.
;		  Does not reset RDI back to starting position, leaves it where it is.
;	param/		RAX = number to convert
;	param/		RDI = pointer location of buffer to put string
;	returns/	RAX = number of bytes written
;******************************************************************************
intToString_incr:
	push rbx
	push rcx
	push rdx
	push rbp

	push rdi 			; save starting point to stack

	mov ebp, esp
	mov ecx, 10

.pushDigits:
	xor edx, edx		; zero extend eax
	div ecx				; divide EAX by 10, EDX is now the next digit
	add edx, 30h		; convert to ASCII digit
	push rdx 			; push back onto stack and store it to be popped off
	test eax, eax 		; remove leading zeros
	jnz .pushDigits

.popDigits:
	pop rax
	stosb				; only write the lower byte, not the whole word
	cmp esp, ebp		; if ESP==EBP, all digits popped
	jne .popDigits

	mov byte [rdi], 0	; add trailing NULL

	mov rax, rdi
	pop rbx 			; pop original starting point
	sub rax, rbx 		; calculate and return number of bytes written

	pop rbp
	pop rdx
	pop rcx
	pop rbx
ret


;*******************************************************************************
; Get IP addresses, NICs 1 to 4.
; IN:	---
; OUT:	RAX = NIC1
;		RBX = NIC2
;		RCX = NIC3
;		RDX = NIC4
;*******************************************************************************
net_get_ip:
	push rdx
	xor rax,rax 		; initialize reg's
	xor rbx,rbx 		;
	xor rcx,rcx 		;
	xor rdx,rdx 		;
	mov rdx,0x1A		; get IP's
	int 0xFF
	pop rdx
ret

;*******************************************************************************
; Initializes memory to zeros.
; IN:	RAX = memory start
;		RCX = size, in bytes
;*******************************************************************************
null_ram:
	push rax
	push rbx
	push rcx
	push rdx
	push rdi
	push r8 			; memory start

	mov r8,rax			; free up RAX

	mov rax,rcx
	mov rbx,8
	xor rdx,rdx
	div rbx
	mov rcx,rax
	mov rdi, r8
	xor rax,rax
	cld
	rep stosq 			; NULL QWORDS
	mov rcx,rdx
	rep stosb			; NULL remaining bytes

	pop r8
	pop rdi
	pop rdx
	pop rcx
	pop rbx
	pop rax
ret


;******************************************************************************
; Text mode or GUI mode print to X,Y location.
;
; This is the same as print_cli, except you can specify X,Y co-ordinates. In
; GUI mode; X will use character width * X and Y will use character height *
; Y.
; NOTE: This routine will not clear the screen. Programmer needs to figure out
;       when to do that.
;
; IN:	 AL = X
;		 AH = Y
;		RSI = pointer to string location
;******************************************************************************
print_cli_xy:
	push rdx
	mov rdx,0x400
	int 0xFF
	pop rdx
ret


;******************************************************************************
; Sames as print_cli_xy, except you can specify a color if in GUI mode.
; IN:	 AL = X
;		 AH = y
;		RSI = pointer to string location
;******************************************************************************
print_cli_xy_clr:
	push rdx
	mov rdx,0x402
	int 0xFF
	pop rdx
ret

;******************************************************************************
; Same as print_cli_xy, except you specify number of characters to print.
; And the width (x coordinate).
; NOTE, this routine does not check if you are at the end of the screen.
; Or any other error checking, up to the programmer.
;
; IN:	 AL = X
;		 AH = Y
;		 BX = width
;		 CX = number of characters to print
;		RSI = pointer to string location
; OUT:	RAX = x/y coordinates
;******************************************************************************
print_cli_xy_cw:
	push rdx
	mov rdx,0x401
	int 0xFF
	pop rdx
ret


; Prints a NULL terminated string to the screen. This is the same as a console
; mode print routine. It will start at the beginning of the line and print
; the text.
;
; IN:	LINE_NO = Y coordinate
;		RSI = String to print
print_ln:
	cmp byte [GUI],0
	jnz Print_gui

	push rax
	xor ax,ax

	inc word [LINE_NO]

	cmp word [LINE_NO],21
	jb .End_clr_screen
		call clear_screen
	.End_clr_screen:
	push rbx
	mov bx,[LINE_NO]
	mov ah,bl
	pop rbx
	call Print_txt

	pop rax
ret

; Prints a NULL terminated string in GUI mode
; IN:	LINE_NO = Y coordinate
;		RSI = null temrinated string
Print_gui:
	push rax
	push rbx
	push rcx
	push rdx

	; Check if end of screen
	cmp word [LINE_NO],21
	jb .Skip_clr_scr
		call clear_screen
	.Skip_clr_scr:


;	Parameters:	RDX = 0x121
;			AX = X coordinate
;			BX = Y coordinate
;			ECX = color
;			RSI = memory location of NULL terminated string
	mov ax,5
	call .Get_line_no			; returns to BX
	mov ecx, 0x00FF00
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


; Prints a NULL terminated string in text mode
; IN:	 AL = X coordinate
;		 AH = Y coordinate
;		RSI = null terminated string
Print_txt:
	push rdx
	mov rdx,0x305				; print string
	int 0xFF
	pop rdx
ret


;******************************************************************************
; Relase memory from current user program. This does not give memory back to
; the OS. It only deletes the entry(s) in the Page Tables.
; IN:	RAX = memory location
;		RCX = size in bytes to release
;******************************************************************************
relmem:
	push rdx
	mov rdx,0x223
	int 0xFF
	pop rdx
ret


;******************************************************************************
;	str_chomp
;		- removes leading and trailing spaces
;	param/		RAX = address pointer to string
;******************************************************************************
str_chomp:
	push rax
	push rcx
	push rdx
	push rdi
	push rsi

	mov rdx, rax				; save string location

	mov rdi, rax				; put location into RDI
	mov rcx, 0					; space counter

.Count:							; get number of leading spaces
	cmp byte [rdi], ' '
	jne .Counted
	inc rcx
	inc rdi
	jmp .Count

.Counted:
	cmp rcx, 0					; if no leading spaces
	je  .Finished_copy

	mov rsi, rdi 				; address of first non-space
	mov rdi, rdx 				; reset to original start of string

.Copy_string:
	mov al, [rsi]				; copy to ESI to DSI
	mov [rdi], al				; includes terminator
	cmp al, 0
	je  .Finished_copy

	inc rsi
	inc rdi
	jmp .Copy_string

.Finished_copy:
	mov rax, rdx 				; EAX = original string start
	call str_len
	cmp ax, 0					; if string empty, then exit
	je  .Done

	mov rsi, rdx
	add rsi, rax 				; move to end of string

.More:
	dec rsi
	cmp byte [rsi], ' '
	jne .Done
	mov byte [rsi], 0			; fill end spaces with NULL
	jmp .More					; first Zero is the string terminator

.Done:
	pop rsi
	pop rdi
	pop rdx
	pop rcx
	pop rax
 ret


 ;******************************************************************************
 ;	str_cmp
 ;		- compares two zero terminated strings, if they are the same;
 ;		  returns 0 othrwise, return 1.
 ;	param/		RSI = pointer to source string
 ;	param/		RDI = pointer to destination string
 ;	returns/	 AL = 0 strings are the same, 1 strings are different
 ;******************************************************************************
str_cmp:
 	push rbx
 	push rdi
 	push rsi

 .Loop1:
 	mov al, BYTE [rsi]
 	mov bl, BYTE [rdi]

 	cmp al, 0					; end of string
 	je  .Done

	cmp al, bl
 	jne .Not_the_same

 	inc rsi
 	inc rdi
 	jmp .Loop1

 .Not_the_same:
 	mov al, 1					; return code for strings are different
	jmp .Exit

 .Done:
 	xor al,al					; return code for strings are equal
.Exit:
 	pop rsi
 	pop rdi
 	pop rbx
 ret


;******************************************************************************
;	str_cmp_ctr
;		- compares two strings for a specified number of characters, if they are
;		  the same; returns 0 othrwise, return 1.
;	param/		RSI = pointer to source string
;	param/		RDI = pointer to destination string
;	param/		ECX = number of characters to check
;	returns/	EAX = 0 strings are the same, 1 strings are different
;******************************************************************************
str_cmp_ctr:
 	push rbx
 	push rcx
 	push rdi
 	push rsi

.Loop1:
 	mov al, BYTE [rsi]
 	mov bl, BYTE [rdi]

 	cmp al, bl
 	jne .Not_the_same

 	inc rsi
 	inc rdi
 	loop .Loop1

 	mov eax, 0					; return match found code
 	jmp .Done

 .Not_the_same:
 	mov eax, 1					; return NO match found code

 .Done:
 	pop rsi
 	pop rdi
 	pop rcx
 	pop rbx
 ret


;******************************************************************************
;	str_cmp_nocase
;		- Same as str_cmp, except this is case insensitive. It will compare
;		  two strings, if they are the same, regardless of upper or lower case
;		  letters. The Source string (RSI) MUST be zero terminated. The
;		  destination string (RDI) doesn't matter if terminated or not.
;		  returns 0 othrwise, return 1.
;	param/		RSI = pointer to source string
;	param/		RDI = pointer to destination string
;	returns/	 AL = 0 strings are the same, 1 strings are different
;******************************************************************************
str_cmp_nocase:
    push rbx
    push rdi
    push rsi

 .Loop1:
    mov al, BYTE [rdi]
	call str_upper_ch
	mov bl,al
	mov al, BYTE [rsi]
	call str_upper_ch

    cmp al, 0					; end of string
    je  .Done

    cmp al, bl
    jne .Not_the_same

    inc rsi
    inc rdi
    jmp .Loop1

 .Not_the_same:
    mov al, 1					; return code for strings are different
    jmp .Exit

 .Done:
    xor al,al					; return code for strings are equal
 .Exit:
    pop rsi
    pop rdi
    pop rbx
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


;******************************************************************************
; Basically the same as str_cpy except will terminate on either NULL or a
; linefeed (0xA).
;
; IN:	RSI = address pointer to source
; 		RDI = address pointer to destination
;******************************************************************************
str_cpy_line:
	push rax
	xor  rax, rax

.Loop1:
	lodsb 						; load AL, inc RSI
	stosb 						; store to RDI, inc RDI
	cmp byte al, 0xA 			; check for linefeed
	je  .Done
	cmp byte al, 0				; check for NULL
	jne .Loop1

.Done:
	pop  rax
ret


;******************************************************************************
; Find a phrase within a string for a specified number of character.
; IN:	RSI = memory pointer to NULL terminated source string
;		RAX = NULL temrinated string to find
;		RCX = number of characters to search
; OUT:	RAX = location of found string. Zero if not found.
;******************************************************************************
str_fnd_ctr:


ret

;******************************************************************************
; Find and Replace.
; Looks for characters in a string and replaces them with
; another set of characters. NOTE: the string must be large enough if the
; characters to replace with is larger then the characters replaced. That is,
; RBX > RAX.
;
; IN:	RSI = memory pointer to NULL terminated source string
;		RAX = NULL temrinated string to find
;		RBX = NULL terminated string to replace with
; OUT:	RSI = modified NULL terminated string
;		RAX = -1 if there was no memory for result
;******************************************************************************
str_fnd_n_rpl:
	push rbx		; pointer to original string
	push rcx		; pointer to result string
	push rdx
	push rdi
	push rsi
	push r8			; string to find
	push r9			; string to replace with
	push r10 		; Result: location of temp mem
	push r11 		; size of temp mem
	push r12 		; original string

	push rax

	; free up registers
	mov r8,rax
	mov r9,rbx
	mov r12,rsi

; Calculate how much memory to allocate for result.
	xor r11,r11
	mov rax,r8
	call str_len
	mov rcx,rax
	mov rax,r9
	call str_len
	cmp rax,rcx
	jbe .Allocate_mem	; if replace string is smaller or same size, allocate mem
	; if larger, then get the difference
	sub rax,rcx
	mov r11,rax

; Allocate temp memory to store result
.Allocate_mem:
	mov rax,rsi
	call str_len
	add r11,rax 		; save size
	mov rdx,0x221
	int 0xFF
	cmp bl,0
	jnz .Err1
	mov r10,rax			; save temp mem location

; Find and Replace
	mov rbx,rsi			; pointer original string
	mov rcx,r10			; pointer result string
	mov rdi,r8			; string to find

	.Search:
	; RDI = string to find
	; RSI = original string
		mov al,[rdi]
		cmp al,0		; check if end of string to find
		jz .Found		; if so, a match was found
		cmp byte [rsi],0; check if end of original string
		je .End
		cmp al,[rsi]	; compare string to find with original string
		jne .No_match
		inc rsi
		inc rdi
		jmp .Search

	.Found:
		; If match found, replace it in temp mem
		mov rbx,rsi 	; save pointer to original string
		dec rbx
		mov rsi,r9		; string to replace with

	.Replace:
		lodsb
		cmp al,0
		je .Next
		mov [rcx],al
		inc rcx
		jmp .Replace

	.No_match:
		mov rsi,rbx 	; current location of original
		mov rdi,rcx 	; current location of result
		lodsb
		stosb
		inc rcx 		; move result pointer

	.Next:
		mov rdi,r8
		inc rbx 		; move pointer to original
		mov rsi,rbx
		cmp byte [rsi],0
		jne .Search

	.End:
		mov byte [rcx],0

; Copy result back to original string.
	mov rsi,r10			; result string
	mov rdi,r12			; oritinal string
	.Loop_copy:
		lodsb
		stosb
		cmp al,0
	jnz .Loop_copy


.Deallocate_mem:
	mov rax,r10
	mov rcx,r11
	mov rdx,0x222
	int 0xFF

	pop rax

.Done:
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rsi
	pop rdi
	pop rdx
	pop rcx
	pop rbx
ret
.Err1:
	pop rax
	mov rax,-1
	jmp .Done


;******************************************************************************
;	str_len
;		- determines the length of a string
;	param/		RAX = address pointer to string
;	returns/	RAX = length
;******************************************************************************
str_len:
	push rbx
	push rcx

	mov rbx, rax
	mov rcx, 0					; initialize counter

.Continue:
	cmp byte [rbx], 0			; end of string check
	je  .Done
	inc rbx
	inc rcx
	jmp .Continue

.Done:
	mov rax, rcx

	pop rcx
	pop rbx
ret


;******************************************************************************
; Splits a string into 2 based on a specified character. The routine will
; search for the first instance of the specified character. It will then
; return the source memory pointer as well as a second pointer of the same string.
; It will terminate the strings and remove leading zeros.
;
; IN:	RSI = source string
;		 BL = character to split on
; OUT:	RSI = memory location for first string; zero terminated, tailing spaces removed
;		RDI = memory location for second string; zero terminated, leading/trailing spaces removed.
;		      If match unsucessful, RDI=0.
;******************************************************************************
str_split:
	push rax
	push rsi 						; save starting location
	xor rdi,rdi

.Loop1:
	cmp [rsi], byte 0x0				; if reached the end, then exit
	jz  .End_of_string

	cmp bl, byte [rsi]
	jne .No_match
	jmp .Match_found

.No_match:
	inc rsi
	jmp .Loop1

.Match_found:
	mov rdi, rsi 					; set starting point for second string
	inc rdi 						;

	;	remove trailing spaces and set NULL terminator
	mov [rsi], byte 0x0 			; replace split char with NULL
	mov rax, rsi
	call str_chomp 					; remove any trailing spaces

	;push rsi 						; save string 1 starting position for now, RSI used in next call
	mov rax, rdi
	;mov rsi, rdi
	call str_chomp
	mov rdi, rax
	;mov rdi, rsi

	;pop rsi
	jmp .Done

.End_of_string:
	xor rdi,rdi 				; return zero, not found

.Done:
	pop rsi 					; restore starting location
	pop rax
ret


;******************************************************************************
; Same idea as str_split except instead of looking for the character to split
; on from left to right, this routine goes in the opposite direction; right
; to left.
;
; IN:	RSI = source string
;		 BL = character to split on
; OUT:	RSI = memory location for first string; zero terminated, tailing spaces removed
;		RDI = memory location for second string; zero terminated, leading/trailing spaces removed.
;		      If match unsucessful, RDI=0.
;******************************************************************************
str_split_r:
	push rax
	push rcx
	push rsi

	mov rax,rsi 				; get length of string
	call str_len
	cmp rax,0
	jz .No_match 				; no string to check, exit with RDI=0

	mov rcx,rax
.Loop1:
	cmp bl, [rsi+rcx]
	je .Match
	loop .Loop1

; Becuase RCX=0 is not checked in loop above, drops out before that, we
; need to do one more check.
	cmp bl, [rsi]
	je .Match

.No_match:
	xor rdi,rdi
	jmp .Done

.Match:
	mov byte [rsi+rcx], 0x00	; replace seperator with NULL
	inc rcx
	add rcx, rsi
	mov rdi, rcx
	mov rax, rsi
	call str_chomp 				; remove leading and trailing spaces
	mov rax, rdi
	call str_chomp

.Match_at_char0:


.Done:
	pop rsi
	pop rcx
	pop rax
ret


;******************************************************************************
;	str_upper_ch
; 		- Converts a character to upper case
;
; 	IN:		AL = character to convert
; 	OUT:	AL = return character, unchaged if not in a-z range
;******************************************************************************
str_upper_ch:
   ;	Check if character is in the range of a-z. If not, then return
   ;	character unchanged.
   cmp al, 'a'
   jb .Done
   cmp al, 'z'
   ja .Done
   sub al, 0x20
.Done:
ret


;******************************************************************************
; Clear TCP signalling header
; IN:	RCV_BUFF
; OUT:	---
;******************************************************************************
tcp_clear_sig:
;	push rax
;	push rcx
;	push rdx
	push rdi

;	mov rax,TCP_SIG_HDR_Size
;	mov rcx,8
;	xor rdx,rdx
;	div ecx
;	mov ecx,eax

	; Clear signalling bytes in NET_BUFF
;	xor rax,rax
	mov rdi,[RCV_BUFF]
;	cld
;	rep stosq

	mov word [rdi],0

	pop rdi
;	pop rdx
;	pop rcx
;	pop rax
ret


;******************************************************************************
; Closes a TCP connection.
; IN:	RCX = connection ID
; OUT:	RAX = network module response code
;******************************************************************************
tcp_close:
	push rdx
	mov rdx,0x27
	int 0xFF
	pop rdx
ret

;******************************************************************************
; Closes a TCP connection, does not wait for a response.
; IN:	RCX = connection ID
; OUT:	RAX = network module response code
;******************************************************************************
tcp_close_nw:
	push rdx
	mov rdx,0x26
	int 0xFF
	pop rdx
ret

;******************************************************************************
; Closes a TCP connection using STP.
; IN:	RCX = connection ID
; OUT:	RAX = return code
;******************************************************************************
tcp_close_stp:
	push rdx
	push rsi

	xor rax,rax					; set 0 bytes to send, this will flag to do a close only
	xor rsi,rsi
	push rbx
		; set close flag
		mov rbx,1
		shl rbx,32
		or rax,rbx
	pop rbx

	mov rdx, 0x2F				; Send TCP data
	int 0xFF

	pop rsi
	pop rdx
ret

;******************************************************************************
; Opens a TCP listener port using common variables
; IN:	PORT
;		RCV_BUFF
;		RCV_BUFF_SZ
; OUT:	RAX = return code; 0=success, refer to NET_RTN_ codes
;		[CID] = connection ID
;		RCX   = connection ID
;******************************************************************************
tcp_listener:
	push rdx
	push rdi

	movzx rax, word [PORT]
	mov ecx,[RCV_BUFF_SZ]
;	mov rdi,[RCV_BUFF]				; not used anymore
	mov rdx,0x30
	int 0xFF
	cmp rax,0
	jnz .Done
	mov [CID],rcx
.Done:
	pop rdi
	pop rdx

	cmp rax,0
	jnz Error_open_port
ret


;******************************************************************************
; TCP Send. Sends data through and existing connection.
; IN:	RCX = connection ID
;		EAX = send buffer size
;		RSI = virtual address of send buffer
; OUT:	RAX = return code
;******************************************************************************
tcp_send:
	push rdx
	mov rdx, 0x28				; Send TCP data
	int 0xFF
	pop rdx
ret

;******************************************************************************
; TCP Send. Sends data through an existing connection.
; IN:	RCX = connection ID
;		EAX = send buffer size
;		RSI = virtual address of send buffer
; OUT:	RAX = return code
;******************************************************************************
tcp_sendq:
	push rdx
	mov rdx, 0x2B				; Send TCP data
	int 0xFF
	pop rdx
ret

;******************************************************************************
; TCP Send using the Send TCP Packet program. This spawns a new user program
; so that the current program doesn't have to wait for a response.
; Sends data through and existing connection.
; IN:	RCX = connection ID
;		EAX = send buffer size & flags
;		RSI = virtual address of send buffer
; OUT:	RAX = return code
;******************************************************************************
tcp_send_stp:
	push rdx
	mov rdx, 0x2F				; Send TCP data
	int 0xFF
	pop rdx
ret

; This is the same as tcp_send_stp except it signals STP to close the
; conection when the send is completed.
tcp_send_stp_c:
	push rax
	push rdx

	push rbx
		mov rbx,1
		shl rbx,32
		or rax,rbx
	pop rbx

	mov rdx, 0x2F				; Send TCP data
	int 0xFF
	pop rdx
	pop rax
ret

;******************************************************************************
; Returns number of seconds the system has been running.
; IN:	---
; OUT:	RAX = seconds
;******************************************************************************
uptime_s:
uptime_seconds:
	push rbx
	push rdx

	mov rdx,0x0D
	int 0xFF
	mov rbx,1000
	xor rdx,rdx
	div rbx

	pop rdx
	pop rbx
ret

;******************************************************************************
; Waits for a period of time. This routine will not sit in a busy wait and
; will switch to another process until the time period expires.
; IN:	RCX = how long to wait, in milliseconds (i.e. 1000 = 1 sec)
; OUT:	---
;******************************************************************************
waitms:
	push rax
	push rcx
	push rdx

	; Get current ms
	mov rdx,0xD
	int 0xFF
;	mov rcx,rax
	add rcx,rax
	wait_loop:
		mov edx, 0xF
		int 0xFF
		mov rdx, 0xD
		int 0xFF
		cmp rax,rcx
	jbe wait_loop

	pop rdx
	pop rcx
	pop rax
ret

; Locks process
xl:
	push rax
	push rdx

	mov ax,1
	mov rdx,0xFFFF
	int 0xFF

	pop rdx
	pop rax
ret

; Unlocks process
xul:
	push rax
	push rdx

	mov ax,0
	mov rdx,0xFFFF
	int 0xFF

	pop rdx
	pop rax
ret
