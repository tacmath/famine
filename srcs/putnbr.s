;------------------------------------------------------------------------------;
; void   ft_putnbr(const long nb)                                              ;
;                                                                              ;
; 1st arg:  rdi  nb                                                            ;
;------------------------------------------------------------------------------;

section .text
	global ft_putnbr		; export ft_putnbr (LINUX)

; rbx, nb
ft_putnbr:					; ft_putnbr (LINUX)
    enter 21, 0             ; char buff[21];

    push rax                ; --> no destructif function
    push rbx                ; --> no destructif function
    push rcx                ; --> no destructif function
    push rdx                ; --> no destructif function
    push rdi                ; --> no destructif function
    push rsi                ; --> no destructif function

    mov rax, rdi            ; long tmp = nb
    mov rbx, 21             ; int idx = 21;
    cmp rdi, 0              ; if (nb < 0)
    jns ft_putnbrloop                ;   nb = abs(nb)
    neg rax
    ft_putnbrloop:
    cmp rax, 0              ; while (nb)
    jz endft_putnbrloop              ;
    xor rdx, rdx            ;
    mov rcx, 10             ; nb = nb / 10
    div rcx                 ;
    add dl, '0'             ; c = nb % 10 + '0'
    dec rbx                 ; idx = idx - 1
    mov [rsp + rbx], dl     ; buff[idx] = c
    jmp ft_putnbrloop                ;
    endft_putnbrloop:
    cmp rdi, 0              ; if (nb < 0)
    jns exitft_putnbr                ; idx = idx - 1
    dec rbx                 ; buff[idx] = '-'
    mov byte [rsp + rbx], '-'
    exitft_putnbr:
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, rsp
    add rsi, rbx
    mov rdx, 21
    sub rdx, rbx
    syscall                 ; write(1, buff, 21 - buff)

    pop rsi                ; --> no destructif function
    pop rdi                ; --> no destructif function
    pop rdx                ; --> no destructif function
    pop rcx                ; --> no destructif function
    pop rbx                ; --> no destructif function
    pop rax                ; --> no destructif function

    leave
    ret
