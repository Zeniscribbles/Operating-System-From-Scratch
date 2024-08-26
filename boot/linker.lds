OUTPUT_FORMAT(elf64-x86-64)  /* Specify the output format as 64-bit ELF for the x86-64 architecture */
ENTRY(start)                 /* Set the entry point of the program to the 'start' label */


/* Define the sections of the binary */
SECTIONS {
    . = 0x200000;   /* Set the starting address of the output file to 0x200000 */
    .text : {
        *(.text)    /* Place all .text (code) sections from the input files here */
    }

    .rodata : {
        *(.rodata)  /* Place all .rodata (read-only data) sections here */
    }

    . = ALIGN(16);  /* Align the next section on a 16-byte boundary */
    .data : {
        *(.data)    /* Place all .data (initialized data) sections here */
    }

    .bss : {
        *(.bss)     /* Place all .bss (uninitialized data) sections here */
    }
}