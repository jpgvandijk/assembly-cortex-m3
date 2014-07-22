/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _FLASH_H_
#define _FLASH_H_

// Includes
#include "stm32f103ve.h"

// Definitions
#define FLASH_SPI_BAUDRATE				0

#ifndef __ASSEMBLER__

// Global functions
extern void FLASH_Init (void);
extern uint8_t FLASH_ReadByte (void * address);
extern void FLASH_ReadBytes (void * address, uint8_t * buffer, uint32_t count);

#endif//__ASSEMBLER__

#endif//_FLASH_H_
