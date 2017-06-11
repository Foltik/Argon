MAKE="make"

CC = i686-elf-gcc

CFLAGS = -std=gnu99 -ffreestanding -O2 -Wall -Wextra -fno-exceptions -ISystem/include
LFLAGS = -ffreestanding -O2 -nostdlib -lgcc

BUILDDIR = build

KRNFILES = $(wildcard System/kernel/*.c)
LIBFILES = $(wildcard System/lib/*.c)

OBJ = $(addprefix $(BUILDDIR)/obj/, $(KRNFILES:.c=.o))
LIBOBJ = $(addprefix $(BUILDDIR)/obj/, $(LIBFILES:.c=.o))

all: builddirs assemble compile mkiso

clean:
	rm -rf build

builddirs:
	@mkdir -p build
	@mkdir -p build/obj/System/kernel
	@mkdir -p build/obj/System/lib

assemble: 
	i686-elf-as System/kernel/bootstrap.asm -o build/obj/System/kernel/bootstrap.o

compile: $(OBJ) $(LIBOBJ)
	$(CC) -T System/kernel/link.ld -o build/Argon.sys build/obj/System/kernel/bootstrap.o $(OBJ) $(LIBOBJ) $(LFLAGS)

$(BUILDDIR)/obj/System/kernel/%.o: System/kernel/%.c
	$(CC) -c $< -o $@ $(CFLAGS)
	
$(BUILDDIR)/obj/System/lib/%.o: System/lib/%.c
	$(CC) -c $< -o $@ $(CFLAGS)

mkiso:
	mkdir -p build/iso/boot/grub
	cp -p Boot/grub.cfg build/iso/boot/grub
	cp -p build/Argon.sys build/iso/boot
	grub-mkrescue -o build/Argon.iso build/iso -d /usr/lib/grub/i386-pc
	rm -rf build/iso
