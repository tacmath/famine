;------------------------------------------------------------------------------;
; void   ft_putnbr(const long nb)                                              ;
;                                                                              ;
; 1st arg:  rdi  nb                                                            ;
;------------------------------------------------------------------------------;

ft_putnbr:                                      ; ft_putnbr (LINUX)
    enter 21, 0             ; char buff[21];  
    mov rax, rdi            ; long tmp = nb
    mov rbx, 21             ; int idx = 21;
    cmp rdi, 0              ; if (nb < 0)
    jz putnbr_print_zero
    jns putnbr_loop                ;   nb = abs(nb)
    neg rax
    putnbr_loop:
    cmp rax, 0              ; while (nb)
    jz endputnbr_loop              ;
    xor rdx, rdx            ;
    mov rcx, 10             ; nb = nb / 10
    div rcx                 ;
    add dl, '0'             ; c = nb % 10 + '0'
    dec rbx                 ; idx = idx - 1
    mov [rsp + rbx], dl     ; buff[idx] = c
    jmp putnbr_loop                ;
    endputnbr_loop:
    cmp rdi, 0              ; if (nb < 0)
    jns putnbr_exit                ; idx = idx - 1
    dec rbx                 ; buff[idx] = '-'
    mov byte [rsp + rbx], '-'
    putnbr_exit:
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, rsp
    add rsi, rbx
    mov rdx, 21
    sub rdx, rbx
    syscall                 ; write(1, buff, 21 - buff)
    leave
    ret
    putnbr_print_zero:
    dec rbx
    mov byte [rsp + rbx], '0'
    jmp putnbr_exit