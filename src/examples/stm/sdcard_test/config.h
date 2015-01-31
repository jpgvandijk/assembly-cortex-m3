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
* SD-CARD													*
************************************************************/

// Include drivers
#define _USE_UART1_
#define _USE_SPI1_
#define _USE_SDCARD_
#define _USE_FAT_

// Configure the SD-card
#define SDCARD_SPI_BAUDRATE_INIT					7
#define SDCARD_SPI_BAUDRATE							0
#define SDCARD_AUTODETECT
#define SDCARD_CARD_DETECTION_PERIOD				500
#define SDCARD_CARD_DETECTION_DELAY					1000
#define SDCARD_INIT_DELAY_MS						2
#define SDCARD_INIT_DELAY_CYCLES					20
#define SDCARD_INIT_IDLE_DELAY_MS					10
#define SDCARD_READ_TOKEN_TIMEOUT					100000
#define SDCARD_COMMAND_TIMEOUT						10

// CUSTOM BOARD or HY-STM32 BOARD
#ifdef STM_BOARD_CUSTOM

	// SD-Card
	#define SDCARD_PIN							3
	#define SDCARD_GPIO							GPIOA
	#define SDCARD_BRR							GPIOA_BRR
	#define SDCARD_BSRR							GPIOA_BSRR
	#define SDCARD_GPIO_REGS					STM_GPIOA
	#define SDCARD_SPI_GET_EXCLUSIVE_ACCESS		SPI1_GetExclusiveAccess
	#define SDCARD_SPI_CLEAR_EXCLUSIVE_ACCESS	SPI1_ClearExclusiveAccess
	#define SDCARD_SPI_ENABLE_DEFAULT			SPI1_EnableDefault
	#define SDCARD_SPI_DISABLE_DEFAULT			SPI1_DisableDefault
	#define SDCARD_SPI_ENABLE_RX_ONLY_DMA		SPI1_EnableRXOnlyWithDMA
	#define SDCARD_SPI_WAIT_RX_ONLY_DMA			SPI1_WaitRXOnlyWithDMA
	#define SDCARD_SPI_DISABLE_RX_ONLY_DMA		SPI1_DisableRXOnlyWithDMA
	#define SDCARD_SPI_ENABLE_TX_ONLY_DMA		SPI1_EnableTXOnlyWithDMA
	#define SDCARD_SPI_WAIT_TX_ONLY_DMA			SPI1_WaitTXOnlyWithDMA
	#define SDCARD_SPI_DISABLE_TX_ONLY_DMA		SPI1_DisableTXOnlyWithDMA
	#define SDCARD_SPI_TRANSFER					SPI1_Transfer
	
#else

	// SD-Card
	#define SDCARD_PIN							6
	#define SDCARD_GPIO							GPIOD
	#define SDCARD_BRR							GPIOD_BRR
	#define SDCARD_BSRR							GPIOD_BSRR
	#define SDCARD_GPIO_REGS					STM_GPIOD
	#define SDCARD_SPI_GET_EXCLUSIVE_ACCESS		SPI1_GetExclusiveAccess
	#define SDCARD_SPI_CLEAR_EXCLUSIVE_ACCESS	SPI1_ClearExclusiveAccess
	#define SDCARD_SPI_ENABLE_DEFAULT			SPI1_EnableDefault
	#define SDCARD_SPI_DISABLE_DEFAULT			SPI1_DisableDefault
	#define SDCARD_SPI_ENABLE_RX_ONLY_DMA		SPI1_EnableRXOnlyWithDMA
	#define SDCARD_SPI_WAIT_RX_ONLY_DMA			SPI1_WaitRXOnlyWithDMA
	#define SDCARD_SPI_DISABLE_RX_ONLY_DMA		SPI1_DisableRXOnlyWithDMA
	#define SDCARD_SPI_ENABLE_TX_ONLY_DMA		SPI1_EnableTXOnlyWithDMA
	#define SDCARD_SPI_WAIT_TX_ONLY_DMA			SPI1_WaitTXOnlyWithDMA
	#define SDCARD_SPI_DISABLE_TX_ONLY_DMA		SPI1_DisableTXOnlyWithDMA
	#define SDCARD_SPI_TRANSFER					SPI1_Transfer
	
#endif

#endif//_CONFIG_H_
