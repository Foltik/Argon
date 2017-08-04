Argon
=====

Argon OS is a small 32-bit protected mode OS,
which is being created as a side project. It is not
meant to be, or will it ever be, a full scale production OS.

Building and Running
--------
`make` -- Build the kernel image


To automatically boot the kernel (multiboot compatible):
```
qemu-system-x86_64 \
  -kernel Build/Argon.sys \  # Kernel Image
  -m 32 \                    # RAM Allocated -- Change as desired
  -s \                       # Enable remote GDB debugging at port 1234
  -monitor stdio             # Enable printing information about the OS while it is running to stdio
```

TODO:
-----

The following are ordered by priority and development order, 
going from next to be implemented to long term goals.

Short Term:

- [x] Stage 1 Bootloader to load and execute Stage 2
- [x] Stage 2 Bootloader to load and execute the Kernel
- [ ] Kernel Framework
- [x] Syscalls to print different datatypes
- [ ] Ring0 shell on boot
- [ ] Filesystem Driver
- [ ] Basic Hardware I/O
- [ ] Interrupt Handling with a custom IVT
- [ ] Exception Handling
- [ ] Ring Separation
- [ ] Multi-Tasking

Long Term:

- [ ] Paging
- [ ] Move to FAT16
- [ ] Move to Long Mode
- [ ] Multi-Threading
