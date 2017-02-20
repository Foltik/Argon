Argon
=====

Argon OS is a small 32-bit protected mode OS,
which is being created as a side project. It is not
meant to be, or will it ever be, a full scale production OS.

Building and Running
--------
`make` -- Note: Requires root access to mount and copy boot2.bin to the image
```
qemu-system-x86_64 \
  -boot a \               # Boot FDA
  -fda build/Argon.flp \  # Image to Load
  -m 32 \                 # Change as desired
  -s \                    # For remote GDB debugging at port 1234
  -monitor stdio          # For viewing information about the OS while it is running
```

TODO:
-----

The following are ordered by priority and development order, 
going from next to be implemented to long term goals.

Short Term:

- [x] Stage 1 Bootloader to load and execute Stage 2
- [ ] Stage 2 Bootloader to load and execute the Kernel
- [ ] Kernel Framework
- [ ] Syscalls to print different datatypes
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
