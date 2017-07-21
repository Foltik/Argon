static __inline void outb(unsigned short port, unsigned char val) {
	__asm__ __volatile__ (
			"outb %b0,%w1"
			: 
			: "a" (val), "Nd" (port)
	);
}
