%include "include.s"

section .text
	global checknpheader64

; checknpheader64(char *data, file_size)
checknpheader64:
	; reset register
	xor rax, rax
	xor rbx, rbx
	xor rcx, rcx
	xor rdx, rdx

	; check if the file is bigger than an ELF_HEADER_FILE
	cmp rsi, 64
	jl corrupt

	; check if the file is bigger than pheader info indicated
	mov ax, [rdi + e_phentsize]
	mov cx, [rdi + e_phnum]
	mul cx
	cmp si, ax
	jl corrupt

	; check if the file is bigger than the sheader info indicated
	mov ax, [rdi + e_shentsize]
	mov cx, [rdi + e_shnum]
	mul cx
	add rax, [rdi + e_shoff]
	cmp rax, rsi
	jne corrupt

	; check each pheader
	mov bx, [rdi + e_ehsize]
	mov cx, [rdi + e_phnum]
	check_phader:

	; check offset
	mov rdx, [rdi + rbx + p_offset]
	cmp rsi, rdx
	jl corrupt

	; check size
	add rdx, [rdi + rbx + p_filesz]
	cmp rsi, rdx
	jl corrupt


	; check aligment
	mov rdx, [rdi + rbx + p_align]
	cmp rdx, 4096
	jg corrupt

	; go to the next header
	add bx, [rdi + e_phentsize]	
	dec cx

	; check if all the pheader has been read
	cmp cx, 0
	jg check_phader

	; the file is not corrupt
	clean:
	mov rax, 0
	ret

	; the file is corrupt
	corrupt:
	mov rax, -1
	ret