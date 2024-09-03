#!/bin/bash
#End of Line Sequence: Set to CRLF

#Ensure that boot.asm, loader.asm, and kernel.asm exist
for file in boot.asm loader.asm kernel.asm main.c linker.lds; do
  if [ ! -f $file ]; then
    echo "'$file' not found in the current directory."
    exit 1
  fi
done

#Assemble boot.asm 
echo "Assembling boot.asm..."
nasm -f bin -o boot.bin boot.asm
if [ $? -ne 0 ]; then
  echo "Assembly of boot.asm failed."
  exit 1
fi

#Assemble loader.asm
echo "Assembling loader.asm..."
nasm -f bin -o loader.bin loader.asm
if [ $? -ne 0 ]; then
  echo "Assembly of loader.asm failed."
  exit 1
fi

#Assemble kernel.asm
echo "Assembling kernel.asm..."
nasm -f elf64 -o kernel.o kernel.asm
if [ $? -ne 0 ]; then
  echo "Assembly of kernel.asm failed."
  exit 1
fi

#Assemble trap.asm
echo "Assembling trap.asm..."
nasm -f elf64 -o trapa.o trap.asm
if [ $? -ne 0 ]; then
  echo "Assembly of trap.asm failed."
  exit 1
fi

#Assemble lib.asm
echo "Assembling lib.asm..."
nasm  -f elf64 -o liba.o lib.asm
if [ $? -ne 0 ]; then
  echo "Assembly of lib.asm failed."
  exit 1
fi


#Compile main.c
echo "Assembling main.c..."
gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c main.c
if [ $? -ne 0 ]; then
  echo "Compilation of main.c failed."
  exit 1
fi

echo "Assembling trap.c..."
gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c trap.c
if [ $? -ne 0 ]; then
  echo "Compilation of trap.c failed."
  exit 1
fi


# Link kernel.o and main.o
echo "Linking kernel.o, main.o, trap.o, and lib.o..."
ld -nostdlib -T linker.lds -o kernel kernel.o main.o trapa.o trap.o liba.o
if [ $? -ne 0 ]; then
  echo "Linking failed."
  exit 1
fi


# Convert the kernel to a binary format
echo "Converting kernel to binary format..."
objcopy -O binary kernel kernel.bin
if [ $? -ne 0 ]; then
  echo "Conversion to binary failed."
  exit 1
fi


# Verify that boot.bin, loader.bin, kernel.o, and main.o were created
if [ ! -f boot.bin ]; then
  echo "'boot.bin' not found after assembly."
  exit 1
fi

if [ ! -f loader.bin ]; then
  echo "'loader.bin' not found after assembly."
  exit 1
fi

if [ ! -f kernel.o ]; then
  echo "'kernel.o' not found after assembly."
  exit 1
fi

if [ ! -f main.o ]; then
  echo "'main.o' not found after assembly."
  exit 1
fi 

if [ ! -f trap.o ]; then
  echo "'trap.o' not found after assembly."
  exit 1
fi


#Remove any existing boot.img file
if [ -f boot.img ]; then
  echo "Removing existing boot.img..."
  rm -f boot.img
fi

#Create a 10MB image file
IMAGE_SIZE_MB=10
IMAGE_SIZE_BYTES=$((IMAGE_SIZE_MB * 1024 * 1024))
echo "Creating a ${IMAGE_SIZE_MB}MB bootable image..."
dd if=/dev/zero of=boot.img bs=512 count=$((IMAGE_SIZE_BYTES / 512))  # Create a blank image of the correct size
if [ $? -ne 0 ]; then
  echo "Failed to create boot.img."
  exit 1
fi

#Write boot.bin to the boot image
dd if=boot.bin of=boot.img bs=512 count=1 conv=notrunc
if [ $? -ne 0 ]; then
  echo "Failed to write boot.bin to boot.img."
  exit 1
fi

#Write loader.bin to the boot image
dd if=loader.bin of=boot.img bs=512 count=5 seek=1 conv=notrunc
if [ $? -ne 0 ]; then
  echo "Failed to write loader.bin to boot.img."
  exit 1
fi

echo "Bootable image created successfully: boot.img"

#Write kernel.bin to the boot image
dd if=kernel.bin of=boot.img bs=512 count=100 seek=6 conv=notrunc
if [ $? -ne 0 ]; then
  echo "Failed to write kernel.bin to boot.img."
  exit 1
fi