;*******************************************************************************
;	LIBRARY - GRAPHIC USER INTERFACE (GUI) FOR APPLICATIONS
;
; A library file with common GUI routines that would be used in applications.
;
; NOTE: Before using this library, the user program must meet the following
;		condition:
;		1. lib_app MUST be included BEFORE this library.
;		2. The program MUST execute the get_gui_mode routine before using any
;		   routine in this library. Global variables are populated in
;          get_gui_mode.
;
; Copyright (c) 2016-2020, David Borsato
; Created: Aug 26, 2019 by David Borsato
;*******************************************************************************


;*******************************************************************************
; Draws an empty box.
;
; IN:	 R8 = starting X (left)
;		 R9 = starting Y (top)
;		R10 = width
;		R11 = height
;		ECX = color
;*******************************************************************************
gui_draw_box:
cmp byte [GUI],0
jz .Return
	push rax
	push rbx
	push rcx
	push r8
	push r9
	push r10
	push r11
	push r12

	;	top
	mov rax, r8
	mov rbx, r9
	mov r8, r10 						; R8 is now length
	call gui_draw_horz_line

	;	left side
	mov r8, r11							; R8 is now height
	call gui_draw_vert_line

	;	bottom
	add rbx, r11 						; add height to get new Y
	mov r8, r10							; length
	call gui_draw_horz_line

	;	right side
	mov rbx, r9 						; restore original Y
	add rax, r10 						; add length to get new X
	dec rax
	mov r8, r11							; height
	call gui_draw_vert_line

	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rcx
	pop rbx
	pop rax
.Return:
ret


;*******************************************************************************
; Draws a filled box.
;
; IN:	 R8 = starting X (left)
;		 R9 = starting Y (top)
;		R10 = width
;		R11 = height
;		ECX = color
;*******************************************************************************
gui_draw_box_f:
cmp byte [GUI],0
jz .Return
	push rax
	push rbx
	push r8
	push r11

	mov rax, r8
	mov rbx, r9
	mov r8, r10
.Loop1:
	call gui_draw_horz_line
	inc rbx
	dec r11
	jg .Loop1

.Done:
	pop r11
	pop r8
	pop rbx
	pop rax
.Return:
ret


;*******************************************************************************
; Places a pixel on the screen
;
;	uint32 pixel_offset = y * pitch + (x * (bpp/8)) + framebuffer;
;
; IN:	 AX = X
;		 BX = Y
;		ECX = color using the format 0xRRGGBB
;*******************************************************************************
gui_draw_dot:
cmp byte [GUI],0
jz .Return
	push rax
	push rbx
	push rdx
	push rdi
	push r8

	and eax, 0xFFFF					; clean registers
	and ebx, 0xFFFF					;
	and r8,  0xFFFFFF 				;

	call gui_get_lin_addr					; linear address returned to RDI
	call gui_set_color

	pop r8
	pop rdi
	pop rdx
	pop rbx
	pop rax
.Return:
ret

;*******************************************************************************
; IN:	 AX = starting X
;		 BX = starting y
;		ECX = color
;		 R8 = length
;*******************************************************************************
gui_draw_horz_line:
cmp byte [GUI],0
jz .Return
	push rax
	push rbx
	push rcx
	push rdx
	push rdi
	push r8

	and eax, 0xFFFF					; clean registers
	and ebx, 0xFFFF					;
	xor rdx,rdx

	xchg rcx, r8
	call gui_get_lin_addr			; returns linear address to RDI
	xchg rcx, r8
	mov dl, byte [BytesPP]

	mov rax,rcx 					; RAX is now the color
	mov rcx,r8 						; RCX is now the line counter
	rep stosd 						; paint screen

.Done:
	pop r8
	pop rdi
	pop rdx
	pop rcx
	pop rbx
	pop rax
.Return:
ret

;*******************************************************************************
; Draws a line on the screen
;
;	==============================
;	= Bresenham's line algorithm =
;	==============================
;	Refercence link: https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
;	plotLine(x0,y0, x1,y1)
;	  dx = x1 - x0
;	  dy = y1 - y0
;	  D = 2*dy - dx
;	  y = y0
;
;	  for x from x0 to x1
;	    plot(x,y)
;	    if D > 0
;	       y = y + 1
;	       D = D - 2*dx
;       end if
;       D = D + 2*dy
;
; IN:	 R8 = X0
;		 R9 = Y0
;		R10 = X1
;		R11 = Y1
;		ECX = color
;*******************************************************************************
gui_draw_line:
cmp byte [GUI],0
jz .Return
	push rax						; x
	push rbx						; y
	push rcx						; color 0xRRGGBB
	push rdx
	push rdi
	push r8							; X0
	push r9							; Y0
	push r10						; X1
	push r11						; Y1
	push r12						; delta X (dx)
	push r13 						; delta Y (dy)
	push r14						; D
	push r15 						; used for calculations

	;
	;	Error checking
	;
	; * do some boundary checking (e.g. x is not greater than the screen size, etc.)
	cmp r8, 0
	jge .Good_low_x0
	mov r8, 0
.Good_low_x0:

	mov rax,r8
	cmp ax, word [GUI_X]
	jbe .Good_high_x0
	mov ax, word [GUI_X]
	mov r8, rax
.Good_high_x0:

	cmp r10, 0
	jge .Good_low_x1
	mov r10, 0
.Good_low_x1:

	mov rax,r10
	cmp ax, word [GUI_X]
	jbe .Good_high_x1
	mov ax, word [GUI_X]
	mov r10, rax
.Good_high_x1:

	cmp r9, 0
	jge .Good_low_y0
	mov r9, 0
.Good_low_y0:

	mov rax,r9
	cmp ax, word [GUI_Y]
	jbe .Good_high_y0
	mov ax, word [GUI_Y]
	mov r9, rax
.Good_high_y0:

	cmp r11, 0
	jge .Good_low_y1
	mov r11, 0
.Good_low_y1:

	mov rax,r11
	cmp ax, word [GUI_Y]
	jbe .Good_high_y1
	mov ax, word [GUI_Y]
	mov r11, rax
.Good_high_y1:

	mov r12, r10
	sub r12, r8						; dx = x1 - x0
	mov r13, r11
	sub r13, r9						; dy = y1 - y0

	; Check for optimzations; if it is a strait line side to side (Y is constent)
	; or up/down (X is constent) then we do not need to keep recalculating linear position
	; and can just use add/substract.
	cmp r13, 0
	jz  .Plot_horizontal_line
	cmp r12, 0
	jz  .Plot_vertical_line

	; Determine which direction the line is going; left/right, up/down
	cmp r12,0						; if dx is positive, the going right
	jg  .Going_right
	neg r8							; going LEFT
	neg r12
.Going_right:

	cmp r13,0						; if dy is positive, then going down
	jg  .Going_down
	neg r9							; going UP
	neg r13
.Going_down:

	; Calculate initial D value; D = 2*dy - dx
	mov rax, r13
	mov r15d, 2						; used for 2*dx/y calculations
	mul r15
	sub rax, r12 					; D = 2*dy - dx
	mov r14, rax 					; store D in r14, free up RAX


	; calculate 2*dx and 2*dy
	mov rax, r12
	mul r15
	mov r12,rax 					; 2*dx
	mov rax, r13
	mul r15
	mov r13, rax 					; 2*dy


	; set initial X,Y values
	mov rax,r8
	mov rbx,r9

.Plot_normal_line:
.For_loop:
	; Plot the absolute values of X/Y
	push rax
	push rbx
	cmp rax,0
	jge .Positive_x
	neg rax
.Positive_x:
	cmp rbx,0
	jge .Positive_y
	neg rbx
.Positive_y:
	call gui_draw_dot
	pop rbx
	pop rax

	cmp r14, 0						; if D > 0
	jle .End_if
		inc rbx
		sub r14, r12				; D = D - 2*dx
	.End_if:
	add r14, r13					; D = D + 2*dy
	inc rax

	; Check if absolute X = X1
	push rax
	cmp rax,0
	jge .PX
	neg rax
.PX:
	cmp rax, r10
	pop rax
	jne .For_loop
	jmp .Done

.Plot_horizontal_line:
	;	Always plot left (lowest X) to right (hightest X)
	;	First, set it so that x0 is lower then x1.

	cmp r8,r10 						; cmp x0,x1
	jb  .Skip_X_xchg
	xchg r8,r10
	mov r12, r10
	sub r12, r8						; dx = x1 - x0
.Skip_X_xchg:

	mov rax, r8						; set starting X
	mov rbx, r9						; set starting Y
	;mov r8, rcx						; set color
	;mov rcx, r12					; set length, dx
	mov r8, r12
	call gui_draw_horz_line
	jmp .Done


.Plot_vertical_line:
	cmp r9, r11
	jb  .Skip_Y_xchg
	xchg r9,r11
	mov r13, r11
	sub r13, r9						; dy = y1 - y0
.Skip_Y_xchg:

	mov rax, r8						; set starting X
	mov rbx, r9						; set starting Y
	;mov r8, rcx 					; set color
	mov r8, r13 					; set length, dy
	call gui_draw_vert_line

.Done:
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rdi
	pop rdx
	pop rcx
	pop rbx
	pop rax
.Return:
ret


;*******************************************************************************
; IN:	 AX = starting X
;		 BX = starting y
;		 R8 = length of line
;		ECX = color
;*******************************************************************************
gui_draw_vert_line:
cmp byte [GUI],0
jz .Return
	push rax
	push rbx
	push rcx
	push rdx
	push rdi

	and eax, 0xFFFF					; clean registers
	and ebx, 0xFFFF					;
	and r8,  0xFFFFFF 				;

	xchg rcx,r8

	call gui_get_lin_addr			; returns linear address to EDI
	.Loop1:
		push rcx
			mov ecx, r8d
			call gui_set_color				; paint color to screen
			xor ecx,ecx
			mov cx, word [YPITCH]
			add edi, ecx					; move to next X position
		pop rcx
		inc ax
	loop .Loop1

	pop rdi
	pop rdx
	pop rcx
	pop rbx
	pop rax
.Return:
ret


;*******************************************************************************
; Calculates and returns the linear address of a X/Y coordinate
;
; IN:	 AX = X
;		 BX = Y
; OUT:	RDI = linear address
;*******************************************************************************
gui_get_lin_addr:
cmp byte [GUI],0
jz .Return
	push rax
	push rbx
	push rdx

	and rax, 0xFFFF 					; clean up registers
	and rbx, 0xFFFF						;
	xor rdi, rdi 						;

	push rbx							; save Y position

	xor rbx,rbx							; calculate X
	mov bl, [BytesPP]
	mul ebx
	mov rdi, rax						; save result

	mov ax, word [YPITCH]				; calculate Y
	pop rbx								; retrieve Y
	mul rbx
	add rdi, rax 						; add to X co-ordinate
	add rdi, [VID_ADDR]					; linear address

	pop rdx
	pop rbx
	pop rax
.Return:
ret


;*******************************************************************************
; Sets the color of a pixel
;
; IN:	RCX = color
;		RDI = starting linear position
; OUT:	---
;*******************************************************************************
gui_set_color:
cmp byte [GUI],0
jz .Return
	push rcx
	push rdx
	push rdi

	cmp [BPP], word 24
	jne .Set_color32

.Set_color24:
	mov rdx, rcx 				; copy to RDX
	and ecx, 0xFFFF
	mov word [rdi], cx
	inc rdi
	inc rdi
	shr edx, 16
	mov byte [rdi], dl
	jmp .Done

.Set_color32:
	mov dword [rdi], ecx

.Done:
	pop rdi
	pop rdx
	pop rcx
.Return:
ret
