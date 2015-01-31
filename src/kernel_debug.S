/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"cortex_m3.h"
			#include	"kernel.h"
			#include	"print.h"
			
			#ifdef		_USE_KERNEL_





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Functions
			.global		KERNEL_DEBUG_Init
			.global		KERNEL_DEBUG_TaskSwitch





@-----------------------------------------------------------@
@ FUNCTIONS													@
@-----------------------------------------------------------@

			.section	.text.KERNEL_DEBUG_Init
			.type		KERNEL_DEBUG_Init, "function"
KERNEL_DEBUG_Init:

			@ Enable tracing with all count registers active
			ldr			r0, =DEMCR
			ldr			r1, [r0]
			tst			r1, #(1 << 24)
			bne			0f
			orrs		r1, #(1 << 24)
			str			r1, [r0]
			ldr			r0, =DWT_CTRL
			movs		r1, #0
			str			r1, [r0, (DWT_CYCCNT - DWT_CTRL)]
			str			r1, [r0, (DWT_CPICNT - DWT_CTRL)]
			str			r1, [r0, (DWT_EXCCNT - DWT_CTRL)]
			str			r1, [r0, (DWT_SLEEPCNT - DWT_CTRL)]
			str			r1, [r0, (DWT_LSUCNT - DWT_CTRL)]
			str			r1, [r0, (DWT_FOLDCNT - DWT_CTRL)]
			ldr			r1, [r0]
			orrs		r1,	0x003E0000
			orrs		r1,	0x00000001
			str			r1, [r0]

			@ Return
0:			bx			lr





			.section	.text.KERNEL_DEBUG_TaskSwitch
			.type		KERNEL_DEBUG_TaskSwitch, "function"
KERNEL_DEBUG_TaskSwitch:

			@ Arguments
			@ r2: task

			@ For now simply print the task name over the ETM
			push		{lr}
			ldr			r0, =ITM_SendPort0
			movs		r1, PRINT_CHARACTERS(5)
			ldr			r2, [r2, KERNEL_TaskTableEntryFieldDescriptor]
			adds		r2, KERNEL_TaskDescriptorFieldDescription
			bl			Print
			movs		r0, '\n'
			bl			ITM_SendPort0
			pop			{pc}





			#endif
