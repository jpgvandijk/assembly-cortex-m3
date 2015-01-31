/************************************************************************************
*
* Author: J.P.G. van Dijk
*
* FIXME: disable interrupts/scheduler?
*
* The heap space consists of empty blocks, these contain:
* 	Empty link structure, contains:
* 		(uint32_t) address of next empty link structure or NULL if last link
* 		(uint16_t) size of the total empty block, including this structure
*		(uint16_t) reserved (keep structure multiple word sized!)
*	Empty block:
*		this is the one of interest for request size and return pointer
*		minimum of 4 bytes necessary, total must be a multiple of 4 bytes for word alignment!
* Important: everything should be word-aligned (also in the heap)!
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"cortex_m3.h"
			#include	"kernel.h"
			
			#ifdef		_USE_KERNEL_HEAP_





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Variables
			.global		KERNEL_Heap
			.global		KERNEL_HeapEmptyList

			@ Functions
			.global		KERNEL_InitHeap
			.global		KERNEL_Alloc
			.global		KERNEL_Free





@-----------------------------------------------------------@
@ uint8_t KERNEL_Heap[CONFIG_HeapSize]						@
@-----------------------------------------------------------@

			#ifdef		DEBUG
			.section	.bss.KERNEL_Heap
			#else
			.section	.noinit.KERNEL_Heap
			#endif
			.type		KERNEL_Heap, "object"
			.align		2
KERNEL_Heap:
			@ Reserve space for the heap
			.space		CONFIG_HeapSize





@-----------------------------------------------------------@
@ uint32_t KERNEL_HeapEmptyList								@
@-----------------------------------------------------------@

			#ifdef		DEBUG
			.section	.bss.KERNEL_HeapEmptyList
			#else
			.section	.noinit.KERNEL_HeapEmptyList
			#endif
			.type		KERNEL_HeapEmptyList, "object"
KERNEL_HeapEmptyList:
			@ The address of the first empty structure link
			.space		4





@-----------------------------------------------------------@
@ Kernel heap management functions							@
@-----------------------------------------------------------@

			.section	.text.HeapManagement
HeapManagement:





@-----------------------------------------------------------@
@ KERNEL_InitHeap											@
@-----------------------------------------------------------@
@															@
@ This function initializes the heap. It must be called 	@
@ before using the allocate and free functions.				@
@															@
@ > Arguments:			<none>								@
@ > Return values:		<none>								@
@ > Changed registers:	r0, r1								@
@ > Changed variables:	KERNEL_Heap, KERNEL_HeapEmptyList	@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			.type		KERNEL_InitHeap, "function"
KERNEL_InitHeap:

			@ Init to 1 huge empty block
			ldr			r0, =KERNEL_Heap
			movs		r1, NULL
			str			r1, [r0, KERNEL_HeapLinkStructFieldNext]
			movs		r1, CONFIG_HeapSize
			strh		r1, [r0, KERNEL_HeapLinkStructFieldSize]

			@ Init empty linked list pointer to this empty block
			ldr			r1, =KERNEL_HeapEmptyList
			str			r0, [r1]

			@ Return
			bx			lr





@-----------------------------------------------------------@
@ KERNEL_Alloc												@
@-----------------------------------------------------------@
@															@
@ This function allocates memory on the heap and returns a	@
@ pointer to this region. The requested memory will be 		@
@ automatically adjusted for word-alignment.				@
@															@
@ > Arguments:			r0: requested memory size (bytes)	@
@ > Return values:		r0: pointer to the allocated region	@
@						or NULL in case of an error			@
@ > Changed registers:	r0, r1, r2, r3						@
@ > Changed variables:	KERNEL_Heap, KERNEL_HeapEmptyList	@
@ > Stack usage:		1									@
@-----------------------------------------------------------@

			.type		KERNEL_Alloc, "function"
KERNEL_Alloc:

			@ r0 contains requested size, increment by link struct size and word-align
			adds		r0, (KERNEL_HeapLinkStructSize + 3)
			bic			r0, #0x03

			@ Find empty block with correct size
			ldr			r1, =KERNEL_HeapEmptyList
_kernel_alloc_search_list_:
			mov			r3, r1
			ldr			r1, [r3, KERNEL_HeapLinkStructFieldNext]
			cbz			r1, _kernel_alloc_not_found_

			@ Get size of this block, sufficient free space? No, advance to next block
			ldrh		r2, [r1, KERNEL_HeapLinkStructFieldSize]
			cmp			r2, r0
			blo			_kernel_alloc_search_list_

_kernel_alloc_found_:

			@ Block of sufficient size found
			@ r0: requested size (later address of new empty block)
			@ r1: address of empty block
			@ r2: size of empty block (later size of new empty block)
			@ r3: address of pointer that pointed to this block

			@ Determine whether we should split this block (only if some reasonable size left)
			subs		r2, r0
			cmp			r2, KERNEL_HeapMinFragmentSize
			ittt		lo	@ No, total block will be used, remove it from the empty list
			ldrlo		r0, [r1, KERNEL_HeapLinkStructFieldNext]
			strlo		r0, [r3, KERNEL_HeapLinkStructFieldNext]
			blo			_kernel_alloc_return_

_kernel_alloc_split_:

			@ Change size of allocated part
			@ Create structure in empty part
			@ Previous block must point to empty part instead of allocated part
			push		{r4}
			strh		r0, [r1, KERNEL_HeapLinkStructFieldSize]
			adds		r0, r1
			ldr			r4, [r1, KERNEL_HeapLinkStructFieldNext]
			str			r4, [r0, KERNEL_HeapLinkStructFieldNext]
			strh		r2, [r0, KERNEL_HeapLinkStructFieldSize]
			str			r0, [r3, KERNEL_HeapLinkStructFieldNext]
			pop			{r4}

_kernel_alloc_return_:

			@ Return address after structure
			add			r0, r1, KERNEL_HeapLinkStructSize
			bx			lr

_kernel_alloc_not_found_:

			@ No block with sufficient free space found, return NULL
			movs		r0, NULL
			bx			lr





@-----------------------------------------------------------@
@ KERNEL_Free												@
@-----------------------------------------------------------@
@															@
@ This function frees previously allocated memory. Adjacent	@
@ free blocks will be merged.								@
@															@
@ > Arguments:			r0: pointer to the allocated region	@
@ > Return values:		<none>								@
@ > Changed registers:	r0, r1, r2, r3						@
@ > Changed variables:	KERNEL_Heap, KERNEL_HeapEmptyList	@
@ > Stack usage:		1									@
@-----------------------------------------------------------@

			.type		KERNEL_Free, "function"
KERNEL_Free:

			@ r0 contains the pointer to the block to free
			subs		r0, KERNEL_HeapLinkStructSize

			@ Empty list remains address sorted during allocation
			@ We also want it to remain address sorted after deallocation
			@ We can use this fact to merge empty blocks on deallocation
			ldr			r2, =KERNEL_HeapEmptyList
_kernel_free_search_:
			mov			r1, r2
			ldr			r2, [r1, KERNEL_HeapLinkStructFieldNext]
			cbz			r2, _kernel_free_append_
			cmp			r2, r0
			blo			_kernel_free_search_

			@ Should be inserted in the list (or appended to the list)
			@ r2 is block after block to deallocate (or null)
			@ r1 is block that pointed to r2 and thus block before block to deallocate
			@ r0 is block to free
_kernel_free_insert_:
_kernel_free_check_after_:

			@ Only in this case a free block can follow the block to free
			@ In that case, remove the following block and increase the size of the block to free
			@ r0 and r1 may not change so we can fall-through in the append/check-before case
			ldrh		r3, [r0, KERNEL_HeapLinkStructFieldSize]
			add			r3, r0
			cmp			r3, r2
			bne			_kernel_free_check_before_

			@ Increase the size of the block to free with the size of the following block
			push		{r4}
			ldrh		r3, [r2, KERNEL_HeapLinkStructFieldSize]
			ldrh		r4, [r0, KERNEL_HeapLinkStructFieldSize]
			add			r4, r3
			strh		r4, [r0, KERNEL_HeapLinkStructFieldSize]
			pop			{r4}

			@ Remove the following block
			ldr			r3, [r2, KERNEL_HeapLinkStructFieldNext]
			str			r3, [r1, KERNEL_HeapLinkStructFieldNext]

_kernel_free_append_:
_kernel_free_check_before_:
			@ A free block can be before this one
			@ In that case, insert by increasing free block before
			@ Otherwise, actually insert it: [r0] = [r1], [r1] = r0
			ldrh		r3, [r1, KERNEL_HeapLinkStructFieldSize]
			add			r2, r3, r1
			cmp			r2, r0
			bne			_kernel_free_not_before_

			@ Simply insert by increasing the size of the free block before
			ldrh		r2, [r0, KERNEL_HeapLinkStructFieldSize]
			add			r3, r2
			strh		r3, [r1, KERNEL_HeapLinkStructFieldSize]

			@ Return
			bx			lr

_kernel_free_not_before_:

			@ Insert r0 after r1
			ldr			r2, [r1, KERNEL_HeapLinkStructFieldNext]
			str			r2, [r0, KERNEL_HeapLinkStructFieldNext]
			str			r0, [r1, KERNEL_HeapLinkStructFieldNext]

			@ Return
			bx			lr

HeapManagement_END:

			@ Calculate function group size
			.set		HeapManagement_SIZE, HeapManagement_END - HeapManagement





			#endif
