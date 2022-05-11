;  char ft_strcmp(char *str1, char* str2)
ft_strcmp:
    xor rax, rax
    xor rbx, rbx
    jmp ft_strcmp_cmp
    ft_strcmp_loop:
    mov bl, [rdi + rax]
    sub bl, [rsi + rax]
    cmp bl, 0
    jnz quit_ft_strcmp_loop
    inc rax
    ft_strcmp_cmp:
    cmp byte [rdi + rax], 0
    jnz ft_strcmp_loop
    quit_ft_strcmp_loop:
    mov bl, [rdi + rax]
    sub bl, [rsi + rax]
    mov rax, rbx
    ret