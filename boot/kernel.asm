;;; This is the Kernel...A wild byte has appeared

[BITS 64]       ;Directive: Kernel is running in 16=bit mode. [Push and pop
                ;           instructions are 2 bytes in 16-bit mode.]

[ORG 0x200000]  ;Directive: Kernel runs at base address 0x200000


start:
    lgdt [Gdt64Ptr]

    push 8
    push KernelEntry
    db 0x48
    retf

KernelEntry:
    mov byte[0xb8000],'K'
    mov byte[0xb8001],0xa


End:
    hlt         ;Halt the CPU.
    jmp End     ;Infinite loop to prevent execution past the end.


Gdt64:  
    dq 0
    dq 0x0020980000000000

Gdt64Len: equ $-Gdt64

Gdt64Ptr: dw Gdt64Len-1
          dq Gdt64
