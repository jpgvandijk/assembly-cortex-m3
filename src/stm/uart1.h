/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _UART1_H_
#define _UART1_H_

// Includes
#include "stm32f103ve.h"

#ifndef __ASSEMBLER__

// Global functions
extern void UART1_Init (void);
extern void UART1_Tx (char character);

#endif//__ASSEMBLER__

#endif//_UART1_H_
