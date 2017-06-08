#include <stdint.h>
#include <string.h>
#include <stdarg.h>
#include "vga.h"

#define VRAM 0xB8000

static unsigned _posx = 0;
static unsigned _posy = 0;
static unsigned _startx = 0;
static unsigned _starty = 0;
static unsigned _color = 0;

unsigned iabs(int32_t i) {
	if (i >= 0)
		return (unsigned)i;
	return (UINT32_MAX - (unsigned)i) + 1U;
}

void _itoa_imp(unsigned i, unsigned base, char* buf) {
	static const char* digits = "0123456789ABCDEF";
	char tbuf[32];

	unsigned pos = 0;
	unsigned npos = 0;
	unsigned end = 0;

	while(i != 0) {
		tbuf[pos++] = digits[i % base];
		i /= base;
	}
	end = pos--;

	while(npos < end)
		buf[npos++] = tbuf[pos--]; 

	buf[npos] = '\0';
}

void itoa_s(int i, unsigned base, char* buf) {
	if (base < 2 || base > 16) {
		buf[0] = '0';
		buf[1] = '\0';
		return;
	}

	if (i < 0)
		*buf++ = '-';

	_itoa_imp(iabs(i), base, buf);
}

void VGA_Putc(unsigned char c) {
	if (c == 0)
		return;

	if (c == '\n' || c == '\r') {
		_posy += 2;
		_posx = _startx;
		return;
	}

	if (_posx > 79) {
		_posy += 2;
		_posx = _startx;
		return;
	}

	uint8_t* p = (uint8_t*)(VRAM + (_posx++)*2 + _posy * 80);
	*p++ = c;
	*p = _color;
}



unsigned VGA_Printf(const char* str, ...) {
	int count = 0;

	if(!str)
		return count;

	va_list args;
	va_start(args, str);

	for (size_t i = 0; i < strlen(str); i++) {
		switch(str[i]) {
			case '%': {
				switch(str[i + 1]) {
					case '%': {
						VGA_Putc('%');
						i++;
						count++;
						break;
					}
					
					case 'c': {
						char c = va_arg(args, char);
						VGA_Putc(c);
						i += 2;
						count++;
						break;
					}

					case 's': {
						char* s = va_arg(args, char*);
						VGA_Puts(s);
						count += strlen(s);
						i += 2;
						break;
					}
					
					case 'd':
					case 'i': {
						int n = va_arg(args, int);
						char s[32];
						itoa_s(n, 10, s);
						VGA_Puts(s);
						count += strlen(s);
						i += 2;
						break;
					}
					
					case 'X':
					case 'x': {
						int n = va_arg(args, int);
						char s[32];
						itoa_s(n, 16, s);
						VGA_Puts(s);
						count += strlen(s);
						i += 2;
						break;
					}

					case 'n': {
						unsigned* n = va_arg(args, unsigned*);
						*n = count;
						i += 2;
						break;	
					}

					default: {
						va_end(args);
						return count;
					}
				}
			}
			default:
				VGA_Putc(str[i]);
				break;
		}
	}

	va_end(args);
	return count;
}

void VGA_Puts(char* str) {
	if (!str)
		return;

	for (size_t i = 0; i < strlen(str); i++)
		VGA_Putc(str[i]);	
}

void VGA_GotoXY(unsigned x, unsigned y) {
	_posx = x * 2;
	_posy = y * 2;

	_startx = _posx;
	_starty = _posy;
}

void VGA_Clear(const unsigned short c) {
	uint8_t* p = (uint8_t*)VRAM;
	
	for (size_t i = 0; i < 160 * 30; i += 2) {
		p[i] = ' ';
		p[i + 1] = c;
	}

	_posx = _startx;
	_posy = _starty;
}

unsigned VGA_SetColor(const unsigned c) {
	unsigned old = _color;
	_color = c;
	return old;
}
