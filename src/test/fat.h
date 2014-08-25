/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _FAT_H_
#define _FAT_H_

// Includes
#include <stdint.h>
#include "stm32f103ve.h"
#include "sdcard.h"

// Structures
typedef struct __attribute__((packed)) {
	uint8_t FileShortName[8];
	uint8_t FileShortExtension[3];
	uint8_t FileOtherInfo[15];
	uint16_t FileStartCluster;
	uint32_t FileSize;
} FAT_DirectoryEntry_TypeDef;

typedef struct {
	uint32_t Size;
	uint32_t Address;
	uint32_t AddressFAT1;
	uint32_t AddressFAT2;
	uint32_t AddressData;
	uint32_t SectorsPerFAT;
	uint32_t RootCluster;
	uint16_t RootMaxEntries;
	uint8_t SectorsPerCluster;
	uint8_t Type;
} FAT_Partition_TypeDef;

typedef struct {
	uint32_t Counter;
	uint32_t Cluster;
	uint8_t Sector;
	uint8_t Entry;
} FAT_DirectoryFind_TypeDef;

// Definitions
#define PARTITION_TYPE_FAT16			16
#define PARTITION_TYPE_FAT32			32

#define FAT_DIRECTORY_FIND_EMPTY		0x00
#define FAT_DIRECTORY_FIND_VOLUME		0x01
#define FAT_DIRECTORY_FIND_DIRECTORY	0x02
#define FAT_DIRECTORY_FIND_OTHER		0x04
#define FAT_DIRECTORY_FIND_ANY			0x07
#define FAT_DIRECTORY_FIND_WITH_NAME	0x10

// Function prototypes
uint32_t FAT_GetPartitionType (uint32_t n);
uint32_t FAT_LoadPartition (uint32_t n);
uint32_t FAT_GetAddress (uint32_t cluster);
uint32_t FAT_GetNextCluster (uint32_t cluster);
uint32_t FAT_Allocate (void);
uint32_t FAT_Link (uint32_t first, uint32_t add);
uint32_t FAT_DirectoryExtend (uint32_t cluster);
uint32_t FAT_DirectoryEntryGetStartCluster (FAT_DirectoryEntry_TypeDef * entry);
void FAT_DirectoryEntryPrintDOSName (FAT_DirectoryEntry_TypeDef * entry);
void FAT_DirectoryEntryGatherLFN (FAT_DirectoryEntry_TypeDef * entry);
void FAT_DirectoryEntryScatterLFN (FAT_DirectoryEntry_TypeDef * entry, char * name);
void FAT_DirectoryFindSetup (uint32_t cluster);
uint32_t FAT_DirectoryFindNext (uint32_t type);
uint32_t FAT_DirectoryFindVolumeLabel (void);
uint32_t FAT_DirectoryFindName (uint32_t cluster, uint32_t type, char * name);
uint32_t FAT_DirectoryFindContiguousEntries (uint32_t cluster, uint32_t required);
uint32_t FAT_DirectoryAddItem (uint32_t cluster, char * name, uint8_t type);
uint32_t FAT_AnalyseAndCreateSFN (char * name);

// Global constants/variables
extern FAT_Partition_TypeDef FAT_Partition;
extern FAT_DirectoryFind_TypeDef FAT_DirectoryFind;
extern char FAT_LFN_Buffer[];
extern uint16_t FAT_LFN_Index;
extern char FAT_SFN_Buffer[];
extern uint16_t FAT_UniqueSFN;
extern const uint8_t FAT_LFN_ENTRIES[];

#endif//_FAT_H_
