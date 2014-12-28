/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _BOARD_H_
#define _BOARD_H_

#ifdef STM_BOARD_CUSTOM

	/********************************************************************************
	* CUSTOM BOARD
	********************************************************************************/

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

	/********************************************************************************
	* HY-STM32 BOARD
	********************************************************************************/

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

#endif//_BOARD_H_
