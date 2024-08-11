[BITS 16]       ;Directive: Boot code is running in 16=bit mode. (Push and pop
                ;           instructions are 2 bytes in 16-bit mode.)


[ORG 0x7e00]    ;Directive: Loader runs at address 0x7e00


;start: The start of the loader. Checking for long mode support
start:  
    mov [DriveID], dl   ;Move [DriveID previously saved] dl to DriveID.

    mov eax, 0x80000000 ;pass 0x80000001 to eax. 
    cpuid               ;Returns processor identification and feature information.
    cmp eax, 0x80000001 ;If the written value in eax < 0x80000001 then input value is not supported.
    jb NotSupport       ;Jump if below

    mov eax, 0x80000001 ;Input value: Processor Features.
    cpuid
    test edx, (1<<29)   ;Checking if bit 29  of edx is set.
    jz NotSupport       ;Long mode not supported [zero flag set].
    test edx, (1<<26)   ;Checking if bit 26 of edx is set.
    jz NotSupport       ;1 GB page support Not Supported [zero flag set].

;Loading the Kernel into memeory
LoadKernal:
    mov si, ReadPacket      ;Load the address of ReadPacket into SI.
    mov word[si], 0x10      ;Set the size of the packet structure to 16 bytes.
    mov word[si+2], 100     ;Set the number of sectors to read (100 sectors, 50 KB).
    mov word[si+4], 0       ;Set the low part of the memory address to load to (0).
    mov word[si+6], 0x1000  ;Set the segment part of the memory address to 0x1000.
    mov dword[si+8], 6      ;Set the starting LBA (low 32 bits) to 6.
    mov dword[si+0xc],0     ;Set the starting LBA (high 32 bits) to 0.
    mov dl, [DriveID]         ;Load the drive ID from memory into DL.
    mov ah, 0x42            ;Set AH to 0x42 (extended read function).
    int 0x13                ;Call BIOS interrupt 0x13 to read the sectors.
    jc ReadError            ;If there is an error (carry flag set), jump to ReadError.

GetMemoryInfoStart:    
    mov eax, 0xe820       ;Pass 0xe820 to eax.
    mov edx, 0x534d4150   ;ASCHII code for the s-map to edx.
    mov ecx, 20           ;Save length of the memory block [20] to edx.
    mov edi, 0x9000       ;Save memory block address in edi.
    xor ebx, ebx          ;Zero ebx before calling function.
    int 0x15              ;Call BIOS interrupy 0x15.
    jc  NotSupport        ;If carry flag is set, jump to NotSupport.

GetMemoryInfo:
    add edi, 20           ;Set edi to point to the next memory address
    mov eax, 0xe820       ;Pass 0xe820 to eax.
    mov edx, 0x534d4150   ;ASCHII code for the s-map to edx.
    mov ecx, 20           ;Save length of the memory block [20] to edx.
    int 0x15              ;Call BIOS interrupt 0x15.
    jc GetMemoryDone      ;If carry flag is set, jump to GetMemoryDone.

    test ebx, ebx         ;Check if EBX is zero.
    jnz GetMemoryInfo     ;If not zero, continue to get more memory info.

GetMemoryDone:
;Test if the A20 lineis enabled:
;        The A20 line: Also known as the A20 gate, is a legacy hardware feature in 
;        x86 architecture that controls access to the 21st address line (A20) of the 
;        system's address bus. ; The A20 line allows access to memory beyond 1MB, 
;        which is necessary for protected mode.
TestA20:
    mov ax, 0xffff              ;Load AX with 0xFFFF (the highest possible segment value).
    mov es, ax                  ;Load ES with the value of AX (0xFFFF).
    mov word[ds:0x7c00], 0xa200 ;Write a test value (0xA200) to memory at 0x7C00.
    cmp word[es:0x7c10], 0xa200 ;Compare the value at memory address 0xFFFF:0x7C10 with 0xA200.
    jne SetA20LineDone          ;If the values do not match, A20 line is not enabled, jump to SetA20LineDone.
    mov word[0x7c00], 0xb200    ;Write another test value (0xB200) to memory at 0x7C00.
    mov word[es:0x7c10], 0xb200 ;Compare the value at memory address 0xFFFF:0x7C10 with 0xB200.
    je End                      ;If the values match, A20 line is enabled, jump to End.


SetA20LineDone:
    xor ax, ax              ;Zero out ax
    mov es, ax              ;Zero out es

SetVideoMode:
    mov ax, 0x0003          ;Set ax to 0x0003 (80x25 text mode).
    int 0x10                ;Call BIOS interrupt 0x10 to set video mode.

    cli                     ;Clear interrupt flag. Processor will not respond to interrupt.
    lgdt [Gdt32Ptr]         ;Load GDT adress and size [16 bits in 16-bit mode].
    lidt [Idt32Ptr]         ;Load IDT address and size. 

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp  8:PmEntry

ReadError:
NotSupport:
End:
    hlt         ;Halt the CPU.
    jmp End     ;Infinite loop to prevent execution past the end.


[BITS 32]
PmEntry:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x7c00

    mov byte[0xb8000], 'P'
    mov byte[0xb8001], 0xa

PEnd: 
    hlt
    jmp End


DriveID:    db 0                        ;Variable to store the drive ID.
ReadPacket: times 16 db 0               ;Define 16 bytes, each initialized to 0.

;Data structure for the extended read function. 
;Disk Address Packet (DAP) Structure:
;------------------------------------
;Offset	Size (bytes)	Description
;0x00	2	Size of the packet (must be 0x10)
;0x02	2	Number of sectors to read/write
;0x04	2	Low word of the target address
;0x06	2	Segment of the target address
;0x08	4	Starting LBA (Low 32 bits)
;0x0C	4	Starting LBA (High 32 bits)


;Defining the GDT [Global Descriptor Table]
Gdt32:
    dq 0        ;The first GDT entry is always zero, "null descriptor".
                ;It is required by the x86 architecture. It occupies 8 bytes and is used
                ;to prevent accidental use of a null selector.

;Code Segment Descriptor:
code32:
    dw 0xffff   ;Segment limit (lower 16 bits). Set to 0xFFFF, defining the segment's maximum size (4 GB).
    dw 0        ;Base address (lower 16 bits). Set to 0x0000, meaning the code segment starts at address 0x00000000.
    db 0        ;Base address (middle 8 bits). Also set to 0, continuing the base address from the previous line.
    db 0x9a     ;Access byte:
                ;- 1st nibble (9): Sets the segment as a code segment (bit 3), executable (bit 2), readable (bit 1),
                ;accessed (bit 0), and DPL (Descriptor Privilege Level) to 0 (highest privilege).
                ;- 2nd nibble (A): Sets the segment as present (bit 7), and enables the default operation size to 32-bit (bit 6).
    db 0xcf     ;0xcf [hexadecimal] 110111
    db 0        ;Base address (upper 8 bits) Set to 0x0000

;Data Segement Descriptor: 
Data32:
dw 0xffff   ;Segment limit (lower 16 bits). Set to 0xFFFF, defining the segment's maximum size (4 GB).
    dw 0        ;Base address (lower 16 bits). Set to 0x0000, meaning the code segment starts at address 0x00000000.
    db 0        ;Base address (middle 8 bits). Also set to 0, continuing the base address from the previous line.
    db 0x92     ;Access byte: Readable and Writable
                ;- 1st nibble (9): Sets the segment as a code segment (bit 3), executable (bit 2), readable (bit 1),
                ;accessed (bit 0), and DPL (Descriptor Privilege Level) to 0 (highest privilege).
                ;- 2nd nibble (A): Sets the segment as present (bit 7), and enables the default operation size to 32-bit (bit 6).
    db 0xcf     ;0xcf [hexadecimal] 110111
    db 0         ;Base address (upper 8 bits) Set to 0x0000

;Calculating the length of the descriptor table:
Gdt32Len: equ $-Gdt32       ;Length of table: Forst two bytes and address of gdt to the next four bytes.

Gdt32Ptr: dw Gdt32Len-1     ;Size of GDT minus one [2 bytes]
          dd Gdt32          ;Address of GDT [4 bytes].

        
Idt32Ptr: dw 0  ;Set to zero to avoid interrupts before entering long mode
          dd 0  ;The reason is that non-maskable interrupts indicate that 
                ;non-recoverable hardware errors such as ram error, there is no
                ;need to boot our system if errors occur.