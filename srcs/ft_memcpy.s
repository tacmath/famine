ft_memcpy:
    mov rcx, rdx
    shr rcx, 3          ; rcx >> 3 == rcx / 8
    rep movsq
    mov rcx, rdx
    and rcx, 7          ; rcx & 7 == rcx % 8
    rep movsb
    ret

ft_memrcpy:
    std
    lea rdi, [rdi + rdx - 1]
    lea rsi, [rsi + rdx - 1]
    mov rcx, rdx
    and rcx, 7          ; rcx & 7 == rcx % 8
    rep movsb
    sub rdi, 7
    sub rsi, 7
    mov rcx, rdx
    shr rcx, 3          ; rcx >> 3 == rcx / 8
    rep movsq
    cld
    ret