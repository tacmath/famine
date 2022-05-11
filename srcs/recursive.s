%include "include_recur.s"

section .text
	global recursive


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
	push r8
	sub rsp, BUFFSIZE
	;open:
	mov r12, rdi			;  buff[4096]
	mov rsi, 0			    ; O_RDONLY
	mov rax, OPEN   	 	; open("", O_RDONLY);
	syscall
	mov r15, rax			; fd
	cmp r12, 0
	jle exit
	call ft_strlen
	mov r8, rax
	
	;getents
	loop_dir:
	mov rdi, r15		; fd
	mov rsi, rsp		; buff[300]
	mov rdx, BUFFSIZE	; 300
	mov rax, GETDENTS
	syscall
	mov r14, rax		; byte read
	cmp rax, 0
	jle exit


	; loop files
	xor r13, r13
	jmp files_loop_end
	files_loop:
	

	;affiche name

	mov rdi, STDOUT
	mov rsi, r12
	mov rdx, r8
	mov rax, WRITE
	syscall

	lea rdi, [rsp + r13 + d_name]
	call ft_strlen
	mov rdi, STDOUT
	lea rsi, [rsp + r13 + d_name]
	mov rdx, rax
	mov rax, WRITE
	syscall
	mov rdi, STDOUT
	lea rsi, [rel str] 
	mov rdx, 1
	mov rax, WRITE
	syscall

	;check type
	xor rax, rax
	xor rdi, rdi
	mov di, [rsp + r13 + d_reclen]
	add rdi, r13
	mov al, byte [rsp + rdi - 1]
	cmp rax, DT_DIR
	jnz end_recur
	;start recussif
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
	lea rdi, [rsp + r13 + d_name]
	call ft_strlen
	add rax, r8
	cmp rax, PATHBUFFSIZE - 2
	jge end_recur
	lea rdi, [r12 + r8]
	cmp byte [rdi - 1], '/'
	jz slash_ok
	mov byte [rdi], '/'
	inc rdi
	slash_ok:
	lea rsi, [rsp + r13 + d_name]
	call ft_strcpy
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
	lea rdi, [r12 + r8]
	
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
	exit:
		mov rdi, r15
		mov rax, CLOSE
		syscall
		leave
		ret


