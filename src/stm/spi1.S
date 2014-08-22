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
			.global		SPI1_EnableDefault
			.global		SPI1_DisableDefault
			.global		SPI1_EnableRXOnlyWithDMA
			.global		SPI1_WaitRXOnlyWithDMA
			.global		SPI1_DisableRXOnlyWithDMA
			.global		SPI1_EnableTXOnlyWithDMA
			.global		SPI1_WaitTXOnlyWithDMA
			.global		SPI1_DisableTXOnlyWithDMA





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





			.section	.text.SPI1_EnableDefault
			.type		SPI1_EnableDefault, "function"
SPI1_EnableDefault:

			@ Enable the SPI in default mode
			ldr			r0, =STM_SPI1
			ldr			r1, [r0, SPIx_CR1]
			orrs		r1, 0x0040
			str			r1, [r0, SPIx_CR1]

			@ Return
			bx			lr





			.section	.text.SPI1_DisableDefault
			.type		SPI1_DisableDefault, "function"
SPI1_DisableDefault:

			@ Disable the SPI from default mode and return to normal mode
			ldr			r0, =STM_SPI1
0:			ldr			r1, [r0, SPIx_SR]
			tst			r1, #(1 << 7)
			bne			0b
			ldr			r1, [r0, SPIx_DR]
			ldr			r1, [r0, SPIx_SR]
			ldr			r1, [r0, SPIx_CR1]
			bics		r1, (0x0040 | (1 << 10))
			str			r1, [r0, SPIx_CR1]

			@ Return
			bx			lr





			.section	.text.SPI1_EnableRXOnlyWithDMA
			.type		SPI1_EnableRXOnlyWithDMA, "function"
SPI1_EnableRXOnlyWithDMA:

			@ Arguments:
			@ r0: destination address
			@ r1: count

			@ Setup the DMA
			ldr			r2, =STM_DMA1
			ldr			r3, =(STM_SPI1 + SPIx_DR)
			str			r3, [r2, DMAx_CPAR2]
			str			r0, [r2, DMAx_CMAR2]
			str			r1, [r2, DMAx_CNDTR2]
			movs		r0, #0x2080
			str			r0, [r2, DMAx_CCR2]

			@ Clear the flags and enable the DMA channel, high priority
			movs		r1, #0x10
			str			r1, [r2, DMAx_IFCR]
			orrs		r0, #0x0001
			str			r0, [r2, DMAx_CCR2]

			@ Enable the SPI in RX only mode with DMA on the RX channel
			subs		r3, SPIx_DR
			ldr			r2, [r3, SPIx_CR1]
			orrs		r2, #(1 << 10)
			str			r2, [r3, SPIx_CR1]
			movs		r1, #0x01
			str			r1, [r3, SPIx_CR2]
			orrs		r2, #(1 << 6)
			str			r2, [r3, SPIx_CR1]

			@ Return
			bx			lr





			.section	.text.SPI1_WaitRXOnlyWithDMA
			.type		SPI1_WaitRXOnlyWithDMA, "function"
SPI1_WaitRXOnlyWithDMA:

			@ Wait for the DMA transfers to complete
			ldr			r1, =STM_DMA1
0:			ldr			r0, [r1, DMAx_ISR]
			tst			r0, #(1 << 5)
			beq			0b

			@ Return
			bx			lr





			.section	.text.SPI1_DisableRXOnlyWithDMA
			.type		SPI1_DisableRXOnlyWithDMA, "function"
SPI1_DisableRXOnlyWithDMA:

			@ Disable the DMA
			ldr			r1, =STM_DMA1
			movs		r0, #0
			str			r0, [r1, DMAx_CCR2]

			@ Disable the SPI and return to normal mode
			ldr			r1, =STM_SPI1
			ldr			r0, [r1, SPIx_CR1]
			bics		r0, (0x0040 | (1 << 10))
			str			r0, [r1, SPIx_CR1]
0:			ldr			r0, [r1, SPIx_SR]
			tst			r0, #(1 << 0)
			beq			0b
			ldr			r0, [r1, SPIx_DR]

			@ Return
			bx			lr





			.section	.text.SPI1_EnableTXOnlyWithDMA
			.type		SPI1_EnableTXOnlyWithDMA, "function"
SPI1_EnableTXOnlyWithDMA:

			@ Arguments:
			@ r0: source address
			@ r1: count

			@ Setup the DMA
			ldr			r2, =STM_DMA1
			ldr			r3, =(STM_SPI1 + SPIx_DR)
			str			r3, [r2, DMAx_CPAR3]
			str			r0, [r2, DMAx_CMAR3]
			str			r1, [r2, DMAx_CNDTR3]
			movw		r0, #0x2090
			str			r0, [r2, DMAx_CCR3]

			@ Enable the SPI with DMA on the TX channel
			subs		r3, SPIx_DR
			movs		r1, #0x02
			str			r1, [r3, SPIx_CR2]
			ldr			r1, [r3, SPIx_CR1]
			orrs		r1, #(1 << 6)
			str			r1, [r3, SPIx_CR1]

			@ Clear the flags and enable the DMA channel, high priority
			movs		r1, #0x100
			str			r1, [r2, DMAx_IFCR]
			orrs		r0, #0x0001
			str			r0, [r2, DMAx_CCR3]

			@ Return
			bx			lr





			.section	.text.SPI1_WaitTXOnlyWithDMA
			.type		SPI1_WaitTXOnlyWithDMA, "function"
SPI1_WaitTXOnlyWithDMA:

			@ Wait for the DMA transfers to complete
			ldr			r1, =STM_DMA1
0:			ldr			r0, [r1, DMAx_ISR]
			tst			r0, #(1 << 9)
			beq			0b

			@ Return
			bx			lr





			.section	.text.SPI1_DisableTXOnlyWithDMA
			.type		SPI1_DisableTXOnlyWithDMA, "function"
SPI1_DisableTXOnlyWithDMA:

			@ Disable the DMA
			ldr			r1, =STM_DMA1
			movs		r0, #0
			str			r0, [r1, DMAx_CCR3]

			@ Disable the SPI and return to normal mode
			ldr			r0, =STM_SPI1
0:			ldr			r1, [r0, SPIx_SR]
			tst			r1, #(1 << 7)
			bne			0b
			ldr			r1, [r0, SPIx_DR]
			ldr			r1, [r0, SPIx_SR]
			ldr			r1, [r0, SPIx_CR1]
			bics		r1, (0x0040 | (1 << 10))
			str			r1, [r0, SPIx_CR1]

			@ Return
			bx			lr




