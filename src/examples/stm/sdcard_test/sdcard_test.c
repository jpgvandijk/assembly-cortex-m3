/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

// Includes
#include <stdint.h>
#include "stm32f103ve.h"
#include "kernel.h"
#include "system.h"
#include "spi1.h"
#include "sdcard.h"
#include "fat.h"
#include "print.h"
#include "uart1.h"

// Function prototypes
void TaskSDCard (uint32_t arg);

// Global variables
const KERNEL_TaskDescriptor TaskDescriptor_TaskSDCard = {TaskSDCard, 0, (KERNEL_MinimumTaskStackSpace + 1024), 0, "SDC"};

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
	
	// Init the UART module
	UART1_Init();

	// Init the SPI module
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
	// Set printer for logging
	Printer printer = UART1_Tx;

	// Init SDCARD (in task)
	Print(printer, PRINT_TEXT, (PrintArgument) "Waiting for SD-card... ");
	SDCARD_Init();
	Print(printer, PRINT_TEXT, (PrintArgument) "found and initialized!");
	FAT_Init();
	
	// Checking the type of the partitions
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\nPartition 0: "), PRINT_UNSIGNED_8, (PrintArgument) FAT_TypeOfPartition(0));
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\nPartition 1: "), PRINT_UNSIGNED_8, (PrintArgument) FAT_TypeOfPartition(1));
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\nPartition 2: "), PRINT_UNSIGNED_8, (PrintArgument) FAT_TypeOfPartition(2));
	Print(Print(printer, PRINT_TEXT, (PrintArgument) "\nPartition 3: "), PRINT_UNSIGNED_8, (PrintArgument) FAT_TypeOfPartition(3));
	
	// Print RAW data as check
	uint32_t i;
	for (i = 0; i < 512; i++)
	{
		if ((i & 15) == 0)
			printer('\n');
		Print(printer, PRINT_HEX_8, (PrintArgument) FAT_CacheData.Buffer[i]);
		printer(' ');
	}
	
	// Load the first partition
	Print(printer, PRINT_TEXT, (PrintArgument) "\n\nLoading the first partition... ");
	if (FAT_MountPartition(0) == 0)
		return;
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
	if (FAT_FindVolumeLabel())
		Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n\tVolume label: "), PRINT_TEXT, (PrintArgument) (char *) &FAT_NameBuffers.LFN_Buffer[FAT_NameBuffers.LFN_Index]);

	// Start in the root
	uint32_t cluster = FAT_Partition.RootCluster;

	// ls
	Print(printer, PRINT_TEXT, (PrintArgument) "\n\n> ls -files -directories\n");
	FAT_FindSetup(cluster);
	while (FAT_FindNext(FAT_FIND_DIRECTORY | FAT_FIND_OTHER | FAT_FIND_WITH_NAME) == 1)
		Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n"), PRINT_TEXT, (PrintArgument) (char *) &FAT_NameBuffers.LFN_Buffer[FAT_NameBuffers.LFN_Index]);

	// cd "System Volume Information"
	Print(printer, PRINT_TEXT, (PrintArgument) "\n\n> cd \"System Volume Information\"");
	if (FAT_FindName(FAT_Partition.RootCluster, FAT_FIND_DIRECTORY, "System Volume Information") == 0)
		return;
	cluster = FAT_EntryGetStartCluster(FAT_GetEntry());

	// ls
	Print(printer, PRINT_TEXT, (PrintArgument) "\n> ls -files\n");
	FAT_FindSetup(cluster);
	while (FAT_FindNext(FAT_FIND_OTHER | FAT_FIND_WITH_NAME) == 1)
		Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n"), PRINT_TEXT, (PrintArgument) (char *) &FAT_NameBuffers.LFN_Buffer[FAT_NameBuffers.LFN_Index]);

	// Create files in root
	cluster = FAT_Partition.RootCluster;
	Print(printer, PRINT_TEXT, (PrintArgument) "\n\n Creating file...");
	FAT_AddItem(cluster, "New Text Document.txt", 0x00);
	FAT_AddItem(cluster, "simple.TXT", 0x00);
	FAT_AddItem(cluster, "My Folder", 0x10);
	FAT_AddItem(cluster, "Some File.csv", 0x00);

	// ls
	Print(printer, PRINT_TEXT, (PrintArgument) "\n> ls -all\n");
	FAT_FindSetup(cluster);
	while (FAT_FindNext(FAT_FIND_ANY | FAT_FIND_WITH_NAME) == 1)
		Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n"), PRINT_TEXT, (PrintArgument) (char *) &FAT_NameBuffers.LFN_Buffer[FAT_NameBuffers.LFN_Index]);

	/*
		
	// Remove a file
	FAT_DirectoryFindName(cluster, FAT_DIRECTORY_FIND_OTHER, "simple.TXT");
	Print(printer, PRINT_TEXT, (PrintArgument) "\n\n Deleting simple.TXT...");
	FAT_DirectoryDeleteItem();
	
	// ls
	Print(printer, PRINT_TEXT, (PrintArgument) "\n> ls -all\n");
	FAT_DirectoryFindSetup(cluster);
	while (FAT_DirectoryFindNext(FAT_DIRECTORY_FIND_ANY | FAT_DIRECTORY_FIND_WITH_NAME) == 1)
		Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n"), PRINT_TEXT, (PrintArgument) (char *) &FAT_LFN_Buffer[FAT_LFN_Index]);

	// Add data to a file
	FAT_DirectoryFindName(cluster, FAT_DIRECTORY_FIND_OTHER, "Some File.csv");
	uint32_t index = FAT_LoadFile(0xFFFFFFFF);
	char * string1 = "11:22,24-08-2014,25.00\n";
	while (*string1)
		SDCARD_WriteBuffer[index++] = (uint8_t) *string1++;
	FAT_SaveFile(index);

	// Add more data to the file
	FAT_DirectoryFindName(cluster, FAT_DIRECTORY_FIND_OTHER, "Some File.csv");
	index = FAT_LoadFile(0xFFFFFFFF);
	char * string2 = "11:27,24-08-2014,25.06\n";
	while (*string2)
		SDCARD_WriteBuffer[index++] = (uint8_t) *string2++;
	FAT_SaveFile(index);
	
	Print(printer, PRINT_TEXT, (PrintArgument) "\n\n> data stored to: Some File.csv\n");
	
	// FIXME: commit problems?!
	// ls
	Print(printer, PRINT_TEXT, (PrintArgument) "\n> ls -all\n");
	FAT_DirectoryFindSetup(cluster);
	while (FAT_DirectoryFindNext(FAT_DIRECTORY_FIND_ANY | FAT_DIRECTORY_FIND_WITH_NAME) == 1)
		Print(Print(printer, PRINT_TEXT, (PrintArgument) "\n"), PRINT_TEXT, (PrintArgument) (char *) &FAT_LFN_Buffer[FAT_LFN_Index]);
		
	*/
		
	// Unmount
	Print(printer, PRINT_TEXT, (PrintArgument) "\n\nClosing the partition... ");
	FAT_UnmountPartition();
	Print(printer, PRINT_TEXT, (PrintArgument) "the SD-card can now safely be removed!");
}
