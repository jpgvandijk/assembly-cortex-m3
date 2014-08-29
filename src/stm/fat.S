/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"fat.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Functions
			.global		FAT_Next
			.global		FAT16_Next
			.global		FAT32_Next
			.global		FAT_CacheFATChanger
			.global		FAT16_AllocHelper
			.global		FAT32_AllocHelper
			.global		FAT_Alloc
			.global		FAT_Free
			.global		FAT_GetEntry
			.global		FAT_ClearEntriesOfCluster
			.global		FAT_EntryGetStartCluster
			.global		FAT_EntrySetStartCluster
			.global		FAT_EntryGartherLFN
			.global		FAT_EntryScatterLFN
			.global		FAT_EntryPrintSFN
			.global		FAT_CreateSFN
			.global		FAT_GetData
			.global		FAT_TypeOfPartition
			.global		FAT_MountPartition
			.global		FAT_UnmountPartition
			.global		FAT_FindSetup
			.global		FAT_FindNext

			@ Variables
			.global		FAT_Partition
			.global		FAT_Partition_Size
			.global		FAT_Partition_Address
			.global		FAT_Partition_AddressFAT1
			.global		FAT_Partition_AddressFAT2
			.global		FAT_Partition_AddressData
			.global		FAT_Partition_SectorsPerFAT
			.global		FAT_Partition_RootCluster
			.global		FAT_Partition_RootMaxEntries
			.global		FAT_Partition_SectorsPerCluster
			.global		FAT_Partition_Type
			.global		FAT_NameBuffers
			.global		FAT_LFN
			.global		FAT_LFN_Index
			.global		FAT_LFN_Buffer
			.global		FAT_SFN
			.global		FAT_SFN_Buffer
			.global		FAT_FindCounter
			.global		FAT_CacheFAT
			.global		FAT_CacheFAT_Address
			.global		FAT_CacheFAT_Modified
			.global		FAT_CacheFAT_Buffer
			.global		FAT_CacheEntries
			.global		FAT_Cluster
			.global		FAT_Sector
			.global		FAT_Entry
			.global		FAT_CacheEntries_Policy
			.global		FAT_CacheEntries_MRU
			.global		FAT_CacheEntry1
			.global		FAT_CacheEntry1_Address
			.global		FAT_CacheEntry1_Modified
			.global		FAT_CacheEntry1_Buffer
			.global		FAT_CacheEntry2
			.global		FAT_CacheEntry2_Address
			.global		FAT_CacheEntry2_Modified
			.global		FAT_CacheEntry2_Buffer
			.global		FAT_CacheData
			.global		FAT_CacheData_Address
			.global		FAT_CacheData_Modified
			.global		FAT_CacheData_Buffer

			@ Constants
			.global		FAT_EntryLFN_Indices





@-----------------------------------------------------------@
@ FAT Variables												@
@-----------------------------------------------------------@

			@ Partition info
			.section	.noinit.FAT_Partition
			.type		FAT_Partition, "object"
			.align		2
FAT_Partition:
FAT_Partition_Size:
			.space		4
FAT_Partition_Address:
			.space		4
FAT_Partition_AddressFAT1:
			.space		4
FAT_Partition_AddressFAT2:
			.space		4
FAT_Partition_AddressData:
			.space		4
FAT_Partition_SectorsPerFAT:
			.space		4
FAT_Partition_RootCluster:
			.space		4
FAT_Partition_RootMaxEntries:
			.space		2
FAT_Partition_SectorsPerCluster:
			.space		1
FAT_Partition_Type:
			.space		1





			@ Name buffers
			.section	.noinit.FAT_NameBuffers
			.type		FAT_NameBuffers, "object"
			.align		1
FAT_NameBuffers:
FAT_LFN:
FAT_LFN_Index:
			.space		2
FAT_LFN_Buffer:
			.space		260
FAT_SFN:
FAT_SFN_Buffer:
			.space		11





			@ Find variables
			.section	.noinit.FAT_FindCounter
			.type		FAT_FindCounter, "object"
			.align		2
FAT_FindCounter:
			.space		4





			@ Cache for the FAT
			.section	.noinit.FAT_CacheFAT
			.type		FAT_CacheFAT, "object"
			.align		2
FAT_CacheFAT:
FAT_CacheFAT_Address:
			.space		4
FAT_CacheFAT_Modified:
			.space		1
_fat_cachefat_reserved_:
			.space		2
_fat_cachefat_token_:
			.space		1
FAT_CacheFAT_Buffer:
			.space		512





			@ Cache for the directory entries
			.section	.noinit.FAT_CacheEntries
			.type		FAT_CacheEntries, "object"
			.align		2
FAT_CacheEntries:

			@ Management + global identification registers (cluster, sector, entry)
FAT_Cluster:
			.space		4
FAT_Sector:
			.space		1
FAT_Entry:
			.space		1
FAT_CacheEntries_Policy:
			.space		1
FAT_CacheEntries_MRU:
			.space		1

			@ Entry 1
FAT_CacheEntry1:
FAT_CacheEntry1_Address:
			.space		4
FAT_CacheEntry1_Modified:
			.space		1
_fat_cacheentry1_reserved_:
			.space		2
_fat_cacheentry1_token_:
			.space		1
FAT_CacheEntry1_Buffer:
			.space		512

			@ Entry 2
FAT_CacheEntry2:
FAT_CacheEntry2_Address:
			.space		4
FAT_CacheEntry2_Modified:
			.space		1
_fat_cacheentry2_reserved_:
			.space		2
_fat_cacheentry2_token_:
			.space		1
FAT_CacheEntry2_Buffer:
			.space		512





			@ Cache for the data
			.section	.noinit.FAT_CacheData
			.type		FAT_CacheData, "object"
			.align		2
FAT_CacheData:
FAT_CacheData_Address:
			.space		4
FAT_CacheData_Modified:
			.space		1
_fat_cachedata_reserved_:
			.space		2
_fat_cachedata_token_:
			.space		1
FAT_CacheData_Buffer:
			.space		512





@-----------------------------------------------------------@
@ FAT Functions												@
@-----------------------------------------------------------@

			.section	.text.FAT_Next
			.type		FAT_Next, "function"
FAT_Next:
			@ Arguments:
			@ r0: cluster number

			@ Return values:
			@ r0: next cluster number, -1 if last
			@ r1: pointer for internal use

			@ Jump to the correct function
			@ On repeated calls from a single function it is better to do this check
			@ only once and jump to the correct handler using e.g. function pointers
			ldrb		r3, [r0, (FAT_Partition_Type - FAT_Partition)]
			cmp			r3, PARTITION_TYPE_FAT16
			beq			FAT16_Next
			b			FAT32_Next





			.section	.text.FAT16_Next
			.type		FAT16_Next, "function"
FAT16_Next:
			@ Arguments:
			@ r0: cluster number

			@ Return values:
			@ r0: next cluster number, -1 if last
			@ r1: pointer for internal use

			@ If cluster is 0 return 0
			cbz			r0, 0f

			@ Calculate the address offset
			lsrs		r2, r0, #8

			@ Check if it matches with the cached address
			ldr			r1, =FAT_CacheFAT
			ldr			r3, [r1, (FAT_CacheFAT_Address - FAT_CacheFAT)]
			cmp			r3, r2
			beq			1f

			@ Change cached block
			push		{r0, r1, lr}
			bl			FAT_CacheFATChanger
			pop			{r0, r1, lr}

			@ Read the next cluster number
1:			ands		r0, #0xFF
			adds		r1, r1, r0, LSL #1
			ldrh		r0, [r1, (FAT_CacheFAT_Buffer - FAT_CacheFAT)]

			@ Last cluster
			movw		r3, #0xFFFF
			cmp			r0, r3
			it			eq
			moveq		r0, #-1

			@ Return
0:			bx			lr





			.section	.text.FAT32_Next
			.type		FAT32_Next, "function"
FAT32_Next:
			@ Arguments:
			@ r0: cluster number

			@ Return values:
			@ r0: next cluster number, -1 if last
			@ r1: pointer for internal use

			@ If cluster is 0 return 0
			cbz			r0, 0f

			@ Calculate the address offset
			lsrs		r2, r0, #7

			@ Check if it matches with the cached address
			ldr			r1, =FAT_CacheFAT
			ldr			r3, [r1, (FAT_CacheFAT_Address - FAT_CacheFAT)]
			cmp			r3, r2
			beq			1f

			@ Change cached block
			push		{r0, r1, lr}
			bl			FAT_CacheFATChanger
			pop			{r0, r1, lr}

			@ Read the next cluster number
1:			ands		r0, #0x7F
			adds		r1, r1, r0, LSL #2
			ldr			r0, [r1, (FAT_CacheFAT_Buffer - FAT_CacheFAT)]
			ldr			r3, =0x0FFFFFFF
			ands		r0, r3

			@ Last cluster
			cmp			r0, r3
			it			eq
			moveq		r0, #-1

			@ Return
0:			bx			lr





			.section	.text.FAT_CacheFATChanger
			.type		FAT_CacheFATChanger, "function"
FAT_CacheFATChanger:

			@ Arguments:
			@ r1: FAT_CacheFAT
			@ r2: new address offset
			@ r3: current address offset

			@ Save registers
			push		{lr}

			@ Check if cached block must be written back
			ldrb		r0, [r1, (FAT_CacheFAT_Modified - FAT_CacheFAT)]
			cbz			r0, 0f

			@ Reset the modified flag
			movs		r0, #0
			strb		r0, [r1, (FAT_CacheFAT_Modified - FAT_CacheFAT)]

			@ Write back the cached block to both FATs
			push		{r1, r2, r4, r5}
			cpy			r4, r3
			ldr			r5, =FAT_Partition
			ldr			r0, [r5, (FAT_Partition_AddressFAT1 - FAT_Partition)]
			adds		r0, r4
			ldr			r1, =_fat_cachefat_token_
			bl			SDCARD_Write
			ldr			r0, [r5, (FAT_Partition_AddressFAT2 - FAT_Partition)]
			adds		r0, r4
			ldr			r1, =_fat_cachefat_token_
			bl			SDCARD_Write
			pop			{r1, r2, r4, r5}

			@ New block can be loaded
0:			str			r2, [r1, (FAT_CacheFAT_Address - FAT_CacheFAT)]
			ldr			r0, =FAT_Partition
			ldr			r0, [r0, (FAT_Partition_AddressFAT1 - FAT_Partition)]
			adds		r0, r2
			adds		r1, (FAT_CacheFAT_Buffer - FAT_CacheFAT)
			bl			SDCARD_Read

			@ Restore registers and return
			pop			{pc}





			.section	.text.FAT16_AllocHelper
			.type		FAT16_AllocHelper, "function"
FAT16_AllocHelper:

			@ Return values
			@ r0: index: 0...255, 512 if not found

			@ Check currently loaded sector for an empty spot
			movs		r0, #0
			ldr			r1, =FAT_CacheFAT_Buffer
0:			ldrh		r2, [r1, r0]
			cbz			r2, 1f
			adds		r0, #2
			cmp			r0, #512
			blo			0b
			bx			lr

			@ Empty spot found
1:			movw		r2, #0xFFFF
			strh		r2, [r1, r0]
			lsrs		r0, #1
			bx			lr





			.section	.text.FAT32_AllocHelper
			.type		FAT32_AllocHelper, "function"
FAT32_AllocHelper:

			@ Return values
			@ r0: index: 0...127, 512 if not found

			@ Check currently loaded sector for an empty spot
			movs		r0, #0
			ldr			r1, =FAT_CacheFAT_Buffer
0:			ldr			r2, [r1, r0]
			cbz			r2, 1f
			adds		r0, #4
			cmp			r0, #512
			blo			0b
			bx			lr

			@ Empty spot found
1:			movs		r2, #0x0FFFFFFF
			str			r2, [r1, r0]
			lsrs		r0, #2
			bx			lr





			.section	.text.FAT_Alloc
			.type		FAT_Alloc, "function"
FAT_Alloc:

			@ Arguments:
			@ r0: cluster number of chain to link to, 0 if no linking required

			@ Return values:
			@ r0: new cluster number, 0 on error

			@ Save registers and arguments
			push		{r4, r5, lr}
			cpy			r4, r0

			@ Load address bases
			ldr			r0, =FAT_Partition
			ldr			r1, =FAT_CacheFAT

			@ Load analysis function
			ldrb		r3, [r0, (FAT_Partition_Type - FAT_Partition)]
			cmp			r3, PARTITION_TYPE_FAT16
			ite			eq
			ldreq		r5, =FAT16_AllocHelper
			ldrne		r5, =FAT32_AllocHelper

			@ For each sector
			movs		r2, #0

			@ After two sectors the buffer contents must have been written back
			@ Since, except for the last analysed sector, the sectors are only read a faster swap is possible
0:			push		{r0, r1, r2}
			cmp			r2, #2
			bhs			1f
			ldr			r3, [r1, (FAT_CacheFAT_Address - FAT_CacheFAT)]
			cmp			r3, r2
			beq			2f

			@ Change cached block
			bl			FAT_CacheFATChanger
			b			2f

			@ Simply read the next block
1:			ldr			r0, [r0, (FAT_Partition_AddressFAT1 - FAT_Partition)]
			adds		r0, r2
			adds		r1, (FAT_CacheFAT_Buffer - FAT_CacheFAT)
			bl			SDCARD_Read

			@ Sector read, analyse it
2:			blx			r5
			cmp			r0, #512
			blo			3f

			@ Advance to the next sector
			pop			{r0, r1, r2}
			ldr			r3, [r0, (FAT_Partition_SectorsPerFAT - FAT_Partition)]
			adds		r2, #1
			cmp			r2, r3
			bne			0b

			@ No empty spot was found
			@ Set cached address, since this was conveniently skipped!
			subs		r2, #1
			str			r2, [r1, (FAT_CacheFAT_Address - FAT_CacheFAT)]

			@ Return error, no linking possible if required
			movs		r0, #0
			pop			{r4, r5, pc}

			@ Empty spot was found and allocated, first correct the stack and cached address
3:			cpy			r5, r0
			pop			{r0, r1, r2}
			str			r2, [r1, (FAT_CacheFAT_Address - FAT_CacheFAT)]

			@ Set the modified flag
			movs		r3, #1
			strb		r3, [r1, (FAT_CacheFAT_Modified - FAT_CacheFAT)]

			@ Calculate the cluster number
			ldrb		r3, [r0, (FAT_Partition_Type - FAT_Partition)]
			cmp			r3, PARTITION_TYPE_FAT16
			ite			eq
			addeq		r5, r5, r2, LSL #8
			addne		r5, r5, r2, LSL #7

			@ Return the cluster number if linking is not required
			cbnz		r4, 4f
			cpy			r0, r5
			pop			{r4, r5, pc}

			@ Link, find the last
4:			push		{r6}
			cmp			r3, PARTITION_TYPE_FAT16
			ite			eq
			ldreq		r6, =FAT16_Next
			ldrne		r6, =FAT32_Next
5:			movs		r0, r4
			blx			r6
			cbz			r0, 6f
			cmp			r0, #-1
			itt			ne
			movne		r4, r0
			bne			5b

			@ The last link was found, modify to the new cluster number
			@ The sector is in the buffer and a useful pointer is available
			ldr			r0, =FAT_Partition
			ldrb		r3, [r0, (FAT_Partition_Type - FAT_Partition)]
			cmp			r3, PARTITION_TYPE_FAT16
			ite			eq
			strheq		r5, [r1, (FAT_CacheFAT_Buffer - FAT_CacheFAT)]
			strne		r5, [r1, (FAT_CacheFAT_Buffer - FAT_CacheFAT)]

			@ Set the modified flag
			ldr			r1, =FAT_CacheFAT
			movs		r3, #1
			strb		r3, [r1, (FAT_CacheFAT_Modified - FAT_CacheFAT)]

			@ Return the cluster number
			cpy			r0, r5

			@ FAT next returned cluster 0, this is an error
6:			pop			{r6}
			pop			{r4, r5, pc}





			.section	.text.FAT_Free
			.type		FAT_Free, "function"
FAT_Free:

			@ Arguments:
			@ r0: starting cluster (immediately returns without error if 0)

			@ Return values:
			@ r0: status, 0 on error

			@ Immediately return without error if 0
			cbnz		r0, 0f
			movs		r0, #1
			bx			lr

			@ Setup the registers
0:			push		{r4, r5, lr}
			ldr			r4, =FAT_Partition
			ldrb		r4, [r4, (FAT_Partition_Type - FAT_Partition)]
			cmp			r4, PARTITION_TYPE_FAT16
			ite			eq
			ldreq		r5, =FAT16_Next
			ldrne		r5, =FAT32_Next

			@ Get the next cluster number
1:			blx			r5
			cbz			r0, 2f

			@ Mark current spot as free and set the modified flag
			movs		r2, #0
			cmp			r4, PARTITION_TYPE_FAT16
			ite			eq
			strheq		r2, [r1, (FAT_CacheFAT_Buffer - FAT_CacheFAT)]
			strne		r2, [r1, (FAT_CacheFAT_Buffer - FAT_CacheFAT)]

			@ Set the modified flag
			ldr			r1, =FAT_CacheFAT
			movs		r2, #1
			strb		r2, [r1, (FAT_CacheFAT_Modified - FAT_CacheFAT)]

			@ Continue to the next if it was not the last
			cmp			r0, #-1
			bne			1b

			@ Return with the status
2:			pop			{r4, r5, pc}





			.section	.text.FAT_GetEntry
			.type		FAT_GetEntry, "function"
FAT_GetEntry:

			@ Arguments:
			@ none

			@ Return values:
			@ r0: pointer to the entry

			@ Shortcut for internal use: _fat_getentry_address_in_r2_
			@ Arguments: r0: FAT_CacheEntries,  r2: address
			@ Return values: r2: base of the buffer

			@ Load base addresses of the data structures
			ldr			r0, =FAT_CacheEntries
			ldr			r1, =FAT_Partition

			@ Get the cluster number to calculate the base address
			ldr			r2, [r0, (FAT_Cluster - FAT_CacheEntries)]
			cbnz		r2, 0f

			@ Cluster 0 for root directory on FAT16 partition
			ldr			r2, [r1, (FAT_Partition_AddressFAT2 - FAT_Partition)]
			ldr			r3, [r1, (FAT_Partition_SectorsPerFAT - FAT_Partition)]
			adds		r2, r3
			b			1f

			@ Cluster in the data region
0:			ldrb		r3, [r1, (FAT_Partition_SectorsPerCluster - FAT_Partition)]
			muls		r2, r3
			ldr			r3, [r1, (FAT_Partition_AddressData - FAT_Partition)]
			adds		r2, r3

			@ Calculate the address
1:			ldrb		r3, [r0, (FAT_Sector - FAT_CacheEntries)]
			adds		r2, r3

_fat_getentry_address_in_r2_:

			@ Check if this address is already cached
			ldr			r3, [r0, (FAT_CacheEntry1_Address - FAT_CacheEntries)]
			cmp			r3, r2
			beq			_fat_getentry_cached1_
			ldr			r3, [r0, (FAT_CacheEntry2_Address - FAT_CacheEntries)]
			cmp			r3, r2
			beq			_fat_getentry_cached2_

			@---------------------------------------------

			@ Save registers
			push		{r0, lr}

			@ Check if one of the cache locations is empty
			cmp			r3, #-1
			itt			eq
			addeq		r1, r0, (FAT_CacheEntry2 - FAT_CacheEntries)
			beq			_fat_getentry_load_
			ldr			r3, [r0, (FAT_CacheEntry1_Address - FAT_CacheEntries)]
			cmp			r3, #-1
			itt			eq
			addeq		r1, r0, (FAT_CacheEntry1 - FAT_CacheEntries)
			beq			_fat_getentry_load_

			@ Use the least recently used cache location
			ldrb		r3, [r0, (FAT_CacheEntries_MRU - FAT_CacheEntries)]
			cmp			r3, #0
			ite			eq
			addeq		r1, r0, (FAT_CacheEntry2 - FAT_CacheEntries)
			addne		r1, r0, (FAT_CacheEntry1 - FAT_CacheEntries)

			@ Check if the contents are modified
			ldrb		r3, [r1, (FAT_CacheEntry1_Modified - FAT_CacheEntry1)]
			cbz			r3, _fat_getentry_load_
			movs		r3, #0
			strb		r3, [r1, (FAT_CacheEntry1_Modified - FAT_CacheEntry1)]

			@ Write-back
			push		{r1, r2}
			ldr			r0, [r1, (FAT_CacheEntry1_Address - FAT_CacheEntry1)]
			adds		r1, (_fat_cacheentry1_token_ - FAT_CacheEntry1)
			bl			SDCARD_Write
			pop			{r1, r2}

			@ Load, new address must still be set
_fat_getentry_load_:
			str			r2, [r1, (FAT_CacheEntry1_Address - FAT_CacheEntry1)]
			push		{r1}
			cpy			r0, r2
			adds		r1, (FAT_CacheEntry1_Buffer - FAT_CacheEntry1)
			bl			SDCARD_Read
			pop			{r1}

			@ Restore registers and determine where to continue
			pop			{r0, lr}
			ldr			r2, =FAT_CacheEntry1
			cmp			r1, r2
			bne			_fat_getentry_cached2_

			@---------------------------------------------

			@ Address cached in location 1, update MRU if required
_fat_getentry_cached1_:
			ldrb		r2, [r0, (FAT_CacheEntries_Policy - FAT_CacheEntries)]
			cbnz		r2, 2f
			movs		r2, #0
			strb		r2, [r0, (FAT_CacheEntries_MRU - FAT_CacheEntries)]

			@ Return a pointer to the entry
2:			adds		r2, r0, (FAT_CacheEntry1_Buffer - FAT_CacheEntries)
			ldrb		r3, [r0, (FAT_Entry - FAT_CacheEntries)]
			adds		r0, r2, r3, LSL #5
			bx			lr

			@ Address cached in location 2, update MRU if required
_fat_getentry_cached2_:
			ldrb		r2, [r0, (FAT_CacheEntries_Policy - FAT_CacheEntries)]
			cbnz		r2, 3f
			movs		r2, #1
			strb		r2, [r0, (FAT_CacheEntries_MRU - FAT_CacheEntries)]

			@ Return a pointer to the entry
3:			adds		r2, r0, (FAT_CacheEntry2_Buffer - FAT_CacheEntries)
			ldrb		r3, [r0, (FAT_Entry - FAT_CacheEntries)]
			adds		r0, r2, r3, LSL #5
			bx			lr





			.section	.text.FAT_ClearEntriesOfCluster
			.type		FAT_ClearEntriesOfCluster, "function"
FAT_ClearEntriesOfCluster:

			@ Arguments
			@ r0: cluster number (0/1 not allowed, not checked)
			@ Note: Function assumes that none of the sectors of this cluster is in the MRU cache location!

			@ Save registers
			push		{r4, r5, r6, lr}

			@ Calculate the cluster base address, and the address of the last sector
			ldr			r1, =FAT_Partition
			ldrb		r2, [r1, (FAT_Partition_SectorsPerCluster - FAT_Partition)]
			muls		r0, r2
			ldr			r3, [r1, (FAT_Partition_AddressData - FAT_Partition)]
			adds		r4, r0, r3
			adds		r5, r4, r2
			subs		r5, #1

			@ Replace LRU cache entry
			@ Don't use the global identification registers, use shortcut into the function and use the buffer returned in r2
			@ FIXME: one read from the SD-card is performed which is completely useless...
			ldr			r0, =FAT_CacheEntries
			cpy			r2, r5
			bl			_fat_getentry_address_in_r2_
			subs		r6, r2, #1

			@ Clear the buffer contents
			movs		r0, #0
			adds		r3, r2, #512
0:			str			r0, [r2], #4
			cmp			r2, r3
			bne			0b

			@ Write-back to all sectors but the first sector in the cluster
			@ r4: lowest address
			@ r5: highest address
			@ r6: buffer token address
1:			cpy			r0, r5
			cpy			r1, r6
			bl			SDCARD_Write
			subs		r5, #1
			cmp			r4, r5
			bne			1b

			@ Don't write back the first sector in the cluster, but set the address and modified flag
			str			r4, [r6, (FAT_CacheEntry1_Address - _fat_cacheentry1_token_)]
			movs		r0, #1
			strb		r0, [r6, (FAT_CacheEntry1_Modified - _fat_cacheentry1_token_)]

			@ Restore registers and return
			pop			{r4, r5, r6, pc}





			.section	.text.FAT_EntryStartCluster
			.type		FAT_EntryGetStartCluster, "function"
FAT_EntryGetStartCluster:

			@ Argument
			@ r0: pointer to an entry

			@ Return values:
			@ r0: start cluster

			@ Load the first halfword and conditionally append a second one
			ldrh		r2, [r0, #26]
			ldr			r1, =FAT_Partition
			ldrb		r1, [r1, (FAT_Partition_Type - FAT_Partition)]
			cmp			r1, PARTITION_TYPE_FAT16
			itt			ne
			ldrhne		r3, [r0, #20]
			addne		r2, r2, r3, LSL #16
			cpy			r0, r2
			bx			lr





			.section	.text.FAT_EntryStartCluster
			.type		FAT_EntrySetStartCluster, "function"
FAT_EntrySetStartCluster:

			@ Argument
			@ r0: pointer to an entry
			@ r1: start cluster

			strh		r1, [r0, #26]
			ldr			r2, =FAT_Partition
			ldrb		r2, [r2, (FAT_Partition_Type - FAT_Partition)]
			cmp			r2, PARTITION_TYPE_FAT16
			ite			eq
			moveq		r1, #0
			lsrne		r1, #16
			strh		r1, [r0, #20]
			bx			lr





			.section	.text.FAT_EntryLFN
			.type		FAT_EntryGartherLFN, "function"
FAT_EntryGartherLFN:

			@ Argument:
			@ r0: pointer to an entry

			@ Save registers
			push		{r4, lr}

			@ Setup
			ldr			r1, =FAT_LFN
			ldrh		r2, [r1, (FAT_LFN_Index - FAT_LFN)]
			subs		r2, #13
			strh		r2, [r1, (FAT_LFN_Index - FAT_LFN)]
			adds		r1, (FAT_LFN_Buffer - FAT_LFN)
			adds		r1, r2
			adds		r2, r1, #13
			ldr			r3, =FAT_EntryLFN_Indices

			@ Loop
0:			ldrb		r4, [r3], #1
			ldrb		r4, [r0, r4]
			strb		r4, [r1], #1
			cmp			r1, r2
			bne			0b

			@ Restore registers and return
			pop			{r4, pc}





			.section	.text.FAT_EntryLFN
			.type		FAT_EntryScatterLFN, "function"
FAT_EntryScatterLFN:

			@ Arguments:
			@ r0: pointer to an entry
			@ r1: text string starting at the position to be used

			@ Save registers
			push		{r4, r5, r6, lr}

			@ Setup
			ldr			r2, =FAT_EntryLFN_Indices
			adds		r3, r2, #13
			movs		r5, #1

			@ Loop
0:			ldrb		r4, [r2], #1

			@ Check if padding required
			cbz			r5, 1f

			@ Write character
			ldrb		r5, [r1], #1
			strb		r5, [r0, r4]
			movs		r6, #0x00
			b			2f

			@ Padd
1:			movs		r6, #0xFF
			strb		r6, [r0, r4]
2:			adds		r4, #1
			strb		r6, [r0, r4]
			cmp			r2, r3
			bne			0b

			@ Restore registers and return
			pop			{r4, r5, r6, pc}





			.section	.text.FAT_EntryLFN
			.type		FAT_EntryLFN_Indices, "object"
FAT_EntryLFN_Indices:
			.byte		0x01
			.byte		0x03
			.byte		0x05
			.byte		0x07
			.byte		0x09
			.byte		0x0E
			.byte		0x10
			.byte		0x12
			.byte		0x14
			.byte		0x16
			.byte		0x18
			.byte		0x1C
			.byte		0x1E
			.align		1





			.section	.text.FAT_EntryPrintSFN
			.type		FAT_EntryPrintSFN, "object"
FAT_EntryPrintSFN:

			@ Arguments:
			@ r0: pointer to an entry

			@ Save registers
			push		{r4, r5, lr}

			@ Setup
			adds		r1, r0, #8
			ldrb		r2, [r0, #12]
			ldr			r4, =FAT_LFN_Buffer
			cpy			r5, r4

			@ Read a character and advance the pointer
0:			ldrb		r3, [r0], #1

			@ Convert to lower case if required
			tst			r2, (1 << 3)
			beq			1f
			cmp			r3, 'A'
			blo			1f
			cmp			r3, 'Z'
			bhi			1f
			adds		r3, ('a'-'A')

			@ Store the character in the LFN buffer
1:			strb		r3, [r4], #1

			@ Remember the position of a non-space character
			cmp			r3, ' '
			it			ne
			movne		r5, r4

			@ Continue for the complete basename
			cmp			r0, r1
			bne			0b

			@ Check if there is actually an extension
			ldrb		r3, [r0]
			cmp			r3, ' '
			beq			4f

			@ Store the dot and setup for the extension
			movs		r3, '.'
			strb		r3, [r5], #1
			adds		r1, #3

			@ Read a character and advance the pointer
2:			ldrb		r3, [r0], #1

			@ No spaces allowed
			cmp			r3, ' '
			beq			4f

			@ Convert to lower case if required
			tst			r2, (1 << 4)
			beq			3f
			cmp			r3, 'A'
			blo			3f
			cmp			r3, 'Z'
			bhi			3f
			adds		r3, ('a'-'A')

			@ Store the character in the LFN buffer
3:			strb		r3, [r5], #1

			@ Continue for the complete basename
			cmp			r0, r1
			bne			2b

			@ All copied, terminate the string
4:			movs		r3, #0
			strb		r3, [r5]

			@ Set the start of the string
			ldr			r0, =FAT_LFN_Index
			strh		r3, [r0]

			@ Restore registers and return
			pop			{r4, r5, pc}





			.section	.text.FAT_CreateSFN
			.type		FAT_CreateSFN, "object"
FAT_CreateSFN:

			@ Arguments:
			@ r0: name string, N.B.: special characters are not checked and must be valid for use in short file names!

			@ Return values:
			@ r0: 0x0100: LFN
			@ r0: 0x0000: SFN, upper case base name, upper case extension
			@ r0: 0x0008: SFN, lower case base name, upper case extension
			@ r0: 0x0010: SFN, upper case base name, lower case extension
			@ r0: 0x0018: SFN, lower case base name, lower case extension

			@ Save registers
			push		{r4, r5, lr}

			@ Setup for the base
			ldr			r1, =FAT_SFN_Buffer
			adds		r2, r1, #8
			movs		r4, #0

			@ Load character and advance the pointer
0:			ldrb		r3, [r0], #1

			@ Is it the end of the basename?
			cmp			r3, '.'
			beq			2f
			cbz			r3, 2f

			@ Is it lower case?
			cmp			r3, 'a'
			blo			1f
			cmp			r3, 'z'
			bhi			1f

			@ If case is unknown, set lowercase: 0 > 1
			@ If was uppercase, set mixed case: 2 > 3
			@ And convert to upper case
			orrs		r4, #0x01
			subs		r4, ('a'-'A')
			b			3f

			@ Is it upper case?
1:			cmp			r3, 'A'
			blo			3f
			cmp			r3, 'Z'
			bhi			3f

			@ If case is unknown, set uppercase: 0 > 2
			@ If was lowercase, set mixed case: 1 > 3
			tst			r4, #2
			it			eq
			addeq		r4, #2
			b			3f

			@ Fill with spaces
2:			movs		r3, ' '
			subs		r0, #1

			@ Store the character
3:			strb		r3, [r1], #1
			cmp			r1, r2
			bne			0b

			@ Increment until end or dot found, if more than once no SFN
4:			ldrb		r3, [r0], #1
			cmp			r3, '.'
			beq			5f
			cmp			r3, '\0'
			itt			ne
			movne		r4, #3
			bne			4b

			@ Make sure the terminating character will be read again
			subs		r0, #1

			@ Setup for the extension
5:			adds		r2, #3
			movs		r5, #0

			@ Load character and advance the pointer
6:			ldrb		r3, [r0], #1

			@ Is it the end of the extension?
			cbz			r3, 8f

			@ Is it lower case?
			cmp			r3, 'a'
			blo			7f
			cmp			r3, 'z'
			bhi			7f

			@ If case is unknown, set lowercase: 0 > 1
			@ If was uppercase, set mixed case: 2 > 3
			@ And convert to upper case
			orrs		r5, #0x01
			subs		r5, ('a'-'A')
			b			9f

			@ Is it upper case?
7:			cmp			r3, 'A'
			blo			9f
			cmp			r3, 'Z'
			bhi			9f

			@ If case is unknown, set uppercase: 0 > 2
			@ If was lowercase, set mixed case: 1 > 3
			tst			r5, #2
			it			eq
			addeq		r5, #2
			b			9f

			@ Fill with spaces
8:			movs		r3, ' '
			subs		r0, #1

			@ Store the character
9:			strb		r3, [r1], #1
			cmp			r1, r2
			bne			6b

			@ Not a SFN if not the end
			ldrb		r3, [r0]
			movs		r0, #0x0100
			cbnz		r3, 10f

			@ LFN required?
			cmp			r4, #3
			beq			10f
			cmp			r5, #3
			beq			10f

			@ A short file name can be used, code the case information
			ands		r4, #0x01
			orrs		r0, r3, r4, LSL #3
			ands		r5, #0x01
			orrs		r0, r0, r5, LSL #4

			@ Restore registers and return the analysis results
10:			pop			{r4, r5, pc}





			.section	.text.FAT_GetData
			.type		FAT_GetData, "function"
FAT_GetData:

			@ Arguments
			@ r0: address

			@ Immediately return if the address matches with the cached address
			ldr			r1, =FAT_CacheData
			ldr			r2, [r1, (FAT_CacheData_Address - FAT_CacheData)]
			cmp			r0, r2
			it			eq
			bxeq		lr

			@ Save registers
			push		{lr}

			@ Check if cached block must be written back
			ldrb		r3, [r1, (FAT_CacheData_Modified - FAT_CacheData)]
			cbz			r3, 0f

			@ Reset the modified flag
			movs		r3, #0
			strb		r3, [r1, (FAT_CacheData_Modified - FAT_CacheData)]

			@ Write back the cached block
			push		{r0, r1}
			cpy			r0, r2
			adds		r1, (_fat_cachedata_token_ - FAT_CacheData)
			bl			SDCARD_Write
			pop			{r0, r1}

			@ Read the new block and set the new address
0:			str			r0, [r1, (FAT_CacheData_Address - FAT_CacheData)]
			adds		r1, (FAT_CacheData_Buffer - FAT_CacheData)
			bl			SDCARD_Read

			@ Restore registers and return
			pop			{pc}





			.section	.text.FAT_TypeOfPartition
			.type		FAT_TypeOfPartition, "function"
FAT_TypeOfPartition:

			@ Arguments
			@ r0: partition number (0...3)

			@ Return values
			@ r0: partition type, 0 if invalid MBR or unused/unsupported type

			@ Save registers and arguments
			push		{r4, lr}
			cpy			r4, r0

			@ Read the MBR
			movs		r0, #0
			bl			FAT_GetData

			@ Check for the boot signature, return with error on mismatch
			movs		r0, #0
			ldr			r1, =FAT_CacheData_Buffer
			ldrh		r2, [r1, #510]
			movw		r3, #0xAA55
			cmp			r2, r3
			it			ne
			popne		{r4, pc}

			@ Read requested partition entry type field
			movs		r2, #450
			adds		r2, r2, r4, LSL #4
			ldrb		r2, [r1, r2]

			@ FAT16?
			cmp			r2, #0x06
			itt			eq
			moveq		r0, PARTITION_TYPE_FAT16
			popeq		{r4, pc}

			@ FAT32?
			cmp			r2, #0x0B
			it			eq
			moveq		r0, PARTITION_TYPE_FAT32

			@ Restore registers and return
			pop			{r4, pc}





			.section	.text.FAT_MountPartition
			.type		FAT_MountPartition, "function"
FAT_MountPartition:

			@ Arguments:
			@ r0: partition number (0...3)

			@ Return values:
			@ r0: 0 if error

			@ Save registers
			push		{r4, r5, r6, lr}
			ldr			r5, =FAT_Partition
			ldr			r6, =FAT_CacheData_Buffer

			@ Use the FAT_TypeOfPartition function to load the MBR and determine the partition type
			adds		r4, r6, r0, LSL #4
			bl			FAT_TypeOfPartition
			cmp			r0, #0
			beq			3f

			@ Store the data of interest
			strb		r0, [r5, (FAT_Partition_Type - FAT_Partition)]
			ldr			r0, [r6, #458]
			str			r0, [r5, (FAT_Partition_Size - FAT_Partition)]
			ldr			r0, [r6, #454]
			str			r0, [r5, (FAT_Partition_Address - FAT_Partition)]

			@ Read the boot sector of the partition
			cpy			r4, r0
			bl			FAT_GetData

			@ Check the bytes per logical sector field
			ldrh		r0, [r6, #11]
			cmp			r0, #512
			bne			3f

			@ Use count of reserved logical sectors to calculate the address of FAT1
			ldrh		r0, [r6, #14]
			adds		r4, r0
			str			r4, [r5, (FAT_Partition_AddressFAT1 - FAT_Partition)]

			@ Get the logical sectors per FAT (without checking if it's appropriate for the FAT type)
			ldrh		r0, [r6, #22]
			cmp			r0, #0
			it			eq
			ldreq		r0, [r6, #36]
			str			r0, [r5, (FAT_Partition_SectorsPerFAT - FAT_Partition)]

			@ Check the number of FATs (max 2 for now), and calculate the address of FAT2
			ldrb		r1, [r6, #16]
			cmp			r1, #1
			beq			0f
			cmp			r1, #2
			bne			3f
			adds		r4, r0
0:			str			r4, [r5, (FAT_Partition_AddressFAT2 - FAT_Partition)]

			@ Remember the maximum number of root directory entries
			ldrh		r1, [r6, #17]
			strh		r1, [r5, (FAT_Partition_RootMaxEntries - FAT_Partition)]

			@ Remember logical sectors per cluster
			ldrb		r2, [r6, #13]
			strb		r2, [r5, (FAT_Partition_SectorsPerCluster - FAT_Partition)]

			@ Determine the root directory cluster (set to 0 for FAT16, max root entries 0 for FAT32)
			movs		r3, #0
			cbnz		r1, 1f
			ldr			r3, [r6, #44]
			cbz			r3, 3f
1:			str			r3, [r5, (FAT_Partition_RootCluster - FAT_Partition)]

			@ Calculate the base address of the data region
			adds		r4, r0
			subs		r4, r4, r2, LSL #1
			cbz			r1, 2f
			movw		r3, #511
			adds		r3, r3, r1, LSL #5
			adds		r4, r4, r3, LSR #9
2:			str			r4, [r5, (FAT_Partition_AddressData - FAT_Partition)]

			@ Initialize the caches, all data invalid since the SD-card could have been removed
			ldr			r0, =FAT_CacheFAT
			ldr			r1, =FAT_CacheEntries
			ldr			r2, =FAT_CacheData

			@ Set all cache locations as empty
			movs		r3, #-1
			str			r3, [r0, (FAT_CacheFAT_Address - FAT_CacheFAT)]
			str			r3, [r1, (FAT_CacheEntry1_Address - FAT_CacheEntries)]
			str			r3, [r1, (FAT_CacheEntry2_Address - FAT_CacheEntries)]
			str			r3, [r2, (FAT_CacheData_Address - FAT_CacheData)]

			@ Set the write token
			movs		r3, SDCARD_WRITE_TOKEN
			strb		r3, [r0, (_fat_cachefat_token_ - FAT_CacheFAT)]
			strb		r3, [r1, (_fat_cacheentry1_token_ - FAT_CacheEntries)]
			strb		r3, [r1, (_fat_cacheentry2_token_ - FAT_CacheEntries)]
			strb		r3, [r2, (_fat_cachedata_token_ - FAT_CacheData)]

			@ Clear the modified flags
			movs		r3, #0
			strb		r3, [r0, (FAT_CacheFAT_Modified - FAT_CacheFAT)]
			strb		r3, [r1, (FAT_CacheEntry1_Modified - FAT_CacheEntries)]
			strb		r3, [r1, (FAT_CacheEntry2_Modified - FAT_CacheEntries)]
			strb		r3, [r2, (FAT_CacheData_Modified - FAT_CacheData)]

			@ Set the default policy
			strb		r3, [r1, (FAT_CacheEntries_Policy - FAT_CacheEntries)]

			@ Restore registers and return success
			movs		r0, #1
			pop			{r4, r5, r6, pc}

			@ Restore registers and return error
3:			movs		r0, #0
			pop			{r4, r5, r6, pc}





			.section	.text.FAT_UnmountPartition
			.type		FAT_UnmountPartition, "function"
FAT_UnmountPartition:

			@ Write back all non-empty, modified cache locations
			push		{lr}
			ldr			r0, =FAT_CacheFAT
			bl			_fat_unmount_partition_helper_
			ldr			r0, =FAT_CacheEntry1
			bl			_fat_unmount_partition_helper_
			ldr			r0, =FAT_CacheEntry2
			bl			_fat_unmount_partition_helper_
			ldr			r0, =FAT_CacheData
			bl			_fat_unmount_partition_helper_
			pop			{pc}

			@ Write back the cached block if required
_fat_unmount_partition_helper_:
			push		{lr}
			ldrb		r1, [r0, #4]
			cbz			r1, 0f
			movs		r1, #0
			strb		r1, [r0, #4]
			adds		r1, r0, #7
			ldr			r0, [r0, #0]
			bl			SDCARD_Write
0:			pop			{pc}





			.section	.text.FAT_FindSetup
			.type		FAT_FindSetup, "function"
FAT_FindSetup:

			@ Arguments:
			@ r0: starting cluster of the directory

			@ Set the global identification registers
			ldr			r1, =FAT_CacheEntries
			str			r0, [r1, (FAT_Cluster - FAT_CacheEntries)]
			movs		r0, #0
			strh		r0, [r1, (FAT_Sector - FAT_CacheEntries)]

			@ Reset the counter
			ldr			r1, =FAT_FindCounter
			str			r0, [r1]

			@ Return
			bx			lr





			.section	.text.FAT_FindNext
			.type		FAT_FindNext, "function"
FAT_FindNext:

			@ Arguments:
			@ r0: type (flags determine what's passed, 0: find empty entry)

			@ Return values:
			@ r0: 0 if error, 2 if end of last cluster reached, 3 if max entries analysed in root,
			@ 1 if success (entry remains valid/available, name in FAT_LFN_Buffer at FAT_LFN_Index if wanted (slower))

			@ Save registers and arguments
			push		{r4, r5, lr}
			cpy			r4, r0
			movs		r5, #0xFF

			@ Increment the counter
0:			ldr			r2, =FAT_CacheEntries
			ldr			r3, =FAT_FindCounter
			ldr			r1, [r3]
			adds		r1, #1
			str			r1, [r3]
			cmp			r1, #1
			bls			1f

			@ Advance to the next entry
			ldrb		r0, [r2, (FAT_Entry - FAT_CacheEntries)]
			adds		r0, #1
			ands		r0, #15
			strb		r0, [r2, (FAT_Entry - FAT_CacheEntries)]
			bne			1f

			@ Advance to the next sector
			ldr			r3, =FAT_Partition
			ldr			r3, [r3, (FAT_Partition_SectorsPerCluster - FAT_Partition)]
			subs		r3, #1
			ldrb		r0, [r2, (FAT_Sector - FAT_CacheEntries)]
			adds		r0, #1
			ands		r0, r3
			strb		r0, [r2, (FAT_Sector - FAT_CacheEntries)]
			bne			1f

			@ Advance to the next cluster
			ldr			r0, [r2, (FAT_Cluster - FAT_CacheEntries)]
			push		{r1, r2}
			bl			FAT_Next
			pop			{r1, r2}
			str			r0, [r2, (FAT_Cluster - FAT_CacheEntries)]
			cmp			r0, #0
			beq			11f
			cmp			r0, #-1
			itt			eq
			moveq		r0, #2
			popeq		{r4, r5, pc}

			@ Stop if FAT16 root directory and max entries analysed
1:			ldr			r0, [r2, (FAT_Cluster - FAT_CacheEntries)]
			cbnz		r0, 2f
			ldr			r3, =FAT_Partition
			ldrh		r3, [r3, (FAT_Partition_RootMaxEntries - FAT_Partition)]
			cmp			r1, r3
			itt			hi
			movhi		r0, #3
			pophi		{r4, r5, pc}

			@ Get the entry
2:			bl			FAT_GetEntry

			@ Empty/deleted entry?
			ldrb		r1, [r0, #0]
			cbz			r1, 10f
			cmp			r1, #0xE5
			beq			10f

			@ Is it part of a LFN?
			ldrb		r2, [r0, #11]
			cmp			r2, #0x0F
			bne			5f
			tst			r4, FAT_FIND_WITH_NAME
			beq			0b

			@ Last entry of the LFN?
			ands		r2, r1, #0x1F
			tst			r1, #(1 << 6)
			beq			3f

			@ Reset the index and store the sequence number
			subs		r5, r2, #1
			cmp			r5, #20
			bhs			11f
			ldr			r3, =FAT_LFN
			movs		r2, #260
			strh		r2, [r3, (FAT_LFN_Index - FAT_LFN)]
			b			4f

			@ Check sequence number
3:			cmp			r2, r5
			bne			11f
			subs		r5, #1

			@ Copy the characters to the FAT_LFN_Buffer
4:			bl			FAT_EntryGartherLFN
			b			0b

			@ New directory entry found: does it pass our search filter?
5:			tst			r4, FAT_FIND_VOLUME
			beq			6f
			cmp			r2, #0x08
			beq			8f
6:			tst			r4, FAT_FIND_DIRECTORY
			beq			7f
			ands		r3, r2, #0x78
			cmp			r3, #0x10
			beq			8f
7:			tst			r4, FAT_FIND_OTHER
			beq			0b
			ands		r3, r2, #0x58
			cmp			r3, #0x00
			bne			0b

			@ Entry passed the search filter
			@ Create the short name in the LFN buffer if no LFN and name required
8:			tst			r4, FAT_FIND_WITH_NAME
			beq			9f
			cbz			r5, 9f
			bl			FAT_EntryPrintSFN

			@ Return success
9:			movs		r0, #1
			pop			{r4, r5, pc}

			@ Empty/deleted entry
10:			cmp			r4, #0
			bne			0b

			@ Return success, since we were looking for an available entry
			movs		r0, #1
			pop			{r4, r5, pc}

			@ Return with error
11:			movs		r0, #0
			pop			{r4, r5, pc}




