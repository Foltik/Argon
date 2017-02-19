	bits	16
	org		0x0000

start:
	jmp		loader
	times	0x0B-$+start db 0 ; Pad zeroes between jmp and 0x0B (Start of BPB)

; FAT12 BIOS Parameter Block
BytesPerSector:  	dw 512
SectorsPerCluster: 	db 1
ReservedSectors: 	dw 1
NumFATs: 			db 2
RootEntries:     	dw 224
TotalSectors: 		dw 2880
MediaDescriptor     db 0xF0
SectorsPerFAT: 	    dw 9
SectorsPerTrack:	dw 18
HeadsPerCylinder: 	dw 2
HiddenSectors: 	    dd 0
LargeSectors:     	dd 0
DriveNumber:		db 0
Unused:				db 0
BootSignature: 		db 0x29
VolumeID:			dd 0x13333337
VolumeLabel:		db "SUGOIFLOPPY"
FileSystem:			db "FAT12   "


	
ReadSectors: ; Reads sectors --- start=ax buffer=es:bx count=cx
	.begin:
		mov 	si, readMsg
		call 	Print
		mov 	di, 0x0005
	.loop:
		push 	ax
		push 	bx
		push 	cx
		call 	LBAtoCHS
		mov 	ah, 0x02 ; Read Sectors
		mov 	al, 0x01 ; count=1
		mov 	ch, byte [trackCHS]
		mov 	cl, byte [sectorCHS]
		mov 	dh, byte [headCHS]
		mov 	dl, byte [DriveNumber]
		int 	0x13
		jnc 	.success
		xor 	ax, ax
		int 	0x13 ; reset disk
		dec 	di
		pop 	cx
		pop 	bx
		pop 	ax
		jnz 	.loop
		int 	0x18
	.success:
		mov 	si, progressMsg
		call 	Print
		pop 	cx
		pop 	bx
		pop 	ax
		add 	bx, word [BytesPerSector]
		inc 	ax
		loop 	.loop
		mov 	si, endReadMsg
		call 	Print
		ret



CHStoLBA: ; Convert Cylinder-Head-Sector format to Logical Block Addressing format --- ax=CHS
		sub 	ax, 0x0002
		xor 	cx, cx
		mov 	cl, byte [SectorsPerCluster]
		mul 	cx
		add		ax, word [RootDirSector]
		ret ; LBA = (cluster - 2) * SectorsPerCluster



LBAtoCHS: ; Convert Logical Block Addressing format to Cylinder-Head-Sector Format --- ax=LBA
		xor		dx, dx
		div 	word [SectorsPerTrack]
		inc 	dl
		mov 	byte [sectorCHS], dl ; sector = (LBA % SectorsPerTrack) + 1
		xor		dx, dx
		div 	word [HeadsPerCylinder]
		mov 	byte [headCHS], dl ; head = (LBA / SectorsPerTrack) % NumberOfHeads
		mov 	byte [trackCHS], al ; track = LBA / (SectorsPerTrack * NumberOfHeads)
		ret


	
Print: ; Print string --- si=pointer to string
		push ax
.loop:
		lodsb
		cmp 	al, 0x0000 ; Break if a \0 is found or si is invalid
		je 		.done
		mov 	ah, 0x0E ; Print char in al
		int 	0x10
		jmp 	.loop
.done:
		pop ax
		ret



loader:
		;******** ENTRY POINT ********;
		; Begin at segment 0x07C0
		cli
		mov		ax, 0x07C0
		mov		ds, ax
		mov		es, ax
		mov		fs, ax
		mov		gs, ax
		xor		ax, ax 
		mov		ss, ax
		mov		sp, 0xFFF
		sti
	
		mov		si, startMsg
		call	Print

		;******** LOAD FILE SYSTEM ********;

		; Calculate size of root directory
		; -->size = (RootEntires * 32 bytes) / BytesPerSector
		xor		cx, cx
		xor		dx, dx
		mov		ax, 0x0020 
		mul		word [RootEntries]
		div		word [BytesPerSector]
		xchg	ax, cx
		
		; Calculate location of root directory
		; -->location = (NumFATS * SectorsPerFAT) + ReservedSectors
		mov		al, byte [NumFATs]
		mul		word [SectorsPerFAT]
		add		ax, word [ReservedSectors]
		mov		word [RootDirSector], ax
		add		word [RootDirSector], cx

		mov		bx, 0x0200 ; Read into ES:0x0200
		call 	ReadSectors

		;******** LOCATE STAGE 2 ********;

		mov 	cx, word [RootEntries] ; Iterate over each root entry and search for boot2.bin
		mov 	di, 0x0200 ; Offset of first root entry
	.loop:
		push 	cx
		mov 	cx, 0x000B ; Filenames are 11 bytes long
		mov 	si, Stage2Name
		push 	di
		repe	cmpsb ; Compare the target and current file name 
		pop 	di
		je		LoadFAT ; Continue on to loading FAT if comparison was successful
		pop 	cx
		add 	di, 0x0020 ; Each entry is 32 bytes
		loop 	.loop
		jmp 	failure

		;******** LOAD FILE ALLOCATION TABLE ********;
	
	LoadFAT:
		mov 	dx, word [di + 0x001A] ; FAT Entry: Byte 26 - First Cluster
		mov 	word [Stage2Cluster], dx ; Save starting cluster to read later

		xor 	ax, ax
		mov 	al, byte [NumFATs] ; FAT sector count = NumFATs * SectorsPerFAT
		mul 	word [SectorsPerFAT]
		mov 	cx, ax

		mov 	ax, word [ReservedSectors] ; Start after reserved sectors
		
		mov 	bx, 0x0200
		call 	ReadSectors ; Read the FAT into ES:0x0200

		;******** LOAD STAGE 2 BOOTLOADER ********;

		mov 	ax, 0x0050 ; 0x0050:0x0000
		mov 	es, ax
		xor		bx, bx
		push 	bx
	LoadStage2:
		mov 	ax, word [Stage2Cluster]
		pop 	bx
		call	CHStoLBA
		xor 	cx, cx
		mov		cl, byte [SectorsPerCluster]
		call 	ReadSectors
		push bx
	
		mov		ax, word [Stage2Cluster] ; Next cluster
		mov 	cx, ax
		mov 	dx, ax
		shr 	dx, 0x0001
		add		cx, dx
		mov 	bx, 0x0200
		add 	bx, cx
		mov		dx, word [bx]
		test	ax, 0x0001
		jnz		.odd
	.even:
		and		dx, 0000111111111111b ; bitwise AND 12 lower bits if even cluster
		jmp 	.done
	.odd:
		shr 	dx, 0x0004 ; /= 0x10 if odd cluster
	.done:
		mov		word [Stage2Cluster], dx
		cmp 	dx, 0x0FF0 ; End of cluster should be 0x0FF0
		jb		LoadStage2
	finish:
		jmp 	0x0050:0x0000

	failure:
		mov 	si, failMsg
		call	Print
		xor		ax, ax ; wait on keypress
		int 	0x16
		int 	0x19 ; reboot

RootDirSector: dw 0x0000

Stage2Cluster db 0x0000
Stage2Name: db "BOOT2   BIN"

sectorCHS: db 0x00
headCHS: db 0x00
trackCHS: db 0x00

startMsg: db "Beginning Stage 1 Bootloader", 0x0D, 0x0A, 0x00
failMsg: db "Read Error: Press Any Key to Reboot...", 0x0A, 0x00

readMsg: db "Reading Sectors [", 0x00
endReadMsg: db "]", 0x0D, 0x0A, 0x00
progressMsg: db "#", 0x00

	times 510-($-$$) db 0
	dw 0xAA55
