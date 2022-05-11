negsign: db "-", 0,
number: db "0123456789"

putnbr:
	push rbp
	mov rbp, rsp
	push r8
	push r9
	mov r8, rdi
	; manage negative number
	mov r9, 0x8000000000000000
	test r8, r9
	jz value
	mov rdi, STDOUT
	lea rsi, [rel negsign]
	mov rdx, 1
	mov rax, WRITE
	syscall
	neg r8
	value:

	xor rdx, rdx      ; clear dividend
	mov rax, r8	   	  ; dividend
	mov rcx, 10       ; divisor
	div rcx           ; RAX = /, RDX = %

	cmp r8, 9
	jle print_value
	mov rdi, rax
	push rdx
	call putnbr
	pop rdx
	print_value:
	mov rdi, STDOUT
	lea rsi, [rel number + rdx]
	mov rdx, 1
	mov rax, WRITE
	syscall
	pop r8
	pop r9
	leave
	ret