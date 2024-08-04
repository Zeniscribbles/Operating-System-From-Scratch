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

;Set up the Disk Address Packet (DAP) for extended read
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
    int 0x15              ;Call BIOS interrupy 0x15 ().
    jc  NotSupport

GetMemoryInfo:
    add edi, 20             ;Set edi to point to the next memory address
    mov eax, 0xe820       ;Pass 0xe820 to eax.
    mov edx, 0x534d4150   ;ASCHII code for the s-map to edx.
    mov ecx, 20           ;Save length of the memory block [20] to edx.
    int 0x15
    jc GetMemoryDone

    test ebx, ebx
    jnz GetMemoryInfo

GetMemoryDone:
    mov ah,0x13             ;Set AH to 0x13 (write string function).      
    mov al,1                ;Set AL to 1 (write mode).
    mov bx,0xa              ;Set BX to page number 0xa.
    xor dx,dx               ;Clear DX (row and column).
    mov bp, Message         ;Load the address of the message into BP.
    mov cx, MessageLen      ;Set CX to the length of the message.
    int 0x10                ;Call BIOS interrupt 0x10 to display the message.

ReadError:
NotSupport:
End:
    hlt         ;Halt the CPU.
    jmp End     ;Infinite loop to prevent execution past the end.


DriveID:    db 0                        ;Variable to store the drive ID.
Message:    db "Get Memory Info done"   ;Success message string.
MessageLen: equ $-Message               ;Length of the success message string.
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