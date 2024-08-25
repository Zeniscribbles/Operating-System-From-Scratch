;;; This is the Kernel...A wild byte has appeared

[BITS 64]       ;Directive: Assembling the code for 64-bit mode.
                ;           This directive tells the assembler that the code 
                ;           should be generated for 64-bit execution.

[ORG 0x200000]  ;Directive: The kernel's origin is set to 0x200000.
                ;           This is the base address in memory where the kernel
                ;           is loaded and executed.


;Kernel Start - Entry Point
start:
    lgdt [Gdt64Ptr]            ;Load the 64-bit Global Descriptor Table (GDT).
                               ;This sets up the segment registers for 64-bit mode.
    
    ;Transition to 64-bit Mode
    push 8                     ; Push the code segment selector (CS) for the 64-bit code segment onto the stack.
                               ; Selector 8 corresponds to the segment defined in the GDT.

    push KernelEntry           ; Push the address of the KernelEntry label onto the stack.
                               ; This is where execution will continue after switching to 64-bit mode.

    db 0x48                    ; Emit the REX.W prefix (0x48) for a 64-bit `retf` instruction.
                               ; REX.W is needed for a far return (retf) that pops a 64-bit address.

    retf                       ; Far return: This pops the segment selector (CS) and instruction pointer (RIP) 
                               ; from the stack, effectively jumping to the KernelEntry in 64-bit mode.


;Kernel Entry - 64-bit Mode
KernelEntry:
    ;Display the letter 'K' on the screen
    mov byte[0xb8000],'K'      ;Move the ASCII value for 'K' into the first byte of video memory.
                               ;0xb8000 is the start address of the text mode video memory.

    mov byte[0xb8001],0xa      ;Move the color attribute (light green on black) into the second byte.
                               ;This sets the color for the character 'K'.

;Infinite Loop - Kernel Halt
End:
    hlt         ;Halt the CPU.
    jmp End     ;Infinite loop to prevent execution past the end.
                ;Keeps the kernel running in a stable state.


;64-bit Global Descriptor Table (GDT) Definition
Gdt64:  
    dq 0                       ;Null descriptor: Required by the CPU, it must be the first entry in the GDT.

    dq 0x0020980000000000      ;64-bit code segment descriptor:
                               ;- Base address = 0 (0x00000000)
                               ;- Limit = 4GB (0xFFFFF)
                               ;- Type = Code segment (Execute/Read)
                               ;- DPL = 0 (Privilege level)
                               ;- Present = 1
                               ;- Granularity = 1 (4KB blocks)

; GDT Size and Pointer Setup              
Gdt64Len: equ $-Gdt64          ; Calculate the size of the GDT by subtracting the start address from the current address.

Gdt64Ptr: 
    dw Gdt64Len-1              ; Store the size of the GDT minus one (required format for `lgdt` instruction).
    dq Gdt64                   ; Store the base address of the GDT (where it starts in memory).
