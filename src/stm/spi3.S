/************************************************************************************
*
* Author: J.P.G. van Dijk
*
* SPI3 usage: always return to the following configuration:
* - CR1 = MSTR/SSI/SSM set, SPI module disabled
* - CR2 = 0
* - And slave deselected!
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"spi3.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Variables
			.global		SPI3_Data
			.global		SPI3_ExclusiveAccess
			.global		SPI3_ExclusiveAccessSPI

			@ Functions
			.global		SPI3_GetExclusiveAccess
			.global		SPI3_ClearExclusiveAccess
			.global		SPI3_Init
			.global		SPI3_Transfer
			.global		SPI3_EnableDefault
			.global		SPI3_DisableDefault
			.global		SPI3_EnableRXOnlyWithDMA
			.global		SPI3_WaitRXOnlyWithDMA
			.global		SPI3_DisableRXOnlyWithDMA
			.global		SPI3_EnableTXOnlyWithDMA
			.global		SPI3_WaitTXOnlyWithDMA
			.global		SPI3_DisableTXOnlyWithDMA





@-----------------------------------------------------------@
@ SPI3 Data													@
@-----------------------------------------------------------@

			.section	.bss.SPI3_Data
			.align		2
SPI3_Data:

			@ uint8_t SPI3_ExclusiveAccess[1]
			.type		SPI3_ExclusiveAccess, "object"
SPI3_ExclusiveAccess:
SPI3_ExclusiveAccessSPI:
			.space		1





@-----------------------------------------------------------@
@ SPI3 Functions											@
@-----------------------------------------------------------@

			.section	.text.SPI3_GetExclusiveAccess
			.type		SPI3_GetExclusiveAccess, "function"
SPI3_GetExclusiveAccess:

			@ Arguments:
			@ r0: SPI clock prescaler

			@ Save registers
			push		{r4, lr}
			cpy			r4, r0

			@ Try to get exclusive access to the SPI
2:			ldr			r0, =SPI3_ExclusiveAccessSPI
			bl			KERNEL_GetExclusiveAccess
			cbnz		r0, 0f

			@ Change the baudrate and return succes
			ldr			r0, =STM_SPI3
			ldr			r1, [r0, SPIx_CR1]
			bfi			r1, r4, #3, #3
			str			r1, [r0, SPIx_CR1]
			movs		r0, #0
			pop			{r4, pc}

0:			@ Access not granted to the SPI, try again after some time
			movs		r0, SVC_ForceContextSwitchDelay
			movs		r1, SPI3_EXCLUSIVE_ACCESS_DELAY
			svc			SVC_ForceContextSwitch
			b			2b





			.section	.text.SPI3_ClearExclusiveAccess
			.type		SPI3_ClearExclusiveAccess, "function"
SPI3_ClearExclusiveAccess:

			@ Save registers
			push		{lr}

			@ Release access to the SPI and DMA
			ldr			r0, =SPI3_ExclusiveAccessSPI
			bl			KERNEL_ClearExclusiveAccess

			@ Restore registers and return
			pop			{pc}





			.section	.text.SPI3_Init
			.type		SPI3_Init, "function"
SPI3_Init:

			@ Save registers
			push		{lr}

			@ Remap the JTAG interface
			ldr			r0, =AFIO_MAPR
			movs		r2, #0x02
			ldr			r1, [r0]
			bfi			r1, r2, #24, #3
			str			r1, [r0]

			@ Enable the SPI peripheral
			movs		r0, PERIPHERAL_SPI3
			bl			SystemEnablePeripheral

			@ Configure the SPI pins
			movs		r0, GPIOB
			movs		r1, 3
			movs		r2, PIN_AF_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure
			movs		r0, GPIOB
			movs		r1, 4
			movs		r2, PIN_AF_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure
			movs		r0, GPIOB
			movs		r1, 5
			movs		r2, PIN_AF_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure

			@ Configure the SPI module, but not enabled yet
			ldr			r0, =STM_SPI3
			movs		r1, #0x030C
			str			r1, [r0, SPIx_CR1]
			ldr			r1, [r0, SPIx_I2SCFGR]
			bics		r1, 0x0800
			str			r1, [r0, SPIx_I2SCFGR]
			movs		r1, #0
			str			r1, [r0, SPIx_CR2]

			@ Restore registers and return
			pop			{pc}





			.section	.text.SPI3_Transfer
			.type		SPI3_Transfer, "function"
SPI3_Transfer:

			@ Arguments:
			@ r0: write data

			@ Return values:
			@ r0: data read

			@ Load SPI base address
			ldr			r1, =STM_SPI3

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





			.section	.text.SPI3_EnableDefault
			.type		SPI3_EnableDefault, "function"
SPI3_EnableDefault:

			@ Enable the SPI in default mode
			ldr			r0, =STM_SPI3
			ldr			r1, [r0, SPIx_CR1]
			orrs		r1, 0x0040
			str			r1, [r0, SPIx_CR1]

			@ Return
			bx			lr





			.section	.text.SPI3_DisableDefault
			.type		SPI3_DisableDefault, "function"
SPI3_DisableDefault:

			@ Disable the SPI from default mode and return to normal mode
			ldr			r0, =STM_SPI3
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




