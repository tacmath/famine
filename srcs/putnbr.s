section .text
	global putnbr

number: db "0123456789-"

putnbr:
	mov rbx, rdi
	cmp rsi, 4
	jz putnbr_32
putnbr_64:
	; manage negative number
	cmp rbx, 0
	jns number_recursive
	neg rbx
	jmp putnbr_neg
putnbr_32:
	; manage negative number
	cmp ebx, 0
	jns number_recursive
	neg ebx

putnbr_neg:

	mov rdi, 1
	lea rsi, [rel number + 10]
	mov rdx, 1
	mov rax, 1
	syscall
	
	mov rdi, rbx
	call number_recursive
	ret

number_recursive:
	push rbp
	mov rbp, rsp 
	xor rdx, rdx      ; clear dividend
	mov rax, rdi	   	  ; dividend
	mov rcx, 10       ; divisor
	div rcx           ; RAX = /, RDX = %

	cmp rdi, 9
	jle print_value_int
	mov rdi, rax
	push rdx
	call number_recursive
	pop rdx
	print_value_int:
	mov rdi, 1
	lea rsi, [rel number]
	add rsi, rdx
	mov rdx, 1
	mov rax, 1
	syscall
	leave
	ret