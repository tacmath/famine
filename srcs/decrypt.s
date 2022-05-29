decrypt_v1:
    mov rax, ENCRYPT_SIZE
    xor rdx, rdx
	mov rbx, KEY_SIZE
    div rbx
    mov rcx, ENCRYPT_SIZE
    lea rdi, [rel decrypt_v1 + DECRYPT_FUNC_SIZE]
    lea rsi, [rel decrypt_v1 + DECRYPT_KEY_OFFSET]
	decrypte_loop_v1:
	cmp rdx, 0
	jnz decrypte_nochange_v1
	mov rdx, KEY_SIZE
	decrypte_nochange_v1:
    dec rdx
    dec rcx
	mov bl, byte [rdi+rcx-1]
    add bl, byte [rsi+rdx]
	sub [rdi+rcx], bl
	cmp rcx, 1
	jnz decrypte_loop_v1
    mov bl, byte [rsi]
	sub [rdi], bl
    jmp rdi
decrypt_v1_end:

decrypt_v2:
    lea rdi, [rel decrypt_v2 + DECRYPT_FUNC_SIZE]
    lea rsi, [rel decrypt_v2 + DECRYPT_KEY_OFFSET]
    mov rcx, KEY_SIZE
    mov rbx, ENCRYPT_SIZE
    dec rbx
    decrypt2_loop:

    ; if (i == 0) ; data[i] = data[i] ^ value[0]; else ; data[i] = data[i] ^ data[i - 1];
    cmp rbx, 0
    jne decrypt2_i
    mov rdx, [rel decrypt_v2]
    jmp decrypt2_end_i
    decrypt2_i:
    mov rdx, [rdi + rbx - 1]
    decrypt2_end_i:
    xor byte [rdi + rbx], dl
    

    ; data[i] = data[i] ^ key[i % key_size];
    xor rdx, rdx
    mov rax, rbx
    div rcx
    mov dl, [rsi + rdx]
    xor [rdi + rbx], dl

    ; data[i] = data[i] ^ value[i % 16]
    mov rax, rbx
    and rax, 15
    lea rdx, [rel decrypt_v2]
    mov al,  [rdx + rax]
    xor byte [rdi + rbx], al

    ; data[i] = (data[i] + i) % 256
    mov al, byte [rdi + rbx]
    sub al, bl
    mov byte [rdi + rbx], al

    dec rbx
    cmp rbx, 0
    jge decrypt2_loop
    jmp rdi
decrypt_v2_end: