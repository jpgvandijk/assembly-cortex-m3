/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

// FIXME: completely ignores all end markers in directories, slightly slower searches, but easier updates!

#ifdef STM

// Includes
#include "fat.h"

// Global variables and constants
FAT_Partition_TypeDef FAT_Partition;
FAT_DirectoryFind_TypeDef FAT_DirectoryFind;
char FAT_LFN_Buffer[260];
uint16_t FAT_LFN_Index;
char FAT_SFN_Buffer[8+3];
uint16_t FAT_UniqueSFN;
const uint8_t FAT_LFN_ENTRIES[] = {0x01, 0x03, 0x05, 0x07, 0x09, 0x0E, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1C, 0x1E};

// FIXME: Place these helper functions in string library
static char ToLowerCase (char character) {
	return (character >= 'A' && character <= 'Z') ? (character | 0x60) : character;
}

static char ToUpperCase (char character) {
	return (character >= 'a' && character <= 'z') ? (character - 32) : character;
}

static uint32_t IsUpperCase (char character) {
	return (character >= 'A' && character <= 'Z');
}

static char IsLowerCase (char character) {
	return (character >= 'a' && character <= 'z');
}

static int32_t StringCompare (char * s1, char * s2)
{
    while(*s1 && (*s1==*s2))
        s1++,s2++;
    return *(uint8_t*)s1-*(uint8_t*)s2;
}

static uint32_t StringLength (char * s)
{
	uint32_t i = 0;
	while(*s++)
		i++;
	return i;
}

// FIXME: use DMA?
static void SDCARD_CopyReadBufferToWriteBuffer (void)
{
	// Slightly more efficient word copy
	uint32_t i;
	for (i = 0; i < 128; i++)
		*(((uint32_t *) SDCARD_WriteBuffer) + i) = *(((uint32_t *) SDCARD_ReadBuffer) + i);
}

static void SDCARD_ClearWriteBuffer (void)
{
	// Slightly more efficient word set
	uint32_t i;
	for (i = 0; i < 128; i++)
		*(((uint32_t *) SDCARD_WriteBuffer) + i) = 0;
}












// Functions
uint32_t FAT_GetPartitionType (uint32_t n)
{
	// Argument: 0...3 allowed
	// Return: 0 if error/unused/unsupported

	// Read and validate MBR
	if (SDCARD_Read(0) == 0)
		return 0;
	if ((SDCARD_ReadBuffer[510] != 0x55) || (SDCARD_ReadBuffer[511] != 0xAA))
		return 0;

	// Read requested partition entry type field
	n = 450 + (n << 4);
	if (SDCARD_ReadBuffer[n] == 0x06)
		return PARTITION_TYPE_FAT16;
	else if (SDCARD_ReadBuffer[n] == 0x0B)
		return PARTITION_TYPE_FAT32;

	return 0;
}

uint32_t FAT_LoadPartition (uint32_t n)
{
	// Argument: 0...3 allowed
	// Return: 0 if error

	// Function loads the MBR and returns the type
	FAT_Partition.Type = FAT_GetPartitionType(n);

	// Return if unused/unsupported/other error
	if (FAT_Partition.Type == 0)
		return 0;

	// Read requested partition entry
	n = 446 + (n << 4);
	FAT_Partition.Address = *(uint32_t *)(SDCARD_ReadBuffer + n + 8);
	FAT_Partition.Size = *(uint32_t *)(SDCARD_ReadBuffer + n + 12);

	// Read the boot sector of the partition
	if (SDCARD_Read(FAT_Partition.Address) == 0)
		return 0;

	// Check bytes per logical sector field
	if (*((uint16_t *)(SDCARD_ReadBuffer + 11)) != SDCARD_BLOCK_SIZE)
		return 0;

	// Remember logical sectors per cluster
	FAT_Partition.SectorsPerCluster = SDCARD_ReadBuffer[13];

	// Use count of reserved logical sectors to calculate the address of FAT1
	FAT_Partition.AddressFAT1 = FAT_Partition.Address + *((uint16_t *)(SDCARD_ReadBuffer + 14));

	// Get the logical sectors per FAT
	if (FAT_Partition.Type == PARTITION_TYPE_FAT16)
		FAT_Partition.SectorsPerFAT = *((uint16_t *)(SDCARD_ReadBuffer + 22));
	else if ((FAT_Partition.Type == PARTITION_TYPE_FAT32) && (*((uint16_t *)(SDCARD_ReadBuffer + 22)) == 0))
		FAT_Partition.SectorsPerFAT = *((uint32_t *)(SDCARD_ReadBuffer + 36));
	else
		return 0;

	// Check number of FATs (max 2 for now), and calculate the address of FAT2
	if (SDCARD_ReadBuffer[16] == 1)
		FAT_Partition.AddressFAT2 = FAT_Partition.AddressFAT1;
	else if (SDCARD_ReadBuffer[16] == 2)
		FAT_Partition.AddressFAT2 = FAT_Partition.AddressFAT1 + FAT_Partition.SectorsPerFAT;
	else
		return 0;

	// Remember maximum number of root directory entries
	FAT_Partition.RootMaxEntries = *((uint16_t *)(SDCARD_ReadBuffer + 17));

	// Determine the root directory cluster (set to 0 for FAT16)
	if (FAT_Partition.Type == PARTITION_TYPE_FAT16)
		FAT_Partition.RootCluster = 0;
	else if ((FAT_Partition.Type == PARTITION_TYPE_FAT32) && (*((uint32_t *)(SDCARD_ReadBuffer + 44)) != 0))
		FAT_Partition.RootCluster = *((uint32_t *)(SDCARD_ReadBuffer + 44));
	else
		return 0;

	// Calculate base address of the data region
	FAT_Partition.AddressData = FAT_Partition.AddressFAT2 + FAT_Partition.SectorsPerFAT - (FAT_Partition.SectorsPerCluster << 1);
	if (FAT_Partition.Type == PARTITION_TYPE_FAT16)
		FAT_Partition.AddressData += (((FAT_Partition.RootMaxEntries << 5) + (SDCARD_BLOCK_SIZE - 1)) >> SDCARD_BLOCK_SIZE_LOG);

	// Return success
	return 1;
}

uint32_t FAT_GetAddress (uint32_t cluster)
{
	// Return root directory address for cluster 0 (FAT16)
	if (cluster != 0)
		return (FAT_Partition.AddressData + cluster * FAT_Partition.SectorsPerCluster);
	else
		return (FAT_Partition.AddressFAT2 + FAT_Partition.SectorsPerFAT);
}

uint32_t FAT_GetNextCluster (uint32_t cluster)
{
	// Return: 0 if error, 0xFFFFFFFF if last
	if (cluster == 0)
		return 0;

	// Read FAT1 table for next cluster
	if (FAT_Partition.Type == PARTITION_TYPE_FAT16)
	{
		if (SDCARD_Read(FAT_Partition.AddressFAT1 + (cluster >> 8)) == 0)
			return 0;

		cluster = *(((uint16_t *) SDCARD_ReadBuffer) + (cluster & 0xFF));
		if (cluster == 0xFFFF)
			cluster = 0xFFFFFFFF;
	}
	else
	{
		if (SDCARD_Read(FAT_Partition.AddressFAT1 + (cluster >> 7)) == 0)
			return 0;

		cluster = (*(((uint32_t *) SDCARD_ReadBuffer) + (cluster & 0x7F))) & 0x0FFFFFFF;
		if (cluster == 0x0FFFFFFF)
			cluster = 0xFFFFFFFF;
	}

	return cluster;
}

uint32_t FAT_Allocate (void)
{
	// Return: 0 if error/not found, cluster number otherwise
	uint32_t sector;
	uint32_t entry;

	// Consider all sectors
	for (sector = 0; sector < FAT_Partition.SectorsPerFAT; sector++)
	{
		// Read the sector
		if (SDCARD_Read(FAT_Partition.AddressFAT1 + sector) == 0)
			return 0;

		// Check for empty entry
		if (FAT_Partition.Type == PARTITION_TYPE_FAT16)
		{
			uint16_t * entries = (uint16_t *) SDCARD_ReadBuffer;
			for (entry = 0; entry < 256; entry++)
			{
				if (entries[entry] == 0x0000)
				{
					// Allocate, read buffer can be altered since immediately invalidated by write
					entries[entry] = 0xFFFF;

					// Write back to both FATs
					SDCARD_CopyReadBufferToWriteBuffer();
					if (SDCARD_Write(FAT_Partition.AddressFAT1 + sector) == 0)
						return 0;
					if (SDCARD_Write(FAT_Partition.AddressFAT2 + sector) == 0)
						return 0;

					// Return cluster number
					return ((sector << 8) + entry);
				}
			}
		}
		else
		{
			uint32_t * entries = (uint32_t *) SDCARD_ReadBuffer;
			for (entry = 0; entry < 128; entry++)
			{
				if (entries[entry] == 0x00000000)
				{
					// Allocate, read buffer can be altered since immediately invalidated by write
					entries[entry] = 0x0FFFFFFF;

					// Write back to both FATs
					SDCARD_CopyReadBufferToWriteBuffer();
					if (SDCARD_Write(FAT_Partition.AddressFAT1 + sector) == 0)
						return 0;
					if (SDCARD_Write(FAT_Partition.AddressFAT2 + sector) == 0)
						return 0;

					// Return cluster number
					return ((sector << 7) + entry);
				}
			}
		}
	}

	// Nothing found
	return 0;
}

uint32_t FAT_Link (uint32_t first, uint32_t add)
{
	// Return: 0 if error, 1 otherwise
	uint32_t next;
	while (1)
	{
		next = FAT_GetNextCluster(first);
		if (next == 0)
			return 0;

		if (next == 0xFFFFFFFF)
		{
			// Change link of first to add
			if (FAT_Partition.Type == PARTITION_TYPE_FAT16)
			{
				// Link, read buffer can be altered since immediately invalidated by write
				// The read buffer contains the entry that must be changed
				*(((uint16_t *) SDCARD_ReadBuffer) + (first & 0xFF)) = add & 0xFFFF;

				// Write back to both FATs
				SDCARD_CopyReadBufferToWriteBuffer();
				if (SDCARD_Write(FAT_Partition.AddressFAT1 + (first >> 8)) == 0)
					return 0;
				if (SDCARD_Write(FAT_Partition.AddressFAT2 + (first >> 8)) == 0)
					return 0;
			}
			else
			{
				// Link, read buffer can be altered since immediately invalidated by write
				// The read buffer contains the entry that must be changed
				*(((uint32_t *) SDCARD_ReadBuffer) + (first & 0x7F)) = add & 0x0FFFFFFF;

				// Write back to both FATs
				SDCARD_CopyReadBufferToWriteBuffer();
				if (SDCARD_Write(FAT_Partition.AddressFAT1 + (first >> 7)) == 0)
					return 0;
				if (SDCARD_Write(FAT_Partition.AddressFAT2 + (first >> 7)) == 0)
					return 0;
			}

			return 1;
		}
		first = next;
	}
}

uint32_t FAT_DirectoryExtend (uint32_t cluster)
{
	// Argument: if cluster is 0 the newCluster is not linked
	// Return: 0 if error, newCluster otherwise
	uint32_t result;

	// Allocate new cluster
	uint32_t newCluster;
	newCluster = FAT_Allocate();
	if (newCluster == 0)
		return 0;

	// Completely empty the cluster (could otherwise be mistaken for directory entries)
	uint32_t i;
	for (i = 0; i < 128; i++)
		*(((uint32_t *) SDCARD_WriteBuffer) + i) = 0;
	result = FAT_GetAddress(newCluster);
	for (i = 0; i < FAT_Partition.SectorsPerCluster; i++)
		if (SDCARD_Write(result + i) == 0)
			return 0;

	// Link the new cluster
	if (cluster != 0)
		if (FAT_Link(cluster, newCluster) == 0)
			return 0;

	// No errors
	return newCluster;
}

uint32_t FAT_DirectoryEntryGetStartCluster (FAT_DirectoryEntry_TypeDef * entry)
{
	// Starting cluster scattered over the entry for FAT32
	if (FAT_Partition.Type == PARTITION_TYPE_FAT16)
		return entry->FileStartCluster;
	else
		return ((*(((uint16_t *) entry) + 10) << 16) | (entry->FileStartCluster));
}

void FAT_DirectoryEntrySetStartCluster (FAT_DirectoryEntry_TypeDef * entry, uint32_t cluster)
{
	// Starting cluster scattered over the entry for FAT32
	entry->FileStartCluster = cluster & 0xFFFF;
	if (FAT_Partition.Type == PARTITION_TYPE_FAT16)
		*(((uint16_t *) entry) + 10) = 0;
	else
		*(((uint16_t *) entry) + 10) = (cluster >> 16) & 0x0FFF;
}

void FAT_DirectoryEntryPrintDOSName (FAT_DirectoryEntry_TypeDef * entry)
{
	// The name is printed in FAT_LFN_Buffer and FAT_LFN_Index is reset
	uint32_t i;
	uint32_t nonspace;

	// Copy the base name
	for (i = 0; i < 8; i++)
	{
		// Convert to lower case if necessary
		if (entry->FileOtherInfo[1] & (1 << 3))
			FAT_LFN_Buffer[i] = ToLowerCase(entry->FileShortName[i]);
		else
			FAT_LFN_Buffer[i] = entry->FileShortName[i];

		// Remember non-space
		if (entry->FileShortName[i] != ' ')
			nonspace = i;
	}

	// Check if there's an extension
	if (entry->FileShortExtension[0] != ' ')
	{
		// Print dot
		FAT_LFN_Buffer[++nonspace] = '.';

		// Print extension
		for (i = 0; i < 3; i++)
		{
			// No spaces allowed
			if (entry->FileShortExtension[i] == ' ')
				break;

			// Convert to lower case if necessary
			if (entry->FileOtherInfo[1] & (1 << 4))
				FAT_LFN_Buffer[++nonspace] = ToLowerCase(entry->FileShortExtension[i]);
			else
				FAT_LFN_Buffer[++nonspace] = entry->FileShortExtension[i];
		}
	}

	// Terminate string and reset start of string
	FAT_LFN_Buffer[++nonspace] = '\0';
	FAT_LFN_Index = 0;
}

void FAT_DirectoryEntryGatherLFN (FAT_DirectoryEntry_TypeDef * entry)
{
	// Gather in FAT_LFN_Buffer using FAT_LFN_Index
	FAT_LFN_Index -= 13;
	uint32_t i;
	for (i = 0; i < 13; i++)
		FAT_LFN_Buffer[FAT_LFN_Index + i] = *(((uint8_t *) entry) + FAT_LFN_ENTRIES[i]);
}

void FAT_DirectoryEntryScatterLFN (FAT_DirectoryEntry_TypeDef * entry, char * name)
{
	// Scatter the name over the entry
	uint32_t i;
	uint32_t pad = 0;
	for (i = 0; i < 13; i++)
	{
		uint32_t index = FAT_LFN_ENTRIES[i];
		if (pad == 0)
		{
			// Only support ASCII
			*(((uint8_t *) entry) + index) = name[i];
			*(((uint8_t *) entry) + index + 1) = 0;

			// Start padding if string ended, pad after the terminating null character
			if (name[i] == '\0')
				pad = 1;
		}
		else
		{
			// Pad
			*((uint16_t *)(((uint8_t *) entry) + index)) = 0xFFFF;
		}
	}
}

void FAT_DirectoryFindSetup (uint32_t cluster)
{
	// Initialise variables for first find next call
	FAT_DirectoryFind.Counter = 0;
	FAT_DirectoryFind.Cluster = cluster;
	FAT_DirectoryFind.Sector = 0;
	FAT_DirectoryFind.Entry = 0;
}

uint32_t FAT_DirectoryFindNext (uint32_t type)
{
	// Argument: 0: find empty entry, other flags: determine what non-empty entries are passed
	// Return: 0 if error, 2 if end of last cluster reached, 3 if max entries analysed in root

	// 1 if success (Entry remains valid/available, name in FAT_LFN_Buffer at FAT_LFN_Index if wanted (slower))
	uint8_t FAT_SequenceNumber = 0xFF;

	while (1)
	{
		// Advance to next directory entry
		FAT_DirectoryFind.Counter++;
		if (FAT_DirectoryFind.Counter > 1)
		{
			// Advance to next entry
			FAT_DirectoryFind.Entry++;
			if (FAT_DirectoryFind.Entry == 16)
			{
				// Advance to next sector
				FAT_DirectoryFind.Entry = 0;
				FAT_DirectoryFind.Sector++;
				if (FAT_DirectoryFind.Sector == FAT_Partition.SectorsPerCluster)
				{
					// Advance to next cluster, root directory search should never continue
					FAT_DirectoryFind.Sector = 0;
					FAT_DirectoryFind.Cluster = FAT_GetNextCluster(FAT_DirectoryFind.Cluster);
					if (FAT_DirectoryFind.Cluster == 0)
						return 0;
					if (FAT_DirectoryFind.Cluster == 0xFFFFFFFF)
						return 2;
				}
			}
		}

		// Stop if FAT16 root directory and max entries analysed
		if ((FAT_DirectoryFind.Cluster == 0) && (FAT_DirectoryFind.Counter > FAT_Partition.RootMaxEntries))
			return 3;

		// Get directory entry
		if (SDCARD_Read(FAT_GetAddress(FAT_DirectoryFind.Cluster) + FAT_DirectoryFind.Sector) == 0)
			return 0;
		FAT_DirectoryEntry_TypeDef * entry = ((FAT_DirectoryEntry_TypeDef *) SDCARD_ReadBuffer) + FAT_DirectoryFind.Entry;

		// Treat end marker only as empty entry
		// Skip deleted entries
		if ((entry->FileShortName[0] == 0x00) || (entry->FileShortName[0] == 0xE5))
		{
			// Empty directory entry found!
			if (type == 0)
				return 1;
		}
		else
		{
			// Check for part of LFN
			if (entry->FileOtherInfo[0] == 0x0F)
			{
				if (type & FAT_DIRECTORY_FIND_WITH_NAME)
				{
					// Check if start of LFN
					if (entry->FileShortName[0] & (1 << 6)) {
						FAT_LFN_Index = 260;
						FAT_SequenceNumber = (entry->FileShortName[0] & 0x1F) - 1;
						if (FAT_SequenceNumber >= 20)
							return 0;
					} else if ((entry->FileShortName[0] & 0x1F) == FAT_SequenceNumber)
						FAT_SequenceNumber--;
					else
						return 0;

					// Copy the characters to the FAT_LFN_Buffer
					FAT_DirectoryEntryGatherLFN(entry);
				}
			}
			else
			{
				// New directory entry found: does it pass our search filter?
				if (((type & FAT_DIRECTORY_FIND_VOLUME) && (entry->FileOtherInfo[0] == 0x08)) ||
					((type & FAT_DIRECTORY_FIND_DIRECTORY) && ((entry->FileOtherInfo[0] & 0x78) == 0x10)) ||
					((type & FAT_DIRECTORY_FIND_OTHER) && ((entry->FileOtherInfo[0] & 0x58) == 0x00)))
				{

					// Create the short name in the LFN buffer if no LFN and name required
					if ((type & FAT_DIRECTORY_FIND_WITH_NAME) && (FAT_SequenceNumber != 0))
						FAT_DirectoryEntryPrintDOSName(entry);

					// New directory entry found!
					return 1;
				}
			}
		}
	}
}

uint32_t FAT_DirectoryFindVolumeLabel (void)
{
	// Return: 0 if error, 1 if success
	// The name is printed in FAT_LFN_Buffer and FAT_LFN_Index is reset

	// Fast search (no name creation)
	FAT_DirectoryFindSetup(FAT_Partition.RootCluster);
	if (FAT_DirectoryFindNext(FAT_DIRECTORY_FIND_VOLUME) == 1)
	{
		// Get the directory entry
		FAT_DirectoryEntry_TypeDef * entry = ((FAT_DirectoryEntry_TypeDef *) SDCARD_ReadBuffer) + FAT_DirectoryFind.Entry;
		FAT_DirectoryEntryPrintDOSName(entry);
		return 1;
	}
	return 0;
}

uint32_t FAT_DirectoryFindName (uint32_t cluster, uint32_t type, char * name)
{
	// !!! Return: 0xFFFFFFFF if error/not found, cluster number otherwise

	// Slow search
	FAT_DirectoryFindSetup(cluster);
	while (FAT_DirectoryFindNext(type | FAT_DIRECTORY_FIND_WITH_NAME) == 1)
	{
		// Compare the name
		if (StringCompare(name, &FAT_LFN_Buffer[FAT_LFN_Index]) == 0)
			return FAT_DirectoryEntryGetStartCluster(((FAT_DirectoryEntry_TypeDef *) SDCARD_ReadBuffer) + FAT_DirectoryFind.Entry);
	}
	return 0xFFFFFFFF;
}

uint32_t FAT_DirectoryFindContiguousEntries (uint32_t cluster, uint32_t required)
{
	// Return: 0 if error, 1 otherwise
	// Position is stored in the FAT_DirectoryFind structure (counter not updated)

	// Find a contiguous empty region that's big enough
	uint32_t newCluster;
	uint8_t sector;
	uint8_t entry;
	uint32_t result;
	FAT_DirectoryFindSetup(cluster);
	while (1)
	{
		// Find empty spot
		result = FAT_DirectoryFindNext(0);
		if (result == 0)
		{
			// Error
			return 0;
		}
		else if (result == 1)
		{
			// Certainly single empty entry found
			if (required == 1)
				return 1;

			// Check if the spot is big enough
			uint32_t counter = FAT_DirectoryFind.Counter;
			newCluster = FAT_DirectoryFind.Cluster;
			sector = FAT_DirectoryFind.Sector;
			entry = FAT_DirectoryFind.Entry;

			// Find next non-empty
			result = FAT_DirectoryFindNext(FAT_DIRECTORY_FIND_ANY);
			if (result == 0)
			{
				// Error
				return 0;
			}
			else if (result == 1)
			{
				// Check if it is big enough, otherwise continue search
				if ((FAT_DirectoryFind.Counter - counter) >= required)
				{
					// Set start position of contiguous block
					break;
				}
			}
			else if (result == 2)
			{
				// End of last cluster reached (calculate size till end of THIS LAST cluster)
				if ((FAT_DirectoryFind.Counter - counter) >= required)
				{
					// Set start position of contiguous block
					break;
				}
				else
				{
					// Possible, but requires extension (part in old cluster)
					newCluster = FAT_DirectoryExtend(cluster);
					if (newCluster == 0)
						return 0;

					// Set start position of contiguous block
					break;
				}
			}
			else if (result == 3)
			{
				// Max entries analysed in root
				if ((FAT_DirectoryFind.Counter - counter) >= required)
				{
					// Fits in limited size of root directory
					break;
				}
				else
				{
					// Won't fit and not extensible
					return 0;
				}
			}
		}
		else if (result == 2)
		{
			// End of last cluster reached (must extend, completely in new cluster)
			newCluster = FAT_DirectoryExtend(cluster);
			if (newCluster == 0)
				return 0;

			// Set start position of contiguous block
			FAT_DirectoryFind.Cluster = newCluster;
			FAT_DirectoryFind.Sector = 0;
			FAT_DirectoryFind.Entry = 0;
			return 1;
		}
		else if (result == 3)
		{
			// Max entries analysed in root (no more space error)
			return 0;
		}
	}

	// Set start position of contiguous block
	FAT_DirectoryFind.Cluster = newCluster;
	FAT_DirectoryFind.Sector = sector;
	FAT_DirectoryFind.Entry = entry;
	return 1;
}

uint32_t FAT_DirectoryAddItem (uint32_t cluster, char * name, uint8_t type)
{
	// Return: 0 if error, 1 if success (the FAT_DirectoryFind structure points to the short file name entry, or the cluster of the new directory)
	uint32_t result;
	uint32_t required;

	// Check if the file already exists
	if (FAT_DirectoryFindName(cluster, FAT_DIRECTORY_FIND_ANY, name) != 0xFFFFFFFF)
		return 0;

	// Determine whether LFN is required and prepare short name
	result = FAT_AnalyseAndCreateSFN(name);
	if (result & 0x0100)
		required = 2 + StringLength(name) / 13;
	else
		required = 1;

	// Find a contiguous empty region that's big enough
	if (FAT_DirectoryFindContiguousEntries(cluster, required) == 0)
		return 0;

	// Perform a read-modify as much as possible-write
	// Read the sector containing the entry to be changed
	if (SDCARD_Read(FAT_GetAddress(FAT_DirectoryFind.Cluster) + FAT_DirectoryFind.Sector) == 0)
		return 0;
	uint8_t * write = (uint8_t *)(((FAT_DirectoryEntry_TypeDef *) SDCARD_ReadBuffer) + FAT_DirectoryFind.Entry);

	uint8_t sum = 0;
	uint8_t first = 1;
	while (required)
	{
		// Write back?
		if (write >= SDCARD_ReadBuffer + 512)
		{
			// Write back
			SDCARD_CopyReadBufferToWriteBuffer();
			if (SDCARD_Write(FAT_GetAddress(FAT_DirectoryFind.Cluster) + FAT_DirectoryFind.Sector) == 0)
				return 0;

			// Get next sector
			FAT_DirectoryFind.Sector++;
			if (FAT_DirectoryFind.Sector == FAT_Partition.SectorsPerCluster)
			{
				// Advance to next cluster, root directory search should never continue
				FAT_DirectoryFind.Sector = 0;
				FAT_DirectoryFind.Cluster = FAT_GetNextCluster(FAT_DirectoryFind.Cluster);
				if ((FAT_DirectoryFind.Cluster == 0) || (FAT_DirectoryFind.Cluster == 0xFFFFFFFF))
					return 0;
			}

			// Read
			if (SDCARD_Read(FAT_GetAddress(FAT_DirectoryFind.Cluster) + FAT_DirectoryFind.Sector) == 0)
				return 0;

			// Set new write pointer
			write = SDCARD_ReadBuffer;
		}

		// Regular entry or LFN entries?
		if (required == 1)
		{
			// Add regular entry, copy the short name (and case), type, cluster 0, size 0 etc.
			uint32_t i;
			for (i = 0; i < 11; i++)
				write[i] = FAT_SFN_Buffer[i];
			write[11] = type;
			write[12] = result & 0xFF;
			for (i = 13; i < 32; i++)
				write[i] = 0;
		}
		else
		{
			// String index
			uint32_t index = 13 * (required - 2);

			// Set sequence number
			write[0] = (required - 1);

			// Update SFN and calculate checksum if LFN must be created
			if (first)
			{
				// FIXME: new name is not checked to be unique, but probably is if the other files are also created in the same power cycle
				FAT_SFN_Buffer[5] = '~';
				FAT_UniqueSFN++;
				FAT_SFN_Buffer[6] = 'A' + FAT_UniqueSFN / 26;
				FAT_SFN_Buffer[7] = 'A' + FAT_UniqueSFN % 26;

				// Calculate the checksum
				uint8_t * name = (uint8_t *) FAT_SFN_Buffer;
				sum = 0;
				uint32_t i;
				for (i = 11; i; i--)
					sum = ((sum & 1) << 7) + (sum >> 1) + *name++;

				// Note end
				write[0] |= (1 << 6);
				first = 0;
			}

			// Set other fields of interest
			write[11] = 0x0F;
			write[12] = 0x00;
			write[13] = sum;
			write[26] = 0;
			write[27] = 0;

			// Fill in the characters
			FAT_DirectoryEntryScatterLFN((FAT_DirectoryEntry_TypeDef *) write, name + index);
		}

		// Advance
		write += 32;
		required--;
	}

	// Write back
	SDCARD_CopyReadBufferToWriteBuffer();
	if (SDCARD_Write(FAT_GetAddress(FAT_DirectoryFind.Cluster) + FAT_DirectoryFind.Sector) == 0)
		return 0;

	// Return with the FAT_DirectoryFind structure pointing to the short file name entry
	FAT_DirectoryFind.Entry = (FAT_DirectoryFind.Entry + required - 1) & 0x0F;

	// In case a directory was added, add a file with the "." and ".." entries
	if ((type & 0x58) == 0x10)
	{
		// Allocate a cluster
		uint32_t newCluster = FAT_DirectoryExtend(0);
		if (newCluster == 0)
			return 0;

		// Add the "." and ".." entries
		uint32_t i;
		SDCARD_ClearWriteBuffer();
		SDCARD_WriteBuffer[0] = '.';
		for (i = 1; i < 11; i++)
			SDCARD_WriteBuffer[i] = ' ';
		SDCARD_WriteBuffer[11] = 0x10;
		SDCARD_WriteBuffer[32] = '.';
		SDCARD_WriteBuffer[33] = '.';
		for (i = 34; i < 43; i++)
			SDCARD_WriteBuffer[i] = ' ';
		SDCARD_WriteBuffer[43] = 0x10;
		FAT_DirectoryEntrySetStartCluster((FAT_DirectoryEntry_TypeDef *)(SDCARD_WriteBuffer + 0), newCluster);
		FAT_DirectoryEntrySetStartCluster((FAT_DirectoryEntry_TypeDef *)(SDCARD_WriteBuffer + 32), cluster);
		if (SDCARD_Write(FAT_GetAddress(newCluster)) == 0)
			return 0;

		// Link the cluster
		if (SDCARD_Read(FAT_GetAddress(FAT_DirectoryFind.Cluster) + FAT_DirectoryFind.Sector) == 0)
			return 0;
		FAT_DirectoryEntrySetStartCluster((FAT_DirectoryEntry_TypeDef *)(write - 32), newCluster);
		SDCARD_CopyReadBufferToWriteBuffer();
		if (SDCARD_Write(FAT_GetAddress(FAT_DirectoryFind.Cluster) + FAT_DirectoryFind.Sector) == 0)
			return 0;

		// Return with the FAT_DirectoryFind.Cluster pointing to the new directory
		FAT_DirectoryFind.Cluster = newCluster;
	}

	return 1;
}

uint32_t FAT_AnalyseAndCreateSFN (char * name)
{
	// Return:
	// 0x0100: LFN
	// 0x0000: SFN, upper case base name, upper case extension
	// 0x0008: SFN, lower case base name, upper case extension
	// 0x0010: SFN, upper case base name, lower case extension
	// 0x0018: SFN, lower case base name, lower case extension
	// FIXME: Special characters not checked, special case "." and ".." not handled

	// 0: case unknown, 1: lower case, 2: upper case, 3: mixed case
	uint32_t i = 0;

	// Determine SFN of base, remember properties
	uint32_t base = 0;
	while (i < 8)
	{
		// Advance pointer if still in base name
		if ((*name == '.') || (*name == '\0'))
		{
			// Pad with spaces
			FAT_SFN_Buffer[i] = ' ';
		}
		else
		{
			// Mixed case?
			if (base == 0)
			{
				// Determine case
				if (IsLowerCase(*name))
					base = 1;
				else if (IsUpperCase(*name))
					base = 2;
			}
			else if (base == 1)
			{
				// Different case?
				if (IsUpperCase(*name))
					base = 3;
			}
			else if (base == 2)
			{
				// Different case?
				if (IsLowerCase(*name))
					base = 3;
			}

			// Copy character, possibly transforming to upper case
			FAT_SFN_Buffer[i] = ToUpperCase(*name);
			name++;
		}
		i++;
	}

	// Increment until end or dot found
	while (!((*name == '.') || (*name == '\0')))
	{
		// Not a SFN
		base = 3;
		name++;
	}

	// Increment if dot
	if (*name == '.')
		name++;

	// Determine SFN of extension, remember properties
	uint32_t extension = 0;
	while (i < 11)
	{
		// Advance pointer if still in extension name
		if (*name == '\0')
		{
			// Pad with spaces
			FAT_SFN_Buffer[i] = ' ';
		}
		else
		{
			// Mixed case?
			if (extension == 0)
			{
				// Determine case
				if (IsLowerCase(*name))
					extension = 1;
				else if (IsUpperCase(*name))
					extension = 2;
			}
			else if (extension == 1)
			{
				// Different case?
				if (IsUpperCase(*name))
					extension = 3;
			}
			else if (extension == 2)
			{
				// Different case?
				if (IsLowerCase(*name))
					extension = 3;
			}

			// Copy character, possibly transforming to upper case
			FAT_SFN_Buffer[i] = ToUpperCase(*name);
			name++;
		}
		i++;
	}

	// Is it not the end?
	if (*name != '\0')
		// Not a SFN
		extension = 3;

	// Return LFN result
	if ((base == 3) || (extension == 3))
		return 0x0100;

	// Return lower case result
	return (((base == 1) << 3) | ((extension == 1) << 4));
}

#endif//STM
