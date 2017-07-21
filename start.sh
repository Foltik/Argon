#!/bin/bash
export NO_AT_BRIDGE=1
qemu-system-x86_64 \
	-hda build/Argon.iso \
	-m 4096 \
	-s \
	-monitor stdio
