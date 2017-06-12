.set MAGIC,		0xE85250D6
.set ARCH,		0x00000000
.set LENGTH,	_mbEnd - _mbStart
.set CHECKSUM,	-(MAGIC + ARCH + LENGTH)

.section .multiboot
_mbStart:
.long	MAGIC
.long	ARCH
.long	LENGTH
.long	CHECKSUM
.word 	0
.word	0
.long	8
_mbEnd:

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

		mov		$__bss_start, %edi
		mov		$__end + 3, %ecx
		xor		%eax, %eax
		sub		%edi, %ecx
		shr		$2, %ecx
		rep; stosl
		
		call	kmain

		cli
		hlt
.size 	_entry, . - _entry
