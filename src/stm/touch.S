/************************************************************************************
*
* Author: J.P.G. van Dijk
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
			movs		r0, TOUCH_SS_GPIO
			movs		r1, TOUCH_SS_PIN
			movs		r2, PIN_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure

			@ Deselect the chip
			ldr			r0, =TOUCH_SS_BSRR
			movs		r1, (1 << TOUCH_SS_PIN)
			str			r1, [r0]

			@ Initialize the IRQ pin
			movs		r0, TOUCH_IRQ_GPIO
			movs		r1, TOUCH_IRQ_PIN
			movs		r2, PIN_INPUT_FLOATING
			bl			PIN_Configure

			@ Select port for IRQ external interrupt
			ldr			r0, =TOUCH_IRQ_EXTICR
			movs		r2, TOUCH_IRQ_GPIO
			ldr			r1, [r0]
			bfi			r1, r2, #TOUCH_IRQ_EXTICR_LSB, #4
			str			r1, [r0]

			@ EXTI Line interrupt on falling edge
			ldr			r0, =STM_EXTI
			movs		r2, #(1 << TOUCH_IRQ_PIN)
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

			@ Set EXTI priority, interrupt not yet enabled
			movs		r0, TOUCH_IRQ_NUMBER
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
			bl			TOUCH_SPI_GET_EXCLUSIVE_ACCESS

			@ Enable the SPI
			bl			TOUCH_SPI_ENABLE_DEFAULT

			@ Select the chip
			ldr			r0, =TOUCH_SS_BRR
			movs		r1, (1 << TOUCH_SS_PIN)
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
			bl			TOUCH_SPI_TRANSFER
0:			movs		r0, #0
			bl			TOUCH_SPI_TRANSFER
			and			r6, r0, #0x7F
			lsls		r6, #5
			ldrb		r0, [r5], #1
			bl			TOUCH_SPI_TRANSFER
			and			r0, #0x1F
			orrs		r6, r0
			strh		r6, [r4], #2
			cmp			r4, r7
			blo			0b
			movs		r0, #0
			bl			TOUCH_SPI_TRANSFER

			@ Deselect the chip
			ldr			r0, =TOUCH_SS_BSRR
			movs		r1, (1 << TOUCH_SS_PIN)
			str			r1, [r0]
			
			@ Disable the SPI and return to normal mode
			bl			TOUCH_SPI_DISABLE_DEFAULT

			@ Release exclusive access to the SPI module
			bl			TOUCH_SPI_CLEAR_EXCLUSIVE_ACCESS

			@ Restore registers and return
			pop			{r4, r5, r6, r7, pc}

_touch_read_data_:

			@ Measurement commands
			.byte		0xd3
			.byte		0x93
			.byte		0xb3
			.byte		0xc3
			.byte		0x80




