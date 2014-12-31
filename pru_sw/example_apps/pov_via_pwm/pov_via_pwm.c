// author: raphael luckom raphaelluckom@gmail.com
// Based on examples by Texas Instruments

/*****************************************************************************
* Include Files                                                              *
*****************************************************************************/

#include <stdio.h>

// Driver header file
#include <prussdrv.h>
#include <pruss_intc_mapping.h>

/*****************************************************************************
* Explicit External Declarations                                             *
*****************************************************************************/

/*****************************************************************************
* Local Macro Declarations                                                   *
*****************************************************************************/

#define PRU_NUM 	1
#define ADDEND1		0x0010F012u
#define ADDEND2		0x0000567Au

#define AM33XX

/*****************************************************************************
* Local Typedef Declarations                                                 *
*****************************************************************************/


/*****************************************************************************
* Local Function Declarations                                                *
*****************************************************************************/

static int LOCAL_exampleInit ( unsigned short pruNum );
static unsigned short LOCAL_examplePassed ( unsigned short pruNum );

/*****************************************************************************
* Local Variable Definitions                                                 *
*****************************************************************************/


/*****************************************************************************
* Intertupt Service Routines                                                 *
*****************************************************************************/


/*****************************************************************************
* Global Variable Definitions                                                *
*****************************************************************************/

static void *pruDataMem;
static unsigned int *pruDataMem_int;

/*****************************************************************************
* Global Function Definitions                                                *
*****************************************************************************/

int main (void)
{
    unsigned int ret;
    tpruss_intc_initdata pruss_intc_initdata = PRUSS_INTC_INITDATA;

    printf("\nINFO: Starting %s example.\r\n", "pov_via_pwm");
    /* Initialize the PRU */
    prussdrv_init ();

    /* Open PRU Interrupt */
    ret = prussdrv_open(PRU_EVTOUT_0);
    if (ret)
    {
        printf("prussdrv_open open failed\n");
        return (ret);
    }

    /* Get the interrupt initialized */
    prussdrv_pruintc_init(&pruss_intc_initdata);

    /* Initialize example */
    printf("\tINFO: Initializing example.\r\n");
    LOCAL_exampleInit(PRU_NUM);

    /* Execute example on PRU */
    printf("\tINFO: Executing example.\r\n");
    prussdrv_exec_program (PRU_NUM, "./pov_via_pwm.bin");


    /* Wait until PRU0 has finished execution */
    printf("\tINFO: Waiting for HALT command.\r\n");
    prussdrv_pru_wait_event (PRU_EVTOUT_0);
    printf("\tINFO: PRU completed transfer.\r\n");
    prussdrv_pru_clear_event (PRU_EVTOUT_0, PRU0_ARM_INTERRUPT);

    /* Disable PRU and close memory mapping*/
    prussdrv_pru_disable (PRU_NUM);
    prussdrv_exit ();
    printf("INFO: Example finished succesfully.\r\n");

    return(0);

}

/*****************************************************************************
* Local Function Definitions                                                 *
*****************************************************************************/

static int LOCAL_exampleInit ( unsigned short pruNum )
{
    //Initialize pointer to PRU data memory
    if (pruNum == 0)
    {
      prussdrv_map_prumem (PRUSS0_PRU0_DATARAM, &pruDataMem);
    }
    else if (pruNum == 1)
    {
      prussdrv_map_prumem (PRUSS0_PRU1_DATARAM, &pruDataMem);
    }
    pruDataMem_int = (unsigned int*) pruDataMem;
    static const unsigned int img_data[78] = {
    0, 0, 0, 4294967295, 268435455, 0, 
    0, 0, 4293918720, 0, 4026531840, 255, 
    0, 0, 1048320, 4278190080, 15, 1048320, 
    0, 0, 1048320, 16773120, 268369920, 1048320, 
    0, 0, 1048320, 16773120, 0, 1048320, 
    0, 0, 1048320, 16773120, 268369920, 1048320, 
    0, 0, 1048320, 4278190080, 15, 1048320, 
    0, 0, 4293918720, 0, 4026531840, 255, 
    0, 0, 0, 4294967295, 268435455, 0, 
    0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0
    };
    
    memcpy(pruDataMem_int, img_data, sizeof(img_data));
//    pruDataMem_int[0] = 0x04002001;
//    pruDataMem_int[1] = 0x00100080;
//    pruDataMem_int[2] = 0x08004002;
//    pruDataMem_int[3] = 0x00200100;
//    pruDataMem_int[4] = 0x00008004;
//    pruDataMem_int[5] = 0x00000000;
//    pruDataMem_int[6] = 0x00000000;
//    pruDataMem_int[0] = 0;
//    pruDataMem_int[1] = 0;
//    pruDataMem_int[2] = 0;
//    pruDataMem_int[3] = 4278190080;
//    pruDataMem_int[4] = 268369935;
//    pruDataMem_int[5] = 1048320;

    return(0);
}
