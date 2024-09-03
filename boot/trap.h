#ifndef _TRAP_H_
#define _TRAP_H_

#include "stdint.h"

//Structure representing an entry in the Interrupt Descriptor Table (IDT)
struct IdtEntry {
    uint16_t low;       //Low 16 bits of the address of the interrupt handler
    uint16_t selector;  //Selector for the code segment
    uint8_t  res0;      //Reserved, must be set to 0
    uint8_t  attr;      //Attributes (e.g., type, privilege level)
    uint16_t mid;       //Middle 16 bits of the address of the interrupt handler
    uint32_t high;      //High 32 bits of the address of the interrupt handler
    uint32_t res1;      //Reserved, must be set to 0
} __attribute__((packed)); //Ensures no padding between fields

//Structure representing the IDT pointer
struct IdtPtr {
    uint16_t limit;         //Limit of the IDT (size - 1)
    uint64_t addr;          //Address of the IDT
} __attribute__((packed));  //Ensures no padding between fields

//Structure representing the state of the CPU registers during an interrupt
struct TrapFrame {
    int64_t r15;        //Register r15
    int64_t r14;        //Register r14
    int64_t r13;        //Register r13
    int64_t r12;        //Register r12
    int64_t r11;        //Register r11
    int64_t r10;        //Register r10
    int64_t r9;         //Register r9
    int64_t r8;         //Register r8
    int64_t rbp;        //Base Pointer (rbp)
    int64_t rdi;        //Destination Index (rdi)
    int64_t rsi;        //Source Index (rsi)
    int64_t rdx;        //Data Register (rdx)
    int64_t rcx;        //Count Register (rcx)
    int64_t rbx;        //Base Register (rbx)
    int64_t rax;        //Accumulator Register (rax)
    int64_t trapno;     //Trap number (interrupt vector)
    int64_t errorcode;  //Error code (if applicable)
    int64_t rip;        //Instruction Pointer (rip)
    int64_t cs;         //Code Segment Register (cs)
    int64_t rflags;     //Flags Register (rflags)
    int64_t rsp;        //Stack Pointer (rsp)
    int64_t ss;         //Stack Segment Register (ss)
};

//Declarations of interrupt service routines (ISRs) for various interrupt vectors
void vector0(void);  //ISR for interrupt vector 0
void vector1(void);  //ISR for interrupt vector 1
void vector2(void);  //ISR for interrupt vector 2
void vector3(void);  //ISR for interrupt vector 3
void vector4(void);  //ISR for interrupt vector 4
void vector5(void);  //ISR for interrupt vector 5
void vector6(void);  //ISR for interrupt vector 6
void vector7(void);  //ISR for interrupt vector 7
void vector8(void);  //ISR for interrupt vector 8
void vector10(void); //ISR for interrupt vector 10
void vector11(void); //ISR for interrupt vector 11
void vector12(void); //ISR for interrupt vector 12
void vector13(void); //ISR for interrupt vector 13
void vector14(void); //ISR for interrupt vector 14
void vector16(void); //ISR for interrupt vector 16
void vector17(void); //ISR for interrupt vector 17
void vector18(void); //ISR for interrupt vector 18
void vector19(void); //ISR for interrupt vector 19
void vector32(void); //ISR for interrupt vector 32
void vector39(void); //ISR for interrupt vector 39

//Function prototypes
void init_idt(void);                //Initializes the Interrupt Descriptor Table (IDT)
void eoi(void);                     //Sends an End Of Interrupt (EOI) signal to the Programmable Interrupt Controller (PIC)
void load_idt(struct IdtPtr *ptr);  //Loads the IDT using the provided IDT pointer
unsigned char read_isr(void);       //Reads the current Interrupt Service Routine (ISR) status

#endif //End of header guard
