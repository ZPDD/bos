;*******************************************************************************
; SHA256 TEST
;
;   A sample program to test the SHA256 library.
;
; Copyright (c) 2016-2022 David Borsato
; Created: Feb 27, 2021 by David Borsato
;*******************************************************************************
org 0x70000000
bits 64
jmp ENTRY
nop
nop


;*******************************************************************************
;*  PROGRAM DATA
;*******************************************************************************

; All tests use the following format:
; <Title> - use any string you like as the title
; <to-hash> - string or value to be hash, NULL terminated.
; <hash-answer> - a 32 byte (8 DWORDS) hashed value to compare what comes out of sha256
TESTS:
test_1_t    db 'Test NULL string',0
test_1_s    db '',0
test_1_a    dd 0xE3B0C442, 0x98FC1C14, 0x9AFBF4C8, 0x996FB924
            dd 0x27AE41E4, 0x649B934C, 0xA495991B, 0x7852B855

test_2_t    db 'Test abc',0
test_2_s    db 'abc',0
test_2_a    dd 0xba7816bf, 0x8f01cfea, 0x414140de, 0x5dae2223
            dd 0xb00361a3, 0x96177a9c, 0xb410ff61, 0xf20015ad

test_3_t    db 'Test 3',0
test_3_s    db 'test',0
test_3_a    dd 0x9F86D081, 0x884C7D65, 0x9A2FEAA0, 0xC55AD015
            dd 0xA3BF4F1B, 0x2B0B822C, 0xD15D6C15, 0xB0F00A08

test_4_t    db 'Test 4',0
test_4_s    db 'TEST',0
test_4_a    dd 0x94EE0593, 0x35E587E5, 0x01CC4BF9, 0x0613E081
            dd 0x4F00A7B0, 0x8BC7C648, 0xFD865A2A, 0xF6A22CC2

test_5_t    db 'Test 5',0
test_5_s    db '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abc',0
test_5_a    dd 0x3403cffb, 0xc10d2f96, 0x2e5e917a, 0xe5c082f7
            dd 0xad4a0318, 0xf7673c8d, 0x8eaef7bb, 0xa1ad1df6

test_6_t    db 'Test 6',0
test_6_s    db '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcd',0
test_6_a    dd 0x0e43e172, 0x35777394, 0x1c2a9eac, 0x726fe754
            dd 0x930accaa, 0xc56e2829, 0x3c6ce656, 0x694fca95

test_7_t    db 'Test 7',0
test_7_s    db '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcde',0
test_7_a    dd 0x057ee79e, 0xce0b9a84, 0x9552ab8d, 0x3c335fe9
            dd 0xa5f1c46e, 0xf5f1d9b1, 0x90c29572, 0x8628299c

test_8_t    db 'Test 8',0
test_8_s    db '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',0
test_8_a    dd 0xa8ae6e6e, 0xe929abea, 0x3afcfc52, 0x58c8ccd6
            dd 0xf85273e0, 0xd4626d26, 0xc7279f32, 0x50f77c8e

test_9_t    db 'Test 9',0
test_9_s    db '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0',0
test_9_a    dd 0x2a6ad82f, 0x3620d3eb, 0xe9d678c8, 0x12ae1231
            dd 0x2699d673, 0x240d5be8, 0xfac0910a, 0x70000d93

test_10_t   db 'Test 10',0
test_10_s   db '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123',0
test_10_a   dd 0x3bf9bf95, 0xcecce1ec, 0x2f972d1f, 0x12841f1e
            dd 0x71ee8618, 0xef63ffef, 0x985b07ff, 0xd9e5a65c

test_11_t   db 'Test 11',0
test_11_s   db '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',0
test_11_a   dd 0xb320e859, 0x78db0513, 0x4003a291, 0x4eebddd8
            dd 0xd3b87268, 0x18f2e2c6, 0x79e1898c, 0x721562a9

test_12_t   db 'Test 12',0
test_12_s   db '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123',0
test_12_a   dd 0x7d30e848, 0x155f1931, 0x00935569, 0xe0846d25
            dd 0xf7a47bef, 0x67ad47bd, 0xb8a5825c, 0x0a4e507d

; Testing ends with a NULL QWORD
test_stop   dq 0x0,0x0


; This is where the hashed value will be placed if hash routine is
; successful.
hash    times 32 db 0           ; 32 byte answer

;*******************************************************************************
;*  INCLUDED FILES
;*******************************************************************************
%include "lib_sha256.asm"
%include "lib_app.asm"

ENTRY:
call gui_init
call clear_screen

; Uncomment the section below if you want to run a specific test.
; I used it for testing.
; ____ START _____
    ; mov rsi,test_11_t
    ; call print_ln

; These are the 3 parameters needed. If you wanted a lean hashing
; routine, this block is all you need.
    ; mov rax, test_11_s
    ; call str_len                ; returns length to RAX
    ; mov rsi, test_11_s
    ; mov rdi, hash
    ; call sha256

; Check the results
    ; call move_eos
    ; call check_results

; ____ END ____

call run_tests
call exit

;*******************************************************************************
;*  PROCEDURES
;*******************************************************************************

run_tests:
    mov rsi,TESTS           ; start of test block
    mov rdi,hash            ; location to put hash value

    .Main_loop:
        cmp qword [rsi],0   ; if RSI=0 then quit
        jz .Return

        ; Print test title
        call print_ln

        ; Move past title
        call move_eos

        ; Get string length of text to hash
        mov rax, rsi
        call str_len                ; returns length to RAX

        ; IN:   RSI = memory location of string to hash
        ;       RDI = memory location to put hash. MUST be at least 32 bytes.
        ;       RAX = total length of string to hash (in bytes)
        call sha256

        ; Move past string to be hashed
        call move_eos

        ; Check results. This routine moves RSI 32 bytes (pass or fail) and
        ; sets up RSI for the next test.
        call check_results

    jmp .Main_loop

.Return:
ret

; Compares the hashed calculated in sha256 to the hashed answer provided
; above. This routine will move RSI 32 bytes forward.
; IN:   RSI = memory location of answer (e.g. test_1_a)
;       RDI = memory location of hash calculated by sha256
; OUTl  RAX = 1=sucess, 0=fail
;       RSI = moved 32 bytes
check_results:
    push rbx
    push rcx
    push rdi
    push r8         ; pass / fail flag

    mov r8,1        ; assume everything passes

    mov rcx,8
    .Loop1:
        lodsd
        mov ebx,[rdi]
        cmp eax,ebx
        jne .Set_flag_fail
    .Cont1:
        add rdi,4
    loop .Loop1

    cmp r8,0
    jz .Return_Fail

    ; If here is all values matched, exit with pass.
    push rsi
        mov rsi, .str_pass
        call print_ln
    pop rsi
    mov rax,1
    jmp .Done

.Return_Fail:
    push rsi
        mov rsi, .str_fail
        call print_ln
    pop rsi
    mov rax,0

.Done:
    pop r8
    pop rdi
    pop rcx
    pop rbx
ret
.str_pass       db 'Passed',0
.str_fail       db '>>> Failed! <<<',0

; Sets the flag to FAIL (0) and returns back to the loop. Need to do this
; so that RSI is set to the next test.
.Set_flag_fail:
    mov r8,0
    jmp .Cont1

; Moves to end of string
;   Using a NULL terminated string as input, run thru a string until you
;   reach the NULL (0). Then, add 1 more to move past the null.
; IN:   RSI = string location
; OUT:  RSI = updated position
move_eos:
    push rax

    .Loop1:
        lodsb
        cmp al,0
        jz .Done
    jmp .Loop1

.Done:
;    inc rsi         ; move past NULL
    pop rax
ret
