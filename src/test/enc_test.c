/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifdef STM

// Includes
#include <stdint.h>
#include "stm32f103ve.h"
#include "kernel.h"
#include "system.h"
#include "spi1.h"
#include "flash.h"
#include "spi2.h"
#include "enc28j60.h"
#include "ethernet.h"
#include "tcp.h"
#include "board.h"

// Function prototypes
void TaskENC (uint32_t arg);

// Global variables
const KERNEL_TaskDescriptor TaskDescriptor_TaskENC = {TaskENC, 0, (KERNEL_MinimumTaskStackSpace + 1024), 0, "ENC"};

// Main
void enc_test (void)
{
	// Enable the DMA1
	SystemEnablePeripheral(PERIPHERAL_DMA1);

	// Init the FLASH chip and SPI module
	// Init the ENC chip and SPI module
	FLASH_Init();
	SPI1_Init();
	SPI2_Init();
	ENC_Init();

	// Init kernel
	KERNEL_Init();

	// Create tasks
	KERNEL_AddTask(&TaskDescriptor_TaskENC);

	// Start kernel (this function never returns)
	KERNEL_Start();
}

void TaskENC (uint32_t arg)
{
	// Get exclusive access to the SPI module
	SPI1_GetExclusiveAccess(FLASH_SPI_BAUDRATE);

	// Reset and configure the controller
	ENC_Reset();
	ENC_EnableReceiver();

	// Handle incoming packets
	while (1)
	{
		// Wait for a packet to be available
		ENC_TaskWaitForPacketAvailable();

		// Read the packet, don't process if there was an error
		ETH_Size = ENC_ReceivePacket(ETH_Buffer, ETH_BUFFER_SIZE);

		// Analyze the packet
		uint32_t result = ETH_AnalyzePacket();
		if (result == ETH_ANALYZE_TYPE_ARP)
			ETH_SendARPReply();
		else if (result == ETH_ANALYZE_TYPE_ICMP_REQUEST)
			ETH_SendICMPReply();
		else if (result == ETH_ANALYZE_TYPE_TCP_CLIENT)
			TCP_HandleClient();
		else if (result == ETH_ANALYZE_TYPE_TCP_SERVER)
			TCP_HandleServer();
	}

	// Clear access to the module
	SPI1_ClearExclusiveAccess();
}

#endif//STM
