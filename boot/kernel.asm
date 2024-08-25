;;; This is the Kernel...A wild byte has appeared

[BITS 64]       ;Directive: Assembling the code for 64-bit mode.
                ;           This directive tells the assembler that the code 
                ;           should be generated for 64-bit execution.

[ORG 0x200000]  ;Directive: The kernel's origin is set to 0x200000.
                ;           This is the base address in memory where the kernel
                ;           is loaded and executed.


;Kernel Start - Entry Point
start:

    ;Setup IDT entries
    mov rdi, Idt               ;Load the address of the Interrupt Descriptor Table (IDT) into RDI.
    mov rax, Handler0          ;Load the address of the interrupt handler (Handler0) into RAX.

    mov [rdi], ax              ;Store the lower 16 bits of the handler address into the IDT entry.
    shr rax, 16                ;Shift the handler address right by 16 bits to access the next 16 bits.
    mov [rdi+6], ax            ;Store these next 16 bits into the IDT entry at offset +6.
    shr rax, 16                ;Shift the handler address right by another 16 bits to access the high 32 bits.
    mov [rdi+8], eax           ;Store the high 32 bits of the handler address into the IDT entry at offset +8.

 
    mov rax, Timer
    add rdi, 32*16             ;Timer Entry
    mov [rdi], ax              ;Store the lower 16 bits of the handler address into the IDT entry.
    shr rax, 16                ;Shift the handler address right by 16 bits to access the next 16 bits.
    mov [rdi+6], ax            ;Store these next 16 bits into the IDT entry at offset +6.
    shr rax, 16                ;Shift the handler address right by another 16 bits to access the high 32 bits.
    mov [rdi+8], eax  

    ;Load GDT and IDT
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

    ;sti     ;Enable interrupts
   
    ;Prepare for switching to 64-bit mode and call the UserEntry function.
    push 0x18|3         ;Push the code segment selector (CS) with the 64-bit segment (0x18) and privilege level (3).
                        ;This selector is used to access the code segment in 64-bit mode with user privileges.

    push 0x7c00         ;Push the address (0x7c00) where execution will continue after switching to 64-bit mode.
                        ;This address should be where the kernel's 64-bit entry point is located.

    push 0x2            ;Push the value 0x2 onto the stack.
                        

    push 0x10|3         ;Push the stack segment selector (SS) with the 64-bit stack segment (0x10) and privilege level (3).
                        ;This selector is used for the stack segment in 64-bit mode with user privileges.

    push UserEntry      ;Push the address of the UserEntry label onto the stack.
                        ;This is the entry point where execution will continue after switching to 64-bit mode.

    iretq               ;The IRETQ instruction will pop the values off the stack (CS, RIP, and flags) and
                        ;resume execution at the address specified, transitioning to 64-bit mode.

;Infinite Loop - Kernel Halt
End:
    hlt         ;Halt the CPU.
    jmp End     ;Infinite loop to prevent execution past the end.
                ;Keeps the kernel running in a stable state.


UserEntry:
    ;Check the current privilege level by examining the value in the CS (Code Segment) register.
    mov ax, cs              ;Move the value of the CS (Code Segment) register into AX.
                            ;This contains the segment selector and privilege level bits.

    and al, 11b             ;Mask out all but the lower 2 bits of AL.
                            ;The lower 2 bits of the CS register indicate the current privilege level (CPL).
                            ;Ring 3 (user mode) has a privilege level of 3 (binary 11).

    cmp al, 3               ;Compare the result in AL with 3.
                            ;This checks if the current privilege level is Ring 3 (user mode).

    jne UEnd                ;If the current privilege level is not Ring 3 (CPL != 3), jump to UEnd.
                            ;This effectively means if we are not in user mode, skip the following code.

    ;Display 'U' on the screen if the privilege level is Ring 3.
    mov byte[0xb8010], 'U'  ;Move the ASCII value for 'U' into the first byte of video memory at address 0xb8010.
                            ;This sets the character 'U' to be displayed on the screen.

    mov byte[0xb8011], 0xE  ;Move the color attribute (light purple on black) into the second byte of video memory at address 0xb8011.
                            ;This sets the color for the character 'U'.

UEnd:
    jmp UEnd                ;Jump to UEnd and loop indefinitely.
                            ;This halts further execution and keeps the CPU in a stable state.
                            

Handler0:

    ;Saving the state of all general-purpose registers at the start of the interrupt handler,
    ;performs a task (in this case, displaying a character on the screen), and then restoring
    ;the original register values before returning from the interrupt. 

    ;Save the state of all general-purpose registers to preserve their values
    push rax
    push rbx  
    push rcx
    push rdx  	  
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

    ;Display the letter 'D' on the screen
    mov byte[0xb8000],'D'      ;Move the ASCII value for 'D' into the first byte of video memory.
                               ;0xb8000 is the start address of the text mode video memory.

    mov byte[0xb8001], 0xc     ;Move the color attribute (red on black) into the second byte.
                               ;This sets the color for the character 'D'.
    
   
    jmp End      ;Skip the register restoration and jump to the end of the handler

    ;Restore the state of all general-purpose registers
    pop	r15
    pop	r14
    pop	r13
    pop	r12
    pop	r11
    pop	r10
    pop	r9
    pop	r8
    pop	rbp
    pop	rdi
    pop	rsi  
    pop	rdx
    pop	rcx
    pop	rbx
    pop	rax

    iretq  ;Return from the interrupt handler and resume normal execution
     

Timer: 

    ;Save the state of all general-purpose registers to preserve their values
    push rax
    push rbx  
    push rcx
    push rdx  	  
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    
    ;Display the letter 'T' in a different location than 'K'
    mov byte[0xb8020], 'T'  ;Move 'T' into a different location in video memory.
    mov byte[0xb8021], 0xe  ;Color attribute (yellow on black).

    jmp End      ;Skip the register restoration and jump to the end of the handler

    ;Restore the state of all general-purpose registers
    pop	r15
    pop	r14
    pop	r13
    pop	r12
    pop	r11
    pop	r10
    pop	r9
    pop	r8
    pop	rbp
    pop	rdi
    pop	rsi  
    pop	rdx
    pop	rcx
    pop	rbx
    pop	rax

    iretq   ;Return from the interrupt handler and resume normal execution

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
    dq 0x0020f80000000000 
    dq 0x0000f20000000000 

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

