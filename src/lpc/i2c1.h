/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _I2C1_H_
#define _I2C1_H_

// Includes
#include "lpc1769.h"

// Definitions
#define I2C1_BUFFER_SIZE				32

#define I2C1_STATE_IDLE					0
#define I2C1_STATE_BUSY					1
#define I2C1_STATE_ERROR				2
#define I2C1_STATE_ERROR_NACK_DATA		3
#define I2C1_STATE_ERROR_NACK_ADDRESS	4
#define I2C1_STATE_ERROR_TIMEOUT		5

#ifndef __ASSEMBLER__

// Global variables
extern uint32_t I2C1_Timeout;
extern uint16_t I2C1_WriteLength;
extern uint16_t I2C1_ReadLength;
extern uint8_t I2C1_State;
extern uint8_t I2C1_Buffer[I2C1_BUFFER_SIZE];

// Global functions
extern void I2C1_Init (void);
extern void I2C1_StartTransfer (void);
extern uint32_t I2C1_WaitEndTransfer (uint32_t timeout);
extern void I2C1_IRQHandler (void);

#endif//__ASSEMBLER__

#endif//_I2C1_H_
