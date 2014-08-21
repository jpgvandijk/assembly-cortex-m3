/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _SPI1_H_
#define _SPI1_H_

// Includes
#include "stm32f103ve.h"
#include "kernel.h"

// Configuration
#define SPI1_EXCLUSIVE_ACCESS_DELAY 			1

#ifndef __ASSEMBLER__

// Global variables
extern uint8_t SPI1_ExclusiveAccess[2];

// Global functions
extern void SPI1_GetExclusiveAccess (uint32_t baudrate);
extern void SPI1_ClearExclusiveAccess (void);
extern void SPI1_Init (void);
extern uint8_t SPI1_Transfer (uint8_t data);
extern void SPI1_EnableDefault (void);
extern void SPI1_DisableDefault (void);
extern void SPI1_EnableRXOnlyWithDMA (uint8_t * buffer, uint32_t count);
extern void SPI1_WaitRXOnlyWithDMA (void);
extern void SPI1_DisableRXOnlyWithDMA (void);

#endif//__ASSEMBLER__

#endif//_SPI1_H_
