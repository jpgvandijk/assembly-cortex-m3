/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _FAT_H_
#define _FAT_H_

// Includes
#include "sdcard.h"

// Definitions
#define PARTITION_TYPE_FAT16			16
#define PARTITION_TYPE_FAT32			32
#define FAT_FIND_EMPTY					0x00
#define FAT_FIND_VOLUME					0x01
#define FAT_FIND_DIRECTORY				0x02
#define FAT_FIND_OTHER					0x04
#define FAT_FIND_ANY					0x07
#define FAT_FIND_WITH_NAME				0x10

#ifndef __ASSEMBLER__

// Structures
typedef struct __attribute__((packed)) {
	uint8_t FileShortName[8];
	uint8_t FileShortExtension[3];
	uint8_t FileOtherInfo[15];
	uint16_t FileStartCluster;
	uint32_t FileSize;
} FAT_Entry_TypeDef;

typedef struct __attribute__((packed))
{
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

typedef struct __attribute__((packed))
{
	uint16_t LFN_Index;
	uint8_t LFN_Buffer[260];
	uint8_t SFN_Buffer[11];
} FAT_NameBuffers_TypeDef;

typedef struct __attribute__((packed))
{
	uint32_t Address;
	uint8_t Modified;
	uint8_t reserved[3];
	uint8_t Buffer[512];
} FAT_CacheFAT_TypeDef;

typedef struct __attribute__((packed))
{
	uint32_t Cluster;
	uint8_t Sector;
	uint8_t Entry;
	uint8_t Policy;
	uint8_t MRU;
	uint32_t Address1;
	uint8_t Modified1;
	uint8_t reserved1[3];
	uint8_t Buffer1[512];
	uint32_t Address2;
	uint8_t Modified2;
	uint8_t reserved2[3];
	uint8_t Buffer2[512];
} FAT_CacheEntries_TypeDef;

typedef struct __attribute__((packed))
{
	uint32_t Address;
	uint8_t Modified;
	uint8_t reserved[3];
	uint8_t Buffer[512];
} FAT_CacheData_TypeDef;

// Global variables
extern FAT_Partition_TypeDef FAT_Partition;
extern FAT_NameBuffers_TypeDef FAT_NameBuffers;
extern uint32_t FAT_FindCounter;
extern FAT_CacheFAT_TypeDef FAT_CacheFAT;
extern FAT_CacheEntries_TypeDef FAT_CacheEntries;
extern FAT_CacheData_TypeDef FAT_CacheData;

// Global functions
extern uint32_t FAT_Next (uint32_t cluster);
extern uint32_t FAT16_Next (uint32_t cluster);
extern uint32_t FAT32_Next (uint32_t cluster);
extern uint32_t FAT_Alloc (uint32_t link);
extern uint32_t FAT_Free (uint32_t start);
extern FAT_Entry_TypeDef * FAT_GetEntry (void);
extern void FAT_ClearEntriesOfCluster (uint32_t cluster);
extern uint32_t FAT_EntryGetStartCluster (FAT_Entry_TypeDef * entry);
extern void FAT_EntrySetStartCluster (FAT_Entry_TypeDef * entry, uint32_t cluster);
extern void FAT_EntryGartherLFN (FAT_Entry_TypeDef * entry);
extern void FAT_EntryScatterLFN (FAT_Entry_TypeDef * entry, char * filename);
extern void FAT_EntryPrintSFN (FAT_Entry_TypeDef * entry);
extern uint32_t FAT_CreateSFN (char * filename);
extern void FAT_GetData (uint32_t address);
extern uint32_t FAT_TypeOfPartition (uint32_t n);
extern uint32_t FAT_MountPartition (uint32_t n);
extern void FAT_UnmountPartition (void);
extern void FAT_FindSetup (uint32_t cluster);
extern uint32_t FAT_FindNext (uint32_t type);

#endif//__ASSEMBLER__

#endif//_FAT_H_
