[BITS 16]       ;Directive: Boot code is running in 16=bit mode. (Push and pop
                ;           instructions are 2 bytes in 16-bit mode.)


[ORG 0x7c00]    ;Directive:  BIOS loads the boot code from the first sector 
                ;            into memory address 7c00


;Initilizing the segment registers and stack pointer.
;            Zeroing out the segment registers makes the offset
;            the memory address we want to access.
start:          ;Label: Start of code
    xor ax,ax   ;Zeroing ax register  
    mov ds,ax   ;copying the value of ax into ds, ex, and ss.
    mov es,ax  
    mov ss,ax
    mov sp,0x7c00


TestDiskExtension:
    mov [DriveID],dl
    mov ah,0x41
    mov bx,0x55aa
    int 0x13
    jc NotSupport
    cmp bx,0xaa55
    jne NotSupport


;Loading the loader:
LoadLoader:                 ;The ReadPacket/DriveID Structure:
    mov si,ReadPacket       ;0. Moving the address of ReadPacket to si register.
    mov word[si],0x10       ;1. Structure length 0x10 [16d]
    mov word[si+2],5        ;2. Number of sectors we want to read [5 sectors, small but enough space for loader].
    mov word[si+4],0x7e00   ;3. Memory location that file is read into [The Offset of address].
    mov word[si+6],0        ;4. Memory location that file is read into [The Segment of address].
    mov dword[si+8],1       ;Lower half of 64-bit logical block address.
    mov dword[si+0xc],0     ;Higher half of 64-bit logical block address.
    mov dl,[DriveID]        ;Saving the DriveID before calling DES.
    mov ah,0x42             ;Function code 0x42 in ah (Disk Extension Service).
    int 0x13                ;interupt 13.
    jc  ReadError           ;If interrupt 13 fails

    mov dl,[DriveID]        ;Passing DriveID to loader.Kernal file is loaded using DriveID
    jmp 0x7e00              ;Jump to memory where loader file is loaded from disk

;Replacing the print message with ReadError Message
ReadError:
NotSupport:
    mov ah,0x13
    mov al,1
    mov bx,0xa
    xor dx,dx
    mov bp,Message
    mov cx,MessageLen 
    int 0x10

End:    ;End of code
    hlt ;Processor is placed in halt state.    
    jmp End


DriveID:    db 0
Message:    db "We have an error in boot process"   
MessageLen: equ $-Message
ReadPacket: times 16 db 0       ;A Structure for DriveID to be passed.


;times: A direcective that repeats commands. 
;       '$$' is the begining of the current section.
;       '$-$$' represents the size from the start of the code to 
;        the end of the message.
times (0x1be-($-$$)) db 0  ;How many times db is repeated.

    db 80h                 ;Boot indicator [bootable partition].
    
    ;cylinder-head-sector (CHS): Addressing scheme allows the operating
    ;                            system to specify the exact location of 
    ;                            data on a disk. 
    ;
    ;          The cylinder number specifies the vertical position of the track on all platters.
    ;          The head number specifies which read/write head (and thus which platter surface) is being accessed.
    ;          The sector number specifies the specific sector within the track where the data is located.
    ;
    ;Refer to definitions below.
    db 0,2,0            ;Starting CHS [Cylinder, Head, Sector]
    db 0f0h             ;Type
    db 0ffh,0ffh,0ffh   ;Ending CHS
    dd 1                ;Starting sector
    dd (20*16*63-1)     ;size
	
    times (16*3) db 0

    ;Signature, size of boot 512 bytes.
    db 0x55
    db 0xaa