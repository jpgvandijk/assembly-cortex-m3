/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifdef LPC

// Includes
#include <stdint.h>
#include "lpc1769.h"
#include "system.h"
#include "i2c1.h"

// Debugging variables
volatile uint32_t status;

void i2c1_test (void)
{
	// Init the I2C module
	I2C1_Init();

	// Write to the 24LC64
	I2C1_Buffer[0] = 0xA0;
	I2C1_Buffer[1] = 0;
	I2C1_Buffer[2] = 0;
	I2C1_Buffer[3] = 0xAB;
	I2C1_Buffer[4] = 0xBC;
	I2C1_Buffer[5] = 0xCD;
	I2C1_Buffer[6] = 0xDE;
	I2C1_Buffer[7] = 0xEF;
	I2C1_WriteLength = 8;
	I2C1_ReadLength = 0;
	I2C1_StartTransfer();
	status = I2C1_WaitEndTransfer(100000);

	// Wait for the write to complete
	SystemDelayMs(100);

	// Read back
	I2C1_Buffer[0] = 0xA0;
	I2C1_Buffer[1] = 0;
	I2C1_Buffer[2] = 0;
	I2C1_WriteLength = 3;
	I2C1_ReadLength = 0;
	I2C1_StartTransfer();
	status = I2C1_WaitEndTransfer(100000);
	I2C1_Buffer[0] = 0xA1;
	I2C1_WriteLength = 1;
	I2C1_ReadLength = 8;
	I2C1_StartTransfer();
	status = I2C1_WaitEndTransfer(100000);

	// Check the result (available during debugging)
	while (I2C1_Buffer[0]);
}

#endif//LPC
