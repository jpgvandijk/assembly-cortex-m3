/************************************************************************************
*
* Author: J.P.G. van Dijk
*
* N.B.: If channel 4/5 is also used for other applications exclusive access must be
* granted. Also DMA1 must be enabled in advance:
* - movs	r0, PERIPHERAL_DMA1
* - bl		SystemEnablePeripheral
*
* SPI2 usage: always return to the following configuration:
* - CR1 = MSTR/SSI/SSM set, SPI module disabled
* - CR2 = 0
* - And slave deselected!
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"spi2.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Variables
			.global		SPI2_Data
			.global		SPI2_ExclusiveAccess
			.global		SPI2_ExclusiveAccessSPI
			.global		SPI2_ExclusiveAccessDMA

			@ Functions
			.global		SPI2_GetExclusiveAccess
			.global		SPI2_ClearExclusiveAccess
			.global		SPI2_Init
			.global		SPI2_Transfer
			.global		SPI2_EnableDefault
			.global		SPI2_DisableDefault
			.global		SPI2_EnableRXOnlyWithDMA
			.global		SPI2_WaitRXOnlyWithDMA
			.global		SPI2_DisableRXOnlyWithDMA
			.global		SPI2_EnableTXOnlyWithDMA
			.global		SPI2_WaitTXOnlyWithDMA
			.global		SPI2_DisableTXOnlyWithDMA





@-----------------------------------------------------------@
@ SPI2 Data													@
@-----------------------------------------------------------@

			.section	.bss.SPI2_Data
			.align		2
SPI2_Data:

			@ uint8_t SPI2_ExclusiveAccess[2]
			.type		SPI2_ExclusiveAccess, "object"
SPI2_ExclusiveAccess:
SPI2_ExclusiveAccessSPI:
			.space		1
SPI2_ExclusiveAccessDMA:
			.space		1





@-----------------------------------------------------------@
@ SPI2 Functions											@
@-----------------------------------------------------------@

			.section	.text.SPI2_GetExclusiveAccess
			.type		SPI2_GetExclusiveAccess, "function"
SPI2_GetExclusiveAccess:

			@ Arguments:
			@ r0: SPI clock prescaler

			@ Save registers
			push		{r4, lr}
			cpy			r4, r0

			@ Try to get exclusive access to the SPI
2:			ldr			r0, =SPI2_ExclusiveAccessSPI
			bl			KERNEL_GetExclusiveAccess
			cbnz		r0, 0f

			@ Try to get exclusive access to the DMA
			ldr			r0, =SPI2_ExclusiveAccessDMA
			bl			KERNEL_GetExclusiveAccess
			cbnz		r0, 1f

			@ Change the baudrate and return succes
			ldr			r0, =STM_SPI2
			ldr			r1, [r0, SPIx_CR1]
			bfi			r1, r4, #3, #3
			str			r1, [r0, SPIx_CR1]
			movs		r0, #0
			pop			{r4, pc}

1:			@ Access to the DMA was not granted, release access to the SPI
			ldr			r0, =SPI2_ExclusiveAccessSPI
			bl			KERNEL_ClearExclusiveAccess

0:			@ Access not granted to the SPI, try again after some time
			movs		r0, SVC_ForceContextSwitchDelay
			movs		r1, SPI2_EXCLUSIVE_ACCESS_DELAY
			svc			SVC_ForceContextSwitch
			b			2b





			.section	.text.SPI2_ClearExclusiveAccess
			.type		SPI2_ClearExclusiveAccess, "function"
SPI2_ClearExclusiveAccess:

			@ Save registers
			push		{lr}

			@ Release access to the SPI and DMA
			ldr			r0, =SPI2_ExclusiveAccessSPI
			bl			KERNEL_ClearExclusiveAccess
			ldr			r0, =SPI2_ExclusiveAccessDMA
			bl			KERNEL_ClearExclusiveAccess

			@ Restore registers and return
			pop			{pc}





			.section	.text.SPI2_Init
			.type		SPI2_Init, "function"
SPI2_Init:

			@ Save registers
			push		{lr}

			@ Enable the SPI peripheral
			movs		r0, PERIPHERAL_SPI2
			bl			SystemEnablePeripheral

			@ Configure the SPI pins
			movs		r0, GPIOB
			movs		r1, 13
			movs		r2, PIN_AF_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure
			movs		r0, GPIOB
			movs		r1, 14
			movs		r2, PIN_AF_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure
			movs		r0, GPIOB
			movs		r1, 15
			movs		r2, PIN_AF_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure

			@ Configure the SPI module, but not enabled yet
			ldr			r0, =STM_SPI2
			movs		r1, #0x030C
			str			r1, [r0, SPIx_CR1]
			ldr			r1, [r0, SPIx_I2SCFGR]
			bics		r1, 0x0800
			str			r1, [r0, SPIx_I2SCFGR]
			movs		r1, #0
			str			r1, [r0, SPIx_CR2]

			@ Restore registers and return
			pop			{pc}





			.section	.text.SPI2_Transfer
			.type		SPI2_Transfer, "function"
SPI2_Transfer:

			@ Arguments:
			@ r0: write data
			
			@ Return values:
			@ r0: data read
			
			@ Load SPI base address
			ldr			r1, =STM_SPI2
			
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





			.section	.text.SPI2_EnableDefault
			.type		SPI2_EnableDefault, "function"
SPI2_EnableDefault:

			@ Enable the SPI in default mode
			ldr			r0, =STM_SPI2
			ldr			r1, [r0, SPIx_CR1]
			orrs		r1, 0x0040
			str			r1, [r0, SPIx_CR1]

			@ Return
			bx			lr





			.section	.text.SPI2_DisableDefault
			.type		SPI2_DisableDefault, "function"
SPI2_DisableDefault:

			@ Disable the SPI from default mode and return to normal mode
			ldr			r0, =STM_SPI2
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





			.section	.text.SPI2_EnableRXOnlyWithDMA
			.type		SPI2_EnableRXOnlyWithDMA, "function"
SPI2_EnableRXOnlyWithDMA:

			@ Arguments:
			@ r0: destination address
			@ r1: count

			@ Setup the DMA
			ldr			r2, =STM_DMA1
			ldr			r3, =(STM_SPI2 + SPIx_DR)
			str			r3, [r2, DMAx_CPAR4]
			str			r0, [r2, DMAx_CMAR4]
			str			r1, [r2, DMAx_CNDTR4]
			movs		r0, #0x2080
			str			r0, [r2, DMAx_CCR4]

			@ Clear the flags and enable the DMA channel, high priority
			movs		r1, #0x1000
			str			r1, [r2, DMAx_IFCR]
			orrs		r0, #0x0001
			str			r0, [r2, DMAx_CCR4]

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





			.section	.text.SPI2_WaitRXOnlyWithDMA
			.type		SPI2_WaitRXOnlyWithDMA, "function"
SPI2_WaitRXOnlyWithDMA:

			@ Wait for the DMA transfers to complete
			ldr			r1, =STM_DMA1
0:			ldr			r0, [r1, DMAx_ISR]
			tst			r0, #(1 << 13)
			beq			0b

			@ Return
			bx			lr





			.section	.text.SPI2_DisableRXOnlyWithDMA
			.type		SPI2_DisableRXOnlyWithDMA, "function"
SPI2_DisableRXOnlyWithDMA:

			@ Disable the DMA
			ldr			r1, =STM_DMA1
			movs		r0, #0
			str			r0, [r1, DMAx_CCR4]

			@ Disable the SPI and return to normal mode
			ldr			r1, =STM_SPI2
			ldr			r0, [r1, SPIx_CR1]
			bics		r0, (0x0040 | (1 << 10))
			str			r0, [r1, SPIx_CR1]
0:			ldr			r0, [r1, SPIx_SR]
			tst			r0, #(1 << 0)
			beq			0b
			ldr			r0, [r1, SPIx_DR]

			@ Return
			bx			lr





			.section	.text.SPI2_EnableTXOnlyWithDMA
			.type		SPI2_EnableTXOnlyWithDMA, "function"
SPI2_EnableTXOnlyWithDMA:

			@ Arguments:
			@ r0: source address
			@ r1: count

			@ Setup the DMA
			ldr			r2, =STM_DMA1
			ldr			r3, =(STM_SPI2 + SPIx_DR)
			str			r3, [r2, DMAx_CPAR5]
			str			r0, [r2, DMAx_CMAR5]
			str			r1, [r2, DMAx_CNDTR5]
			movw		r0, #0x2090
			str			r0, [r2, DMAx_CCR5]

			@ Enable the SPI with DMA on the TX channel
			subs		r3, SPIx_DR
			movs		r1, #0x02
			str			r1, [r3, SPIx_CR2]
			ldr			r1, [r3, SPIx_CR1]
			orrs		r1, #(1 << 6)
			str			r1, [r3, SPIx_CR1]

			@ Clear the flags and enable the DMA channel, high priority
			movs		r1, #0x10000
			str			r1, [r2, DMAx_IFCR]
			orrs		r0, #0x0001
			str			r0, [r2, DMAx_CCR5]

			@ Return
			bx			lr





			.section	.text.SPI2_WaitTXOnlyWithDMA
			.type		SPI2_WaitTXOnlyWithDMA, "function"
SPI2_WaitTXOnlyWithDMA:

			@ Wait for the DMA transfers to complete
			ldr			r1, =STM_DMA1
0:			ldr			r0, [r1, DMAx_ISR]
			tst			r0, #(1 << 17)
			beq			0b

			@ Return
			bx			lr





			.section	.text.SPI2_DisableTXOnlyWithDMA
			.type		SPI2_DisableTXOnlyWithDMA, "function"
SPI2_DisableTXOnlyWithDMA:

			@ Disable the DMA
			ldr			r1, =STM_DMA1
			movs		r0, #0
			str			r0, [r1, DMAx_CCR5]

			@ Disable the SPI and return to normal mode
			ldr			r0, =STM_SPI2
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




