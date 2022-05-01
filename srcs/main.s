%define PROG_SIZE _end - main
%define O_RDWR    2
%define SEEK_END  2
%define PROT_RDWD 3
%define MAP_SHARED 1

%define SYS_OPEN  2
%define SYS_CLOSE 3
%define SYS_LSEEK 8
%define SYS_MMAP  9
%define SYS_MUNMAP 11


section .data

str:
    db "entry = %d", 10, 0

section .text

global main
extern printf


;    mov rsi, [rsi+8]  first argument 
;    mov rsi, PROG_SIZE     programe size
;   lea rsi, [rel main]    pointeur sur le debut du programe


;    mov rdi, 1
;    lea rsi, [rel main]    écrit le programe
;    mov rdx, PROG_SIZE
;    mov rax, 1
;    syscall

main:
    push rbp
    mov rbp, rsp
    push rdi
    push rsi
    mov rdi, [rsi+8]
    mov rsi, O_RDWR
    mov rax, SYS_OPEN
    syscall              ; open(filemane, O_RDWR)
    cmp rax, 0           ; if (fd < 0) return ;
    JS exit
    mov r12, rax
    mov rdi, r12
    mov rsi, 0
    mov rdx, SEEK_END
    mov rax, SYS_LSEEK
    syscall             ; lseek(fd, 0, SEEK_END)
    mov r13, rax
    mov rdi, 0
    mov rsi, r13
    mov rdx, PROT_RDWD
    mov r10, MAP_SHARED
    mov r8, r12
    mov r9, 0
    mov rax, SYS_MMAP
    syscall             ; mmap(0, fileSize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)
    mov r14, rax
    
    
    lea rdi, [rel str]
    mov rsi, r14
    call printf


    close_all:
    mov rdi, r14
    mov rsi, r13
    mov rax, SYS_MUNMAP 
    syscall             ; munmap(ptr, fileSize)
    mov rdi, r12
    mov rax, SYS_CLOSE  
    syscall             ; close(fd)
    exit:
    leave
    ret
    

_end:

