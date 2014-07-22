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

// Global functions
extern void PIN_Configure (uint32_t port, uint32_t pin, uint32_t function);

#endif//__ASSEMBLER__

#endif//_PIN_H_
