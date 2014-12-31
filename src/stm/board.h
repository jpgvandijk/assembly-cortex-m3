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

	// The ENC28J60 ethernet controller
	#define ENC_SS_PIN							12
	#define ENC_SS_GPIO							GPIOB
	#define ENC_SS_BRR							GPIOB_BRR
	#define ENC_SS_BSRR							GPIOB_BSRR
	#define ENC_RST_PIN							10
	#define ENC_RST_GPIO						GPIOB
	#define ENC_RST_BSRR						GPIOB_BSRR
	#define ENC_IRQ_PIN							11
	#define ENC_IRQ_GPIO						GPIOB
	#define ENC_IRQ_EXTICR						AFIO_EXTICR3
	#define ENC_IRQ_EXTICR_LSB					12
	#define ENC_IRQ_NUMBER						EXTI15_10_IRQn
	#define ENC_IRQ_HANDLER						EXTI15_10_IRQHandler
	#define ENC_SPI_GET_EXCLUSIVE_ACCESS		SPI2_GetExclusiveAccess
	#define ENC_SPI_CLEAR_EXCLUSIVE_ACCESS		SPI2_ClearExclusiveAccess
	#define ENC_SPI_ENABLE_DEFAULT				SPI2_EnableDefault
	#define ENC_SPI_DISABLE_DEFAULT				SPI2_DisableDefault
	#define ENC_SPI_ENABLE_RX_ONLY_DMA			SPI2_EnableRXOnlyWithDMA
	#define ENC_SPI_WAIT_RX_ONLY_DMA			SPI2_WaitRXOnlyWithDMA
	#define ENC_SPI_DISABLE_RX_ONLY_DMA			SPI2_DisableRXOnlyWithDMA
	#define ENC_SPI_ENABLE_TX_ONLY_DMA			SPI2_EnableTXOnlyWithDMA
	#define ENC_SPI_WAIT_TX_ONLY_DMA			SPI2_WaitTXOnlyWithDMA
	#define ENC_SPI_DISABLE_TX_ONLY_DMA			SPI2_DisableTXOnlyWithDMA
	#define ENC_SPI_TRANSFER					SPI2_Transfer

	#define ENC_MAC0							0x54
	#define ENC_MAC1							0x55
	#define ENC_MAC2							0x58
	#define ENC_MAC3							0x10
	#define ENC_MAC4							0x00
	#define ENC_MAC5							0x24

	#define ENC_IP0								192
	#define ENC_IP1								168
	#define ENC_IP2								2
	#define ENC_IP3								125

	#define SERVER_IP0							192
	#define SERVER_IP1							168
	#define SERVER_IP2							2
	#define SERVER_IP3							126

	#define ENC_DEVICE_CLIENT_PORT				85
	#define ENC_DEVICE_SERVER_PORT				80

	#define ETH_BUFFER_SIZE						0x0600

	#define ETH_SUPPORT_ICMP
	//#define ETH_SUPPORT_TCP_CLIENT
	//#define ETH_SUPPORT_TCP_SERVER

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
