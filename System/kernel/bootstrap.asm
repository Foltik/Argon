MBALIGN		equ 1<<0
MEMINFO		equ	1<<1
FLAGS		equ	MBALIGN | MEMINFO
MAGIC		equ	0x1BADB002
CHECKSUM	equ	-(MAGIC + FLAGS)

section .multiboot
align	4
dd		MAGIC
dd		FLAGS
dd		CHECKSUM

section .bss
align	4
stackBase:
resb	16384
stackTop:

section .text
global _entry:function (_entry.end - _entry)
_entry:
		mov		esp, stackTop
		
		extern	kmain
		call	kmain

		cli
		hlt
	.end:
	
