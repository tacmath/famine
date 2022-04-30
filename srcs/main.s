%define SIZE _end - main
%define O_RDWR    2
%define SYS_OPEN  2

section .data

str:
    db "fd = %d", 10, 0

section .text

global main
extern printf


;    mov rsi, [rsi+8]  first argument 
;    mov rsi, SIZE     programe size
;   lea rsi, [rel main]    pointeur sur le debut du programe


;    mov rdi, 1
;    lea rsi, [rel main]    écrit le programe
;    mov rdx, SIZE
;    mov rax, 1
;    syscall

main:
    push rbp
    mov rbp, rsp
    mov r13, rdi
    mov r12, rsi
    mov rdi, [rsi+8]
    mov rsi, O_RDWR
    mov rax, SYS_OPEN
    syscall
    cmp rax, 0
    JS exit
    lea rdi, [rel str]
    mov rsi, rax
    call printf
    exit:
    leave
    ret
    

_end:

