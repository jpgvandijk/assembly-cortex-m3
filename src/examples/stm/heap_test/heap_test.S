/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"kernel.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Variables
			.global		DEBUG_Heap
			.global		DEBUG_HeapPointers

			@ Functions
			.global		DEBUG_HeapUpdate
			.global		DEBUG_HeapTest
			.global		DEBUG_HeapTestMerge





@-----------------------------------------------------------@
@ TEST FUNCTIONS AND DATA									@
@-----------------------------------------------------------@

			@ Make a copy of the heap that visualizes the free blocks
			.section	.bss.KERNEL_Heap
			.type		DEBUG_Heap, "object"
			.align		2
DEBUG_Heap:
			.space		CONFIG_HeapSize





			@ This function updates the visualization in the heap copy
			@ Important: it can be placed anywhere as all registers are preserved (except LR!)
			.section	.text.DEBUG_HeapUpdate
			.type		DEBUG_HeapUpdate, "function"
DEBUG_HeapUpdate:

			@ Save registers
			push		{r0-r3, lr}

			@ Calculate buffer offset
			ldr			r0, =DEBUG_Heap
			ldr			r1, =KERNEL_Heap
			subs		r3, r0, r1

			@ Clear the 'heap' space
			add			r1, r0, CONFIG_HeapSize
			movs		r2, #0
0:			str			r2, [r0], 4
			cmp			r0, r1
			bne			0b

			@ Walk through the empty list, drawing the empty spaces
			ldr			r0, =KERNEL_HeapEmptyList
1:			ldr			r0, [r0, KERNEL_HeapLinkStructFieldNext]
			cbz			r0, 2f

			@ r0: kernel pointer, r1: equivalent debug pointer
			add			r1, r0, r3

			@ struct = +0x10
			ldr			r2, [r1, #0]
			add			r2, #0x10101010
			str			r2, [r1, #0]
			ldr			r2, [r1, #4]
			add			r2, #0x10101010
			str			r2, [r1, #4]

			@ empty = +0x01
			ldrh		r2, [r0, KERNEL_HeapLinkStructFieldSize]
			add			r3, r1, r2
3:			ldr			r2, [r1]
			add			r2, #0x01010101
			str			r2, [r1], 4
			cmp			r1, r3
			bne			3b
			b			1b

			@ Restore registers and return
2:			pop			{r0-r3, pc}





			@ Store pointers to allocated regions during the test
			.section	.bss.DEBUG_HeapPointers
			.type		DEBUG_HeapPointers, "object"
DEBUG_HeapPointers:
			.space		1024





			@ This function is for debugging and testing the heap alloc/free
			@ functions and does not return
			.section	.text.DEBUG_HeapTest
			.type		DEBUG_HeapTest, "function"
DEBUG_HeapTest:

			@ Initialize
			bl			KERNEL_InitHeap
			bl			DEBUG_HeapUpdate

			@ Try to allocate as much as possible
			movs		r4, 32768
0:			mov			r0, r4
			bl			KERNEL_Alloc
			bl			DEBUG_HeapUpdate
			cbnz		r0, 2f
			subs		r4, #1
			b			0b

2:			@ Free this block
			bl			KERNEL_Free								@ CHECK: r4 = 2040, copy = all allocated, first link = NULL
			bl			DEBUG_HeapUpdate

			@ Try to allocate as much bytes as possible
			ldr			r5, =DEBUG_HeapPointers					@ CHECK: copy = all free
			movs		r4, #0
1:			movs		r0, #1
			bl			KERNEL_Alloc
			bl			DEBUG_HeapUpdate
			cbz			r0, 3f									@ CHECK: copy = more gets allocated
			str			r0, [r5, r4, LSL #2]
			adds		r4, #1
			b			1b

3:			@ Free first
			ldr			r0, [r5, #0]							@ CHECK: r4 = 170, copy = all allocated, first link = NULL, last size = 20, others 12, remember HeapPointers[0,50,r4-1], pointers word-aligned
			bl			KERNEL_Free
			bl			DEBUG_HeapUpdate

			@ Free somewhere in the middle
			ldr			r0, [r5, #200]							@ CHECK: copy = first free
			bl			KERNEL_Free
			bl			DEBUG_HeapUpdate

			@ Free the last item
			subs		r4, #1
			ldr			r0, [r5, r4, LSL #2]					@ CHECK: copy = first free + somewhere in the middle
			bl			KERNEL_Free
			bl			DEBUG_HeapUpdate

			@ Reallocate previously freed regions
			movs		r0, #1									@ CHECK: copy = first free + somewhere in the middle + last
			bl			KERNEL_Alloc
			bl			DEBUG_HeapUpdate
			movs		r0, #1									@ CHECK: copy = somewhere in the middle + last free, r0 = remembered value[0]
			bl			KERNEL_Alloc
			bl			DEBUG_HeapUpdate
			movs		r0, #1									@ CHECK: copy = last free, r0 = remembered value[50]
			bl			KERNEL_Alloc
			bl			DEBUG_HeapUpdate
			b			.										@ CHECK: copy = all allocated, r0 = remembered value[r4-1]





			@ This short function tests the merging when freeing allocated memory
			.section	.text.DEBUG_HeapTestMerge
			.type		DEBUG_HeapTestMerge, "function"
DEBUG_HeapTestMerge:

			@ Initialize
			bl			KERNEL_InitHeap

			@ Merge after: allocated - free > free
			movs		r0, #20
			bl			KERNEL_Alloc

			bl			KERNEL_Free

			@ Merge before: free - allocated > free
			movs		r0, #1016
			bl			KERNEL_Alloc
			cpy			r4, r0
			movs		r0, #1016
			bl			KERNEL_Alloc
			cpy			r5, r0
			cpy			r0, r4
			bl			KERNEL_Free

			cpy			r0, r5
			bl			KERNEL_Free

			@ Merge before + after: free - allocated - free > free
			movs		r0, #20
			bl			KERNEL_Alloc
			cpy			r4, r0
			movs		r0, #20
			bl			KERNEL_Alloc
			cpy			r5, r0
			cpy			r0, r4
			bl			KERNEL_Free

			cpy			r0, r5
			bl			KERNEL_Free

			b			.




