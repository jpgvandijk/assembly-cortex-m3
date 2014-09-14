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

			@ Functions
			.global		KERNEL_QueueInit
			.global		KERNEL_QueueSend
			.global		KERNEL_QueueReceive





@-----------------------------------------------------------@
@ FUNCTIONS													@
@-----------------------------------------------------------@

			.section	.text.KERNEL_QueueInit
			.type		KERNEL_QueueInit, "function"
KERNEL_QueueInit:

			@ Arguments:
			@ r0: queue structure
			@ r1: lock delay, in case exclusive access is not granted
			@ r2: buffer size, number of elements -1 encoded
			@ r3: element size, only byte (0), halfword (1), word (2) allowed

			@ Set the element and buffer size
			strb		r2, [r0, KERNEL_QueueStructureFieldBufferSize]
			strb		r3, [r0, KERNEL_QueueStructureFieldElementSize]

			@ Reset the lock and indices
			movs		r2, #0
			str			r2, [r0]

			@ Set the lock delay
			strb		r1, [r0, KERNEL_QueueStructureFieldLockDelay]

			@ Return
			bx			lr





			.section	.text.KERNEL_QueueSend
			.type		KERNEL_QueueSend, "function"
KERNEL_QueueSend:

			@ Arguments:
			@ r0: queue structure
			@ r1: element data

			@ Save registers and arguments
			push		{r4, r5, lr}
			cpy			r4, r0
			cpy			r5, r1

			@ Lock the queue
0:			cpy			r0, r4
			bl			KERNEL_GetExclusiveAccess
			cbz			r0, 1f
			movs		r0, SVC_ForceContextSwitchDelay
			ldrb		r1, [r4, KERNEL_QueueStructureFieldLockDelay]
			svc			SVC_ForceContextSwitch
			b			0b

			@ Check if the queue is full
1:			ldrb		r0, [r4, KERNEL_QueueStructureFieldRxIndex]
			ldrb		r1, [r4, KERNEL_QueueStructureFieldTxIndex]
			ldrb		r2, [r4, KERNEL_QueueStructureFieldBufferSize]
			cmp			r0, #0
			ite			eq
			moveq		r0, r2
			subne		r0, #1
			cmp			r0, r1
			bne			2f

			@ The queue is full, release access and try again after some time
			cpy			r0, r4
			bl			KERNEL_ClearExclusiveAccess
			movs		r0, SVC_ForceContextSwitchDelay
			ldrb		r1, [r4, KERNEL_QueueStructureFieldLockDelay]
			svc			SVC_ForceContextSwitch
			b			0b

			@ Add the element
2:			ldrb		r0, [r4, KERNEL_QueueStructureFieldElementSize]
			ldr			r3, [r4, KERNEL_QueueStructureFieldBuffer]
			cmp			r0, #0
			it			eq
			strbeq		r5, [r3, r1, LSL #0]
			beq			3f
			cmp			r0, #1
			ite			eq
			strheq		r5, [r3, r1, LSL #1]
			strne		r5, [r3, r1, LSL #2]

			@ Increment the index
3:			cmp			r1, r2
			ite			eq
			moveq		r1, #0
			addne		r1, #1
			strb		r1, [r4, KERNEL_QueueStructureFieldTxIndex]

			@ Unlock the queue and return
			cpy			r0, r4
			bl			KERNEL_ClearExclusiveAccess
			pop			{r4, r5, pc}





			.section	.text.KERNEL_QueueReceive
			.type		KERNEL_QueueReceive, "function"
KERNEL_QueueReceive:

			@ Arguments:
			@ r0: queue structure
			@ r1: wait for data

			@ Return values:
			@ r0: element data
			@ r1: no new data (only valid if not waiting for data)

			@ Save registers and arguments
			push		{r4, r5, lr}
			cpy			r4, r0
			cpy			r5, r1

			@ Lock the queue
0:			cpy			r0, r4
			bl			KERNEL_GetExclusiveAccess
			cbz			r0, 1f
			movs		r0, SVC_ForceContextSwitchDelay
			ldrb		r1, [r4, KERNEL_QueueStructureFieldLockDelay]
			svc			SVC_ForceContextSwitch
			b			0b

			@ Check if the queue is empty
1:			ldrb		r2, [r4, KERNEL_QueueStructureFieldRxIndex]
			ldrb		r1, [r4, KERNEL_QueueStructureFieldTxIndex]
			eors		r1, r2
			bne			2f

			@ The queue is empty, release access and try again after some time or return with status
			cbz			r5, 4f
			cpy			r0, r4
			bl			KERNEL_ClearExclusiveAccess
			movs		r0, SVC_ForceContextSwitchDelay
			ldrb		r1, [r4, KERNEL_QueueStructureFieldLockDelay]
			svc			SVC_ForceContextSwitch
			b			0b

			@ Get the element
2:			ldrb		r0, [r4, KERNEL_QueueStructureFieldElementSize]
			ldr			r3, [r4, KERNEL_QueueStructureFieldBuffer]
			cmp			r0, #0
			it			eq
			ldrbeq		r5, [r3, r2, LSL #0]
			beq			3f
			cmp			r0, #1
			ite			eq
			ldrheq		r5, [r3, r2, LSL #1]
			ldrne		r5, [r3, r2, LSL #2]

			@ Increment the index
3:			ldrb		r3, [r4, KERNEL_QueueStructureFieldBufferSize]
			cmp			r2, r3
			ite			eq
			moveq		r2, #0
			addne		r2, #1
			strb		r2, [r4, KERNEL_QueueStructureFieldRxIndex]

			@ Unlock the queue and return with the message and status
4:			cpy			r0, r4
			cpy			r4, r1
			bl			KERNEL_ClearExclusiveAccess
			cpy			r1, r4
			cpy			r0, r5
			pop			{r4, r5, pc}




