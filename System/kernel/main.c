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
	//save_boot_info();
	
	VGA_SetClearColor(0x17);
	VGA_Clear(0x17);

	VGA_SetColor(0x17);
	VGA_GotoXY(23, 5);	
	VGA_Puts("+--------------------------------+\n");
	VGA_Puts("| ");
	VGA_SetColor(0x1C);
	VGA_Puts("Welcome to the ArgonOS Kernel!");
	VGA_SetColor(0x17);
   	VGA_Puts(" |\n");
	VGA_Puts("|                                |\n");
	VGA_Puts("|            ");
	VGA_SetColor(0x1C);
	VGA_Puts("Ver. 1");
	VGA_SetColor(0x17);
	VGA_Puts("              |\n");
	VGA_Puts("+--------------------------------+\n\n");
	
	VGA_Printf("String.............%s\nChar...............%c\n", "Test String!", '!');
	VGA_Printf("123d in base10.....%d\n", 123);
	VGA_Printf("291d in base16.....0x%x\n", 291);

	VGA_SetColor(0x12);
	VGA_GotoXY(36, 16);
	VGA_Puts("Goodbye!\n");
	asm(
		"halt:\n"
		"hlt\n"
		"jmp halt\n"
	);
}
