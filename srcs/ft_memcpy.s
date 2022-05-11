;  void *ft_memcpy(void *dest, void* src, size_t size)
ft_memcpy:
    xor rax, rax
    jmp ft_memcpy_cmp
    ft_memcpy_loop:
    mov bl, [rsi + rax]
    mov [rdi + rax], bl
    inc rax
    ft_memcpy_cmp:
    cmp rax, rdx
    jl ft_memcpy_loop
    mov rax, rdi
    ret