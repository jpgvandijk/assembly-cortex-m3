/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _PIN_H_
#define _PIN_H_

// Includes
#include "lpc1769.h"

#ifndef __ASSEMBLER__

// Global functions
extern void PIN_SetFunction (uint32_t port, uint32_t pin, uint32_t function);
extern void PIN_SetInputMode (uint32_t port, uint32_t pin, uint32_t pinmode);
extern void PIN_SetOutputMode  (uint32_t port, uint32_t pin, uint32_t pinmode_od);
extern uint32_t PIN_SetI2C0PinConfiguration (uint32_t configuration);

#endif//__ASSEMBLER__

#endif//_PIN_H_
