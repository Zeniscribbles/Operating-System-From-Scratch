;;; This is the Kernel...A wild byte has appeared
;;;


;Data defined globally:
section .data      

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
    
    dq 0x0020f80000000000      ;64-bit data segment descriptor: Data Segment
                            
    dq 0x0000f20000000000      ;Another data segment descriptor:

TssDesc:
    dw TssLen-1                ;Limit of the TSS segment (size of the TSS structure minus one byte).
                               
    dw 0                       ;Base Address (low 16 bits):
                               ;The lower part of the base address of the TSS segment. This will be combined
                               ;with the other base address fields to form the full 64-bit base address.

    db 0                       ;Base Address (middle 8 bits):
                               ;The middle part of the base address of the TSS segment.

    db 0x89                    ;Type and attribute field:
                               ;- Type = 0x9 (Available 64-bit TSS)
                               ;- DPL = 0 (Privilege level 0, meaning only kernel code can access this TSS)
                               ;- Present bit = 1 (Indicates that the TSS is present in memory)

    db 0                       ;Base Address (high 8 bits):
                               ;The higher part of the base address of the TSS segment.

    db 0                       ;Reserved, typically set to 0.
    
    dq 0                       ;Base Address (upper 32 bits):
                               ;The upper 32 bits of the base address, which are only relevant in 64-bit mode.
                               ;Since this code likely doesn't use addresses beyond 4GB, it's set to 0.

;GDT Size and Pointer Setup              
Gdt64Len: equ $-Gdt64          ; Calculate the size of the GDT by subtracting the start address from the current address.

Gdt64Ptr: 
    dw Gdt64Len-1              ; Store the size of the GDT minus one (required format for `lgdt` instruction).
    dq Gdt64                   ; Store the base address of the GDT (where it starts in memory).



;Defining the Task State Segment (TSS) descriptor:
Tss:
     dd 0                    ;Reserved field, often set to 0. It’s unused and helps align the TSS structure.
    
    dq 0x150000              ;The RSP0 (Stack Pointer for Ring 0) field. This specifies the stack pointer used when
                             ;the CPU transitions from a less privileged level (e.g., user mode) to Ring 0 (kernel mode).
                             ;0x150000 is the address of the stack to be used in kernel mode.

    times 88 db 0            ;Reserved space, setting 88 bytes to 0. This reserves space for other TSS fields that are
                             ;either unused or will be set later. 

    dd TssLen                ;The IO Map Base Address field. This field contains the offset in the TSS at which the 
                             ;I/O permission bit map starts. By setting it to TssLen, the I/O map begins after the end
                             ;of the TSS, effectively disabling it.

TssLen: equ $-Tss           ;Calculate the length of the TSS by subtracting the address of the TSS from the current 
                            ;address (`$`). This gives the size of the TSS structure, which is used in the GDT.


;Start of the text section, where the code resides.
;The .text section typically contains executable instructions.
section .text   
extern KernelMain       ;Declare the external symbol, 'KernelMain' function is defined in another module (or file),
                        ;linker needs to resolve this reference during linking.

global start            ;The 'start' label is the entry point of the program,
                        ;so that the linker or loader knows where to begin execution.

;Kernel Start - Entry Point
start:
    lgdt [Gdt64Ptr]            ;Load the 64-bit Global Descriptor Table (GDT).
                               ;This sets up the segment registers for 64-bit mode.
   

;Setting the Task State Segment (TSS):
SetTss:
    mov rax, Tss               ;Load the base address of the Task State Segment (TSS) into RAX register.
                               ;This address will be used to set up the TSS descriptor.

    ;Update the TSS Descriptor with the base address of the TSS.
    mov [TssDesc + 2], ax      ;Store the lower 16 bits of the TSS base address into TssDesc+2.
    shr rax, 16                ;Shift the base address right by 16 bits to access the next 16 bits.
    mov [TssDesc + 4], al      ;Store these next 16 bits into TssDesc+4.
    shr rax, 8                 ;Shift the base address right by 8 bits to access the next 8 bits.
    mov [TssDesc + 7], al      ;Store these next 8 bits into TssDesc+7.
    shr rax, 8                 ;Shift the base address right by 8 bits to access the final 8 bits.
    mov [TssDesc + 8], eax     ;Store the remaining 32 bits of the base address into TssDesc+8.

    mov ax, 0x20            ;Load the TSS selector (0x20) into AX register.
                            ;This selector points to the TSS descriptor in the GDT.

    ltr ax                  ;Load the Task Register (TR) with the TSS selector.
                            ;This sets up the task state segment for task switching and other task-related operations.


;Initialize the Programmable Interval Timer (PIT)
InitPIT:
    mov al, (1<<2)|(3<<4)
    out 0x43, al            ;Write value in al to th register [mode command: 0x43]

    mov ax, 11931           ;Set the PIT to generate an interrupt every 1000ms (1s)
    out 0x40, al            ;Write the low byte of the value in ax to the PIT counter low register [0x40]
    mov al, ah              ;Move the high byte of the value in ax to al
    out 0x40, al            ;Write the high byte of the value in ax to the PIT counter high register [0x40]


 ;Initialize the Programmable Interrupt Controller (PIC)
InitPIC:                     
    mov al, 0x11              ;Initialize command for PIC.
    out 0x20, al              ;PIC master command register.
    out 0xa0, al              ;PIC slave command register.

    mov al, 32                ;Set PIC master vector offset.
    out 0x21, al              ;PIC master data register.
    mov al, 40                ;Set PIC slave vector offset.
    out 0xa1, al              ;PIC slave data register.

    mov al, 4                 ;Configure PIC cascade.
    out 0x21, al              ;PIC master data register.
    mov al, 2                 ;Configure PIC cascade.
    out 0xa1, al              ;PIC slave data register.

    mov al, 1                 ;Set PIC mode (0 = 8086, 1 = 80x86).
    out 0x21, al              ;PIC master data register.
    out 0xa1, al              ;PIC slave data register.

    mov al, 11111110b         ;Unmask all IRQs except IRQ2.
    out 0x21, al              ;PIC master data register.
    mov al, 11111111b         ;Unmask all IRQs on the slave PIC.
    out 0xa1, al              ;PIC slave data register

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
    xor ax, ax
    mov ss, ax
    
    mov rsp, 0x200000
    call KernelMain
    sti 

;Infinite Loop - Kernel Halt
End:
    hlt         ;Halt the CPU.
    jmp End     ;Infinite loop to prevent execution past the end.
                ;Keeps the kernel running in a stable state.
