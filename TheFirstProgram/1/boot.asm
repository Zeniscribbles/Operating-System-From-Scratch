[BITS 16]       ///Directive: Boot code is running in 16=bit mode. (Push and pop
                ///           instructions are 2 bytes in 16-bit mode.)


[ORG 0x7c00]    ///Directive:  BIOS loads the boot code from the first sector 
                ///            into memory address 7c00


///Initilizing the segment registers and stack pointer.
///            Zeroing out the segment registers makes the offset
///            the memory address we want to access.
start:          //Label: Start of code
    xor ax,ax   //Zeroing ax register  
    mov ds,ax   //copying the value of ax into ds, ex, and ss.
    mov es,ax  
    mov ss,ax
    mov sp,0x7c00


///Printing message to screen: Print characters is done by calling BIOS service
///                            The BIOS services can be accessed with BIOS interrupts.
PrintMessage:
    mov ah,0x13 //Register ah holds the function code. Here we use 13 which means print string.
    mov al,1    //Register AL specifies the write mode, we set it to 1, meaning that the cursor 
                //will be placed at the end of the string.
    mov bx,0xa  //Save A to bx.

                //Bh which is the higher part of bx register represents page number.
                //BL, the lower part of bx holds the information of character attributes.


    xor dx,dx   //Zero dx register

                //We also zero register dx. Dh which is higher part of dx register 
                //represents rows and dL represents columns.
                //Now the message will print at the begining of the screen.

    mov bp, Message //bp holds the address of the screen. Placing brackets around 'Message'
                    //will copy the data in the variable 'message' to bp.

    mov cx, MessageLen //Number of characters to print.
    int 0x10           //Print Function: Calling the interrupt BIOS service [hexdecimal 10]

End:    //End of code
    hlt //Processor is placed in halt state.    
    jmp End
     
Message:    db "Hello"


///equ: directive to define a constant message length. Represents the 
///     number of characters. and copies it to register cx.
MessageLen: equ $-Message //'$' the current assembly position.


///times: A direcective that repeats commands. 
///       '$$' is the begining of the current section.
///       '$-$$' represents the size from the start of the code to 
///        the end of the message.
times (0x1be-($-$$)) db 0   //How many times db is repeated.

    db 80h              //Boot indicator [bootable partition].
    
    ///cylinder-head-sector (CHS): Addressing scheme allows the operating
    ///                            system to specify the exact location of 
    ///                            data on a disk. 
    ///
    ///          The cylinder number specifies the vertical position of the track on all platters.
    ///          The head number specifies which read/write head (and thus which platter surface) is being accessed.
    ///          The sector number specifies the specific sector within the track where the data is located.
    ///
    ///Refer to definitions below.
    db 0,2,0            //Starting CHS [Cylinder, Head, Sector]
    db 0f0h             //Type
    db 0ffh,0ffh,0ffh   //Ending CHS
    dd 1                //Starting sector
    dd (20*16*63-1)     //size
	
    times (16*3) db 0

    //Signature, size of boot 512 bytes.
    db 0x55
    db 0xaa

	
