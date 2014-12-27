/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"uart1.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Functions
			.global		UART1_Init
			.global		UART1_Tx





@-----------------------------------------------------------@
@ FUNCTIONS													@
@-----------------------------------------------------------@

			.section	.text.UART1_Init
			.type		UART1_Init, "function"
UART1_Init:

			@ Quick implementation for messaging over UART with 115200 baud

			@ Save registers
			push		{lr}

			@ Init module and pins
			movs		r0, PERIPHERAL_USART1
			bl			SystemEnablePeripheral
			movs		r0, GPIOA
			movs		r1, #9
			movs		r2, PIN_AF_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure
			movs		r0, GPIOA
			movs		r1, #10
			movs		r2, PIN_INPUT_FLOATING
			bl			PIN_Configure

			@ Init UART1 with a baudrate of 115200
			ldr			r0, =STM_USART1
			ldr			r1, [r0, USARTx_CR2]
			bics		r1, #0x3000
			str			r1, [r0, USARTx_CR2]
			ldr			r2, [r0, USARTx_CR1]
			bics		r2, #0x1600
			orrs		r2, #0x000C
			str			r2, [r0, USARTx_CR1]
			ldr			r1, [r0, USARTx_CR3]
			bics		r1, #0x0300
			str			r1, [r0, USARTx_CR3]
			movw		r1, #(39 << 4 | 1)
			str			r1, [r0, USARTx_BRR]
			orrs		r2, #0x2000
			str			r2, [r0, USARTx_CR1]

			@ Return
			pop			{pc}





			.section	.text.UART1_Tx
			.type		UART1_Tx, "function"
UART1_Tx:
			@ Arguments
			@ r0: character

			@ Wait for the previous transfer to complete
			ldr			r1, =STM_USART1
0:			ldr			r2, [r1, USARTx_SR]
			tst			r2, #0x0080
			beq			0b

			@ Write the character and return
			str			r0, [r1, USARTx_DR]
			bx			lr




