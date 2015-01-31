/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _CONFIG_H_
#define _CONFIG_H_

// Select the target
#define LPC

/************************************************************
* I2C1														*
************************************************************/

// Include the I2C1 driver
#define _USE_I2C1_

// Configure the transfer buffer size
#define I2C1_BUFFER_SIZE				32

// Configure the interrupt priority
#define CONFIG_PriorityI2C1				0

#endif//_CONFIG_H_
