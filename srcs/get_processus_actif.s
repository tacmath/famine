; r15 = int fd
; r14 = bytes read by getend
; r13 = offset of a dir in the data returned by getend
; r12 = path
; r9 = return value
; r8 = long pathSize

; int get_processus_actif();
get_processus_actif:
	enter process_finder_size, 0	; creer un buffer sur la stack utiliser avec getend pour lire les information de donner
	xor r9, r9
	;open:
    lea r12, [rsp + process_path]
    mov rdi, r12
	lea rsi, [rel procdir]
    call ft_strcpy

    mov rdi, r12
	mov rsi, 0			    ; O_RDONLY
	mov rax, SYS_OPEN   	
	syscall					; open(fileName, O_RDONLY);
	cmp rax, 0				; if (fd < 0) return ;
	jl get_processus_actif_exit2
	mov r15, rax			; fd
;	lea rdi, [r12 + fileName] ; rdi is not lost
	call ft_strlen				; recupere la taille de fileName
	mov r8, rax

;	jmp get_processus_actif_exit
	
	;getents
	search_for_procces:
	mov rdi, r15		; fd
	mov rsi, rsp				; le buffer est la stack
	mov rdx, READ_DIR_BUFF_SIZE
	mov rax, SYS_GETDENTS
	syscall
	mov r14, rax		; byte read
	cmp rax, 0			; if (ret < 0) return ;
	jle get_processus_actif_exit


	; loop files
	xor r13, r13
	jmp proc_files_loop_end
	proc_files_loop:
	

	;copy file name to path




	;check type
	xor rax, rax
	xor rdi, rdi
	mov di, [rsp + r13 + d_reclen]
	add rdi, r13
	mov al, byte [rsp + rdi - 1]	; get the byte used to know the file type
	cmp rax, DT_DIR
	jz find_process_name
	jmp not_needed_process				; loop to the next file


	find_process_name:

	lea rdi, [rsp + r13 + d_name]
	call ft_strlen
	add rax, r8
	cmp rax, PATH_BUFF_SIZE - 2
	jge not_needed_process
	lea rdi, [r12 + r8]
	lea rsi, [rsp + r13 + d_name]
	call ft_strcpy

    mov rdi, r12
    call ft_strlen

    lea rdi, [r12 + rax]
    lea rsi, [rel proc_status]
    call ft_strcpy

    mov rdi, r12
	mov rsi, 0			    ; O_RDONLY
	mov rax, SYS_OPEN   	
	syscall					; open(fileName, O_RDONLY);
    cmp rax, 0
    jl not_needed_process

    mov rdi, rax            ; fd
    lea rsi, [rsp + process_status]
    mov rdx, PROCESS_STATUS_READ_SIZE
    mov rax, SYS_READ
    syscall
    mov rax, SYS_CLOSE
    syscall

    lea rdi, [rel proc_test.string]
    lea rsi, [rsp + process_status]
    mov rcx, proc_test.len
    repe cmpsb
	jnz not_needed_process
	inc r9
	jmp get_processus_actif_exit

	not_needed_process:
	xor rax, rax
	mov ax, [rsp + r13 + d_reclen]
	cmp rax, 0
	jz quit_proc_files_loop
	add r13, rax

	proc_files_loop_end:
	cmp r13, r14
	jl proc_files_loop			; while (n < getend_byte_read) {do code on a file; n += file_struct_size};

	quit_proc_files_loop:
	jmp search_for_procces			; while (1);

	get_processus_actif_exit:
	mov rdi, r15
	mov rax, SYS_CLOSE
	syscall					; close(fd)
    mov rax, r9
	get_processus_actif_exit2:
	leave
	ret
