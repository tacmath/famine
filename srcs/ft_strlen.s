ft_strlen:
	mov rax, -1
	str_len_loop:
	inc rax
	cmp BYTE [rdi + rax], 0
	jne str_len_loop
	ret