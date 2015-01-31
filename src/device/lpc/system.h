/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _SYSTEM_H_
#define _SYSTEM_H_

// Includes
#include "lpc1769.h"

#ifndef __ASSEMBLER__

// Global variables
extern uint32_t SystemClock;

// Global functions
extern void SystemInitClock (void);
extern void SystemGetClock (void);
extern void SystemDelayMs (uint32_t milliseconds);
extern void SystemDisablePeripheral (uint32_t peripheral);
extern void SystemInitPeripheral (uint32_t peripheral, uint32_t clock_divider);

#endif//__ASSEMBLER__

#endif//_SYSTEM_H_
