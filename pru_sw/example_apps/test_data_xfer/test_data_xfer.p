// author: raphael luckom raphaelluckom@gmail.com
// based on examples by Texas Instruments
.origin 0
.entrypoint TESTDATAXFER

#include "test_data_xfer.hp"

TESTDATAXFER:

#ifdef AM33XX

    // Configure the block index register for PRU0 by setting c24_blk_index[7:0] and
    // c25_blk_index[7:0] field to 0x00 and 0x00, respectively.  This will make C24 point
    // to 0x00000000 (PRU0 DRAM) and C25 point to 0x00002000 (PRU1 DRAM).
    MOV       r0, 0x00000000
    MOV       r1, CTBIR_0
    ST32      r0, r1
    MOV       r6, 0x0a

#endif
    LBCO      r4, CONST_PRUDRAM, 0, 1 //Load 4 bytes from memory location c3(PRU0/1 Local Data)+4 into r4 using constant table
    LBCO      r3, CONST_PRUDRAM, 4, 1 //Load 4 bytes from memory location c3(PRU0/1 Local Data)+4 into r4 using constant table

BLINK:
    MOV r30, r4
    MOV r5, 0x00f00000

DELAY:
    SUB r5, r5, 1
    QBNE DELAY, r5, 0
    MOV r30, 0x0
    MOV r5, 0x00f00000

DELAY2:
    SUB r5, r5, 1
    QBNE DELAY2, r5, 0
    MOV r30, r3
    MOV r5, 0x00f00000

DELAY3:
    SUB r5, r5, 1
    QBNE DELAY3, r5, 0
    MOV r30, 0x0
    MOV r5, 0x00f00000

DELAY4:
    SUB r5, r5, 1
    QBNE DELAY4, r5, 0
    SUB r6, r6, 1
    QBNE BLINK, r6, 0

#ifdef AM33XX

    // Send notification to Host for program completion
    MOV R31.b0, PRU0_ARM_INTERRUPT+16

#else

    MOV R31.b0, PRU0_ARM_INTERRUPT

#endif

    HALT
