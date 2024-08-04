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
    mov ah,0x13             ;Set AH to 0x13 (write string function).      
    mov al,1                ;Set AL to 1 (write mode).
    mov bx,0xa              ;Set BX to page number 0xa.
    xor dx,dx               ;Clear DX (row and column).
    mov bp, Message         ;Load the address of the message into BP.
    mov cx, MessageLen      ;Set CX to the length of the message.
    int 0x10                ;Call BIOS interrupt 0x10 to display the message.


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

    mov si, Message         ;Load the address of the message into si register.
    mov ax, 0xb800          ;Set ax to 0xB800, which is the base address of the video memory in text mode.
    mov es, ax              ;Move the value in ax (0xB800) to es register, setting es to the video memory segment.
    xor di, di              ;Clear di register (set to 0). di will be used as an offset into the video memory.

    mov cx, MessageLen      ;Setting cx the loop counter to MessageLen

PrintMessage:
    mov al, [si]            ;Load the next character from the message.
    mov [es:di], al         ;Write the character to video memory.
    mov byte[es:di+1], 0xa  ;Write the color attribute (bright green) to the next byte.


    add di, 2               ;Move to the next video memory cell (2 bytes per character)
    add si, 1               ;Move to the next character in the message
    loop PrintMessage       ;Continue until CX (MessageLen) is zero




ReadError:
NotSupport:
End:
    hlt         ;Halt the CPU.
    jmp End     ;Infinite loop to prevent execution past the end.


DriveID:    db 0                        ;Variable to store the drive ID.
Message:    db "Text mode is set"       ;Success message string.
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