/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _TOUCH_H_
#define _TOUCH_H_

// Includes
#include "stm32f103ve.h"

// Definitions
#define TOUCH_SPI_BAUDRATE				5	// TODO: check maximum baudrate!
#define TOUCH_IRQ_PRIORITY				8	// FIXME: STM different interrupts than LPC!
#define TOUCH_IRQ_NUMBER				EXTI9_5_IRQn
#define TOUCH_IRQ_HANDLER				EXTI9_5_IRQHandler

#ifndef __ASSEMBLER__

// Global functions
extern void TOUCH_Init (void);
extern void TOUCH_Read (uint16_t * buffer, uint32_t count);

#endif//__ASSEMBLER__

#endif//_TOUCH_H_
