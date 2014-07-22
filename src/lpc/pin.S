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
			.global		PIN_SetFunction
			.global		PIN_SetInputMode
			.global		PIN_SetOutputMode
			.global		PIN_SetI2C0PinConfiguration





@-----------------------------------------------------------@
@ PIN CONFIGURATION FUNCTIONS								@
@-----------------------------------------------------------@

			.section	.text.PinConfig

			@ Input mode is also used in open-drain output mode!

			@ r0: port
			@ r1: pin
			@ r2: function / pull-resistors setting
			.type		PIN_SetFunction, "function"
			.type		PIN_SetInputMode, "function"

PIN_SetInputMode:

			@ Add 8 to get 0x40 bytes higher address offset and fall-through
			adds		r0, #8

PIN_SetFunction:

			@ Save registers
			push		{r4, lr}

			@ number = pin + 32 * port
			add			r0, r1, r0, LSL #5

			@ Convert number to bit position and register offset
			bl			NumberTo2BitsInWord

			@ Determine register address, mask and value
			ldr			r3, =LPC_PIN
			movs		r4, #0x03
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





			@ r0: port
			@ r1: pin
			@ r2: normal/open-drain
			.type		PIN_SetOutputMode, "function"

PIN_SetOutputMode:

			@ Set/clear PINMODE_OD bit using bit-band alias
			add			r0, r1, r0, LSL #5
			ldr			r1, =(0x42000000 + 32 * (PINMODE_OD0 - 0x40000000))
			str			r2, [r1, r0, LSL #2]
			bx			lr





			@ r0: configuration
			.type		PIN_SetI2C0PinConfiguration, "function"

PIN_SetI2C0PinConfiguration:
			ldr			r1, =LPC_PIN
			str			r0, [r1, (I2CPADCFG - LPC_PIN)]
			bx			lr




