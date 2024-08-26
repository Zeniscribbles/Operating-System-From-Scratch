#include "stdint.h"  //For fixed width data types: uint8_t, uint16_t, etc.
#include "stddef.h"  //For standard definitions like NULL and size_t.

/// @brief KernelMain: Where the kernel starts
/// @param  void
void KernelMain(void){

    char* p = (char*)0xb8000;   //Define a pointer 'p' that points to the video memory address 0xb8000.
    p[0] = 'C';                 //Set the first byte at the video memory address to the ASCII character 'C'.
    p[1] = 0xa;                 //Set the second byte at the video memory address to 0xa (light green on black).
}