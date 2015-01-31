/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _SPI2_H_
#define _SPI2_H_

// Includes
#include "stm32f103ve.h"
#include "kernel.h"
#include "config.h"

#ifdef _USE_SPI2_

// Configuration
#define SPI2_EXCLUSIVE_ACCESS_DELAY 			1

#ifndef __ASSEMBLER__

// Global variables
extern uint8_t SPI2_ExclusiveAccess[2];

// Global functions
extern void SPI2_GetExclusiveAccess (uint32_t baudrate);
extern void SPI2_ClearExclusiveAccess (void);
extern void SPI2_Init (void);
extern uint8_t SPI2_Transfer (uint8_t data);
extern void SPI2_EnableDefault (void);
extern void SPI2_DisableDefault (void);
extern void SPI2_EnableRXOnlyWithDMA (uint8_t * buffer, uint32_t count);
extern void SPI2_WaitRXOnlyWithDMA (void);
extern void SPI2_DisableRXOnlyWithDMA (void);
extern void SPI2_EnableTXOnlyWithDMA (uint8_t * buffer, uint32_t count);
extern void SPI2_WaitTXOnlyWithDMA (void);
extern void SPI2_DisableTXOnlyWithDMA (void);

#endif//__ASSEMBLER__

#endif//_USE_SPI2_

#endif//_SPI2_H_
