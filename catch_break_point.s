%define sys_write        0x01
%define sys_rt_sigaction 0x0d
%define sys_pause        0x22
%define sys_exit         0x3c
%define sys_rt_sigreturn 0x0f
%define SIGTERM 0x0f
%define SIGTRAP 0x05
%define SIGINT 0x02
%define STDOUT 0x01
%define SA_RESTORER 0x04000000

; Definition of sigaction struct for sys_rt_sigaction
struc sigaction
    .sa_handler  resq 1
    .sa_flags    resq 1
    .sa_restorer resq 1
    .sa_mask     resq 1
endstruc

section .data
    ; Message shown when a syscall fails
    error_msg     db  'syscall error', 0x0a
    error_msg_len equ $ - error_msg
    ; Message shown when SIGTRAP is received
    sigterm_msg     db  'SIGTRAP received', 0x0a
    sigterm_msg_len equ $ - sigterm_msg

section .bss
    act resb sigaction_size
    val resd 1

section .text
    global main
main:
    ; Initialize act
    mov qword [act + sigaction.sa_handler], handler
    mov [act + sigaction.sa_flags], dword SA_RESTORER
    mov qword [act + sigaction.sa_restorer], restorer

    ; Set the handler
    mov rax, sys_rt_sigaction
    ;mov rdi, SIGINT
    ;mov rdi, SIGTERM
    mov rdi, SIGTRAP
    lea rsi, [act]
    mov rdx, 0x00
    mov r10, 0x08
    syscall

    ; Ensure the syscall succeeded
    cmp rax, 0
    jne error

    int3
    ; Pause until a signal is received
    mov rax, sys_pause
    syscall

    ; Upon success, jump to exit
    jmp exit

error:
    ; Display an error message
    mov rax, sys_write
    mov rdi, STDOUT
    mov rsi, error_msg
    mov rdx, error_msg_len
    syscall

    ; Set the return value to one
    mov dword [val], 0x01

exit:
    ; Terminate the application gracefully
    mov rax, sys_exit
    mov rdi, [val]
    syscall
    ret
handler:
    ; Display a message
    mov rax, sys_write
    mov rdi, STDOUT
    mov rsi, sigterm_msg
    mov rdx, sigterm_msg_len
    syscall
    ret

restorer:
    ; return from the signal handler
    mov rax, sys_rt_sigreturn
    syscall