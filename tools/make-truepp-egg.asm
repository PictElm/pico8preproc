; could likely be optimized for byte size if needed
        push    r13
        push    r14
        push    r15

        ; allocates in and out buffers on the stack
        mov     r13, $buffer_size
        sub     rsp, r13 ; rsp at start of in-buffer
        mov     r15, rsp
        sub     rsp, r13 ; rsp at start of out-buffer
        mov     r14, rsp
        push    r15 ; in
        push    r14 ; out
        ; now on stack: out in out-buffer in-buffer (r15 r14 r13)

        xor     r14, r14 ; first time around: syscall 0 (read) to 0 (stdin)
        ; (r15 and r13 already set up)

; r14: "stream" number, r15: buffer, r13: buffer size
_loop:
        mov     rax, r14
        mov     rdi, r14
        mov     rsi, r15
        mov     rdx, r13
        syscall
        add     r15, rax
        sub     r13, rax
        jz      _finish ; assuming this will only (and always) occur when writing
        cmp     eax, 0
        jnz     _loop ; assuming this will only (and always) not-occur when reading

        pop     rsi ; out
        pop     rdi ; in
        call    $pico8_preprocess_paddr
        ; now on stack: out-buffer in-buffer (r15 r14 r13)

        mov     r15, rsp
        ; strlen of out buffer (at r15=rsp) into r13
        mov     rdi, r15
        mov     ecx, $buffer_size
        push    ecx
        xor     al, al
        cld
  repnz scasb
        pop     r13
        sub     r13, rcx
        dec     r13

        inc     r14 ; second time around: syscall 1 (write) to 1 (stdout)
        ; (r15 and r13 already set up)
        jmp     _loop

_finish:
        ; now on stack: out-buffer in-buffer (r15 r14 r13)
        mov     r13, $buffer_size
        add     rsp, r13
        add     rsp, r13
        pop     r15
        pop     r14
        pop     r13
        xor     rax, rax
        ret
