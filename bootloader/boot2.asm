	bits 16
	org 0x0000

start:
	jmp loader;



Print:
	lodsb
	cmp al, 0
	je .done
	mov ah, 0x0E
	int 10h
	jmp Print
.done:
	ret



loader:
	cli
	mov 	ax, 0x0050 ; Start data segment at 0x0050:0x0000
	mov		ds, ax
	mov 	es, ax
	mov 	fs, ax
	mov		gs, ax
	
	xor 	ax, ax
	mov		ss, ax
	mov		sp, 0xFFFF
	sti

	mov si, startMsg
	call Print

	jmp $

startMsg: db "Beginning Stage 2 Bootloader", 0x0D, 0x0A, 0x00
