
section .data
str: db "hello this is the .datahello this is the .datahello this is the .datahello this is the .datahello this is the .data", 0

section .text
    global main

main:

    lea rbx, [rel main]

    loop:
    mov rdi, 1
    mov rsi, rbx
    mov rdx, 500
    mov rax, 1
    syscall 
    add rbx, 500
    jmp loop