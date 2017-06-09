.set MBALIGN,	1<<0
.set MEMINFO,	1<<1
.set FLAGS,		MBALIGN | MEMINFO
.set MAGIC,		0x1BADB002
.set CHECKSUM,	-(MAGIC + FLAGS)

.section .multiboot
.align	4
.long	MAGIC
.long	FLAGS
.long	CHECKSUM

.section .bss
.align	4
stackBase:
.skip	16384
stackTop:

.section .text
.global _entry
.type	_entry, @function
_entry:
		mov		$stackTop, %esp
		
		call	kmain

		cli
		hlt
.size 	_entry, . - _entry
