// author: raphael luckom raphaelluckom@gmail.com
// based on examples by Texas Instruments
.origin 0
.entrypoint TESTTLC5940

#include "test_tlc5940.hp"

// Define mapped indices into output register
#define SCLK_IDX 0
#define GSCLK_IDX 1
#define BLANK_IDX 2
#define XLAT_IDX 3
#define SIN_IDX 4
#define PWR_IDX 7

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
#define DATA_BIT_CTR r15
#define PWR_CTR r16
#define TFN r17

.macro wait
    NOP1 r26, r26, r26
    NOP1 r26, r26, r26
    NOP1 r26, r26, r26
.endm

.macro write_bit_to_output
    .mparam input_register, position, output_bit_position, return_function, output_register=r30
    QBBC SET_LOW, input_register, position

    SET_HIGH:
        SET output_register, output_bit_position
        JMP return_function

    SET_LOW:
        CLR output_register, output_bit_position
        JMP return_function
.endm

.macro pulse
    .mparam register, idx
    SET register, idx
    wait
    CLR register, idx
.endm

.macro increment
    .mparam register
    ADD register, register, 0x01
.endm

.macro decrement
    .mparam register
    SUB register, register, 0x01
.endm


TESTTLC5940:

    MOV r22, 0x00000000
    MOV CYCLE_CTR, 90000
    MOV FORTY_NINETY_SIX, 4096
    LDI PWR_CTR, 1
    LDI TFN, 2496

START:
    LDI DATA_POINTER, 0
    LBBO DATA_REGISTER, r22, DATA_POINTER, 4
    ADD DATA_POINTER, DATA_POINTER, 4
    CLR r30, 0 // clear pinouts
    CLR r30, 1 // clear pinouts
    CLR r30, 2 // clear pinouts
    CLR r30, 3 // clear pinouts
    MOV SCLK_CTR, 0
    MOV GSCLK_CTR, 0
    MOV DATA_CTR, 0
    MOV DATA_BIT_CTR, 0
    JMP RUN_LOOP

RUN_LOOP:
    QBEQ RESET_DATA, SCLK_CTR, 192
    QBNE DATA_OUT, DATA_BIT_CTR, TFN
    JMP GS_OUT

RESET_DATA:
    LDI DATA_POINTER, 0
    LDI SCLK_CTR, 0
    JMP RUN_LOOP

DATA_OUT:
    QBEQ LOAD_NEXT, DATA_CTR, 32
    write_bit_to_output DATA_REGISTER, DATA_CTR, SIN_IDX, CONTINUE
CONTINUE:
    pulse r30, SCLK_IDX
    increment DATA_CTR
    increment DATA_BIT_CTR
    increment SCLK_CTR
    JMP GS_OUT

LOAD_NEXT:
    LBBO DATA_REGISTER, r22, DATA_POINTER, 4
    ADD DATA_POINTER, DATA_POINTER, 4
    MOV DATA_CTR, 0
    JMP DATA_OUT

GS_OUT:
    QBEQ LATCH, GSCLK_CTR, FORTY_NINETY_SIX
    pulse r30, GSCLK_IDX
    increment GSCLK_CTR
    JMP RUN_LOOP

LATCH:
    SET r30, BLANK_IDX
    pulse r30, XLAT_IDX
    decrement CYCLE_CTR
    //CLR r30, PWR_IDX
    QBEQ PWR_ON, PWR_CTR, 4
RELOOP:
    increment PWR_CTR
    QBNE START, CYCLE_CTR, 0
    JMP END

PWR_ON:
    SET r30, PWR_IDX
    LDI PWR_CTR, 0
    JMP RELOOP

END:
#ifdef AM33XX


    // Send notification to Host for program completion
    MOV R31.b0, PRU0_ARM_INTERRUPT+16

#else

    MOV R31.b0, PRU0_ARM_INTERRUPT

#endif

    HALT
