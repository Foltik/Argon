#include <stdint.h>
#include <string.h>
#include <stdarg.h>
#include "vga.h"

#define VRAM 0xB8000

// 0 < x < 80
// 0 < y < 25
static unsigned _posx = 0;
static unsigned _posy = 0;
static unsigned _startx = 0;
static unsigned _starty = 0;
static unsigned _color = 0;
static unsigned _ccolor = 0;

void VGA_Scroll() {
	for (int y = 0; y < 24; y++) {
		for (int x = 0; x < 80; x++) {
		    uint8_t* this = (uint8_t*)(VRAM + (x * 2) + (y * 2 * 80));
			uint8_t* next = (uint8_t*)(VRAM + (x * 2) + ((y + 1) * 2 * 80));

			*this++ = *next++;
			*this = *next;
		}
	}
	for (int x = 0; x < 80; x++) {
		uint8_t* this = (uint8_t*)(VRAM + (x * 2) + (24 * 2 * 80)); 
		
		*this++ = ' ';
		*this = _ccolor;
	}
}

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
	if (base < 2 || base > 16 || i == 0) {
		buf[0] = '0';
		buf[1] = '\0';
		return;
	}

	if (i < 0)
		*buf++ = '-';

	_itoa_imp(iabs(i), base, buf);
}

void VGA_Putc(unsigned char c) {
	if (c == '\0')
		return;

	if (c == '\n' || c == '\r') {
		if (_posy == 24) {
			VGA_Scroll();
			_posx = _startx;
			return;
		} else {
			_posy++;
			_posx = _startx;
			return;
		}
	}

	if (_posx > 79) {
        if (_posy == 24) {
            VGA_Scroll();
            _posx = _startx;
        } else {
            _posy++;
            _posx = _startx;
        }
	}

    uint8_t* p = (uint8_t*)(VRAM + (_posx++ * 2) + (_posy * 2 * 80));
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
	_posx = x;
	_posy = y;

	_startx = _posx;
	_starty = _posy;
}

void VGA_Clear() {
	for (int y = 0; y < 25; y++) {
		for (int x = 0; x < 80; x++) {
		    uint8_t* p = (uint8_t*)(VRAM + (x * 2) + (y * 2 * 80));
			*p++ = ' ';
			*p = _ccolor;
		}
	}

	_posx = _startx;
	_posy = _starty;
}

void VGA_SetColor(const unsigned c) {
	_color = c;
}

void VGA_SetClearColor(const unsigned c) {
	_ccolor = c;
}
