/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _UART1_H_
#define _UART1_H_

// Includes
#include "stm32f103ve.h"
#include "config.h"

#ifdef _USE_UART1_

#ifndef __ASSEMBLER__

// Global functions
extern void UART1_Init (void);
extern void UART1_Tx (char character);

#endif//__ASSEMBLER__

#endif//_USE_UART1_

#endif//_UART1_H_
