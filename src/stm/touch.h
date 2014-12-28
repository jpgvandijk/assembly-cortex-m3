/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _TOUCH_H_
#define _TOUCH_H_

// Includes
#include "stm32f103ve.h"
#include "board.h"

// Definitions
#define TOUCH_SPI_BAUDRATE				4	// TODO: check maximum baudrate!
#define TOUCH_IRQ_PRIORITY				8	// FIXME: STM different interrupts than LPC!

#ifndef __ASSEMBLER__

// Global functions
extern void TOUCH_Init (void);
extern void TOUCH_Read (uint16_t * buffer, uint32_t count);

#endif//__ASSEMBLER__

#endif//_TOUCH_H_
