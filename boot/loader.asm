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

    mov ah,0x13         
    mov al,1
    mov bx,0xa
    xor dx,dx
    mov bp,Message
    mov cx,MessageLen 
    int 0x10


NotSupport:
End:
    hlt
    jmp End


DriveID:    db 0        ;Create DriveID variable
Message:    db "long mode is supported"
MessageLen: equ $-Message