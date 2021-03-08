;*******************************************************************************
; SHA256 HASH LIBRABRY
;
; References:
;   https://en.wikipedia.org/wiki/SHA-2
;   https://github.com/amosnier/sha-2/blob/master/sha-256.c
;   https://codereview.stackexchange.com/questions/182812/self-contained-sha-256-implementation-in-c
;
; To use this library, call 'sha256'.
; Run that routine with the parameters needed and you will get a 32
; byte hash (256 bits).
;
; Copyright (c) 2016-2022 David Borsato
; Created: Feb 27, 2021 by David Borsato
; Library Version: 2.0, Mar 7 2021
;*******************************************************************************

sha256__BLOCK_SIZE      equ 64      ; 512 bit is 64 bytes

; (first 32 bits of the fractional parts of the square roots of the
; first 8 primes 2..19):
sha256__h0 dd 0x6a09e667
sha256__h1 dd 0xbb67ae85
sha256__h2 dd 0x3c6ef372
sha256__h3 dd 0xa54ff53a
sha256__h4 dd 0x510e527f
sha256__h5 dd 0x9b05688c
sha256__h6 dd 0x1f83d9ab
sha256__h7 dd 0x5be0cd19

; Initialize array of round constants:
; (first 32 bits of the fractional parts of the cube roots of the
; first 64 primes 2..311):
sha256__k:
dd 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
dd 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174
dd 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da
dd 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967
dd 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85
dd 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070
dd 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3
dd 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2


;*******************************************************************************
; Calculates a SHA256 hash.
;
; IN:   RSI = memory location of string to hash
;       RDI = memory location to put hash. MUST be at least 32 bytes.
;       RAX = total length of string to hash (in bytes)
; OUT:  RDI = updated with a 32 byte hash
;*******************************************************************************
sha256:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    push r8         ; string size
    push r9         ; memory location to put hash
    push r10        ; running string counter & ch
    push r11        ; current string location & maj
    push r12        ; s0, S0
    push r13        ; s1, S1
    push r14        ; temp1
    push r15        ; temp2

; Save parameters
    mov r8,rax
    mov r9,rdi
    mov r11,rsi

; Initialize environment
    xor r10,r10

    ; Initialize hash values:
    push rsi
        mov rsi,sha256__h0
        mov rdi,.h0
        mov rcx,8/2
        cld
        rep movsq
    pop rsi


    .Main_loop:
        mov rdi, .cur_block
        mov rsi, r11
        call sha256_create_block
        mov r11,rsi
        cmp al,0
        jz .Set_hash_val

        ; Process 512bit block

        ; Initialize working variables to current hash value
        mov rsi,.h0
        mov rdi,.a
        mov rcx,8/2         ; showing 8/2 for clarity, compiler will change to 4
        cld
        rep movsq           ; QWORD copy

        ; https://en.wikipedia.org/wiki/SHA-2:
        ; copy chunk into first 16 words w[0..15] of the message schedule array
        ; NOTE: a 'word' in the Wiki is a DWORD in assembler.
        mov rsi, .cur_block
        mov rdi, .w

        mov rcx,16
        .Loop_copy_16_words:
            lodsd
            bswap eax       ; convert to big-endian
            stosd
        loop .Loop_copy_16_words

        ; https://en.wikipedia.org/wiki/SHA-2:
        ; Extend the first 16 words into the remaining 48 words w[16..63] of
        ; the message schedule array.
        mov rcx,16
        .Loop_extend_w:
            ; R12 = s0
            ; R13 = s1
            ; RSI = w

            ; Calculate s0
            ; NOTE: rcx is i.
            ; s0 := (w[i-15] rightrotate  7) xor (w[i-15] rightrotate 18)
            ;       xor (w[i-15] rightshift  3)
            mov rbx,4           ; .w is DWORDS
            mov rax,rcx
            sub rax,15
            mul rbx
            mov rsi,.w
            add rsi,rax         ; RSI set to w[i-15]
            mov eax,[rsi]
            ror eax,7
            mov ebx,[rsi]
            ror ebx,18
            xor eax,ebx
            mov ebx,[rsi]
            shr ebx,3
            xor eax,ebx
            mov r12d,eax        ; save s0

            ; Calculate s1
            ; s1 := (w[i- 2] rightrotate 17) xor (w[i- 2] rightrotate 19)
            ; xor (w[i- 2] rightshift 10)
            mov rbx,4           ; .w is DWORDS
            mov rax,rcx
            sub rax,2
            mul rbx
            mov rsi,.w
            add rsi,rax         ; RSI set to w[i-2]
            mov eax,[rsi]
            ror eax,17
            mov ebx,[rsi]
            ror ebx,19
            xor eax,ebx
            mov ebx,[rsi]
            shr ebx,10
            xor eax,ebx
            mov r13d,eax        ; save s0

            ; w[i] := w[i-16] + s0 + w[i-7] + s1
            mov rbx,4           ; .w is DWORDS
            mov rax,rcx
            sub rax,16
            mul rbx
            mov rsi,.w
            add rsi,rax         ; RSI set to w[i-16]
            mov r14d,[rsi]      ; temp holder
            add r14d,r12d       ; + s0

            mov rbx,4           ; .w is DWORDS
            mov rax,rcx
            sub rax,7
            mul rbx
            mov rsi,.w
            add rsi,rax         ; RSI set to w[i-7]
            add r14d,[rsi]      ; + w[i-7]
            add r14d,r13d       ; + s1

            mov rbx,4           ; .w is DWORDS
            mov rax,rcx
            mul rbx
            mov rsi,.w
            add rsi,rax         ; RSI set to w[i]
            mov [rsi],r14d      ; = w[i]

            inc rcx
        cmp rcx,63
        jbe .Loop_extend_w

        ; Compression function main loop
        push r10        ; R10 & R11 are re-purposed for ch & maj
        push r11
        mov rcx,0
        .Loop_compression:
            ; S1 := (e rightrotate 6) xor (e rightrotate 11) xor (e rightrotate 25)
            ; r13d is S1
                mov eax,[.e]
                mov r13d,[.e]
                ror r13d,6
                mov ebx,eax
                ror ebx,11
                xor r13d,ebx
                mov ebx,eax
                ror ebx,25
                xor r13d,ebx

            ; ch := (e and f) xor ((not e) and g)
            ; r10d is ch
                mov r10d,[.e]
                and r10d,[.f]
                mov eax, [.e]
                not eax
                and eax, [.g]
                xor r10d,eax

            ; temp1 := h + S1 + ch + k[i] + w[i]
            ; r14d is temp1
                mov r14d,[.h]
                add r14d,r13d
                add r14d,r10d

                mov rax,4               ; DWORD
                mul rcx
                mov rsi,sha256__k
                add rsi,rax             ; k[i]
                add r14d,[rsi]

                mov rsi,.w
                add rsi,rax             ; w[i]
                add r14d,[rsi]

            ; S0 := (a rightrotate 2) xor (a rightrotate 13) xor (a rightrotate 22)
            ; r12d is S0
                mov r12d,[.a]
                ror r12d,2
                mov eax,[.a]
                mov rbx,rax
                ror ebx,13
                xor r12d,ebx
                ror eax,22
                xor r12d,eax

            ; maj := (a and b) xor (a and c) xor (b and c)
            ; r11d is maj
                mov r11d,[.a]
                mov eax, r11d
                mov ebx, [.b]       ; eax=a, ebx=b
                and r11d,ebx        ; (a and b)
                mov ebx, [.c]       ; eax=a, ebx=c
                and eax,ebx
                xor r11d,eax
                mov eax, [.b]       ; eax=b, ebx=c
                and eax,ebx
                xor r11d,eax

            ; temp2 := S0 + maj
            ; r15d is temp 2
                mov r15d,r12d
                add r15d,r11d

            ; h := g
                mov eax,[.g]
                mov [.h],eax
            ; g := f
                mov eax,[.f]
                mov [.g],eax
            ; f := e
                mov eax,[.e]
                mov [.f],eax
            ; e := d + temp1
                mov eax,[.d]
                add eax,r14d
                mov [.e],eax
            ; d := c
                mov eax,[.c]
                mov [.d],eax
            ; c := b
                mov eax,[.b]
                mov [.c],eax
            ; b := a
                mov eax,[.a]
                mov [.b],eax
            ; a := temp1 + temp2
                add r14d,r15d
                mov [.a],r14d


            inc rcx
        cmp rcx,63
        jbe .Loop_compression
        pop r11
        pop r10

        ; Add the compressed chunk to the current hash value:
        ; h0 := h0 + a
            mov eax,[.a]
            add [.h0],eax
        ; h1 := h1 + b
            mov eax,[.b]
            add [.h1],eax
        ; h2 := h2 + c
            mov eax,[.c]
            add [.h2],eax
        ; h3 := h3 + d
            mov eax,[.d]
            add [.h3],eax
        ; h4 := h4 + e
            mov eax,[.e]
            add [.h4],eax
        ; h5 := h5 + f
            mov eax,[.f]
            add [.h5],eax
        ; h6 := h6 + g
            mov eax,[.g]
            add [.h6],eax
        ; h7 := h7 + h
            mov eax,[.h]
            add [.h7],eax
    jmp .Main_loop


.Set_hash_val:
; Produce the final hash value (big-endian):
; digest := hash := h0 append h1 append h2 append h3 append h4
;                   append h5 append h6 append h7
    mov rcx,4           ; move 4 QWORDS
    mov rsi,.h0
    mov rdi,r9          ; R9 holds the location to put the final hash.
    cld
    rep movsq


    pop r15
    pop r14
    pop r13
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
    pop rax
ret
.cur_block  times sha256__BLOCK_SIZE db 0       ; current block to hash
.w          times 64 dd 0                       ; message schedule array
.a          dd 0                                ; working hash values
.b          dd 0
.c          dd 0
.d          dd 0
.e          dd 0
.f          dd 0
.g          dd 0
.h          dd 0
.h0         dd 0                                ; hash values h0 .. h7
.h1         dd 0
.h2         dd 0
.h3         dd 0
.h4         dd 0
.h5         dd 0
.h6         dd 0
.h7         dd 0



; Create a 512bit block
; IN:   RSI = current string location
;       RDI = 64 bytes (512 bits) to put the block
;        R8 = size
;       R10 = running counter
; OUT:   AL = return code; 0=done, 1=continue
;       R10 = update counter
;       RSI = moved to next block
sha256_create_block:
    push rcx
    push rdi
    ; Do NOT push RSI, needs to be incremented
    push r9     ; block location
    push r11    ; space left in block
    push rax    ; this needs to be popped first to set return code

; Check if all bytes have been processed, if so; return 0.
    cmp r10,r8
    ja .Ret_0

; Save block location
    mov r9,rdi

; Clear the working block
    xor rax,rax
    mov rcx,sha256__BLOCK_SIZE/8
    cld
    rep stosq       ; RDI should already be set
    mov rdi,r9      ; reset RDI

; Check if we need to pad the current block.
; Check if the size of the string is bigger then a block size. If so, set
; the block string to the next 64 bytes. If the current size is smaller,
; then pad the string.
    mov rax,r8
    sub rax,r10
    cmp rax,sha256__BLOCK_SIZE
    jb .Pad_string
        mov rcx,64/8
        cld
        rep movsq                       ; copy 64 blocks, RSI moved to next block
        add r10,sha256__BLOCK_SIZE      ; update running string counter
        jmp .Ret_1


; Reference pseudocode: https://en.wikipedia.org/wiki/SHA-2
; begin with the original message of length L bits
; append a single '1' bit
; append K '0' bits, where K is the minimum number >= 0 such that L + 1 + K + 64bits is a multiple of 512
; append L as a 64-bit big-endian integer, making the total post-processed length a multiple of 512 bits
.Pad_string:
    cmp rax,0
    jz .Skip_cpy
        call sha256_cpymem
        jmp .Set_bit        ; skip the two checks below
    .Skip_cpy:

    ; If the total size (R8) is 64 byte aligned then
    ; we can assume this is the final run and needs to have the '1' bit
    ; set on the first byte of the block.
    mov rcx,r8
    and rcx,0x3F
    cmp rcx,0
    jz .Set_bit

    ; If the total length (R8) is zero, then this is a NULL string. Append
    ; the single '1' bit to the first byte.
    cmp r8,0
    jnz .Skip_set_bit

    .Set_bit:
        mov [rdi], byte 0x80
    .Skip_set_bit:

    mov r10,r8              ; update counter

    mov r11, sha256__BLOCK_SIZE
    sub r11, rax    ; space left in block

    ; If the space remaining in the block is 8 bytes or less, then exit this
    ; routine with 1. This is needed because there isn't enough room to
    ; append 1 bit and add the size (R8).
    cmp r11,8
    jbe .Ret_1

    ; If here, then there is enough space left in the block to add the total
    ; size * 8.
    mov rdi,r9
    add rdi, sha256__BLOCK_SIZE-8
    mov rax,r8
    shl rax,3           ; size * 8
    mov [rdi+7],al
    mov rax,r8
    shr rax,5
    mov rcx,6
    .Loop_msg_len:
        mov [rdi+rcx],al
        shr rax,8
        dec rcx
    cmp rcx,0
    jge .Loop_msg_len

    inc r10         ; set to 1 above total size, to trigger return hash value.


.Ret_1:
    pop rax
    mov al,1
    jmp .Return

.Ret_0:
    pop rax
    mov al,0

.Return:
    pop r11
    pop r9
    pop rdi
    pop rcx
ret


; Simple routine to copy memory.
; IN:   RSI = source memory
;       RDI = destination memory
;       RAX = number of bytes to copy
sha256_cpymem:
    push rax
    push rdx

    cmp rax,8
    jae .Cont1

    ; Less then 8 bytes, do a byte copy
    mov rcx,rax
    cld
    rep movsb
    jmp .Done

.Cont1:
    mov rcx,8
    xor rdx,rdx
    div rcx
    mov rcx,rax
    cld
    rep movsq
    mov rcx,rdx
    rep movsb

.Done:
    pop rdx
    pop rax
ret
