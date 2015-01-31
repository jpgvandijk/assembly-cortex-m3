/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _TOUCH_H_
#define _TOUCH_H_

// Includes
#include "stm32f103ve.h"
#include "config.h"

#ifdef _USE_TOUCH_

#ifndef __ASSEMBLER__

// Global functions
extern void TOUCH_Init (void);
extern void TOUCH_Read (uint16_t * buffer, uint32_t count);

#endif//__ASSEMBLER__

#endif//_USE_TOUCH_

#endif//_TOUCH_H_
