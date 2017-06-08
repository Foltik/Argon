#ifndef _VGA_H
#define _VGA_H

extern void VGA_Clear(const unsigned short c);
extern void VGA_Puts(char* str);
extern unsigned VGA_Printf(const char* str, ...);
extern unsigned VGA_SetColor(const unsigned c);
extern void VGA_GotoXY(unsigned x, unsigned y);

#endif
