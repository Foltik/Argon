
		bits 16
		org 0x0500

start:
		jmp loader;


;******** BIOS Parameter Block ********;

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

;******** GLOBAL DESCRIPTOR TABLE ********;

; Definition for the default GDT
gdt:
		; null descriptor
		dd 		0
		dd		0
		; code
		dw		0xFFFF
		dw 		0x0000
		db 		0x0
		db		10011010b
		db 		11001111b
		db		0x0
		; data
		dw 		0xFFFF
		dw 		0x0000
		db		0x0
		db		10010010b
		db		11001111b
		db		0x0
gdtEnd:
gdtPtr:
		dw		gdtEnd - gdt - 1
		dd		gdt


ReadSectors:
; Read sequential sectors from disk and store them in memory
; ax = Starting sector
; es:bx = Location to write
; cx = Number of sectors to read
    .begin:
        mov     di, 3 ; 3 Retries 
    .loop:
        ; Convert starting sector into CHS
        push    ax
        push    bx
        push    cx
        call    LBAtoCHS

        ; Call bios read disk function
        mov     ah, 0x2 ; 0x2 = Read Sectors
        mov     al, 1 ; Read 1 sector
        mov     ch, byte [absTrack]
        mov     cl, byte [absSector]
        mov     dh, byte [absHead]
        mov     dl, byte [DriveNumber]
        int     0x13
        jnc     .success

        ; If the read failed, reset the disk and try again for di times,
        ; displaying a boot error message if tries run out
        xor     ax, ax
        int     0x13
        dec     di
        pop     cx
        pop     bx
        pop     ax
        jnz     .loop
        int     0x18

    .success:
        ; Increase the offset of the write location and
        ; increment the starting sector, looping based on count
        pop     cx
        pop     bx
        pop     ax
        add     bx, word [BytesPerSector]
        inc     ax
        loop    .loop

        ret


LBAtoCHS:
; Convert an LBA sector to a Cylinder, Head, and Sector
; Turns a linear track number to a multi-dimensional array indexed by Cylinder, Head, and Sector
; ax = LBA sector
        push    dx

        ; absSector = sector % SectorsPerTrack
        xor     dx, dx
        div     word [SectorsPerTrack] ; store remainder (absSector) in dl, al now contains (sector / SectorsPerTrack)
        inc     dl ; Sectors start counting at 1
        mov     byte [absSector], dl

        ; absHead = (sector / SectorsPerTrack) % NumberOfHeads
        ; absTrack = sector / (SectorsPerTrack * NumberOfHeads)
        xor     dx, dx
        div     word [HeadsPerCylinder] ; store remainder (absHead) in dl, al now contains the track
        mov     byte [absHead], dl
        mov     byte [absTrack], al

        pop     dx
        ret


ClusterToLBA:
; Convert a FAT12 cluster number to an LBA sector as an offset from the root directory
; ax = cluster
        push    dx

        ; LBA sector = (cluster - 2) * SectorsPerCluster
        sub     ax, 2
        xor     dx, dx
        mov     dl, byte [SectorsPerCluster]
        mul     dx
        add     ax, word [RootDirSector]

        pop     dx
        ret




Print:
		lodsb
		cmp al, 0
		je .done
		mov ah, 0x0E
		int 10h
		jmp Print
	.done:
		ret


startMsg: db "Beginning Stage 2 Bootloader", 0x0D, 0x0A, 0x00
gdtMsg: db "Loading Global Decsriptor Table", 0x0D, 0x0A, 0x00
a20Msg: db "Enabling A20 Gate", 0x0D, 0x0A, 0x00
realMsg: db	"Entering Protected Mode", 0x0D, 0x0A, 0x00

rootMsg: db "Loading Root Dir", 0x0D, 0x0A, 0x00
fatMsg: db "Loading FAT", 0x0D, 0x0A, 0x00
searchMsg: db "Searching for KERNEL.SYS", 0x0D, 0x0A, 0x00
loadingMsg: db "Loading into memory", 0x0D, 0x0A, 0x00
successMsg: db "Success! Kernel loaded to memory!", 0x0D, 0x0A, 0x00
failMsg: db "Failed.....", 0x0D, 0x0A, 0x00

RootDirSector: db 0x0000

absTrack: db 0x0000
absHead: db 0x0000
absSector: db 0x0000

kernelName: db "KERNEL  SYS"
kernelCluster: db 0x0000
kernelSize: dw 0x0000

;******** ENTRY POINT ********;

loader:	
		cli
		xor		ax, ax
		mov		ds, ax
		mov 	es, ax
		mov		ax, 0x9000
		mov		ss, ax
		mov		sp, 0xFFFF
		sti

		mov 	si, startMsg
		call 	Print

		;******** LOAD GDT ********;
		
		mov		si, gdtMsg
		call 	Print
		
		cli
		pusha
		lgdt	[gdtPtr]
		sti
		popa

		;******** ENABLE A20 GATE ********;

		mov		si, a20Msg
		call 	Print
		
		
	.waitIn
		in		al, 0x64
		test	al, 10b
		jnz		.waitIn

		; Send 0xD0 to command register
		mov		al, 0xD0 ; 0xD0 = Read Output Port
		out		0x64, al ; Send ^
	.waitOut:
		in		al, 0x64 ; Read Status Register
		test	al, 1b ; Check output buffer status bit
		jnz 	.waitOut
		
		; Read data port and save
		in		al, 0x60 ; Read data port
		push 	eax 
	.waitIn1:
		in		al, 0x64 ; Read Status Register
		test	al, 10b ; Check input buffer status bit
		jnz		.waitIn1

		; Send 0xD1 to command register
		mov		al, 0xD1 ; 0xD1 = Write Output Port
		out		0x64, al ; Send ^
	.waitIn2:
		in		al, 0x64 ; Read Status Register
		test	al, 10b ; Check output buffer status bit
		jnz 	.waitIn2
		
		; Write modified data to data port
		pop 	eax
		or		al, 10b ; Toggle A20 enable bit
		out		0x60, al ; Write to data port
		
		;******** LOAD ROOT DIRECTORY ********;
		mov		si, rootMsg
		call 	Print
		; size = (RootEntries * 32 bytes) / BytesPerSector
		mov		ax, 32
		mul		word [RootEntries]
		div		word [BytesPerSector]
		mov		cx, ax

		xor		ax, ax
		mov		al, byte [NumFATs]
		mul		word [SectorsPerFAT]
		add		ax, word [ReservedSectors]
		mov		word [RootDirSector], ax
		add		word [RootDirSector], cx

		mov		bx, 0x7E00
		call	ReadSectors

		;******** LOCATE KERNEL ********;
		mov		si, searchMsg
		call	Print

		mov		cx, word [RootEntries]
		mov		di, 0x7E00
	.loop:
		push 	cx
		mov		cx, 11 ; filenames are 11 bytes
		mov		si, kernelName
		push	di
		repe	cmpsb
		pop		di
		je		LoadFAT
		pop		cx
		add		di, 32 ; Increment offset to the next root entry
		loop	.loop
		jmp 	failure
		
		;******** LOAD FAT ********;
	LoadFAT:		
		mov		si, fatMsg
		call	Print

		mov		dx, word [di + 0x001C]
		mov		word [kernelSize], dx ; Store kernel size

		mov		dx, word [di + 0x001A]
		mov		word [kernelCluster], dx ; Store kernel first cluster
		
		xor		ax, ax
		mov		al, byte [NumFATs]
		mul		word [SectorsPerFAT]
		mov		cx, ax
		
		mov		ax, word [ReservedSectors]
		
		mov		bx, 0x7C00
		call	ReadSectors
		
		;******** LOAD KERNEL INTO MEMORY ********;

		mov		bx, 0x3000
		push	bx
	LoadKernel:
		mov		si, loadingMsg
		call	Print

		mov		ax, word [kernelCluster]
		pop		bx
		call	ClusterToLBA
		xor		cx, cx
		mov		cl, byte [SectorsPerCluster]
		call	ReadSectors
		push	bx
		
		mov		ax, word [kernelCluster]
		mov		cx, ax
		mov		dx, ax
		shr		dx, 1
		add		cx, dx
		mov		bx, 0x7C00
		add		bx, cx
		mov		dx, word [bx]
		test	ax, 1
		jnz 	.odd
	.even:
		and 	dx, 0x0FFF
		jmp		.done
	.odd:
		shr		dx, 0x4
	.done:
		mov		word [kernelCluster], dx
		cmp		dx, 0x0FF0
		jb		LoadKernel

		mov		si, successMsg
		call	Print
		jmp 	EnterProtected
	
	failure:
		mov		si, failMsg
		call	Print
		cli
		hlt
		
		;******** ENTER PROTECTED MODE ********;
	EnterProtected:
		mov		esi, realMsg
		call 	Print

		cli
		mov		eax, cr0
		or		eax, 1 ; Set bit 1 of cr0 to enable protected mode
		mov		cr0, eax

		;jmp 	0x8:0x3000 ; Fix CS
	
		;******** COPY KERNEL ********;
	CopyKernel:
		mov		ax, 0x10
		mov		ds, ax
		mov		ss, ax
		mov		es, ax
		mov		esp, 0x90000

		push	es
		
		mov		eax, dword [kernelSize]
		mov		ecx, eax
		xor		ebx, ebx
		mov		es, ebx
		mov		esi, 0x3000
		mov		edi, 0x100000
		rep		movsb
		
		pop		es

		jmp 	0x8:0x100000
		
	

;*********************************** BEGIN 32 BITS ****************************************;

		bits 32

posY: db 0x10
posX: db 0x00

kMsg: db "Loading Kernel", 0x0A, 0x00

KernelLoader:
	
		mov		ax, 0x10 ; 0x10 = Data Selector
		mov		ds, ax
		mov		ss, ax
		mov 	es, ax
		mov		esp, 0x90000 ; Base of stac
	
		mov		si, kMsg 
		call	printstring
		
		cli
		hlt

printstring:
	.loop:
		mov		bl, byte [si]
		cmp		bl, 0
		je		.done
		call 	printchar
		inc		si
		jmp 	.loop
	.done:
		ret

printchar:
		; Print char in bl
		pusha
		
		;calculate location in memory based on coordinates		
		mov		edi, 0xB8000 ; Address of Video Memory
		xor		eax, eax
		mov 	ecx, 0xA0 ; 80 columns * 2 bytes
		mov		al, byte [posY] ; Load Y pos
		mul 	ecx ; y * cols
		push	eax
		mov		al, byte [posX] ; Load X pos
		mov		cl, 0x2
		mul		cl ; x * 2 bytes
		pop 	ecx ; load y * cols into ecx
		add		eax, ecx ; add x
		
		xor		ecx, ecx
		add		edi, eax
		
		cmp		bl, 0x0A
		je		.lf		

		; print the character
		mov		dl, bl
		mov		dh, 0x07 ; light gray text on black background attribute
		mov		word [edi], dx
			
		; update position		
		inc 	byte [posX]
		cmp		byte [posX], 80 ; Check if posX is at the end of the line
		je 		.lf
		jmp		.cursor
	.lf:
		inc		byte [posY]
		mov		byte [posX], 0

	.cursor:
		xor 	eax, eax
		mov		ecx, 80
		mov		al, byte [posY]
		mul 	ecx
		add		al, byte [posX]
		mov		ebx, eax

		mov		dx, 0x03D4
		mov		al, 0x0F
		out 	dx, al
		
		mov		dx, 0x03D5
		mov		al, bl
		out		dx, al

		xor 	eax, eax

		mov		dx, 0x03D4
		mov		al, 0x0E
		out		dx, al
		
		mov		al, bh
		mov		dx, 0x03D5
		out		dx, al
	.done:
		popa
		ret
