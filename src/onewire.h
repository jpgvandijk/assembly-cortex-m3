/************************************************************************************
*
* Author: J.P.G. van Dijk
*
* FIXME: bitband addresses must be checked after linking!
*
************************************************************************************/

#ifndef _ONEWIRE_H_
#define _ONEWIRE_H_

// Includes
#ifdef LPC
	#include "lpc1769.h"
#endif
#ifdef STM
	#include "stm32f103ve.h"
#endif

// Configuration
#define OW_WriteBufferSize 				16		// = 128-bit max, count allows for 64-kbits
#define OW_ReadBufferSize 				16		// = 128-bit max, count allows for 64-kbits

// Bitband addresses
#ifdef LPC
	#define OW_TransferWriteBufferBitband	(0x22000000 + 32 * (0x2007C000 - 0x20000000))
	#define OW_TransferReadBufferBitband	(0x22000000 + 32 * (0x2007C010 - 0x20000000))
	#define OWSearch_ROMBitband				(0x22000000 + 32 * (0x2007C020 - 0x20000000))
#endif
#ifdef STM
	#define OW_TransferWriteBufferBitband	(0x22000000 + 32 * (0x20000000 - 0x20000000))
	#define OW_TransferReadBufferBitband	(0x22000000 + 32 * (0x20000010 - 0x20000000))
	#define OWSearch_ROMBitband				(0x22000000 + 32 * (0x20000020 - 0x20000000))
#endif

// Hardware
#ifdef LPC
	#define OW_Timer 					LPC_TIM0
	#define OW_TimerPeripheral 			PERIPHERAL_TIM0
	#define OW_TimerIRQn 				TIMER0_IRQn
	#define OW_TimerHandler 			TIMER0_IRQHandler
#endif
#ifdef STM
	#define OW_Timer 					STM_TIM2
	#define OW_TimerPeripheral 			PERIPHERAL_TIM2
	#define OW_TimerIRQn 				TIM2_IRQn
	#define OW_TimerHandler 			TIM2_IRQHandler
#endif

// Timing
#ifdef LPC
	#define OW_TicksPerMicroSecond 		120
#endif
#ifdef STM
	#define OW_TicksPerMicroSecond 		36
#endif

// Timing
#define OW_Period 					(70 * OW_TicksPerMicroSecond)
#define OW_PeriodReset 				(1000 * OW_TicksPerMicroSecond)
#define OW_DelayWrite0Release 		(65 * OW_TicksPerMicroSecond)
#define OW_DelayWrite1Release 		(5 * OW_TicksPerMicroSecond)
#define OW_DelayReadRelease 		(3 * OW_TicksPerMicroSecond)
#define OW_DelayReadSample 			(13 * OW_TicksPerMicroSecond)
#define OW_DelayResetRelease 		(500 * OW_TicksPerMicroSecond)
#define OW_DelayResetSample 		(580 * OW_TicksPerMicroSecond)

// Data offsets
#define OW_TransferResetAndStatusOffset 	3
#define OW_TransferWriteNBitsOffset 		4
#define OW_TransferReadNBitsOffset 			6
#define OW_TransferPinOffset 				8
#define OW_TransferCallbackFunctionOffset 	12

// State
#define OW_StateUnused 				0	// Must be zero!
#define OW_StateIdle 				1	// Must be one!
#define OW_StateReset 				2
#define OW_StateWrite 				3
#define OW_StateRead 				4

// Start of transfer  search result
#define OW_OK 						0
#define OW_Error 					1
#define OW_Last 					2

// Exclusive access
#define OW_Access 					0
#define OW_NoAccess 				1

#ifndef __ASSEMBLER__

// Global variables
extern uint16_t OW_TransferInternalCount;
extern uint8_t OW_TransferInternalStateAndLock;
extern uint8_t OW_TransferResetAndStatus;
extern uint16_t OW_TransferWriteNBits;
extern uint16_t OW_TransferReadNBits;
extern uint32_t OW_TransferPin;
extern uint32_t OW_TransferCallbackFunction;
extern uint8_t OW_TransferWriteBuffer[OW_WriteBufferSize];
extern uint8_t OW_TransferReadBuffer[OW_ReadBufferSize];
extern uint32_t OWSearch_CallbackFunction;
extern uint8_t OWSearch_CountAndStatus;
extern int8_t OWSearch_LastZero;
extern int8_t OWSearch_LastDiscrepancy;
extern uint64_t OWSearch_ROM;

// Global functions
extern void TIMER0_IRQHandler (void);
extern uint32_t OW_StartTransfer (uint32_t pin, uint32_t reset, uint32_t readwrite, void (*callback)(uint32_t * ow_data));
extern void OW_Init (void);
extern uint32_t OW_InitPin (uint32_t port, uint32_t pin);
extern void OWSearch_Init (void);
extern void OWSearch_Reset (void);
extern uint32_t OWSearch_Next (uint32_t pin, void (*callback)(uint32_t status, uint32_t * owsearch_data));
extern void OWSearch_Algorithm (uint32_t * OW_TransferData);
extern uint32_t OW_CheckCRC8 (uint8_t * buffer, uint32_t count);

#endif//__ASSEMBLER__

#endif//_ONEWIRE_H_
