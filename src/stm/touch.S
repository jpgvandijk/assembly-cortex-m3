/************************************************************************************
*
* Author: J.P.G. van Dijk
*
* N.B.: The touch controller (XPT2046) has the SS pin connected to pin B7, and
* the IRQ pin to pin B6.
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"touch.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Functions
			.global		TOUCH_Init
			.global		TOUCH_Read





@-----------------------------------------------------------@
@ TOUCH Functions											@
@-----------------------------------------------------------@

			.section	.text.TOUCH_Init
			.type		TOUCH_Init, "function"
TOUCH_Init:

			@ Save registers
			push		{lr}

			@ Initialize the SS pin
			movs		r0, GPIOB
			movs		r1, 7
			movs		r2, PIN_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure

			@ Deselect the chip
			ldr			r0, =GPIOB_BSRR
			movs		r1, (1 << 7)
			str			r1, [r0]

			@ Initialize the IRQ pin
			movs		r0, GPIOB
			movs		r1, 6
			movs		r2, PIN_INPUT_FLOATING
			bl			PIN_Configure

			@ Select port PB6 for IRQ external interrupt
			ldr			r0, =AFIO_EXTICR2
			movs		r2, GPIOB
			ldr			r1, [r0]
			bfi			r1, r2, #8, #4
			str			r1, [r0]

			@ EXTI Line 6 interrupt on falling edge
			ldr			r0, =STM_EXTI
			movs		r2, #(1 << 6)
			ldr			r1, [r0, (EXTI_IMR - STM_EXTI)]
			orrs		r1, r2
			str			r1, [r0, (EXTI_IMR - STM_EXTI)]
			ldr			r1, [r0, (EXTI_EMR - STM_EXTI)]
			bics		r1, r2
			str			r1, [r0, (EXTI_EMR - STM_EXTI)]
			ldr			r1, [r0, (EXTI_RTSR - STM_EXTI)]
			bics		r1, r2
			str			r1, [r0, (EXTI_RTSR - STM_EXTI)]
			ldr			r1, [r0, (EXTI_FTSR - STM_EXTI)]
			orrs		r1, r2
			str			r1, [r0, (EXTI_FTSR - STM_EXTI)]

			@ Set EXTI5...9 priority, interrupt not yet enabled
			movs		r0, EXTI9_5_IRQn
			movs		r1, TOUCH_IRQ_PRIORITY
			bl			NVIC_IRQSetPriority

			@ Restore registers and return
			pop			{pc}





			.section	.text.TOUCH_Read
			.type		TOUCH_Read, "function"
TOUCH_Read:

			@ Arguments:
			@ r0: result buffer
			@ r1: number of measurements (e.g.: 2 for only x and y)

			@ Save registers
			push		{r4, r5, r6, r7, lr}
			cpy			r4, r0
			cpy			r7, r1

			@ Get exclusive access to the SPI module
			movs		r0, #TOUCH_SPI_BAUDRATE
			bl			SPI1_GetExclusiveAccess

			@ Enable the SPI
			bl			SPI1_EnableDefault

			@ Select the chip
			ldr			r0, =GPIOB_BRR
			movs		r1, (1 << 7)
			str			r1, [r0]
			
			@ Transfer:
			@ 0xd3_____
			@ 0x00		7 LSBs	\__ 12 bit x
			@ 0x93_____ 5 MSBs	/
			@ 0x00		7 LSBs	\__ 12 bit y
			@ 0xb3_____ 5 MSBs	/
			@ 0x00		7 LSBs	\__ 12 bit z1
			@ 0xc3_____ 5 MSBs	/
			@ 0x00		7 LSBs	\__ 12 bit z2
			@ 0x80_____ 5 MSBs	/
			@ 0x00		-> PD: IRQ pin enabled
			ldr			r5, =_touch_read_data_
			add			r7, r4, r7, LSL #1
			ldrb		r0, [r5], #1
			bl			SPI1_Transfer
0:			movs		r0, #0
			bl			SPI1_Transfer
			and			r6, r0, #0x7F
			lsls		r6, #5
			ldrb		r0, [r5], #1
			bl			SPI1_Transfer
			and			r0, #0x1F
			orrs		r6, r0
			strh		r6, [r4], #2
			cmp			r4, r7
			blo			0b
			movs		r0, #0
			bl			SPI1_Transfer

			@ Deselect the chip
			ldr			r0, =GPIOB_BSRR
			movs		r1, (1 << 7)
			str			r1, [r0]
			
			@ Disable the SPI and return to normal mode
			bl			SPI1_DisableDefault

			@ Release exclusive access to the SPI module
			bl			SPI1_ClearExclusiveAccess

			@ Restore registers and return
			pop			{r4, r5, r6, r7, pc}

_touch_read_data_:

			@ Measurement commands
			.byte		0xd3
			.byte		0x93
			.byte		0xb3
			.byte		0xc3
			.byte		0x80




