/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

// Includes
#include <stdint.h>
#include "stm32f103ve.h"
#include "kernel.h"
#include "config.h"
#include "system.h"
#include "spi1.h"
#include "flash.h"
#include "spi2.h"
#include "enc28j60.h"
#include "ethernet.h"
#include "tcp.h"
#include "http.h"
#include "http_config.h"
#include "webserver.h"
#include "controls_handler.h"
#include "data/Web.h"

// Function prototypes
void TaskENC (uint32_t arg);

// Global variables
const KERNEL_TaskDescriptor TaskDescriptor_TaskENC = {TaskENC, 0, (KERNEL_MinimumTaskStackSpace + 1024), 0, "ENC"};

// Main
void main (void)
{
	// Init the system clock
	SystemInitClock();
	
	// Enable the peripherals
	SystemEnablePeripheral(PERIPHERAL_AFIO);
	SystemEnablePeripheral(PERIPHERAL_IOPA);
	SystemEnablePeripheral(PERIPHERAL_IOPB);
	SystemEnablePeripheral(PERIPHERAL_IOPC);
	SystemEnablePeripheral(PERIPHERAL_IOPD);
	SystemEnablePeripheral(PERIPHERAL_IOPE);
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
	// FIXME: initialize the controls
	Controls_InitHandler();

	// Initialize the webpages
	HTTP_Init();

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

void TCP_HandleClientRequest (void)
{
	// Write request starting at (ETH_TCP_OPTIONS)
	FLASH_ReadBytes(WEB_REQUEST_ADDRESS, &ETH_Buffer[ETH_TCP_OPTIONS], WEB_REQUEST_SIZE);
	ETH_SendTCPData(WEB_REQUEST_SIZE, 0);
}

void TCP_HandleServerRequest (uint32_t headerLength, uint32_t payloadLength)
{
	// Analyse data starting at (ETH_TCP_SRC_PORT + headerLength) with size (payloadLength)
	// Write response starting at (ETH_TCP_OPTIONS)
	HTTP_Page * page = HTTP_AnalyzeRequest(ETH_Buffer + ETH_TCP_SRC_PORT + headerLength, payloadLength);
	HTTP_SendPage(page);
	Page_ActionHandler(page);
}
