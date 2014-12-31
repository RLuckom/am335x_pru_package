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
#define GS_WAIT_CYCLES 20
#define MAIN_LOOP_CYCLES 600
#define ROW_1_IDX 7
#define ROW_2_IDX 5
#define BYTES_OF_DATA 312

// Define mapped registers
#define DATA1_POINTER r11
#define DATA2_POINTER r10
#define DATA_REGISTER r2
#define DATA_CTR r3
#define GSCLK_CTR r4
#define SCLK_CTR r5
#define CYCLE_CTR r6
#define DATA_INPUT_LENGTH r7
#define TOP_STRING_REGISTER r8
#define BOTTOM_STRING_REGISTER r9
#define FORTY_NINETY_SIX r13
#define ONE_BIT_INTERMEDIATE r14
#define GS_CYCLE_CTR r15
#define DATA_BASE_ADDR r16
#define DATA_REMAINDER r17

.macro clear_everything
    MOV r1, 0
    MOV r2, 0
    MOV r3, 0
    MOV r4, 0
    MOV r5, 0
    MOV r6, 0
    MOV r7, 0
    MOV r8, 0
    MOV r9, 0
    MOV r10, 0
    MOV r11, 0
    MOV r12, 0
    MOV r13, 0
    MOV r14, 0
    MOV r15, 0
    MOV r16, 0
    MOV r17, 0
    MOV r18, 0
    MOV r19, 0
    MOV r20, 0
    MOV r21, 0
    MOV r22, 0
    MOV r23, 0
    MOV r24, 0
    MOV r25, 0
    MOV r26, 0
    MOV r27, 0
    MOV r28, 0
    MOV r29, 0
    MOV r30, 0
.endm

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
        JMP SET_DATA_REG
    CHOOSE_NEXT_ADDR:
        QBEQ UPDATE_BASE, GS_CYCLE_CTR, 0
        JMP ZERO_REMAINDER
    UPDATE_BASE:
        ADD DATA_BASE_ADDR, DATA_BASE_ADDR, DATA_REMAINDER
        MOV DATA_REMAINDER, 0
        MOV GS_CYCLE_CTR, GS_WAIT_CYCLES
        QBEQ ZERO_BASE, DATA_BASE_ADDR, DATA_INPUT_LENGTH
        JMP SET_DATA_REG
    ZERO_REMAINDER:
        decrement GS_CYCLE_CTR
        MOV DATA_REMAINDER, 0
        choose_string_to_use SET_DATA_REG
    ZERO_BASE:
        MOV DATA_BASE_ADDR, 0
        decrement CYCLE_CTR
        JMP SET_DATA_REG
    SET_DATA_REG:
        ADD DATA1_POINTER, DATA_BASE_ADDR, DATA_REMAINDER
        ADD DATA2_POINTER, DATA_INPUT_LENGTH, DATA1_POINTER
        LBBO BOTTOM_STRING_REGISTER, r22, DATA1_POINTER, 4
        LBBO TOP_STRING_REGISTER, r22, DATA2_POINTER, 4
        enable_correct_output END0
    END0:
        MOV DATA_CTR, 0
        JMP return
.endm

.macro enable_correct_output
    .mparam return
    QBBS ENABLE_TOP, r30, ROW_1_IDX
    ENABLE_BOTTOM:
        MOV DATA_REGISTER, BOTTOM_STRING_REGISTER
        JMP return
    ENABLE_TOP:
        MOV DATA_REGISTER, BOTTOM_STRING_REGISTER
        JMP return
.endm

.macro choose_string_to_use
    .mparam return
    QBBS ENABLE_TOP, r30, ROW_1_IDX
    ENABLE_BOTTOM:
        CLR r30, ROW_2_IDX
        SET r30, ROW_1_IDX
        JMP return
    ENABLE_TOP:
        CLR r30, ROW_1_IDX
        SET r30, ROW_2_IDX
        JMP return
.endm

.macro switch_registers
    .mparam swap_reg1, swap_reg2, transit_register
    MOV swap_reg1, transit_register
    MOV swap_reg2, swap_reg1
    MOV transit_register, swap_reg2
.endm

TESTTLC5940:
    clear_everything
    SET r30, ROW_1_IDX
    MOV DATA_INPUT_LENGTH, BYTES_OF_DATA
    MOV DATA2_POINTER, BYTES_OF_DATA
    ADD DATA2_POINTER, DATA2_POINTER, 4
    MOV CYCLE_CTR, MAIN_LOOP_CYCLES
    MOV FORTY_NINETY_SIX, 4096
    LBBO BOTTOM_STRING_REGISTER, r22, DATA1_POINTER, 4
    LBBO TOP_STRING_REGISTER, r22, DATA1_POINTER, 4

START:
    CLR r30, 0 // clear pinouts
    CLR r30, 1 // clear pinouts
    CLR r30, 2 // clear pinouts
    CLR r30, 3 // clear pinouts
    MOV SCLK_CTR, 0
    MOV GSCLK_CTR, 0
    MOV DATA_REGISTER, BOTTOM_STRING_REGISTER
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
    update_data_pointer DATA_OUT

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
