/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _SPI3_H_
#define _SPI3_H_

// Includes
#include "stm32f103ve.h"
#include "kernel.h"

// Configuration
#define SPI3_EXCLUSIVE_ACCESS_DELAY 			0

#ifndef __ASSEMBLER__

// Global variables
extern uint8_t SPI3_ExclusiveAccess[1];

// Global functions
extern void SPI3_GetExclusiveAccess (uint32_t baudrate);
extern void SPI3_ClearExclusiveAccess (void);
extern void SPI3_Init (void);
extern uint8_t SPI3_Transfer (uint8_t data);
extern void SPI3_EnableDefault (void);
extern void SPI3_DisableDefault (void);

#endif//__ASSEMBLER__

#endif//_SPI3_H_
