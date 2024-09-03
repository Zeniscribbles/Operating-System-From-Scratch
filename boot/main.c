#include "stdint.h"  //For fixed width data types: uint8_t, uint16_t, etc.
#include "stddef.h"  //For standard definitions like NULL and size_t.
#include "trap.h"

/// @brief KernelMain: Where the kernel starts
/// @param  void:   This function takes no parameters
void KernelMain(void){

    init_idt();   //Initialize the Interrupt Descriptor Table (IDT)

}