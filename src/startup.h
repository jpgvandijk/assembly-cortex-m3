/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _STARTUP_H_
#define _STARTUP_H_

// Includes
#include "config.h"
#ifdef LPC
	#include "lpc1769.h"
#endif
#ifdef STM
	#include "stm32f103ve.h"
#endif

// Definitions
#define CRP_WORD				CRP_NO_CRP

#ifndef __ASSEMBLER__

// Structures
typedef struct
{
	uint32_t * data_LoadAddress;
	uint32_t * data_StartAddress;
	uint32_t * data_EndAddress;
	uint32_t * data_AHB_LoadAddress;
	uint32_t * data_AHB_StartAddress;
	uint32_t * data_AHB_EndAddress;
	uint32_t * bss_StartAddress;
	uint32_t * bss_EndAddress;
	uint32_t * bss_AHB_StartAddress;
	uint32_t * bss_AHB_EndAddress;
} SectionTableType;

// Global constants
extern uint32_t InterruptVectors[51];
extern SectionTableType SectionTable;
extern uint32_t CRPWord;

// Global functions
extern void InitDataSection (uint32_t * data_LoadAddress, uint32_t * data_StartAddress, uint32_t * data_EndAddress);
extern void InitBssSection (uint32_t * bss_StartAddress, uint32_t * bss_EndAddress, uint32_t bss_ClearValue);
extern void Reset_Handler (void);

#endif//__ASSEMBLER__

#endif//_STARTUP_H_
