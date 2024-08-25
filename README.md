# Operating Systems From Scratch
Student Project: Writing a 64-bit operating system - for the x86 architecture from scratch. 

# Expected Student Outcome:
### How to build a simple operating system for the x86 architecture.

   * Understand real mode

   * Understand protected mode and long mode

   * How to handle interrupts and exceptions in the 64-bit mode

   * How to write OS kernel with the assembly code and C code

   * Be able to write print function to print characters on the screen

   * Be able to build a memory manager using an x86 paging mechanism

   * How to write a timer handler for the process manager

   *  How to build a process manager to schedule processes and change them among different states (sleep, ready, killed)

   *  How to implement a system call module to make user programs run in the system

   * Write a keyboard driver (PS/2)

   * Write a simple console and interact with the OS kernel using commands

   * Write a simple file system module that supports reading fat16 system.

# Helpful Tables:

## x86-64 Bit General-Purpose Registers

| Register | Size  | Description |
|----------|-------|-------------|
| **RAX**  | 64-bit | Accumulator register used for arithmetic operations. |
| **EAX**  | 32-bit | Lower 32 bits of RAX. |
| **AX**   | 16-bit | Lower 16 bits of EAX. |
| **AL/AH**| 8-bit  | Lower/Upper 8 bits of AX. |
| **RBX**  | 64-bit | Base register, typically used for data storage. |
| **EBX**  | 32-bit | Lower 32 bits of RBX. |
| **BX**   | 16-bit | Lower 16 bits of EBX. |
| **BL/BH**| 8-bit  | Lower/Upper 8 bits of BX. |
| **RCX**  | 64-bit | Counter register, used in loops and string operations. |
| **ECX**  | 32-bit | Lower 32 bits of RCX. |
| **CX**   | 16-bit | Lower 16 bits of ECX. |
| **CL/CH**| 8-bit  | Lower/Upper 8 bits of CX. |
| **RDX**  | 64-bit | Data register, often used in I/O operations. |
| **EDX**  | 32-bit | Lower 32 bits of RDX. |
| **DX**   | 16-bit | Lower 16 bits of EDX. |
| **DL/DH**| 8-bit  | Lower/Upper 8 bits of DX. |
| **RSI**  | 64-bit | Source index for string operations. |
| **ESI**  | 32-bit | Lower 32 bits of RSI. |
| **SI**   | 16-bit | Lower 16 bits of ESI. |
| **SIL**  | 8-bit  | Lower 8 bits of SI. |
| **RDI**  | 64-bit | Destination index for string operations. |
| **EDI**  | 32-bit | Lower 32 bits of RDI. |
| **DI**   | 16-bit | Lower 16 bits of EDI. |
| **DIL**  | 8-bit  | Lower 8 bits of DI. |
| **RBP**  | 64-bit | Base pointer for stack frames. |
| **EBP**  | 32-bit | Lower 32 bits of RBP. |
| **BP**   | 16-bit | Lower 16 bits of EBP. |
| **BPL**  | 8-bit  | Lower 8 bits of BP. |
| **RSP**  | 64-bit | Stack pointer register, points to the top of the stack. |
| **ESP**  | 32-bit | Lower 32 bits of RSP. |
| **SP**   | 16-bit | Lower 16 bits of ESP. |
| **SPL**  | 8-bit  | Lower 8 bits of SP. |
| **R8-R15** | 64-bit | Additional general-purpose registers in 64-bit mode. |
| **R8D-R15D** | 32-bit | Lower 32 bits of R8-R15. |
| **R8W-R15W** | 16-bit | Lower 16 bits of R8-R15. |
| **R8B-R15B** | 8-bit  | Lower 8 bits of R8-R15. |

## Segment Registers

| Register | Size  | Description | Mode  |
|----------|-------|-------------|-------|
| **CS**   | 16-bit | Code Segment: Points to the segment containing the code being executed. | 32-bit/64-bit |
| **DS**   | 16-bit | Data Segment: Generally points to segment containing data. | 32-bit/64-bit |
| **SS**   | 16-bit | Stack Segment: Points to the segment containing the stack. | 32-bit/64-bit |
| **ES**   | 16-bit | Extra Segment: Additional data segment, often used in string operations. | 32-bit/64-bit |
| **FS**   | 16-bit | Extra Segment: Often used to point to thread-local storage. | 32-bit/64-bit |
| **GS**   | 16-bit | Extra Segment: Also often used for thread-local storage. | 32-bit/64-bit |

## Instruction Pointer Register

| Register | Size  | Description | Mode  |
|----------|-------|-------------|-------|
| **RIP**  | 64-bit | Instruction Pointer: Points to the next instruction to be executed. | 64-bit |
| **EIP**  | 32-bit | Lower 32 bits of RIP. | 32-bit |

## Flags Register

| Register | Size  | Description | Mode  |
|----------|-------|-------------|-------|
| **RFLAGS** | 64-bit | Flags register: Stores the current state of the processor, including condition codes and control flags. | 64-bit |
| **EFLAGS** | 32-bit | Lower 32 bits of RFLAGS. | 32-bit |

## Control Registers

| Register | Size  | Description | Mode  |
|----------|-------|-------------|-------|
| **CR0**  | 64-bit | Control Register 0: Contains system control flags. | 32-bit/64-bit |
| **CR2**  | 64-bit | Control Register 2: Contains the Page Fault Linear Address (PFLA). | 32-bit/64-bit |
| **CR3**  | 64-bit | Control Register 3: Contains the Page Directory Base Register (PDBR), used for paging. | 32-bit/64-bit |
| **CR4**  | 64-bit | Control Register 4: Contains various control flags. | 32-bit/64-bit |
| **CR8**  | 64-bit | Control Register 8: Task Priority Register (TPR), used to control the priority of interrupts. | 64-bit |

## Model-Specific Registers (MSRs)

| Register | Size  | Description | Mode  |
|----------|-------|-------------|-------|
| **EFER** | 64-bit | Extended Feature Enable Register: Used to enable long mode and other CPU features. | 64-bit |


## IDT (Interrupt Descriptor Table)

| **Field**          | **Description**                                                |
|--------------------|----------------------------------------------------------------|
| **Base Address**   | Address where the IDT starts in memory.                        |
| **Limit**          | Size of the IDT, typically set with the `lidt` instruction.      |
| **Entry Size**     | Each IDT entry is 8 bytes (16 bytes in some modes).              |
| **Entry Structure**| Each entry typically includes the offset, segment selector, and type. |

### IDT Entry Structure:

| **Field**          | **Description**                                                |
|--------------------|----------------------------------------------------------------|
| **Offset (15:0)**  | Lower 16 bits of the interrupt handler's address.               |
| **Selector**       | Segment selector for the segment where the handler resides.     |
| **Type (4 bits)**  | Type of the gate (Interrupt, Trap, Task, etc.).                 |
| **DPL (2 bits)**   | Descriptor Privilege Level, defines the privilege level needed to access the gate. |
| **Present (1 bit)**| Indicates if the descriptor is present.                         |
| **Offset (31:16)** | Upper 16 bits of the interrupt handler's address.               |

## GDT (Global Descriptor Table)

| **Field**          | **Description**                                                |
|--------------------|----------------------------------------------------------------|
| **Base Address**   | Address where the GDT starts in memory.                        |
| **Limit**          | Size of the GDT, set with the `lgdt` instruction.               |
| **Entry Size**     | Each GDT entry is 8 bytes.                                      |
| **Entry Structure**| Each entry defines a segment's base address, limit, and attributes. |

### GDT Entry Structure:

| **Field**          | **Description**                                                |
|--------------------|----------------------------------------------------------------|
| **Base (15:0)**    | Lower 16 bits of the base address.                              |
| **Selector**       | Segment selector for this descriptor.                           |
| **Type (4 bits)**  | Type of segment (Code, Data, etc.).                             |
| **S (1 bit)**       | Descriptor type (0 = System, 1 = Code/Data).                    |
| **DPL (2 bits)**   | Descriptor Privilege Level, defines access rights.             |
| **Present (1 bit)**| Indicates if the descriptor is present.                         |
| **Base (23:16)**   | Middle 8 bits of the base address.                              |
| **Limit (15:0)**   | Limit of the segment, specifying its size.                      |
| **Base (31:24)**   | Upper 8 bits of the base address.                               |
| **Type (4 bits)**  | Segment type (Code, Data, etc.).                                |
| **Granularity (1 bit)** | Determines the unit of segment limit (byte or page).       |

## Interrupts and Exceptions

| **Type**            | **Description**                                                |
|---------------------|----------------------------------------------------------------|
| **Interrupts**      | Events that trigger an interrupt request to the CPU.            |
| **Exceptions**      | Errors or exceptional conditions that trigger an interrupt.     |

### Common Interrupts and Exceptions:

| **Type**            | **Number** | **Description**                            |
|---------------------|------------|--------------------------------------------|
| **Divide Error**    | 0          | Division by zero error.                    |
| **Debug Exception** | 1          | Debug exception for debugging purposes.    |
| **NMI**             | 2          | Non-maskable interrupt.                    |
| **Breakpoint**      | 3          | Breakpoint exception for debugging.        |
| **Overflow**        | 4          | Overflow exception for arithmetic overflow.|
| **Bound Range Exceeded** | 5      | Exception for exceeding bounds.            |
| **Invalid Opcode**  | 6          | Invalid opcode exception.                  |
| **Device Not Available** | 7     | CPU device not available exception.        |
| **Double Fault**    | 8          | Double fault exception.                    |
| **Coprocessor Segment Overrun** | 9  | Coprocessor segment overrun exception.     |
| **Invalid TSS**     | 10         | Invalid task state segment exception.      |
| **Segment Not Present** | 11      | Segment not present exception.             |
| **Stack Fault**     | 12         | Stack fault exception.                     |
| **General Protection Fault** | 13 | General protection fault exception.        |
| **Page Fault**      | 14         | Page fault exception.                      |
| **Reserved**        | 15         | Reserved for future use.                   |
| **x87 FPU Floating-Point Error** | 16 | Floating-point unit exception.           |
| **Alignment Check** | 17         | Alignment check exception.                 |
| **Machine Check**   | 18         | Machine check exception.                  |
| **SIMD Floating-Point Exception** | 19 | SIMD floating-point exception.            |
| **Virtualization Exception** | 20  | Virtualization exception.                  |

## Interrupt Controller

**8259A Programmable Interrupt Controller (PIC):**

| **Register**       | **Description**                                             |
|--------------------|-------------------------------------------------------------|
| **ICW1**           | Initialization Command Word 1 (control word for initialization). |
| **ICW2**           | Initialization Command Word 2 (defines the interrupt vector offset). |
| **ICW3**           | Initialization Command Word 3 (defines the cascade configuration). |
| **ICW4**           | Initialization Command Word 4 (defines mode of operation). |
| **OCW1**           | Operation Command Word 1 (mask register for interrupt enable/disable). |
| **OCW2**           | Operation Command Word 2 (defines interrupt handling behavior). |
| **OCW3**           | Operation Command Word 3 (provides additional control functions). |

### ICW and OCW Overview:

| **ICW/OCW** | **Purpose**                                          |
|-------------|------------------------------------------------------|
| **ICW1**    | Initialize PICs, specify mode, and define cascade.  |
| **ICW2**    | Set interrupt vector offset.                        |
| **ICW3**    | Set cascade configuration.                          |
| **ICW4**    | Set operational mode (8086/8088, auto EOI, etc.).   |
| **OCW1**    | Mask interrupts, enable/disable individual IRQs.    |
| **OCW2**    | End of interrupt (EOI) control, set priority.        |
| **OCW3**    | Read IRQ status, additional control.                |


