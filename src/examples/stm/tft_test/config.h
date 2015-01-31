/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _CONFIG_H_
#define _CONFIG_H_

// Select the target
#define STM
#define STM_BOARD_CUSTOM

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
* FLASH / TFT												*
************************************************************/

// Include drivers
#define _USE_SPI1_
#define _USE_FLASH_
#define _USE_TFT_

// Configure flash baudrate
#define FLASH_SPI_BAUDRATE							0

// Configure TFT
#define TFT_CACHE_WIDTH_SIZE						96
#define TFT_CACHE_CHAR_SIZE							384		// max: tft area/25!
#define TFT_CHAR_SPACING							1

// CUSTOM BOARD or HY-STM32 BOARD
#ifdef STM_BOARD_CUSTOM

	// The M25P16 flash chip
	#define FLASH_PIN							4
	#define FLASH_GPIO							GPIOA
	#define FLASH_BRR							GPIOA_BRR
	#define FLASH_BSRR							GPIOA_BSRR
	#define FLASH_SPI_ENABLE_DEFAULT			SPI1_EnableDefault
	#define FLASH_SPI_DISABLE_DEFAULT			SPI1_DisableDefault
	#define FLASH_SPI_ENABLE_RX_ONLY_DMA		SPI1_EnableRXOnlyWithDMA
	#define FLASH_SPI_WAIT_RX_ONLY_DMA			SPI1_WaitRXOnlyWithDMA
	#define FLASH_SPI_DISABLE_RX_ONLY_DMA		SPI1_DisableRXOnlyWithDMA
	#define FLASH_SPI_TRANSFER					SPI1_Transfer

	// TFT
	#define TFT_RESET_PIN						6
	#define TFT_RESET_GPIO						GPIOD
	#define TFT_RESET_GPIO_REGS					STM_GPIOD
	#define TFT_LIGHT_PIN						3
	#define TFT_LIGHT_GPIO						GPIOD
	#define TFT_LIGHT_GPIO_REGS					STM_GPIOD
	
#else

	// The M25P16 flash chip
	#define FLASH_PIN							4
	#define FLASH_GPIO							GPIOA
	#define FLASH_BRR							GPIOA_BRR
	#define FLASH_BSRR							GPIOA_BSRR
	#define FLASH_SPI_ENABLE_DEFAULT			SPI1_EnableDefault
	#define FLASH_SPI_DISABLE_DEFAULT			SPI1_DisableDefault
	#define FLASH_SPI_ENABLE_RX_ONLY_DMA		SPI1_EnableRXOnlyWithDMA
	#define FLASH_SPI_WAIT_RX_ONLY_DMA			SPI1_WaitRXOnlyWithDMA
	#define FLASH_SPI_DISABLE_RX_ONLY_DMA		SPI1_DisableRXOnlyWithDMA
	#define FLASH_SPI_TRANSFER					SPI1_Transfer

	// TFT
	#define TFT_RESET_PIN						1
	#define TFT_RESET_GPIO						GPIOE
	#define TFT_RESET_GPIO_REGS					STM_GPIOE
	
#endif

#endif//_CONFIG_H_
