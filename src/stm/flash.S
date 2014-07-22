/************************************************************************************
*
* Author: J.P.G. van Dijk
*
* For the FLASH memory it was already advantageous to use the DMA when reading
* only 2 bytes!
*
* N.B.: The SPI flash (M25P16) has the SS pin connected to pin A4.
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"flash.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Functions
			.global		FLASH_Init
			.global		FLASH_ReadByte
			.global		FLASH_ReadBytes





@-----------------------------------------------------------@
@ FLASH Functions											@
@-----------------------------------------------------------@

			.section	.text.FLASH_Init
			.type		FLASH_Init, "function"
FLASH_Init:

			@ Save registers
			push		{lr}

			@ Initialize the SS pin
			movs		r0, GPIOA
			movs		r1, 4
			movs		r2, PIN_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure

			@ Deselect the chip
			ldr			r0, =GPIOA_BSRR
			movs		r1, (1 << 4)
			str			r1, [r0]

			@ Restore registers and return
			pop			{pc}





			.section	.text.FLASH_ReadByte
			.type		FLASH_ReadByte, "function"
FLASH_ReadByte:

			@ Arguments:
			@ r0: read address

			@ Return values:
			@ r0: byte read

			@ Save registers
			push		{r4, lr}

			@ Save argument
			cpy			r4, r0

			@ Enable the SPI
			ldr			r0, =STM_SPI1
			ldr			r1, [r0, SPIx_CR1]
			orrs		r1, 0x0040
			str			r1, [r0, SPIx_CR1]

			@ Select the chip
			ldr			r0, =GPIOA_BRR
			movs		r1, (1 << 4)
			str			r1, [r0]

			@ Write instruction for fast read
			movs		r0, #0x0B
			bl			SPI1_Transfer

			@ Write the read address (MSB first)
			lsrs		r0, r4, #16
			bl			SPI1_Transfer
			lsrs		r0, r4, #8
			bl			SPI1_Transfer
			cpy			r0, r4
			bl			SPI1_Transfer

			@ Write a dummy byte and read the data byte
			bl			SPI1_Transfer
			bl			SPI1_Transfer

			@ Deselect the chip
			ldr			r2, =GPIOA_BSRR
			movs		r1, (1 << 4)
			str			r1, [r2]

			@ Disable the SPI and return to normal mode
			ldr			r2, =STM_SPI1
			ldr			r1, [r2, SPIx_CR1]
			bics		r1, (0x0040 | (1 << 10))
			str			r1, [r2, SPIx_CR1]

			@ Restore registers and return with the data byte in r0
			pop			{r4, pc}





			.section	.text.FLASH_ReadBytes
			.type		FLASH_ReadBytes, "function"
FLASH_ReadBytes:

			@ Arguments:
			@ r0: read address
			@ r1: write address
			@ r2: count

			@ Save registers
			push		{r4, r5, r6, lr}

			@ Save arguments
			push		{r0, r1, r2}
			pop			{r4, r5, r6}

			@ Enable the SPI
			ldr			r0, =STM_SPI1
			ldr			r1, [r0, SPIx_CR1]
			orrs		r1, 0x0040
			str			r1, [r0, SPIx_CR1]

			@ Select the chip
			ldr			r0, =GPIOA_BRR
			movs		r1, (1 << 4)
			str			r1, [r0]

			@ Write instruction for fast read
			movs		r0, #0x0B
			bl			SPI1_Transfer

			@ Write the read address (MSB first)
			lsrs		r0, r4, #16
			bl			SPI1_Transfer
			lsrs		r0, r4, #8
			bl			SPI1_Transfer
			cpy			r0, r4
			bl			SPI1_Transfer

			@ Write a dummy byte
			bl			SPI1_Transfer

			@ Disable the SPI to setup the DMA
			ldr			r0, =STM_SPI1
1:			ldr			r1, [r0, SPIx_SR]
			tst			r1, #(1 << 7)
			bne			1b
			ldr			r1, [r0, SPIx_DR]
			ldr			r1, [r0, SPIx_SR]
			ldr			r1, [r0, SPIx_CR1]
			bics		r1, 0x0040
			str			r1, [r0, SPIx_CR1]

			@ Setup the DMA
			ldr			r1, =STM_DMA1
			adds		r2, r0, SPIx_DR
			str			r2, [r1, DMAx_CPAR2]
			str			r5, [r1, DMAx_CMAR2]
			str			r6, [r1, DMAx_CNDTR2]
			movs		r2, #0x2080
			str			r2, [r1, DMAx_CCR2]

			@ Clear the flags and enable the DMA channel, high priority
			movs		r3, #0x10
			str			r3, [r1, DMAx_IFCR]
			orrs		r2, #0x0001
			str			r2, [r1, DMAx_CCR2]

			@ Enable the SPI in RX only mode with DMA on the RX channel
			ldr			r2, [r0, SPIx_CR1]
			orrs		r2, #(1 << 10)
			str			r2, [r0, SPIx_CR1]
			movs		r3, #0x01
			str			r3, [r0, SPIx_CR2]
			orrs		r2, #(1 << 6)
			str			r2, [r0, SPIx_CR1]

			@ Wait for the DMA transfers to complete
2:			ldr			r2, [r1, DMAx_ISR]
			tst			r2, #(1 << 5)
			beq			2b

			@ Disable the DMA
			movs		r2, #0
			str			r2, [r1, DMAx_CCR2]

			@ Deselect the chip
			ldr			r2, =GPIOA_BSRR
			movs		r1, (1 << 4)
			str			r1, [r2]

			@ Disable the SPI and return to normal mode
			ldr			r1, [r0, SPIx_CR1]
			bics		r1, (0x0040 | (1 << 10))
			str			r1, [r0, SPIx_CR1]

			@ Restore registers and return
			pop			{r4, r5, r6, pc}




