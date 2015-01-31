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
* ETHERNET													*
************************************************************/

// Include drivers
#define _USE_SPI2_
#define _USE_ETHERNET_
#define _USE_TCP_
#define _USE_HTTP_

// Configuration
#define ETH_BUFFER_SIZE								0x0600
#define ETH_SUPPORT_ICMP
#define ETH_SUPPORT_TCP_CLIENT
#define ETH_SUPPORT_TCP_SERVER

// Definitions
#define ENC_SPI_BAUDRATE							1
#define ENC_IRQ_PRIORITY							8

// The ENC28J60 ethernet controller
#define ENC_SS_PIN									12
#define ENC_SS_GPIO									GPIOB
#define ENC_SS_BRR									GPIOB_BRR
#define ENC_SS_BSRR									GPIOB_BSRR
#define ENC_RST_PIN									10
#define ENC_RST_GPIO								GPIOB
#define ENC_RST_BSRR								GPIOB_BSRR
#define ENC_IRQ_PIN									11
#define ENC_IRQ_GPIO								GPIOB
#define ENC_IRQ_EXTICR								AFIO_EXTICR3
#define ENC_IRQ_EXTICR_LSB							12
#define ENC_IRQ_NUMBER								EXTI15_10_IRQn
#define ENC_IRQ_HANDLER								EXTI15_10_IRQHandler
#define ENC_SPI_GET_EXCLUSIVE_ACCESS				SPI2_GetExclusiveAccess
#define ENC_SPI_CLEAR_EXCLUSIVE_ACCESS				SPI2_ClearExclusiveAccess
#define ENC_SPI_ENABLE_DEFAULT						SPI2_EnableDefault
#define ENC_SPI_DISABLE_DEFAULT						SPI2_DisableDefault
#define ENC_SPI_ENABLE_RX_ONLY_DMA					SPI2_EnableRXOnlyWithDMA
#define ENC_SPI_WAIT_RX_ONLY_DMA					SPI2_WaitRXOnlyWithDMA
#define ENC_SPI_DISABLE_RX_ONLY_DMA					SPI2_DisableRXOnlyWithDMA
#define ENC_SPI_ENABLE_TX_ONLY_DMA					SPI2_EnableTXOnlyWithDMA
#define ENC_SPI_WAIT_TX_ONLY_DMA					SPI2_WaitTXOnlyWithDMA
#define ENC_SPI_DISABLE_TX_ONLY_DMA					SPI2_DisableTXOnlyWithDMA
#define ENC_SPI_TRANSFER							SPI2_Transfer

// Device MAC address
#define ENC_MAC0									0x54
#define ENC_MAC1									0x55
#define ENC_MAC2									0x58
#define ENC_MAC3									0x10
#define ENC_MAC4									0x00
#define ENC_MAC5									0x24

// Device IP address
#define ENC_IP0										192
#define ENC_IP1										168
#define ENC_IP2										2
#define ENC_IP3										125

// Device TCP ports
#define ENC_DEVICE_CLIENT_PORT_LE					(85 << 8)
#define ENC_DEVICE_SERVER_PORT_LE					(80 << 8)

// Server MAC address
#define SERVER_MAC0									0xD8
#define SERVER_MAC1									0x50
#define SERVER_MAC2									0xE6
#define SERVER_MAC3									0x0A
#define SERVER_MAC4									0x98
#define SERVER_MAC5									0x27

// Server IP address
#define SERVER_IP0									192
#define SERVER_IP1									168
#define SERVER_IP2									2
#define SERVER_IP3									126

// Server TCP port
#define SERVER_PORT_LE								0x401F

/************************************************************
* FLASH														*
************************************************************/

// Include drivers
#define _USE_SPI1_
#define _USE_FLASH_

// Configure flash baudrate
#define FLASH_SPI_BAUDRATE							0

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

#endif

#endif//_CONFIG_H_
