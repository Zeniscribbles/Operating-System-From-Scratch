[BITS 16]       ;Directive: Boot code is running in 16=bit mode. (Push and pop
                ;           instructions are 2 bytes in 16-bit mode.)


[ORG 0x7e00]    ;Directive: Loader runs at address 0x7e00

;start: The start of the loader. Printing message Loader start.
start:  
    mov ah,0x13         ;
    mov al,1
    mov bx,0xa
    xor dx,dx
    mov bp,Message
    mov cx,MessageLen 
    int 0x10
    
End:
    hlt
    jmp End

Message:    db "loader starts"
MessageLen: equ $-Message