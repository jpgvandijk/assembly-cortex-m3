/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _SYSTEM_H_
#define _SYSTEM_H_

// Includes
#include "stm32f103ve.h"

#ifndef __ASSEMBLER__

// Global variables
extern uint32_t SystemClock;

// Global functions
extern void SystemInitClock (void);
extern void SystemGetClock (void);
extern void SystemDelayMs (uint32_t milliseconds);
extern void SystemDisablePeripheral (uint32_t peripheral);
extern void SystemEnablePeripheral (uint32_t peripheral);
extern void SystemResetPeripheral (uint32_t peripheral);

#endif//__ASSEMBLER__

#endif//_SYSTEM_H_
