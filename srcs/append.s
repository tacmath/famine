;  void append_signature(char *name)
append_signature:
    mov rsi, O_WRONLY | O_APPEND
    mov rax, SYS_OPEN
    syscall
    mov rbx, rax
    mov rdi, rbx 
    lea rsi, [rel signature]
    mov rdx, SIGNATURE_SIZE
    mov rax, SYS_WRITE
    syscall
    mov rdi, rbx
    mov rax, SYS_CLOSE
    syscall
    ret
