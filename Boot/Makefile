MAKE="make"

all: builddirs assemble compile link mkflp copyfiles cleanbin

clean:
	rm -rf build

builddirs:
	@mkdir -p build
	@mkdir -p build/Boot
	@mkdir -p build/System
	@mkdir -p build/System/kernel

assemble: 
	nasm -f bin -o build/Boot/boot1.bin Boot/boot1.asm
	nasm -f bin -o build/Boot/boot2.bin Boot/boot2.asm

compile:
	i686-elf-gcc -c System/kernel/kernel.c -o build/System/kernel/kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra

link:
	i686-elf-ld -o build/System/kernel/kernel.sys --Ttext 0x100000 --oformat binary build/System/kernel/kernel.o

mkflp:
	rm -f build/Argon.flp
	dd if=/dev/zero of=build/Argon.flp bs=512 count=0 seek=2880
	dd if=build/Boot/boot1.bin of=build/Argon.flp bs=512 seek=0 count=1 conv=notrunc

copyfiles:
	mkdir build/mnt
	sudo mount build/Argon.flp build/mnt
	sudo cp build/Boot/boot2.bin build/mnt
	sudo cp build/System/kernel/kernel.sys build/mnt
	sudo umount build/mnt
	rm -rf build/mnt	

mkiso:
	mkdir build/mnt
	mkdir build/iso
	sudo mount -o loop,ro build/Argon.flp build/mnt
	cp -Rp build/mnt/* build/iso
	cp -p build/Argon.flp build/iso
	mkisofs -pad -b Argon.flp -R -o build/Argon.iso build/iso
	sudo umount build/mnt
	rm -rf build/iso
	rm -rf build/mnt

cleanbin:
	@printf 'Cleaning objects from build/...\n'
	rm -rf build/Boot
	rm -rf build/System
	@printf 'Done!\n'
