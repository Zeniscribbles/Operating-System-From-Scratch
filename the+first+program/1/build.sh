nasm -f bin -o boot.bin boot.asm

//if [input file], of[output file], bs[block size], 
//count[write boot bin in 1 sector], 
//not runc[do not truncate output file. Boo image remains unchange]
dd if=boot.bin of=boot.img bs=512 count=1 conv=not runc