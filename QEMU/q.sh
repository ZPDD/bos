#!/bin/bash

# Runs QEMU for BOS. Uses the same HT3.VHD for the harddrive image file.
#
# May 21, 2021 - David Borsato.

# NOTE: The last line is commented out. Use this if you want to enable GDB or
#       LLDB (on MAC) to debug.

 qemu-system-x86_64 -drive format=vpc,file=ht3.vhd -d cpu_reset -monitor stdio \
  -device e1000,netdev=net0, -netdev user,id=net0,hostfwd=tcp::80-:80 \
  -device sb16 -audiodev coreaudio,id=coreaudio,out.frequency=48000,out.channels=2,out.format=s32 \
  # -s -S
