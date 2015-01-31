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
* TOUCH														*
************************************************************/

// Task configuration
#define TASK_TOUCH_STACK_SIZE						(KERNEL_MinimumTaskStackSpace + 64)
#define TASK_TOUCH_PRIORITY							0
#define TASK_TOUCH_PERIOD							20
#define TASK_TOUCH_QUEUE_SIZE						32
#define TASK_TOUCH_LOCK_TIMEOUT						5

// Touch tuning
#define TOUCH_TAP_MIN_TIME							1
#define TOUCH_DOUBLE_TAP_MIN_TIME					5
#define TOUCH_DOUBLE_TAP_MAX_TIME					15
#define TOUCH_SCREEN_RESISTANCE						16
#define TOUCH_MIN_PRESSURE							30
#define TOUCH_X_MIN									250
#define TOUCH_X_MAX									3770
#define TOUCH_X_SCALE								11
#define TOUCH_Y_MIN									250
#define TOUCH_Y_MAX									3610
#define TOUCH_Y_SCALE								14
#define TOUCH_CLOSE_DISTANCE						25
#define TOUCH_HOLD_THRESHOLD						100

/************************************************************
* FLASH / TFT / TOUCH										*
************************************************************/

// Include drivers
#define _USE_SPI1_
#define _USE_FLASH_
#define _USE_TFT_
#define _USE_SPI3_
#define _USE_TOUCH_
#define _USE_TASK_TOUCH_

// Configure flash baudrate
#define FLASH_SPI_BAUDRATE							0

// Configure TFT
#define TFT_CACHE_WIDTH_SIZE						96
#define TFT_CACHE_CHAR_SIZE							384		// max: tft area/25!
#define TFT_CHAR_SPACING							1

// Configure touch baudrate/priority
#define TOUCH_SPI_BAUDRATE							4
#define TOUCH_IRQ_PRIORITY							8

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

	// The XPT2046 touch controller
	#define TOUCH_SS_PIN						15
	#define TOUCH_SS_GPIO						GPIOA
	#define TOUCH_SS_BRR						GPIOA_BRR
	#define TOUCH_SS_BSRR						GPIOA_BSRR
	#define TOUCH_IRQ_PIN						6
	#define TOUCH_IRQ_GPIO						GPIOB
	#define TOUCH_IRQ_IDR						GPIOB_IDR
	#define TOUCH_IRQ_EXTICR					AFIO_EXTICR2
	#define TOUCH_IRQ_EXTICR_LSB				8
	#define TOUCH_IRQ_NUMBER					EXTI9_5_IRQn
	#define TOUCH_IRQ_HANDLER					EXTI9_5_IRQHandler
	#define TOUCH_SPI_GET_EXCLUSIVE_ACCESS		SPI3_GetExclusiveAccess
	#define TOUCH_SPI_CLEAR_EXCLUSIVE_ACCESS	SPI3_ClearExclusiveAccess
	#define TOUCH_SPI_ENABLE_DEFAULT			SPI3_EnableDefault
	#define TOUCH_SPI_DISABLE_DEFAULT			SPI3_DisableDefault
	#define TOUCH_SPI_TRANSFER					SPI3_Transfer
	
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

	// The XPT2046 touch controller
	#define TOUCH_SS_PIN						7
	#define TOUCH_SS_GPIO						GPIOB
	#define TOUCH_SS_BRR						GPIOB_BRR
	#define TOUCH_SS_BSRR						GPIOB_BSRR
	#define TOUCH_IRQ_PIN						6
	#define TOUCH_IRQ_GPIO						GPIOB
	#define TOUCH_IRQ_IDR						GPIOB_IDR
	#define TOUCH_IRQ_EXTICR					AFIO_EXTICR2
	#define TOUCH_IRQ_EXTICR_LSB				8
	#define TOUCH_IRQ_NUMBER					EXTI9_5_IRQn
	#define TOUCH_IRQ_HANDLER					EXTI9_5_IRQHandler
	#define TOUCH_SPI_GET_EXCLUSIVE_ACCESS		SPI1_GetExclusiveAccess
	#define TOUCH_SPI_CLEAR_EXCLUSIVE_ACCESS	SPI1_ClearExclusiveAccess
	#define TOUCH_SPI_ENABLE_DEFAULT			SPI1_EnableDefault
	#define TOUCH_SPI_DISABLE_DEFAULT			SPI1_DisableDefault
	#define TOUCH_SPI_TRANSFER					SPI1_Transfer
	
	// TFT
	#define TFT_RESET_PIN						1
	#define TFT_RESET_GPIO						GPIOE
	#define TFT_RESET_GPIO_REGS					STM_GPIOE
	
#endif

#endif//_CONFIG_H_
