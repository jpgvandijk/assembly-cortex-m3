/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _CONFIG_H_
#define _CONFIG_H_

// Select the target
#define STM

/************************************************************
* KERNEL													*
************************************************************/

// Include the kernel
#define _USE_KERNEL_

// Definition to ease kernel debugging, task switching info will be printed over ITM port 0
#ifdef DEBUG
	#define DEBUG_KERNEL
#endif

// The amount of memory that can be dynamically allocated and freed
// Must be a multiple of 4 bytes!
// For 2048 bytes max:
//	1 block of 2040 bytes (0.39% overhead, best-case)
//	170 blocks of 1 byte (92% overhead, worst-case)
#define CONFIG_HeapSize 							2048

// The maximum number of tasks alive, one is used for the idle task
#define CONFIG_TaskTableEntries 					10

// The number of task priorities, the lowest priority must be reserved for the idle task
#define CONFIG_ImplementedPriorities 				4

// Configure the interrupt priorities
#define CONFIG_PriorityGrouping 					PriorityGrouping_Preempt2Sub3	// 4 preemption levels and 8 sublevels
#define CONFIG_PrioritySysTick 						((0 << 3) | 0)					// Highest priority (should not be missed and very fast handler)
#define CONFIG_PrioritySVC 							((2 << 3) | 0)					// Only preempts preempt priority 3 (lowest)
#define CONFIG_PriorityPendSV 						((3 << 3) | 7)					// Lowest priority

/************************************************************
* ONEWIRE													*
************************************************************/

// Include the onewire driver
#define _USE_ONEWIRE_

// Configure the interrupt priority
#define OW_TimerPriority							1

// Hardware
#ifdef LPC
	#define OW_Timer 								LPC_TIM0
	#define OW_TimerPeripheral 						PERIPHERAL_TIM0
	#define OW_TimerIRQn 							TIMER0_IRQn
	#define OW_TimerHandler 						TIMER0_IRQHandler
#endif
#ifdef STM
	#define OW_Timer 								STM_TIM2
	#define OW_TimerPeripheral 						PERIPHERAL_TIM2
	#define OW_TimerIRQn 							TIM2_IRQn
	#define OW_TimerHandler 						TIM2_IRQHandler
#endif

// Timing
#ifdef LPC
	#define OW_TicksPerMicroSecond 					120
#endif
#ifdef STM
	#define OW_TicksPerMicroSecond 					36
#endif

// Buffer configuration
#define OW_WriteBufferSize 							16		// = 128-bit max, count allows for 64-kbits
#define OW_ReadBufferSize 							16		// = 128-bit max, count allows for 64-kbits

// Bitband addresses
#ifdef LPC
	#define OW_TransferWriteBufferBitband			(0x22000000 + 32 * (0x2007C000 - 0x20000000))
	#define OW_TransferReadBufferBitband			(0x22000000 + 32 * (0x2007C010 - 0x20000000))
	#define OWSearch_ROMBitband						(0x22000000 + 32 * (0x2007C020 - 0x20000000))
#endif
#ifdef STM
	#define OW_TransferWriteBufferBitband			(0x22000000 + 32 * (0x20000000 - 0x20000000))
	#define OW_TransferReadBufferBitband			(0x22000000 + 32 * (0x20000010 - 0x20000000))
	#define OWSearch_ROMBitband						(0x22000000 + 32 * (0x20000020 - 0x20000000))
#endif

#endif//_CONFIG_H_
