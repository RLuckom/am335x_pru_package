// author: raphael luckom raphaelluckom@gmail.com
// based on examples by Texas Instruments
.origin 0
.entrypoint TESTDATAXFER

#include "test_tlc5940.hp"

// Define mapped indices into output register
#define SCLK_IDX 0
#define GSCLK_IDX 1
#define BLANK_IDX 2
#define XLAT_IDX 3
#define SIN_IDX 4

// Define mapped registers
#define DATA_POINTER r1.b0
#define DATA_REGISTER r2
#define DATA_CTR r3
#define GSCLK_CTR r4
#define SCLK_CTR r5
#define CYCLE_CTR r6
#define FIRST_DATA_REGISTER r7
#define SECOND_DATA_REGISTER r8
#define THIRD_DATA_REGISTER r9
#define FOURTH_DATA_REGISTER r10
#define FIFTH_DATA_REGISTER r11
#define SIXTH_DATA_REGISTER r12
#define FORTY_NINETY_SIX r13
#define ONE_BIT_INTERMEDIATE r14

TESTDATAXFER:

    MOV r22, 0x00000000
    LBBO FIRST_DATA_REGISTER, r22, 0, 4 //Load 4 bytes from memory location c3(PRU0/1 Local Data)+4 into r4 using constant table
    LBBO SECOND_DATA_REGISTER, r22, 4, 4 //Load 4 bytes from memory location c3(PRU0/1 Local Data)+4 into r4 using constant table
    LBBO THIRD_DATA_REGISTER, r22, 8, 4 //Load 4 bytes from memory location c3(PRU0/1 Local Data)+4 into r4 using constant table
    LBBO FOURTH_DATA_REGISTER, r22, 12, 4 //Load 4 bytes from memory location c3(PRU0/1 Local Data)+4 into r4 using constant table
    LBBO FIFTH_DATA_REGISTER, r22, 16, 4 //Load 4 bytes from memory location c3(PRU0/1 Local Data)+4 into r4 using constant table
    LBBO SIXTH_DATA_REGISTER, r22, 20, 4 //Load 4 bytes from memory location c3(PRU0/1 Local Data)+4 into r4 using constant table
    MOV CYCLE_CTR, 90000
    MOV FORTY_NINETY_SIX, 4096

START:
    LDI DATA_POINTER, 0
    LBBO DATA_REGISTER, r22, DATA_POINTER, 4
    ADD DATA_POINTER, DATA_POINTER, 4
    MOV r30, 0 // clear pinouts
    MOV SCLK_CTR, 0
    MOV GSCLK_CTR, 0
    MOV DATA_CTR, 0
    JMP RUN_LOOP

RUN_LOOP:
    QBNE DATA_OUT, SCLK_CTR, 192
    JMP GS_OUT

DATA_OUT:
    QBEQ LOAD_NEXT, DATA_CTR, 32
    QBBC LOW_DATA, DATA_REGISTER, DATA_CTR
    SET r30, SIN_IDX
    SET r30, SCLK_IDX
    NOP1 r26, r26, r26
    NOP1 r26, r26, r26
    NOP1 r26, r26, r26
    CLR r30, SCLK_IDX
    ADD DATA_CTR, DATA_CTR, 1
    ADD SCLK_CTR, SCLK_CTR, 1
    JMP GS_OUT

LOW_DATA:
    CLR r30, SIN_IDX
    SET r30, SCLK_IDX
    NOP1 r26, r26, r26
    NOP1 r26, r26, r26
    NOP1 r26, r26, r26
    CLR r30, SCLK_IDX
    ADD DATA_CTR, DATA_CTR, 1
    ADD SCLK_CTR, SCLK_CTR, 1
    JMP GS_OUT

LOAD_NEXT:
    LBBO DATA_REGISTER, r22, DATA_POINTER, 4
    ADD DATA_POINTER, DATA_POINTER, 4
    MOV DATA_CTR, 0
    JMP DATA_OUT

GS_OUT:
    QBEQ LATCH, GSCLK_CTR, FORTY_NINETY_SIX
    SET r30, GSCLK_IDX
    NOP1 r26, r26, r26
    NOP1 r26, r26, r26
    NOP1 r26, r26, r26
    CLR r30, GSCLK_IDX
    ADD GSCLK_CTR, GSCLK_CTR, 1
    JMP RUN_LOOP

LATCH:
    SET r30, BLANK_IDX
    SET r30, XLAT_IDX
    NOP1 r26, r26, r26
    NOP1 r26, r26, r26
    NOP1 r26, r26, r26
    CLR r30, XLAT_IDX
    SUB CYCLE_CTR, CYCLE_CTR, 1
    QBNE START, CYCLE_CTR, 0

#ifdef AM33XX

    // Send notification to Host for program completion
    MOV R31.b0, PRU0_ARM_INTERRUPT+16

#else

    MOV R31.b0, PRU0_ARM_INTERRUPT

#endif

    HALT
