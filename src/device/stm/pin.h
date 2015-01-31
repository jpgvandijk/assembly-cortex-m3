/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _PIN_H_
#define _PIN_H_

// Includes
#include "stm32f103ve.h"

#ifndef __ASSEMBLER__

// Macros
#define PIN_Set(port, pin)			(*((volatile uint32_t *) (STM_GPIOx + ((port)<<10) + GPIOx_BSRR)) = (1 << (pin)))
#define PIN_Reset(port, pin)		(*((volatile uint32_t *) (STM_GPIOx + ((port)<<10) + GPIOx_BRR )) = (1 << (pin)))
#define PIN_Read(port, pin)			(*((volatile uint32_t *) (STM_GPIOx + ((port)<<10) + GPIOx_IDR )) & (1 << (pin)))
#define PIN_ReadOutput(port, pin)	(*((volatile uint32_t *) (STM_GPIOx + ((port)<<10) + GPIOx_ODR )) & (1 << (pin)))

// Global functions
extern void PIN_Configure (uint32_t port, uint32_t pin, uint32_t function);

#endif//__ASSEMBLER__

#endif//_PIN_H_
