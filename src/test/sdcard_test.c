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
#include "tft.h"
#include "sdcard.h"
#include "print.h"

// Includes (data)
#include "data/Consolas10.h"

// Function prototypes
void TaskTFTLogCard (uint32_t arg);
void TaskSDCard (uint32_t arg);

// Global variables
const KERNEL_TaskDescriptor TaskDescriptor_TaskTFTLogCard = {TaskTFTLogCard, 0, (KERNEL_MinimumTaskStackSpace + 64), 0, "TFT"};
const KERNEL_TaskDescriptor TaskDescriptor_TaskSDCard = {TaskSDCard, 0, (KERNEL_MinimumTaskStackSpace + 64), 0, "SDC"};

volatile struct {
	uint8_t valid;
	struct {
		uint8_t type;
		uint32_t address;
		uint32_t size;
		uint8_t OEM_Name[8];
		struct
		{
			uint16_t BytesPerLogicalSector;
			uint8_t LogicalSectorsPerCluster;
			uint16_t CountOfReservedLogicalSectors;
			uint8_t NumberOfFileAllocationTables;
			uint16_t MaximumNumberOfRootEntries;
			uint16_t TotalLogicalSectors;
			uint8_t MediaDescriptor;
			uint16_t LogicalSectorsPerFAT;
		} BiosParameterBlock;
		uint8_t PartitionVolumeLabel[11];
		uint8_t FileSystemType[8]
	} partition[4];
} SDCardLog;

// Main
void sdcard_test (void)
{
	// Enable the DMA1
	SystemEnablePeripheral(PERIPHERAL_DMA1);
	
	// Init the FLASH chip and SPI module
	FLASH_Init();
	SPI1_Init();
	
	// Init kernel
	KERNEL_Init();

	// Create tasks
	KERNEL_AddTask(&TaskDescriptor_TaskTFTLogCard);
	KERNEL_AddTask(&TaskDescriptor_TaskSDCard);

	// Start kernel (this function never returns)
	KERNEL_Start();
}

uint16_t TFT_LogX = 0;
uint16_t TFT_LogY = 0;
void TFT_Log (char character)
{
	if (character == '\n')
	{
		TFT_LogY++;
		TFT_LogX = 0;
	}
	else if (character == '\t')
	{
		TFT_LogX = (TFT_LogX + 4) & ~0x03;
	}
	else
	{
		char array[2] = {character, '\0'};
		TFT_PrintString(6*TFT_LogX, 10*TFT_LogY, array);
		TFT_LogX++;
	}
}

void TaskTFTLogCard (uint32_t arg)
{
	// Init TFT (in task)
	TFT_Init();
	TFT_Color = 0xFFFF;
	TFT_SetArea(0, 319, 0, 239);

	// Wait for SD-card data
	while (!SDCardLog.valid)
		KERNEL_SVCForceContextSwitchDelay(10);

	// Print SD-card info
	TFT_Color = 0x0000;
	TFT_SelectFont(Consolas10);
	Printer printer = TFT_Log;
	uint32_t i;
	for (i = 0; i < 4; i++)
	{
		Print(Print(printer, PRINT_TEXT, (PrintArgument) "\nPartition:\t"), PRINT_UNSIGNED_8, (PrintArgument) i);
		if (SDCardLog.partition[i].type == 0x00)
			Print(printer, PRINT_TEXT, (PrintArgument) "\tunused");
		else if (SDCardLog.partition[i].type != 0x06)
		{
			Print(printer, PRINT_TEXT, (PrintArgument) "\tnon-FAT16");
			Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tAddress:\t"), PRINT_HEX_32, (PrintArgument) SDCardLog.partition[i].address);
			Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tSize:\t\t"), PRINT_HEX_32, (PrintArgument) SDCardLog.partition[i].size);
		}
		else
		{
			Print(printer, PRINT_TEXT, (PrintArgument) "\tFAT16");
			Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tAddress:\t"), PRINT_HEX_32, (PrintArgument) SDCardLog.partition[i].address);
			Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tSize:\t\t"), PRINT_HEX_32, (PrintArgument) SDCardLog.partition[i].size);
			Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tOEM:\t\t"), PRINT_CHARACTERS(8), (PrintArgument) (char *) &SDCardLog.partition[i].OEM_Name[0]);
			Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tName:\t\t"), PRINT_CHARACTERS(11), (PrintArgument) (char *) &SDCardLog.partition[i].PartitionVolumeLabel[0]);
			Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tType:\t\t"), PRINT_CHARACTERS(8), (PrintArgument) (char *) &SDCardLog.partition[i].FileSystemType[0]);
		}
	}
}

void TaskSDCard (uint32_t arg)
{
	// Init SDCARD (in task)
	SDCARD_Init();

	// Read MBR
	SPI1_GetExclusiveAccess(SDCARD_SPI_BAUDRATE);
	SDCARD_Read(0);
	SPI1_ClearExclusiveAccess();

	// Check if valid
	if ((SDCARD_Buffer[510] == 0x55) && (SDCARD_Buffer[511] == 0xAA))
	{
		// Read partition entries
		uint32_t i;
		for (i = 0; i < 4; i++)
		{
			uint32_t address = 446 + (i << 4);
			SDCardLog.partition[i].type = SDCARD_Buffer[address + 4];
			SDCardLog.partition[i].address = *(uint32_t *)(SDCARD_Buffer + address + 8);
			SDCardLog.partition[i].size = *(uint32_t *)(SDCARD_Buffer + address + 12);
		}

		// Read partitions
		for (i = 0; i < 4; i++)
		{
			// Skip non FAT16 partitions
			if (SDCardLog.partition[i].type != 0x06)
				continue;

			// Read boot sector
			SPI1_GetExclusiveAccess(SDCARD_SPI_BAUDRATE);
			SDCARD_Read(SDCardLog.partition[i].address);
			SPI1_ClearExclusiveAccess();

			// Copy OEM name
			uint32_t j;
			for (j = 0; j < 8; j++)
				SDCardLog.partition[i].OEM_Name[j] = SDCARD_Buffer[j + 3];

			// Get info from the bios parameter block
			uint8_t * write = (uint8_t *) &SDCardLog.partition[i].BiosParameterBlock;
			for (j = 0; j < 13; j++)
				write[j] = SDCARD_Buffer[j + 11];

			// Get other info
			for (j = 0; j < 11; j++)
				SDCardLog.partition[i].PartitionVolumeLabel[j] = SDCARD_Buffer[j + 43];
			for (j = 0; j < 8; j++)
				SDCardLog.partition[i].FileSystemType[j] = SDCARD_Buffer[j + 54];
		}

		// Set valid bit
		SDCardLog.valid = 1;
	}

	//SPI1_GetExclusiveAccess(SDCARD_SPI_BAUDRATE);
	//SDCARD_Read(135);
	//SPI1_ClearExclusiveAccess();
	//while (SDCARD_Buffer[0]);
}

#endif//STM
