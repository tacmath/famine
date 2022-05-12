;	int getfiletype(char *data)
getfiletype: 
	cmp dword [rdi], 1179403647 ; magic number 0x7f454c46 464c457f
	jnz simple
	mov sil, [rdi + s_support]
	cmp sil, 1			; cmp 32 bit
	je bit_32
	bit_64:
	mov rax, 2
	ret
	bit_32:
	mov rax, 1
	ret
	simple: 
	mov rax, 0
	ret
