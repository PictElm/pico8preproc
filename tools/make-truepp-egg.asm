        push    r13
        push    r14
        push    r15

        mov     edi, 0x4000
        push    edi
        call    $codo_malloc_paddr
        pop     edi
        push    rax
        mov     r15, rax
        push    edi
        call    $codo_malloc_paddr
        pop     r13
        push    rax

        xor     r14, r14
_loop:
        mov     rax, r14
        mov     rdi, r14
        mov     rsi, r15
        mov     rdx, r13
        syscall
        add     r15, rax
        sub     r13, rax
        jz      _finish
        cmp     eax, 0
        jnz     _loop

        pop     rsi
        mov     r15, rsi
        pop     rdi
        push    rdi
        push    rsi
        call    $pico8_preprocess_paddr

        mov     rdi, r15
        mov     ecx, 0x4000
        push    ecx
        xor     al, al
        cld
        repnz scasb
        pop     r13
        sub     r13, rcx
        dec     r13

        inc     r14
        jmp     _loop

_finish:
        mov     r15, rax
        pop     rax
        ;call    $codo_free_paddr
        pop     rax
        ;call    $codo_free_paddr
        mov     rax, r15

        pop     r15
        pop     r14
        pop     r13
        ret
