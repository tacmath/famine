%define GETDENTS 78
%define WRITE 1
%define OPEN 2
%define CLOSE 3

%define STDOUT 1

%define DT_DIR 4
%define DT_REG 8

%define BUFFSIZE 256
%define PATHBUFFSIZE 1024



struc linux_dirent
	d_ino: resq  1;		/* Numero d'inode */
	d_off: resq  1;		/* offset		  */
	d_reclen: resw 1;	/* taille prise par le fichier au sein du dossier */
	d_name:	 resb 1;	/* nom du fichier visé */
endstruc

struc magic_num
    s_magic_number:	resd 1;
	s_support:	 	resb 1;
	s_endian:		resb 1;
	s_version:		resb 1;	
	s_abi:			resb 1;	
endstruc
