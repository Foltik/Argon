MAKE="make"

CC = i686-elf-gcc

CFLAGS = -std=gnu99 -ffreestanding -O2 -Wall -Wextra -fno-exceptions -ISystem/include
LFLAGS = -ffreestanding -O2 -nostdlib -lgcc

BUILDDIR = build

KRNFILES = $(wildcard System/kernel/*.c)
LIBFILES = $(wildcard System/lib/*.c)

OBJ = $(addprefix $(BUILDDIR)/obj/, $(KRNFILES:.c=.o))
LIBOBJ = $(addprefix $(BUILDDIR)/obj/, $(LIBFILES:.c=.o))

all: builddirs assemble compile

clean:
	rm -rf build

builddirs:
	@mkdir -p build
	@mkdir -p build/obj/System/kernel
	@mkdir -p build/obj/System/lib

assemble: 
	nasm -f elf32 System/kernel/bootstrap.asm -o build/obj/System/kernel/bootstrap.o

compile: $(OBJ) $(LIBOBJ)
	$(CC) -T System/kernel/link.ld -o build/Argon.sys build/obj/System/kernel/bootstrap.o $(OBJ) $(LIBOBJ) $(LFLAGS)

$(BUILDDIR)/obj/System/kernel/%.o: System/kernel/%.c
	$(CC) -c $< -o $@ $(CFLAGS)
	
$(BUILDDIR)/obj/System/lib/%.o: System/lib/%.c
	$(CC) -c $< -o $@ $(CFLAGS)

mkiso:
	mkdir build/iso/boot/grub
	sudo mount -o loop,ro build/Argon.flp build/mnt
	cp -Rp build/mnt/* build/iso
	cp -p build/Argon.flp build/iso
	mkisofs -pad -b Argon.flp -R -o build/Argon.iso build/iso
	sudo umount build/mnt
	rm -rf build/iso
	rm -rf build/mnt
