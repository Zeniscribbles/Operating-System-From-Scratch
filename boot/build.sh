#!/bin/bash
#Make sure to change from CLRF to LF [end of line sequence]
# Ensure that boot.asm exists
if [ ! -f boot.asm ]; then
  echo "'boot.asm' not found in the current directory."
  ls -l
  exit 1
fi

# Assemble the boot.asm file to a binary file
echo "Assembling boot.asm..."
nasm -f bin -o boot.bin boot.asm

# Check if nasm was successful
if [ $? -ne 0 ]; then
  echo "Assembly failed."
  exit 1
fi

# Verify that boot.bin was created
if [ ! -f boot.bin ]; then
  echo "'boot.bin' not found after assembly."
  exit 1
fi

# Create a bootable image from the binary file
echo "Creating bootable image..."
dd if=boot.bin of=boot.img bs=512 count=1 conv=notrunc

# Check if dd was successful
if [ $? -ne 0 ]; then
  echo "Failed to create bootable image."
  exit 1
fi

echo "Bootable image created successfully: boot.img"