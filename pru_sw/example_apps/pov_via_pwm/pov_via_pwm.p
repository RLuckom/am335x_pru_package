// author: raphael luckom raphaelluckom@gmail.com
// based on examples by Texas Instruments
.origin 0
.entrypoint TESTTLC5940
#define PRU0_ARM_INTERRUPT      19
#define AM33XX

// Define mapped indices into output register
#define SCLK_IDX 0
#define GSCLK_IDX 1
#define BLANK_IDX 2
#define XLAT_IDX 3
#define SIN_IDX 4
#define GS_WAIT_CYCLES 10
#define MAIN_LOOP_CYCLES 600

// Define mapped registers
#define DATA_POINTER r1.b0
#define DATA_REGISTER r2
#define DATA_CTR r3
#define GSCLK_CTR r4
#define SCLK_CTR r5
#define CYCLE_CTR r6
#define DATA_INPUT_LENGTH r7
#define FORTY_NINETY_SIX r13
#define ONE_BIT_INTERMEDIATE r14
#define GS_CYCLE_CTR r15
#define DATA_BASE_ADDR r16
#define DATA_REMAINDER r17

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

.macro update_data_pointer
    .mparam return
    CHECK_TIME:
        ADD DATA_REMAINDER, DATA_REMAINDER, 4
        QBEQ CHOOSE_NEXT_ADDR, DATA_REMAINDER, 24
        JMP END0
    CHOOSE_NEXT_ADDR:
        QBEQ UPDATE_BASE, GS_CYCLE_CTR, 0
        JMP ZERO_REMAINDER
    UPDATE_BASE:
        ADD DATA_BASE_ADDR, DATA_BASE_ADDR, DATA_REMAINDER
        MOV DATA_REMAINDER, 0
        MOV GS_CYCLE_CTR, GS_WAIT_CYCLES
        QBEQ ZERO_BASE, DATA_BASE_ADDR, DATA_INPUT_LENGTH
        JMP END0
    ZERO_REMAINDER:
        decrement GS_CYCLE_CTR
        MOV DATA_REMAINDER, 0
        JMP END0
    ZERO_BASE:
        MOV DATA_BASE_ADDR, 0
        decrement CYCLE_CTR
        JMP END0
    END0:
        ADD DATA_POINTER, DATA_BASE_ADDR, DATA_REMAINDER
        JMP return
.endm

TESTTLC5940:
    MOV DATA_INPUT_LENGTH, 264
    MOV r22, 0x00000000
    MOV CYCLE_CTR, MAIN_LOOP_CYCLES
    MOV FORTY_NINETY_SIX, 4096
    MOV DATA_BASE_ADDR, 0
    MOV DATA_REMAINDER, 0
    LDI DATA_POINTER, 0
    LBBO DATA_REGISTER, r22, DATA_POINTER, 4
    MOV DATA_CTR, 0

START:
    CLR r30, 0 // clear pinouts
    CLR r30, 1 // clear pinouts
    CLR r30, 2 // clear pinouts
    CLR r30, 3 // clear pinouts
    MOV SCLK_CTR, 0
    MOV GSCLK_CTR, 0
    LBBO DATA_REGISTER, r22, DATA_POINTER, 4
    JMP RUN_LOOP

RUN_LOOP:
    QBNE DATA_OUT, SCLK_CTR, 192
    JMP GS_OUT

DATA_OUT:
    QBEQ SET_DATA_PTR, DATA_CTR, 32
    write_bit_to_output DATA_REGISTER, DATA_CTR, SIN_IDX, CONTINUE
CONTINUE:
    pulse r30, SCLK_IDX
    increment DATA_CTR
    increment SCLK_CTR
    JMP GS_OUT

SET_DATA_PTR:
    update_data_pointer LOAD_NEXT

LOAD_NEXT:
    LBBO DATA_REGISTER, r22, DATA_POINTER, 4
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
    QBNE START, CYCLE_CTR, 0
    JMP END

END:
#ifdef AM33XX


    // Send notification to Host for program completion
    MOV R31.b0, PRU0_ARM_INTERRUPT+16

#else

    MOV R31.b0, PRU0_ARM_INTERRUPT

#endif

    HALT
