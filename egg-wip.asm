; may be able to change some sizes as 0x4000 is 2 bytes...
	push	r13
	push	r14
	push	r15

	; in = malloc(0x4000)
	; out = malloc(0x4000)
	mov	edi, 0x4000
	push	edi
	call	$codo_malloc_paddr
	pop	edi
	push	rax ; in
	mov	r15, rax
	call	$codo_malloc_paddr
	push	rax ; out

	;test	r15, rax ; in and out
	;jz	.finish
	;mov	r13d, 0x4000 ; can do with push edi and pop r13d around the call

	xor	r14d, r14d ; read/write (and r15 is in/out)
	; read(in) or write(out)
.loop:
	mov	eax, r14d
	mov	edi, r14d
	mov	rsi, r15 ; in or out
	mov	edx, 0x4000 ; TODO: size left in buffer with r13d
	syscall
	add	r15d, eax
	;sub	r13d, eax
	;cmovz	ax, 42
	;jz	.finish
	cmp	eax, 0
	;jc	.finish
	jnz	.loop

	test	r14d, r14d
	jnz	.finish
	inc	r14d

	; pico8_preprocess(in, out)
	pop	rsi ; out
	mov	r15, rsi
	pop	rdi ; in
	push	rdi ; in
	push	rsi ; out
	call	$pico8_preprocess_paddr
	;mov	r13d, 0x4000
	jmp	.loop

	; free(in)
	; free(out)
	; return 0
.finish:
	mov	r15, rax
	pop	rax ; out
	call	$codo_free_paddr
	pop	rax ; in
	call	$codo_free_paddr
	mov	rax, r15
	pop	r13
	pop	r14
	pop	r15
	ret
