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
			.global		KERNEL_GetExclusiveAccess
			.global		KERNEL_ClearExclusiveAccess





@-----------------------------------------------------------@
@ GET EXCLUSIVE ACCESS										@
@-----------------------------------------------------------@

			.section	.text.KERNEL_GetExclusiveAccess
			.type		KERNEL_GetExclusiveAccess, "function"
KERNEL_GetExclusiveAccess:

			@ Arguments:
			@ r0: address of lock byte

			@ Return values:
			@ r0: status: 0 if access granted, 1 otherwise

			@ Check if unused
			ldrexb		r1, [r0]
			cbnz		r1, 0f

			@ Try to lock by setting to idle
			movs		r1, #1
			strexb		r2, r1, [r0]
			cbnz		r2, 0f

			@ Access was granted, the module is now reserved
			movs		r0, #0
			bx			lr

0:			@ Already in use, or lock could not be set
			movs		r0, #1
			bx			lr





@-----------------------------------------------------------@
@ CLEAR EXCLUSIVE ACCESS									@
@-----------------------------------------------------------@

			.section	.text.KERNEL_ClearExclusiveAccess
			.type		KERNEL_ClearExclusiveAccess, "function"
KERNEL_ClearExclusiveAccess:

			@ Arguments:
			@ r0: address of lock byte

			@ Set state to unused and return
			movs		r1, #0
			strb		r1, [r0]
			bx			lr




