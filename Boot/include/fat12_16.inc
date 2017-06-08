;******** fat12_16.inc ********;
; Functions for reading 
; sectors and working with 
; the FAT12 file system.
;******************************;

		bits	16
		
; FAT12 BIOS Parameter Block
		BytesPerSector:     dw 512
		SectorsPerCluster:  db 1
		ReservedSectors:    dw 1
		NumFATs:            db 2
		RootEntries:        dw 224
		TotalSectors:       dw 2880
		MediaDescriptor:    db 0xF0
		SectorsPerFAT:      dw 9
		SectorsPerTrack:    dw 18
		HeadsPerCylinder:   dw 2
		HiddenSectors:      dd 0
		LargeSectors:       dd 0
		DriveNumber:        db 0
		Unused:             db 0
		BootSignature:      db 0x29
		VolumeID:           dd 0x13333337
		VolumeLabel:        db "ARGONFLOPPY"
		FileSystem:         db "FAT12   "


		absTrack: db 0x00
		absSector: db 0x00
		absHead: db 0x00
		
		rootDirSector: dw 0x0000
		fileCluster: dw 0x0000

ReadSectors:
; Read sequential sectors from disk and store them in memory
; ax = Starting sector
; es:bx = Location to write
; cx = Number of sectors to read
	.begin:
		mov		di, 3 ; 3 Retries 
	.loop:
		; Convert starting sector into CHS
		push	ax
		push	bx
		push	cx
		call 	LBAtoCHS
		
		; Call bios read disk function
		mov		ah, 0x2 ; 0x2 = Read Sectors
		mov		al, 1 ; Read 1 sector
		mov		ch, byte [track]
		mov		cl, byte [sector]
		mov		dh, byte [head]
		mov		dl, byte [DriveNumber]
		int 	0x13
		jnc 	.success
		
		; If the read failed, reset the disk and try again for di times,
		; displaying a boot error message if tries run out
		xor		ax, ax
		int 	0x13
		dec		di
		pop		cx
		pop		bx
		pop		ax
		jnz		.loop
		int		0x18

	.success:
		; Increase the offset of the write location and
		; increment the starting sector, looping based on count
		pop		cx
		pop		bx
		pop		ax
		add		bx, word [BytesPerSector]
		inc		ax
		loop	.loop
		
		ret


LBAtoCHS:
; Convert an LBA sector to a Cylinder, Head, and Sector
; Turns a linear track number to a multi-dimensional array indexed by Cylinder, Head, and Sector
; ax = LBA sector
		push	dx

		; absSector = sector % SectorsPerTrack
		xor		dx, dx
		div		word [SectorsPerTrack] ; store remainder (absSector) in dl, al now contains (sector / SectorsPerTrack)
		inc		dl ; Sectors start counting at 1
		mov		byte [sector], dl
		
		; absHead = (sector / SectorsPerTrack) % NumberOfHeads
		; absTrack = sector / (SectorsPerTrack * NumberOfHeads)
		xor		dx, dx
		div		word [HeadsPerCylinder] ; store remainder (absHead) in dl, al now contains the track
		mov		byte [head], dl
		mov		byte [track], al
		
		pop		dx
		ret


ClusterToLBA:
; Convert a FAT12 cluster number to an LBA sector as an offset from the root directory
; ax = cluster
		push 	dx

		; LBA sector = (cluster - 2) * SectorsPerCluster
		sub		ax, 2
		xor		dx, dx
		mov		dl, byte [SectorsPerCluster]
		mul		dx
		add		ax, word [RootDirSector]
		
		pop		dx
		ret


LoadRootDirectory:
		pusha
		push	es
		
		; size = (RootEntries * 32 bytes) / BytesPerSector
		mov		ax, 32
		mul		word [RootEntires]
		div		word [BytesPerSector]
		mov		bx, ax
		
		; sector = (NumFATs * SectorsPerFat) + ReservedSectors
		xor		ax, ax
		mov		al, byte [NumFATs]
		mul 	word [SectorsPerFat]
		add		ax, byte [ReservedSectors]
		mov		word [rootDirSector], ax
		add 	word [rootDirSector], bx
		
		; Read into memory at 0x7E00
		mov		bx, 0x07E0
		mov		es, bx
		mov		bx, 0x0000
		call 	ReadSectors

		pop		es
		popa
		ret


LoadFAT:
		pusha
		push	es
		
		xor		ax, ax
		mov		al, byte [NumberOfFATs]
		mul		word [SectorsPerFAT]
		mov		cx, ax
		
		mov		ax, word [ReservedSectors]

		xor		bx, bx
		mov		es, bx
		mov		bx, 0x7c0
		call 	ReadSectors

		pop		es
		popa
		ret


LoadFile:
; Searches for a file in the root directory
; and writes it to a buffer
; es:si = filename
; bx:bp = location to write
		push	bx
		push	cx
		push	dx
		
		; Search for file
		mov		bx, si
		mov		cx, word [RootEntries]
		mov		di, 0x7E00 ; Location of root directory
		cld
	.nloop:
		push	cx ; save counter
		mov		cx, 11 ; 11 byte name
		mov		si, bx
		push	di
		repe	cmpsb
		pop		di
		je		.found
		pop		cx
		add		di, 32
		loop	.nloop
		
	.notfound
		pop		dx
		pop		cx
		pop		bx
		mov		ax, -1
	.found
		pop		ax
		pop		dx
		pop		cx
		pop		bx


