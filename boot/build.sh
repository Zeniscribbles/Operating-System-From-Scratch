#!/bin/bash
#End of Line Sequence: Set to CRLF

# Ensure that boot.asm and loader.asm exist
if [ ! -f boot.asm ]; then
  echo "'boot.asm' not found in the current directory."
  exit 1
fi

if [ ! -f loader.asm ]; then
  echo "'loader.asm' not found in the current directory."
  exit 1
fi

# Assemble boot.asm and loader.asm
echo "Assembling boot.asm..."
nasm -f bin -o boot.bin boot.asm
if [ $? -ne 0 ]; then
  echo "Assembly of boot.asm failed."
  exit 1
fi

echo "Assembling loader.asm..."
nasm -f bin -o loader.bin loader.asm
if [ $? -ne 0 ]; then
  echo "Assembly of loader.asm failed."
  exit 1
fi

# Verify that boot.bin and loader.bin were created
if [ ! -f boot.bin ]; then
  echo "'boot.bin' not found after assembly."
  exit 1
fi

if [ ! -f loader.bin ]; then
  echo "'loader.bin' not found after assembly."
  exit 1
fi

# Remove any existing boot.img file
if [ -f boot.img ]; then
  echo "Removing existing boot.img..."
  rm -f boot.img
fi

# Create a 10MB image file
IMAGE_SIZE_MB=10
IMAGE_SIZE_BYTES=$((IMAGE_SIZE_MB * 1024 * 1024))
echo "Creating a ${IMAGE_SIZE_MB}MB bootable image..."
dd if=/dev/zero of=boot.img bs=512 count=$((IMAGE_SIZE_BYTES / 512))  # Create a blank image of the correct size
if [ $? -ne 0 ]; then
  echo "Failed to create boot.img."
  exit 1
fi

# Write boot.bin to the image
dd if=boot.bin of=boot.img bs=512 count=1 conv=notrunc
if [ $? -ne 0 ]; then
  echo "Failed to write boot.bin to boot.img."
  exit 1
fi

# Write loader.bin to the image
dd if=loader.bin of=boot.img bs=512 count=1 seek=1 conv=notrunc
if [ $? -ne 0 ]; then
  echo "Failed to write loader.bin to boot.img."
  exit 1
fi

echo "Bootable image created successfully: boot.img"
