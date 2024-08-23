;;; This is the Kernel...A wild byte has appeared

[BITS 64]       ;Directive: Kernel is running in 16=bit mode. [Push and pop
                ;           instructions are 2 bytes in 16-bit mode.]

[ORG 0x200000]  ;Directive: Kernel runs at base address 0x200000


start:
    mov byte[0xb8000],'K'
    mov byte[0xb8001],0xa


End:
    hlt         ;Halt the CPU.
    jmp End     ;Infinite loop to prevent execution past the end.

