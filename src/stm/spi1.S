/************************************************************************************
*
* Author: J.P.G. van Dijk
*
* N.B.: If channel 2 is also used for other applications exclusive access must be
* granted. Also DMA1 must be enabled in advance:
* - movs	r0, PERIPHERAL_DMA1
* - bl		SystemEnablePeripheral
*
* SPI1 usage: always return to the following configuration:
* - CR1 = MSTR/SSI/SSM set, SPI module disabled
* - CR2 = 0
* - And slave deselected!
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"spi1.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Variables
			.global		SPI1_Data
			.global		SPI1_ExclusiveAccess
			.global		SPI1_ExclusiveAccessSPI
			.global		SPI1_ExclusiveAccessDMA

			@ Functions
			.global		SPI1_GetExclusiveAccess
			.global		SPI1_ClearExclusiveAccess
			.global		SPI1_Init
			.global		SPI1_Transfer





@-----------------------------------------------------------@
@ SPI1 Data													@
@-----------------------------------------------------------@

			.section	.bss.SPI1_Data
			.align		2
SPI1_Data:

			@ uint8_t SPI1_ExclusiveAccess[2]
			.type		SPI1_ExclusiveAccess, "object"
SPI1_ExclusiveAccess:
SPI1_ExclusiveAccessSPI:
			.space		1
SPI1_ExclusiveAccessDMA:
			.space		1





@-----------------------------------------------------------@
@ SPI1 Functions											@
@-----------------------------------------------------------@

			.section	.text.SPI1_GetExclusiveAccess
			.type		SPI1_GetExclusiveAccess, "function"
SPI1_GetExclusiveAccess:

			@ Arguments:
			@ r0: SPI clock prescaler

			@ Save registers
			push		{r4, lr}
			cpy			r4, r0

			@ Try to get exclusive access to the SPI
2:			ldr			r0, =SPI1_ExclusiveAccessSPI
			bl			KERNEL_GetExclusiveAccess
			cbnz		r0, 0f

			@ Try to get exclusive access to the DMA
			ldr			r0, =SPI1_ExclusiveAccessDMA
			bl			KERNEL_GetExclusiveAccess
			cbnz		r0, 1f

			@ Change the baudrate and return succes
			ldr			r0, =STM_SPI1
			ldr			r1, [r0, SPIx_CR1]
			bfi			r1, r4, #3, #3
			str			r1, [r0, SPIx_CR1]
			movs		r0, #0
			pop			{r4, pc}

1:			@ Access to the DMA was not granted, release access to the SPI
			ldr			r0, =SPI1_ExclusiveAccessSPI
			bl			KERNEL_ClearExclusiveAccess

0:			@ Access not granted to the SPI, try again after some time
			movs		r0, SVC_ForceContextSwitchDelay
			movs		r1, SPI1_EXCLUSIVE_ACCESS_DELAY
			svc			SVC_ForceContextSwitch
			b			2b





			.section	.text.SPI1_ClearExclusiveAccess
			.type		SPI1_ClearExclusiveAccess, "function"
SPI1_ClearExclusiveAccess:

			@ Save registers
			push		{lr}

			@ Release access to the SPI and DMA
			ldr			r0, =SPI1_ExclusiveAccessSPI
			bl			KERNEL_ClearExclusiveAccess
			ldr			r0, =SPI1_ExclusiveAccessDMA
			bl			KERNEL_ClearExclusiveAccess

			@ Restore registers and return
			pop			{pc}





			.section	.text.SPI1_Init
			.type		SPI1_Init, "function"
SPI1_Init:

			@ Save registers
			push		{lr}

			@ Enable the SPI peripheral
			movs		r0, PERIPHERAL_SPI1
			bl			SystemEnablePeripheral

			@ Configure the SPI pins
			movs		r0, GPIOA
			movs		r1, 5
			movs		r2, PIN_AF_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure
			movs		r0, GPIOA
			movs		r1, 6
			movs		r2, PIN_AF_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure
			movs		r0, GPIOA
			movs		r1, 7
			movs		r2, PIN_AF_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure

			@ Configure the SPI module, but not enabled yet
			ldr			r0, =STM_SPI1
			movs		r1, #0x030C
			str			r1, [r0, SPIx_CR1]
			ldr			r1, [r0, SPIx_I2SCFGR]
			bics		r1, 0x0800
			str			r1, [r0, SPIx_I2SCFGR]
			movs		r1, #0
			str			r1, [r0, SPIx_CR2]

			@ Restore registers and return
			pop			{pc}





			.section	.text.SPI1_Transfer
			.type		SPI1_Transfer, "function"
SPI1_Transfer:

			@ Arguments:
			@ r0: write data
			
			@ Return values:
			@ r0: data read
			
			@ Load SPI base address
			ldr			r1, =STM_SPI1
			
			@ Wait until we can transmit
0:			ldr			r2, [r1, SPIx_SR]
			tst			r2, #(1 << 1)
			beq			0b
			
			@ Write data
			str			r0, [r1, SPIx_DR]
			
			@ Wait for the data to be received
1:			ldr			r2, [r1, SPIx_SR]
			tst			r2, #(1 << 0)
			beq			1b
			
			@ Return the data
			ldr			r0, [r1, SPIx_DR]
			bx			lr




