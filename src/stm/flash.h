/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _FLASH_H_
#define _FLASH_H_

// Includes
#include "stm32f103ve.h"
#include "config.h"

#ifdef _USE_FLASH_

// Definitions
#define FLASH_BASE_ADDRESS				__ext_StartAddress
#define FROM_EXTERNAL_FLASH(x)			((x) - FLASH_BASE_ADDRESS)
#define IN_EXTERNAL_FLASH				__attribute__ ((section (".ext")))

#ifndef __ASSEMBLER__

// Global variables
extern uint32_t __ext_StartAddress;

// Global functions
extern void FLASH_Init (void);
extern uint8_t FLASH_ReadByte (void * address);
extern void FLASH_ReadBytes (void * address, uint8_t * buffer, uint32_t count);

#endif//__ASSEMBLER__

#endif//_USE_FLASH_

#endif//_FLASH_H_
