/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _WIRELESS_H_
#define _WIRELESS_H_

// Includes
#include "stm32f103ve.h"
#include "config.h"

#ifdef _USE_WIRELESS_

// State
#define WIRELESS_StateUnused 		0	// Must be zero!
#define WIRELESS_StateIdle 			1	// Must be one!
#define WIRELESS_StateBusy 			2
#define WIRELESS_StateSync			3

// Start of transfer result
#define WIRELESS_OK 				0
#define WIRELESS_Error 				1

// Exclusive access
#define WIRELESS_Access 			0
#define WIRELESS_NoAccess			1

#ifndef __ASSEMBLER__

// Global variables
extern uint32_t WIRELESS_TransferWord;
extern uint32_t WIRELESS_TransferSpecs;
extern uint8_t WIRELESS_TransferBits;
extern uint8_t WIRELESS_TransferRepeat;
extern uint16_t WIRELESS_TransferPulsewidth;
extern uint32_t WIRELESS_TransferPin;
extern uint32_t WIRELESS_TransferCallbackFunction;
extern uint8_t WIRELESS_TransferInternalCount;
extern uint8_t WIRELESS_TransferInternalStateAndLock;

// Global functions
extern void WIRELESS_Init (void);
extern uint32_t WIRELESS_InitPin (uint32_t port, uint32_t pin);
extern uint32_t WIRELESS_Tx (uint32_t pin, uint32_t data, uint32_t specs, void (*callback)(uint32_t * wireless_data));
extern void WIRELESS_TimerHandler (void);

#endif//__ASSEMBLER__

#endif//_USE_WIRELESS_

#endif//_WIRELESS_H_
