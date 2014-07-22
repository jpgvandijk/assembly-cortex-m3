/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"pin.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Functions
			.global		PIN_Configure





@-----------------------------------------------------------@
@ PIN CONFIGURATION FUNCTIONS								@
@-----------------------------------------------------------@

			@ r0: port
			@ r1: pin
			@ r2: function settings
			.section	.text.PIN_Configure
			.type		PIN_Configure, "function"

PIN_Configure:

			@ Save registers
			push		{r4, lr}

			@ number = pin + 2048 * port
			add			r0, r1, r0, LSL #11

			@ Convert number to bit position and register offset
			bl			NumberTo4BitsInWord

			@ Determine register address, mask and value
			ldr			r3, =GPIOA_CRL
			movs		r4, #0x0F
			lsls		r4, r0
			lsls		r2, r0

			@ Change value with a read-modify-write
			ldr			r0, [r3, r1]
			bics		r0, r4
			orrs		r0, r2
			str			r0, [r3, r1]

			@ Restore registers and return
			pop			{r4, pc}
			@bx			lr




