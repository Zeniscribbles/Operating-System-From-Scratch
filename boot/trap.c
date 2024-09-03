#include "trap.h"

//Static variables to hold the IDT pointer and IDT entries
static struct IdtPtr idt_pointer;       //IDT pointer structure
static struct IdtEntry vectors[256];    //Array to hold IDT entries for all 256 interrupt vectors

///@brief Function to initialize an IDT entry
///
///@param entry: Pointer to the IDT entry to initialize
///@param addr: Address of the interrupt handler
///@param attribute: Attributes for the IDT entry (e.g., type, privilege level)
static void init_idt_entry(struct IdtEntry *entry, uint64_t addr, uint8_t attribute)
{
    entry->low = (uint16_t)addr;            //Low 16 bits of the handler address
    entry->selector = 8;                    //Code segment selector (assumed to be 8 for kernel code)
    entry->attr = attribute;                //Attributes for the entry
    entry->mid = (uint16_t)(addr >> 16);    //Middle 16 bits of the handler address
    entry->high = (uint32_t)(addr >> 32);   //High 32 bits of the handler address
}

///@brief Function to initialize the IDT with specific interrupt vectors
void init_idt(void)
{
    //Initialize IDT entries for specific interrupt vectors
    init_idt_entry(&vectors[0], (uint64_t)vector0, 0x8e);   //Vector 0
    init_idt_entry(&vectors[1], (uint64_t)vector1, 0x8e);   //Vector 1
    init_idt_entry(&vectors[2], (uint64_t)vector2, 0x8e);   //Vector 2
    init_idt_entry(&vectors[3], (uint64_t)vector3, 0x8e);   //Vector 3
    init_idt_entry(&vectors[4], (uint64_t)vector4, 0x8e);   //Vector 4
    init_idt_entry(&vectors[5], (uint64_t)vector5, 0x8e);   //Vector 5
    init_idt_entry(&vectors[6], (uint64_t)vector6, 0x8e);   //Vector 6
    init_idt_entry(&vectors[7], (uint64_t)vector7, 0x8e);   //Vector 7
    init_idt_entry(&vectors[8], (uint64_t)vector8, 0x8e);   //Vector 8
    init_idt_entry(&vectors[10], (uint64_t)vector10, 0x8e); //Vector 10
    init_idt_entry(&vectors[11], (uint64_t)vector11, 0x8e); //Vector 11
    init_idt_entry(&vectors[12], (uint64_t)vector12, 0x8e); //Vector 12
    init_idt_entry(&vectors[13], (uint64_t)vector13, 0x8e); //Vector 13
    init_idt_entry(&vectors[14], (uint64_t)vector14, 0x8e); //Vector 14
    init_idt_entry(&vectors[16], (uint64_t)vector16, 0x8e); //Vector 16
    init_idt_entry(&vectors[17], (uint64_t)vector17, 0x8e); //Vector 17
    init_idt_entry(&vectors[18], (uint64_t)vector18, 0x8e); //Vector 18
    init_idt_entry(&vectors[19], (uint64_t)vector19, 0x8e); //Vector 19
    init_idt_entry(&vectors[32], (uint64_t)vector32, 0x8e); //Vector 32
    init_idt_entry(&vectors[39], (uint64_t)vector39, 0x8e); //Vector 39

    //Set up the IDT pointer with the size and address of the IDT
    idt_pointer.limit = sizeof(vectors) - 1;    //Set limit to the size of the IDT - 1
    idt_pointer.addr = (uint64_t)vectors;       //Set address to the base of the IDT array
    
    //Load the IDT using the IDT pointer
    load_idt(&idt_pointer);
}

///@brief Interrupt handler function
///@param tf: Pointer to the TrapFrame structure containing CPU register state
void handler(struct TrapFrame *tf)
{
    unsigned char isr_value;

    //Handle different interrupts based on the trap number
    switch (tf->trapno) {
        case 32:    //Timer interrupt (typically used for periodic tasks)
            eoi();  //Send End Of Interrupt (EOI) signal to the PIC
            break;
            
        case 39:                                //User-defined interrupt or specific device interrupt
            isr_value = read_isr();             //Read the ISR value to determine interrupt status
            if ((isr_value & (1 << 7)) != 0) {  //Check if the specific bit is set
                eoi();                          //Send EOI if the condition is met
            }
            break;

        default:           //Handle unknown interrupts
            while (1) { }  //Infinite loop for unknown interrupts (halt execution)
    }
}
