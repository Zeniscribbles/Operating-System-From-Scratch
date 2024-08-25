;;; This is the Kernel...A wild byte has appeared

[BITS 64]       ;Directive: Assembling the code for 64-bit mode.
                ;           This directive tells the assembler that the code 
                ;           should be generated for 64-bit execution.

[ORG 0x200000]  ;Directive: The kernel's origin is set to 0x200000.
                ;           This is the base address in memory where the kernel
                ;           is loaded and executed.


;Kernel Start - Entry Point
start:
    mov rdi, Idt               ;Load the address of the Interrupt Descriptor Table (IDT) into RDI.
    mov rax, Handler0          ;Load the address of the interrupt handler (Handler0) into RAX.

    mov [rdi], ax              ;Store the lower 16 bits of the handler address into the IDT entry.
    shr rax, 16                ;Shift the handler address right by 16 bits to access the next 16 bits.
    mov [rdi+6], ax            ;Store these next 16 bits into the IDT entry at offset +6.
    shr rax, 16                ;Shift the handler address right by another 16 bits to access the high 32 bits.
    mov [rdi+8], eax           ;Store the high 32 bits of the handler address into the IDT entry at offset +8.


    lgdt [Gdt64Ptr]            ;Load the 64-bit Global Descriptor Table (GDT).
                               ;This sets up the segment registers for 64-bit mode.
    
    lidt [IdtPtr]              ;Load the Interrupt Descriptor Table (IDT) pointer.
                               ;This sets up the interrupt vector table for handling CPU exceptions and interrupts.


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

    ;Division by zero handling:
    xor rbx, rbx
    div rbx

;Infinite Loop - Kernel Halt
End:
    hlt         ;Halt the CPU.
    jmp End     ;Infinite loop to prevent execution past the end.
                ;Keeps the kernel running in a stable state.

Handler0:
    ;Display the letter 'D' on the screen
    mov byte[0xb8000],'D'      ;Move the ASCII value for 'D' into the first byte of video memory.
                               ;0xb8000 is the start address of the text mode video memory.

    mov byte[0xb8001],0xc      ;Move the color attribute (red on black) into the second byte.
                               ;This sets the color for the character 'D'.
    
    jmp End
    iretq ;Interrupt return, handler done.
     

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


;Defining the IDT (Interrupt Descriptor Table):
;The IDT contains 256 entries, each corresponding to an interrupt or exception.
Idt:
    %rep 256
        dw 0          ;Offset bits 0-15 of the interrupt handler (initially set to 0).
        dw 0x8        ;Segment selector: Points to the code segment in the GDT (typically 0x8).
        db 0          ;Reserved: Must be 0.
        db 0x8e       ;Type and attributes: 0x8E represents a 32-bit interrupt gate descriptor
                      ;with DPL=0 (kernel privilege level) and present bit set.
        dw 0          ;Offset bits 16-31 of the interrupt handler (initially set to 0).
        dd 0          ;Offset bits 32-63 of the interrupt handler (initially set to 0).
        dd 0          ;Reserved: Must be 0.
    %endrep

; Define the length of the IDT:
; IdtLen represents the size of the IDT in bytes, calculated as the current address minus the start of the IDT.
IdtLen: equ $-Idt

; Define the IDT pointer structure:
; IdtPtr contains the size of the IDT (IdtLen-1) and the base address of the IDT (Idt).
IdtPtr: dw IdtLen-1   ; Limit field: Length of the IDT in bytes minus one.
        dq Idt        ; Base field: Address of the IDT.