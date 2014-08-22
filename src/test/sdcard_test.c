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
#include "sdcard.h"
#include "print.h"

// FIXME: External functions
extern void UART_Init (void);
extern void UART_Tx (char character);

// Function prototypes
void TaskSDCard (uint32_t arg);

// Global variables
const KERNEL_TaskDescriptor TaskDescriptor_TaskSDCard = {TaskSDCard, 0, (KERNEL_MinimumTaskStackSpace + 1024), 0, "SDC"};
Printer printer = UART_Tx;

// Main
void sdcard_test (void)
{
	// Set printer for logging
	UART_Init();
	
	// Enable the DMA1
	SystemEnablePeripheral(PERIPHERAL_DMA1);

	// Init the FLASH chip and SPI module
	FLASH_Init();
	SPI1_Init();

	// Init kernel
	KERNEL_Init();

	// Create tasks
	KERNEL_AddTask(&TaskDescriptor_TaskSDCard);

	// Start kernel (this function never returns)
	KERNEL_Start();
}















uint32_t addressBootSector = 0;
uint32_t addressFAT1;
uint32_t addressFAT2;
uint32_t addressRootDirectory;
uint32_t addressDataRegion;

struct __attribute__((packed)) {
	uint16_t BytesPerLogicalSector;
	uint8_t LogicalSectorsPerCluster;
	uint16_t CountOfReservedLogicalSectors;
	uint8_t NumberOfFileAllocationTables;
	uint16_t MaximumNumberOfRootEntries;
	uint16_t TotalLogicalSectors;
	uint8_t MediaDescriptor;
	uint16_t LogicalSectorsPerFAT;
} BiosParameterBlock;

typedef struct __attribute__((packed)) {
	uint8_t FileShortName[8];
	uint8_t FileShortExtension[3];
	uint8_t FileOtherInfo[15];
	uint16_t FileStartCluster;
	uint32_t FileSize;
} FAT16_DirectoryEntry;

char FAT16_LFN_Buffer[260];
uint16_t FAT16_LFN_Index;
uint8_t FAT16_SequenceNumber;

char ToLowerCase (char character) {
	return (character >= 'A' && character <= 'Z') ? (character | 0x60) : character;
}

void PrintDOSName (char * name, char * extension)
{
	uint8_t i, length;
	
	// Find first space at the end
	i = 8;
	while (i) {
		i--;
		if (name[i] != ' ')
			break;
	}
	length = i + 1;
	
	// Convert to lower case and print
	for (i = 0; i < length; i++)
		name[i] = ToLowerCase(name[i]);
	Print(printer, PRINT_CHARACTERS(length), (PrintArgument) name);
	
	// Check if there's an extension
	if (extension[0] != ' ')
	{
		// Print dot
		printer('.');
		
		// Find first space at the end
		i = 3;
		while (i) {
			i--;
			if (extension[i] != 0x20)
				break;
		}
		length = i + 1;
		
		// Convert to lower case and print
		for (i = 0; i < length; i++)
			extension[i] = ToLowerCase(extension[i]);
		Print(printer, PRINT_CHARACTERS(length), (PrintArgument) extension);
	}
}

uint32_t FAT16_AnalyseDirectory (uint32_t cluster)
{
	uint32_t i, j;
	uint32_t address;
	uint16_t checked = 0;
	
	// Determine base address of first cluster
	if (cluster == 0)
		address = addressRootDirectory;
	else
		address = addressDataRegion + cluster * BiosParameterBlock.LogicalSectorsPerCluster;
	
	// For every cluster
	do
	{
		// Read all sectors in this cluster
		for (j = 0; j < BiosParameterBlock.LogicalSectorsPerCluster; j++)
		{
			// Read sector
			SPI1_GetExclusiveAccess(SDCARD_SPI_BAUDRATE);
			SDCARD_Read(address+j);
			SPI1_ClearExclusiveAccess();

			/**************************************************************************/
			
			// Get entries (16 per sector)
			FAT16_DirectoryEntry * entries = (FAT16_DirectoryEntry *) SDCARD_ReadBuffer;
			for (i = 0; i < 16; i++)
			{
				// Specific maximum number of entries in root directory
				checked++;
				if (cluster == 0) {
					if (checked > BiosParameterBlock.MaximumNumberOfRootEntries)
						goto FAT16_AnalyseDirectory_finished;
				}

				// Stop if end marker found
				if (entries[i].FileShortName[0] == 0x00)
					goto FAT16_AnalyseDirectory_finished;

				// Skip deleted entries
				if (entries[i].FileShortName[0] == 0xE5)
					continue;

				// Check for part of LFN
				if (entries[i].FileOtherInfo[0] == 0x0F)
				{
					// Check if start of LFN
					if (entries[i].FileShortName[0] & (1 << 6))
					{
						FAT16_LFN_Index = 260;
						FAT16_SequenceNumber = (entries[i].FileShortName[0] & 0x1F) - 1;
						if (FAT16_SequenceNumber >= 20)
							Print(printer, PRINT_TEXT, (PrintArgument) "\n\tERROR: unexpected sequence number in LFN!");
					}
					else if ((entries[i].FileShortName[0] & 0x1F) == FAT16_SequenceNumber)
					{
						FAT16_SequenceNumber--;
					}
					else
					{
						Print(printer, PRINT_TEXT, (PrintArgument) "\n\tERROR: unexpected sequence number in LFN!");
					}

					// Copy the characters to the buffer
					FAT16_LFN_Buffer[--FAT16_LFN_Index] = *(((uint8_t *) &entries[i]) + 0x1E);
					FAT16_LFN_Buffer[--FAT16_LFN_Index] = *(((uint8_t *) &entries[i]) + 0x1C);
					FAT16_LFN_Buffer[--FAT16_LFN_Index] = *(((uint8_t *) &entries[i]) + 0x18);
					FAT16_LFN_Buffer[--FAT16_LFN_Index] = *(((uint8_t *) &entries[i]) + 0x16);
					FAT16_LFN_Buffer[--FAT16_LFN_Index] = *(((uint8_t *) &entries[i]) + 0x14);
					FAT16_LFN_Buffer[--FAT16_LFN_Index] = *(((uint8_t *) &entries[i]) + 0x12);
					FAT16_LFN_Buffer[--FAT16_LFN_Index] = *(((uint8_t *) &entries[i]) + 0x10);
					FAT16_LFN_Buffer[--FAT16_LFN_Index] = *(((uint8_t *) &entries[i]) + 0x0E);
					FAT16_LFN_Buffer[--FAT16_LFN_Index] = *(((uint8_t *) &entries[i]) + 0x09);
					FAT16_LFN_Buffer[--FAT16_LFN_Index] = *(((uint8_t *) &entries[i]) + 0x07);
					FAT16_LFN_Buffer[--FAT16_LFN_Index] = *(((uint8_t *) &entries[i]) + 0x05);
					FAT16_LFN_Buffer[--FAT16_LFN_Index] = *(((uint8_t *) &entries[i]) + 0x03);
					FAT16_LFN_Buffer[--FAT16_LFN_Index] = *(((uint8_t *) &entries[i]) + 0x01);
				}
				else
				{
					// File info
					Print(printer, PRINT_TEXT, (PrintArgument) "\n\t");
					Print(printer, PRINT_HEX_8, (PrintArgument) entries[i].FileOtherInfo[0]);
					Print(printer, PRINT_TEXT, (PrintArgument) "\t\t");
					Print(printer, PRINT_UNSIGNED_32, (PrintArgument) entries[i].FileStartCluster);
					Print(printer, PRINT_TEXT, (PrintArgument) "\t\t");
					Print(printer, PRINT_UNSIGNED_32, (PrintArgument) entries[i].FileSize);
					Print(printer, PRINT_TEXT, (PrintArgument) "\t\t");
					
					// Check if long file name exists for this entry
					if (FAT16_SequenceNumber == 0)
						Print(printer, PRINT_TEXT, (PrintArgument) &FAT16_LFN_Buffer[FAT16_LFN_Index]);
					else
						PrintDOSName((char *) entries[i].FileShortName, (char *) entries[i].FileShortExtension);

					// Delete whatever the long name buffer holds
					FAT16_SequenceNumber = 0xFF;
					
					// FIXME: temp
					KERNEL_SVCForceContextSwitchDelay(2);
				}
			}
			
			/**************************************************************************/
		}

		// Root directory search should never continue
		if (cluster == 0)
			goto FAT16_AnalyseDirectory_finished;
		
		// Find next cluster in FAT
		SPI1_GetExclusiveAccess(SDCARD_SPI_BAUDRATE);
		SDCARD_Read(addressFAT1 + (cluster >> 8));
		SPI1_ClearExclusiveAccess();
		cluster = *(((uint16_t *) SDCARD_ReadBuffer) + (cluster & 0xFF));
		address = addressDataRegion + cluster * BiosParameterBlock.LogicalSectorsPerCluster;
		
	} while (cluster != 0xFFFF);

FAT16_AnalyseDirectory_finished:
	return checked;
}

void TaskSDCard (uint32_t arg)
{
	// Init SDCARD (in task)
	Print(printer, PRINT_TEXT, (PrintArgument) "Waiting for SD-card... ");
	SDCARD_Init();
	Print(printer, PRINT_TEXT, (PrintArgument) "found and initialized!");

	// Read MBR, check validity
	Print(printer, PRINT_TEXT, (PrintArgument) "\nReading MBR... ");
	SPI1_GetExclusiveAccess(SDCARD_SPI_BAUDRATE);
	SDCARD_Read(0);
	SPI1_ClearExclusiveAccess();
	Print(printer, PRINT_TEXT, (PrintArgument) "read ");
	if ((SDCARD_ReadBuffer[510] != 0x55) || (SDCARD_ReadBuffer[511] != 0xAA))
		return;
	Print(printer, PRINT_TEXT, (PrintArgument) "and validated, partition entries:");

	// Read partition entries
	uint32_t i;
	for (i = 0; i < 4; i++)
	{
		uint32_t address = 446 + (i << 4);
		Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tPartition "), PRINT_UNSIGNED_8, (PrintArgument) i);

		// Read partition ID
		if (SDCARD_ReadBuffer[address + 4] == 0x00)
		{
			Print(printer, PRINT_TEXT, (PrintArgument) ": unused");
		}
		else
		{
			// Partition is in use
			if (SDCARD_ReadBuffer[address + 4] != 0x06)
			{
				Print(printer, PRINT_TEXT, (PrintArgument) ": non-FAT16");
			}
			else
			{
				Print(printer, PRINT_TEXT, (PrintArgument) ": FAT16");

				// Store first FAT16 partition
				if (addressBootSector == 0)
					addressBootSector = *(uint32_t *)(SDCARD_ReadBuffer + address + 8);
			}

			// Print partition information
			Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\t\tAddress:\t"), PRINT_HEX_32, (PrintArgument) *(uint32_t *)(SDCARD_ReadBuffer + address + 8));
			Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\t\tSize:\t\t"), PRINT_HEX_32, (PrintArgument) *(uint32_t *)(SDCARD_ReadBuffer + address + 12));
		}
	}

	// Check if FAT16 partition was found
	if (addressBootSector == 0)
		return;
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n> Selected FAT16 partition: "), PRINT_HEX_32, (PrintArgument) addressBootSector);

	// Read the boot sector
	Print(printer, PRINT_TEXT, (PrintArgument) "\n\nReading Boot Sector... ");
	SPI1_GetExclusiveAccess(SDCARD_SPI_BAUDRATE);
	SDCARD_Read(addressBootSector);
	SPI1_ClearExclusiveAccess();
	Print(printer, PRINT_TEXT, (PrintArgument) "read ");
	for (i = 0; i < 13; i++)
		*(((uint8_t *) &BiosParameterBlock) + i) = SDCARD_ReadBuffer[i + 11];
	if (BiosParameterBlock.BytesPerLogicalSector != SDCARD_BLOCK_SIZE)
		return;
	Print(printer, PRINT_TEXT, (PrintArgument) "and validated");

	// Get info from the bios parameter block
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tBytes Per Logical Sector: "), PRINT_UNSIGNED_32, (PrintArgument) BiosParameterBlock.BytesPerLogicalSector);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tLogical Sectors Per Cluster: "), PRINT_UNSIGNED_32, (PrintArgument) BiosParameterBlock.LogicalSectorsPerCluster);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tCount Of Reserved Logical Sectors: "), PRINT_UNSIGNED_32, (PrintArgument) BiosParameterBlock.CountOfReservedLogicalSectors);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tNumber Of File Allocation Tables: "), PRINT_UNSIGNED_32, (PrintArgument) BiosParameterBlock.NumberOfFileAllocationTables);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tMaximum Number Of Root Entries: "), PRINT_UNSIGNED_32, (PrintArgument) BiosParameterBlock.MaximumNumberOfRootEntries);
	if (BiosParameterBlock.TotalLogicalSectors == 0)
		Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tLogical sectors: "), PRINT_HEX_32, (PrintArgument) *((uint32_t *)(SDCARD_ReadBuffer + 32)));
	else
		Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tLogical sectors: "), PRINT_HEX_32, (PrintArgument) BiosParameterBlock.TotalLogicalSectors);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tMedia Descriptor: "), PRINT_HEX_8, (PrintArgument) BiosParameterBlock.MediaDescriptor);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tLogical Sectors Per FAT: "), PRINT_UNSIGNED_32, (PrintArgument) BiosParameterBlock.LogicalSectorsPerFAT);

	// Calculate base addresses, max. 2 FATs supported for now
	addressFAT1 = addressBootSector + BiosParameterBlock.CountOfReservedLogicalSectors;
	if (BiosParameterBlock.NumberOfFileAllocationTables == 1)
		addressFAT2 = addressFAT1;
	else if (BiosParameterBlock.NumberOfFileAllocationTables == 2)
		addressFAT2 = addressFAT1 + BiosParameterBlock.LogicalSectorsPerFAT;
	else
		return;
	addressRootDirectory = addressFAT2 + BiosParameterBlock.LogicalSectorsPerFAT;
	addressDataRegion = addressRootDirectory + (((BiosParameterBlock.MaximumNumberOfRootEntries << 5) + (SDCARD_BLOCK_SIZE - 1)) >> SDCARD_BLOCK_SIZE_LOG) - (BiosParameterBlock.LogicalSectorsPerCluster << 1);

	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\nAddress Boot Sector: "), PRINT_UNSIGNED_32, (PrintArgument) addressBootSector);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\nAddress FAT 1: "), PRINT_UNSIGNED_32, (PrintArgument) addressFAT1);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\nAddress FAT 2: "), PRINT_UNSIGNED_32, (PrintArgument) addressFAT2);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\nAddress Root Directory: "), PRINT_UNSIGNED_32, (PrintArgument) addressRootDirectory);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\nAddress Data Region: "), PRINT_UNSIGNED_32, (PrintArgument) addressDataRegion);

	// Write test
	Print(printer, PRINT_TEXT, (PrintArgument) "\n\nWrite Test 1:\n\n");
	for (i = 0; i < 512; i++)
		SDCARD_WriteBuffer[i] = i & 0xFF;
	SPI1_GetExclusiveAccess(SDCARD_SPI_BAUDRATE);
	SDCARD_Write(addressDataRegion + 10000 * BiosParameterBlock.LogicalSectorsPerCluster);
	SPI1_ClearExclusiveAccess();
	SPI1_GetExclusiveAccess(SDCARD_SPI_BAUDRATE);
	SDCARD_Read(addressDataRegion + 10000 * BiosParameterBlock.LogicalSectorsPerCluster);
	SPI1_ClearExclusiveAccess();
	for (i = 0; i < 512; i++)
		Print(Print(printer, PRINT_TEXT, (PrintArgument) " "), PRINT_HEX_8, (PrintArgument) SDCARD_ReadBuffer[i]);

	Print(printer, PRINT_TEXT, (PrintArgument) "\n\nWrite Test 2:\n\n");
	for (i = 0; i < 512; i++)
		SDCARD_WriteBuffer[i] = 0xAA;
	SPI1_GetExclusiveAccess(SDCARD_SPI_BAUDRATE);
	SDCARD_Write(addressDataRegion + 10000 * BiosParameterBlock.LogicalSectorsPerCluster);
	SPI1_ClearExclusiveAccess();
	SPI1_GetExclusiveAccess(SDCARD_SPI_BAUDRATE);
	SDCARD_Read(addressDataRegion + 10000 * BiosParameterBlock.LogicalSectorsPerCluster);
	SPI1_ClearExclusiveAccess();
	for (i = 0; i < 512; i++)
		Print(Print(printer, PRINT_TEXT, (PrintArgument) " "), PRINT_HEX_8, (PrintArgument) SDCARD_ReadBuffer[i]);

	// Get some FAT1 info
	Print(printer, PRINT_TEXT, (PrintArgument) "\n\nReading start of FAT1... ");
	SPI1_GetExclusiveAccess(SDCARD_SPI_BAUDRATE);
	SDCARD_Read(addressFAT1);
	SPI1_ClearExclusiveAccess();
	Print(printer, PRINT_TEXT, (PrintArgument) "read:\n\t");
	for (i = 0; i < 256; i++)
		Print(Print(printer, PRINT_TEXT, (PrintArgument) " "), PRINT_HEX_16, (PrintArgument) *(((uint16_t *) SDCARD_ReadBuffer) + i));

	// Get some FAT2 info
	Print(printer, PRINT_TEXT, (PrintArgument) "\n\nReading start of FAT2... ");
	SPI1_GetExclusiveAccess(SDCARD_SPI_BAUDRATE);
	SDCARD_Read(addressFAT2);
	SPI1_ClearExclusiveAccess();
	Print(printer, PRINT_TEXT, (PrintArgument) "read:\n\t");
	for (i = 0; i < 256; i++)
		Print(Print(printer, PRINT_TEXT, (PrintArgument) " "), PRINT_HEX_16, (PrintArgument) *(((uint16_t *) SDCARD_ReadBuffer) + i));

	// Analyse root directory
	Print(printer, PRINT_TEXT, (PrintArgument) "\n\nAnalysing Root Directory...\n");
	i = FAT16_AnalyseDirectory(0);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\nEntries analysed: "), PRINT_UNSIGNED_32, (PrintArgument) i);
	
	// Analyse a subdirectory
	Print(printer, PRINT_TEXT, (PrintArgument) "\n\nAnalysing Subdirectory @ cluster 2...\n");
	i = FAT16_AnalyseDirectory(2);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\nEntries analysed: "), PRINT_UNSIGNED_32, (PrintArgument) i);
}

#endif//STM
