MAKE="make"

all: builddirs assemble mkflp copyboot2 cleanbin

builddirs:
	@mkdir -p build
	@mkdir -p build/bootloader

assemble: 
	@printf 'Assembling Bootloader...\n'
	nasm -f bin -o build/bootloader/boot1.bin bootloader/boot1.asm
	nasm -f bin -o build/bootloader/boot2.bin bootloader/boot2.asm

mkflp:
	@printf '\nCreating Floppy Disk Image...\n'
	dd if=/dev/zero of=build/Argon.flp bs=512 count=0 seek=2880
	dd if=build/bootloader/boot1.bin of=build/Argon.flp bs=512 seek=0 count=1 conv=notrunc
	@printf 'Done!\n'

copyboot2:
	@printf 'Copying Stage 2 Bootloader to Floppy Disk Image...\n'
	mkdir build/mnt
	sudo mount build/Argon.flp build/mnt
	sudo cp build/bootloader/boot2.bin build/mnt
	sudo umount build/mnt
	rm -rf build/mnt
	@printf 'Done!\n'

cleanbin:
	@printf 'Cleaning objects from build/...\n'
	rm -rf build/bootloader
	@printf 'Done!\n'
