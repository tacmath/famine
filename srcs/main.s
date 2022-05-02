%define PROG_SIZE   _end - main
%define O_RDWR      2
%define O_DIRECTORY 0200000
%define SEEK_END    2
%define PROT_READ   1
%define PROT_WRITE  2
%define MAP_SHARED  1
%define PT_LOAD	    1

%define SYS_OPEN    2
%define SYS_CLOSE   3
%define SYS_LSEEK   8
%define SYS_MMAP    9
%define SYS_MUNMAP  11

struc   Elf64_Ehdr
    e_ident:     resb 16   ;       /* Magic number and other info */
    e_type:      resw 1    ;		/* Object file type */
    e_machine:   resw 1    ;		/* Architecture */
    e_version:   resd 1    ;		/* Object file version */
    e_entry:     resq 1    ;		/* Entry point virtual address */
    e_phoff:     resq 1    ;		/* Program header table file offset */
    e_shoff:     resq 1    ;		/* Section header table file offset */
    e_flags:     resd 1    ;		/* Processor-specific flags */
    e_ehsize:    resw 1    ;		/* ELF header size in bytes */
    e_phentsize: resw 1    ;		/* Program header table entry size */
    e_phnum:     resw 1    ;		/* Program header table entry count */
    e_shentsize: resw 1    ;		/* Section header table entry size */
    e_shnum:     resw 1    ;		/* Section header table entry count */
    e_shstrndx:  resw 1    ;		/* Section header string table index */
endstruc

struc Elf64_Phdr
    p_type:   resd 1 ;	    /* Segment type */
    p_flags:  resd 1 ;		/* Segment flags */
    p_offset: resq 1 ;		/* Segment file offset */
    p_vaddr:  resq 1 ;	    /* Segment virtual address */
    p_paddr:  resq 1 ;	    /* Segment physical address */
    p_filesz: resq 1 ;		/* Segment size in file */
    p_memsz:  resq 1 ;		/* Segment size in memory */
    p_align:  resq 1 ;		/* Segment alignment */
endstruc

struc famine
    fd:         resq 1
    fileSize:   resq 1
    fileData:   resq 1
    pload:      resq 1
    entry:      resq 1
    oldEntry:   resq 1
endstruc

section .data

str:
    db "nb phdr = %d", 10, 0

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
    sub rsp, famine_size
    push rdi
    push rsi
    mov rdi, [rsi+8]
    mov rsi, O_RDWR
    mov rax, SYS_OPEN
    syscall              ; open(filemane, O_RDWR)
    cmp rax, 0           ; if (fd < 0) return ;
    js exit

get_file_data:
    mov [rsp + fd], rax
    mov rdi, [rsp + fd]
    mov rsi, 0
    mov rdx, SEEK_END
    mov rax, SYS_LSEEK
    syscall             ; lseek(fd, 0, SEEK_END)
    cmp rax, 0          ; if (!size) return ;
    jz exit
    mov [rsp + fileSize], rax
    mov rdi, 0
    mov rsi, [rsp + fileSize]
    mov rdx, PROT_READ | PROT_WRITE
    mov r10, MAP_SHARED ; r10 est le 4 ieme argument car rcx et r11 sont détruit par le kernel
    mov r8, [rsp + fd]
    mov r9, 0
    mov rax, SYS_MMAP
    syscall             ; mmap(0, fileSize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)
    cmp rax, 0          ; if (!fileData) return ;
    jz exit
    mov [rsp + fileData], rax

get_first_pload:
    mov r9, [rsp + fileData]
    xor r8, r8                  ; mise a 0
    xor rdi, rdi
    mov di, [r9 + e_phnum]
    mov rsi, [r9 + e_phoff]
    xor rdx, rdx
    mov dx, [r9 + e_phentsize]
    xor rax, rax
phead_loop:
    mov eax, [r9 + rsi + p_type]
    cmp rax, PT_LOAD
    jz first_pload_found
    inc r8
    add rsi, rdx
    cmp r8, rdi
    jl phead_loop
    jmp exit                    ;on quite si il y a pas de pload trouvé
first_pload_found:
    add r9, rsi
    mov [rsp + pload], r9
    lea rdi, [rel str]
    mov rsi, [r9 + p_filesz]

;    mov rsi, famine_size
    call printf


close_all:
    mov rdi, [rsp + fileData]
    mov rsi, [rsp + fileSize]
    mov rax, SYS_MUNMAP 
    syscall             ; munmap(fileData, fileSize)
    mov rdi, [rsp + fd]
    mov rax, SYS_CLOSE  
    syscall             ; close(fd)
exit:
    leave
    ret
    

_end:

