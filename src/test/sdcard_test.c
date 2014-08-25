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
#include "fat.h"
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

void TaskSDCard (uint32_t arg)
{
	// Init SDCARD (in task)
	Print(printer, PRINT_TEXT, (PrintArgument) "Waiting for SD-card... ");
	SDCARD_Init();
	Print(printer, PRINT_TEXT, (PrintArgument) "found and initialized!");

	// Load the first partition
	Print(printer, PRINT_TEXT, (PrintArgument) "\n\nLoading the first partition... ");
	if (FAT_LoadPartition(0) == 0) return;
	Print(printer, PRINT_TEXT, (PrintArgument) "loaded:");

	// Print partition information
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tType: FAT"), PRINT_UNSIGNED_8, (PrintArgument) FAT_Partition.Type);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tSize: "), PRINT_HEX_32, (PrintArgument) FAT_Partition.Size);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tAddress: "), PRINT_UNSIGNED_32, (PrintArgument) FAT_Partition.Address);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tAddress FAT1: "), PRINT_UNSIGNED_32, (PrintArgument) FAT_Partition.AddressFAT1);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tAddress FAT2: "), PRINT_UNSIGNED_32, (PrintArgument) FAT_Partition.AddressFAT2);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tAddress Data: "), PRINT_UNSIGNED_32, (PrintArgument) FAT_Partition.AddressData);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tRoot Cluster: "), PRINT_UNSIGNED_32, (PrintArgument) FAT_Partition.RootCluster);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tRoot Max Entries: "), PRINT_UNSIGNED_16, (PrintArgument) FAT_Partition.RootMaxEntries);
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tSectors Per Cluster: "), PRINT_UNSIGNED_8, (PrintArgument) FAT_Partition.SectorsPerCluster);
	if (FAT_DirectoryFindVolumeLabel())
		Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tVolume label: "), PRINT_TEXT, (PrintArgument) &FAT_LFN_Buffer[FAT_LFN_Index]);

	// Start in the root
	uint32_t cluster = FAT_Partition.RootCluster;

	// ls
	Print(printer, PRINT_TEXT, (PrintArgument) "\n\n> ls -files -directories\n");
	FAT_DirectoryFindSetup(cluster);
	while (FAT_DirectoryFindNext(FAT_DIRECTORY_FIND_DIRECTORY | FAT_DIRECTORY_FIND_OTHER | FAT_DIRECTORY_FIND_WITH_NAME) == 1)
		Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n"), PRINT_TEXT, (PrintArgument) (char *) &FAT_LFN_Buffer[FAT_LFN_Index]);

	// cd "System Volume Information"
	Print(printer, PRINT_TEXT, (PrintArgument) "\n\n> cd \"System Volume Information\"");
	cluster = FAT_DirectoryFindName(FAT_Partition.RootCluster, FAT_DIRECTORY_FIND_DIRECTORY, "System Volume Information");
	if (cluster == 0xFFFFFFFF) return;

	// ls
	Print(printer, PRINT_TEXT, (PrintArgument) "\n> ls -files\n");
	FAT_DirectoryFindSetup(cluster);
	while (FAT_DirectoryFindNext(FAT_DIRECTORY_FIND_OTHER | FAT_DIRECTORY_FIND_WITH_NAME) == 1)
		Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n"), PRINT_TEXT, (PrintArgument) (char *) &FAT_LFN_Buffer[FAT_LFN_Index]);

	// Create files in root
	cluster = FAT_Partition.RootCluster;
	Print(printer, PRINT_TEXT, (PrintArgument) "\n\n Creating file...");
	FAT_DirectoryAddItem(cluster, "New Text Document.txt", 0x00);
	FAT_DirectoryAddItem(cluster, "simple.TXT", 0x00);
	FAT_DirectoryAddItem(cluster, "My Folder", 0x10);

	// ls
	Print(printer, PRINT_TEXT, (PrintArgument) "\n> ls -all\n");
	FAT_DirectoryFindSetup(cluster);
	while (FAT_DirectoryFindNext(FAT_DIRECTORY_FIND_ANY | FAT_DIRECTORY_FIND_WITH_NAME) == 1)
		Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n"), PRINT_TEXT, (PrintArgument) (char *) &FAT_LFN_Buffer[FAT_LFN_Index]);
}

#endif//STM
