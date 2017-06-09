#if defined(__linux__) || defined(WIN32) || !defined(__i386__)
#error "Incompatible Compiler"
#endif

#include <string.h>
#include <stdint.h>
#include <size_t.h>

#include "vga.h"

uint8_t posX = 0, posY = 0;
uint16_t style = 0x70;

void putc(unsigned char c);
void puts(char* str);

void kmain(void) {
	VGA_SetClearColor(0x17);
	VGA_Clear(0x17);
	VGA_SetColor(0x17);
	VGA_Puts("Welcome to the ArgonOS Kernel!\n");
	VGA_Printf("String:[%s], Char:[%c]\n", "Test String!", '!');
	VGA_Printf("The number 123 in base10 = %d\n", 123);
	VGA_Printf("The number 291 in base16 = 0x%x\n", 291);
	VGA_Puts("Goodbye!\n");
	VGA_Puts("Let's count to 100!\n");
	for (int i = 1; i <= 100; i++) {
		VGA_Printf("%d\n", i);
		for(int i = 0; i < 2000000; i++)
			VGA_SetColor(0x17); // Waste Time
	}
	VGA_Puts("Done!");
loop:
	goto loop;
}
