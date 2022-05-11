
ft_strcpy:
	mov rdx, -1
	str_cpy_loop:
	inc rdx
	mov al, BYTE [rsi + rdx]
	mov BYTE [rdi + rdx], al
	cmp al, 0
	jne str_cpy_loop
	mov rax, rdi
	ret
