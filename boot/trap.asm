section .text
extern handler

;Declare global symbols for interrupt vectors
;vector 9 & 15: Coproccesor segment overrun, reserved.
global vector0       ;Vector 0: Division by zero error
global vector1       ;Vector 1: Debug exception
global vector2       ;Vector 2: Non-maskable interrupt (NMI)
global vector3       ;Vector 3: Breakpoint exception
global vector4       ;Vector 4: Overflow exception
global vector5       ;Vector 5: Bound range exceeded
global vector6       ;Vector 6: Invalid opcode
global vector7       ;Vector 7: Device not available
global vector8       ;Vector 8: Double fault
global vector10      ;Vector 10: Invalid TSS (Task State Segment)
global vector11      ;Vector 11: Segment not present
global vector12      ;Vector 12: Stack fault
global vector13      ;Vector 13: General protection fault
global vector14      ;Vector 14: Page fault
global vector16      ;Vector 16: x87 Floating-point exception
global vector17      ;Vector 17: Alignment check
global vector18      ;Vector 18: Machine check
global vector19      ;Vector 19: SIMD Floating-point exception
global vector32      ;Vector 32: System call interrupt
global vector39      ;Vector 39: Custom or specific hardware interrupt
global eoi           ;Global symbol for End Of Interrupt (EOI) function
global read_isr      ;Global symbol for function to read the Interrupt Service Register (ISR)
global load_idt      ;Global symbol for function to load the Interrupt Descriptor Table (IDT)


Trap:
    push rax             ;Save the value of the rax register
    push rbx             ;Save the value of the rbx register
    push rcx             ;Save the value of the rcx register
    push rdx             ;Save the value of the rdx register
    push rsi             ;Save the value of the rsi register
    push rdi             ;Save the value of the rdi register
    push rbp             ;Save the value of the rbp register
    push r8              ;Save the value of the r8 register
    push r9              ;Save the value of the r9 register
    push r10             ;Save the value of the r10 register
    push r11             ;Save the value of the r11 register
    push r12             ;Save the value of the r12 register
    push r13             ;Save the value of the r13 register
    push r14             ;Save the value of the r14 register
    push r15             ;Save the value of the r15 register

    inc byte[0xb8010]     ;Increment the byte at address 0xb8010 (for debugging or tracking)
    mov byte[0xb8011],0xe ;Move the value 0xe to address 0xb8011 (for debugging or tracking)

    mov rdi,rsp         ;Move the stack pointer to the rdi register
    call handler        ;Call the interrupt handler


TrapReturn:
    pop r15             ;Restore the value of the r15 register
    pop r14             ;Restore the value of the r14 register
    pop r13             ;Restore the value of the r13 register
    pop r12             ;Restore the value of the r12 register
    pop r11             ;Restore the value of the r11 register
    pop r10             ;Restore the value of the r10 register
    pop r9              ;Restore the value of the r9 register
    pop r8              ;Restore the value of the r8 register
    pop rbp             ;Restore the value of the rbp register
    pop rdi             ;Restore the value of the rdi register
    pop rsi             ;Restore the value of the rsi register
    pop rdx             ;Restore the value of the rdx register
    pop rcx             ;Restore the value of the rcx register
    pop rbx             ;Restore the value of the rbx register
    pop rax             ;Restore the value of the rax register
    add rsp,16          ;Adjust the stack pointer (clean up stack if needed)
    iretq               ;Return from the interrupt and restore flags and instruction pointer


vector0:
    push 0              ;Push interrupt vector number 0
    push 0              ;Push additional data for vector 0
    jmp Trap            ;Jump to the Trap handler

vector1:
    push 0              ;Push interrupt vector number 1
    push 1              ;Push additional data for vector 1
    jmp Trap            ;Jump to the Trap handler

vector2:
    push 0              ;Push interrupt vector number 2
    push 2              ;Push additional data for vector 2
    jmp Trap            ;Jump to the Trap handler

vector3:
    push 0              ;Push interrupt vector number 3
    push 3              ;Push additional data for vector 3
    jmp Trap            ;Jump to the Trap handler

vector4:
    push 0              ;Push interrupt vector number 4
    push 4              ;Push additional data for vector 4
    jmp Trap            ;Jump to the Trap handler

vector5:
    push 0              ;Push interrupt vector number 5
    push 5              ;Push additional data for vector 5
    jmp Trap            ;Jump to the Trap handler

vector6:
    push 0              ;Push interrupt vector number 6
    push 6              ;Push additional data for vector 6
    jmp Trap            ;Jump to the Trap handler

vector7:
    push 0              ;Push interrupt vector number 7
    push 7              ;Push additional data for vector 7
    jmp Trap            ;Jump to the Trap handler

vector8:
    push 8              ;Push interrupt vector number 8
    jmp Trap            ;Jump to the Trap handler

vector10:
    push 10             ;Push interrupt vector number 10
    jmp Trap            ;Jump to the Trap handler

vector11:
    push 11             ;Push interrupt vector number 11
    jmp Trap            ;Jump to the Trap handler

vector12:
    push 12             ;Push interrupt vector number 12
    jmp Trap            ;Jump to the Trap handler

vector13:
    push 13             ;Push interrupt vector number 13
    jmp Trap            ;Jump to the Trap handler

vector14:
    push 14             ;Push interrupt vector number 14
    jmp Trap            ;Jump to the Trap handler

vector16:
    push 0              ;Push interrupt vector number 16
    push 16             ;Push additional data for vector 16
    jmp Trap            ;Jump to the Trap handler

vector17:
    push 17             ;Push interrupt vector number 17
    jmp Trap            ;Jump to the Trap handler

vector18:
    push 0              ;Push interrupt vector number 18
    push 18             ;Push additional data for vector 18
    jmp Trap            ;Jump to the Trap handler

vector19:
    push 0              ;Push interrupt vector number 19
    push 19             ;Push additional data for vector 19
    jmp Trap            ;Jump to the Trap handler

vector32:
    push 0              ;Push interrupt vector number 32
    push 32             ;Push additional data for vector 32
    jmp Trap            ;Jump to the Trap handler

vector39:
    push 0              ;Push interrupt vector number 39
    push 39             ;Push additional data for vector 39
    jmp Trap            ;Jump to the Trap handler

eoi:
    mov al,0x20        ;Load the End Of Interrupt command (EOI) value into al register
    out 0x20,al        ;Send EOI signal to the PIC (Port 0x20)
    ret                ;Return from the EOI routine

read_isr:
    mov al,11          ;Load the command to read ISR into al register
    out 0x20,al        ;Send command to PIC (Port 0x20)
    in al,0x20         ;Read the ISR value from the PIC (Port 0x20)
    ret                ;Return from the ISR reading routine

load_idt:
    lidt [rdi]         ;Load the IDT using the address in rdi
    ret                ;Return from the load IDT routine
