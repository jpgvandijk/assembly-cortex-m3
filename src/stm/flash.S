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
			bl			SPI1_EnableDefault

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
			bl			SPI1_DisableDefault

			@ Restore registers and return with the data byte in r0
			pop			{r4, pc}





			.section	.text.FLASH_ReadBytes
			.type		FLASH_ReadBytes, "function"
FLASH_ReadBytes:

			@ Arguments:
			@ r0: read address
			@ r1: write address
			@ r2: count

			@ Save registers and arguments
			push		{r4, r5, r6, lr}
			push		{r0, r1, r2}
			pop			{r4, r5, r6}

			@ Enable the SPI
			bl			SPI1_EnableDefault

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
			bl			SPI1_DisableDefault

			@ Setup the DMA
			cpy			r0, r5
			cpy			r1, r6
			bl			SPI1_EnableRXOnlyWithDMA

			@ Wait for the DMA transfers to complete
			bl			SPI1_WaitRXOnlyWithDMA

			@ Deselect the chip
			ldr			r2, =GPIOA_BSRR
			movs		r1, (1 << 4)
			str			r1, [r2]

			@ Disable the SPI and return to normal mode
			bl			SPI1_DisableRXOnlyWithDMA

			@ Restore registers and return
			pop			{r4, r5, r6, pc}




