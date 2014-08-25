/************************************************************************************
*
* Author: J.P.G. van Dijk
*
* N.B.: The SD-card has the SS pin connected to pin D6
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"sdcard.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Functions
			.global		SDCARD_Init
			.global		SDCARD_Command
			.global		SDCARD_Delay
			.global		SDCARD_Read
			.global		SDCARD_Write

			@ Variables
			.global		SDCARD_CachedBlock
			.global		SDCARD_ReadBuffer
			.global		SDCARD_WriteBuffer





@-----------------------------------------------------------@
@ SDCARD Buffer												@
@-----------------------------------------------------------@

			#ifdef		DEBUG
			.section	.bss.SDCARD_Buffer
			#else
			.section	.noinit.SDCARD_Buffer
			#endif
			.align		2
			.type		SDCARD_CachedBlock, "object"
			.type		SDCARD_ReadBuffer, "object"
			.type		SDCARD_WriteBuffer, "object"
SDCARD_Variables:
SDCARD_CachedBlock:
			.space		4
SDCARD_Buffer:
			.space		1
SDCARD_WriteBuffer:
			.space		SDCARD_BLOCK_SIZE
SDCARD_ReadBuffer:
			.space		SDCARD_BLOCK_SIZE





@-----------------------------------------------------------@
@ SDCARD Functions											@
@-----------------------------------------------------------@

			.section	.text.SDCARD_Init
			.type		SDCARD_Init, "function"
SDCARD_Init:

			@ Function waits until an SD-card is inserted and initialized correctly

			@ Save registers
			push		{lr}

			@ Initialize variables
			ldr			r0, =SDCARD_Variables
			movs		r1, SDCARD_NO_BLOCK_CACHED
			str			r1, [r0, (SDCARD_CachedBlock - SDCARD_Variables)]
			movs		r1, #0xFE
			strb		r1, [r0, (SDCARD_Buffer - SDCARD_Variables)]

			@ Initialize the SS pin as open-drain to detect a card
			movs		r0, GPIOD
			movs		r1, 6
			movs		r2, PIN_OUTPUT_OPENDRAIN_50MHz
			bl			PIN_Configure
			b			0f

			@ Clear exclusive access from previous error
4:			bl			SPI1_ClearExclusiveAccess

			@ Initialize the SS pin as open-drain to detect a card
			movs		r0, GPIOD
			movs		r1, 6
			movs		r2, PIN_OUTPUT_OPENDRAIN_50MHz
			bl			PIN_Configure

			@ Check once in a while
1:			movs		r0, SVC_ForceContextSwitchDelay
			movs		r1, SDCARD_CARD_DETECTION_PERIOD
			svc			SVC_ForceContextSwitch

			@ Pull the SS pin low for a short time
0:			ldr			r0, =STM_GPIOD
			movs		r1, (1 << 6)
			str			r1, [r0, GPIOx_BRR]
			str			r1, [r0, GPIOx_BSRR]

			@ Wait a short time before reading the pin
			movw		r2, SDCARD_CARD_DETECTION_DELAY
2:			subs		r2, #1
			bne			2b

			@ Card inserted if reading a high value
			ldr			r2, [r0, GPIOx_IDR]
			tst			r2, r1
			beq			1b

			@ Configure SS pin properly
			movs		r0, GPIOD
			movs		r1, 6
			movs		r2, PIN_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure

			@ Deselect the chip
			ldr			r0, =STM_GPIOD
			movs		r1, (1 << 6)
			str			r1, [r0, GPIOx_BSRR]

			@ Wait minimum time before starting initialization
			movs		r0, SVC_ForceContextSwitchDelay
			movs		r1, SDCARD_INIT_DELAY_MS
			svc			SVC_ForceContextSwitch

			@ Get exclusive access with low clock frequency
			movs		r0, SDCARD_SPI_BAUDRATE_INIT
			bl			SPI1_GetExclusiveAccess

			@ Wait minimum time before starting initialization
			movs		r0, SDCARD_INIT_DELAY_CYCLES
			bl			SDCARD_Delay

			@ Enter the IDLE state (software reset)
			movs		r0, SDCARD_CMD0
			movs		r1, #0
			bl			SDCARD_Command
			cmp			r0, #0x01
			bne			4b

			@ Wait while IDLE (can take a long time)
5:			bl			SPI1_ClearExclusiveAccess
			movs		r0, SVC_ForceContextSwitchDelay
			movs		r1, SDCARD_INIT_IDLE_DELAY_MS
			svc			SVC_ForceContextSwitch
			movs		r0, SDCARD_SPI_BAUDRATE_INIT
			bl			SPI1_GetExclusiveAccess

			@ Read state
			movs		r0, SDCARD_CMD55
			movs		r1, #0
			bl			SDCARD_Command
			movs		r0, SDCARD_ACMD41
			movs		r1, #0
			bl			SDCARD_Command
			cmp			r0, #0x01
			beq			5b
			cmp			r0, #0
			bne			4b

			@ Read OCR, power up status bit must be set
			movw		r0, SDCARD_CMD58
			movs		r1, #0
			bl			SDCARD_Command
			tst			r0, #(1 << 31)
			beq			4b

			@ Force block size to 512 bytes
			movs		r0, SDCARD_CMD16
			movs		r1, SDCARD_BLOCK_SIZE
			bl			SDCARD_Command
			cmp			r0, #0
			bne			4b

			@ Initialization succeeded!
			bl			SPI1_ClearExclusiveAccess

			@ Restore registers and return
			pop			{pc}





			.section	.text.SDCARD_Command
			.type		SDCARD_Command, "function"
SDCARD_Command:

			@ Arguments:
			@ r0: command + number of ADDITIONAL response bytes
			@ r1: argument

			@ Return values:
			@ r0: response or error code (only last 4 bytes packed)

			@ Save registers and arguments
			push		{r4, r5, r6, lr}
			cpy			r4, r0
			cpy			r5, r1

			@ Enable the SPI
			bl			SPI1_EnableDefault

			@ Select the chip
			ldr			r0, =GPIOD_BRR
			movs		r1, (1 << 6)
			str			r1, [r0]

			@ Wait until the card is not busy + resynchronize
0:			movs		r0, #0xFF
			bl			SPI1_Transfer
			cmp			r0, #0xFF
			bne			0b

			@ Write command
			ands		r0, r4, #0xFF
			bl			SPI1_Transfer

			@ Write argument (4 bytes)
			movs		r6, #24
1:			lsrs		r0, r5, r6
			bl			SPI1_Transfer
			cbz			r6, 2f
			subs		r6, #8
			b			1b

			@ Write fixed CRC
2:			movs		r0, SDCARD_CRC_BYTE
			bl			SPI1_Transfer

			@ Wait for response
			movs		r5, SDCARD_COMMAND_TIMEOUT_RESPONSE
			movs		r6, SDCARD_COMMAND_TIMEOUT
3:			subs		r6, #1
			beq			5f
			movs		r0, #0xFF
			bl			SPI1_Transfer
			tst			r0, #0x80
			bne			3b

			@ First byte of response received
			cpy			r5, r0
			lsrs		r4, #8
			beq			5f
4:			movs		r0, #0xFF
			bl			SPI1_Transfer
			lsls		r5, #8
			orrs		r5, r0
			subs		r4, #1
			bne			4b

			@ Deselect the chip
5:			ldr			r2, =GPIOD_BSRR
			movs		r1, (1 << 6)
			str			r1, [r2]

			@ Disable the SPI and return to normal mode
			bl			SPI1_DisableDefault
			
			@ Restore registers and return with response or error code
			cpy			r0, r5
			pop			{r4, r5, r6, pc}





			.section	.text.SDCARD_Delay
			.type		SDCARD_Delay, "function"
SDCARD_Delay:

			@ Arguments:
			@ r0: number of bytes

			@ Save registers and argument
			push		{r4, lr}
			cpy			r4, r0

			@ Enable the SPI
			bl			SPI1_EnableDefault

			@ Select the chip
			ldr			r0, =GPIOD_BRR
			movs		r1, (1 << 6)
			str			r1, [r0]

			@ Delay
0:			movs		r0, #0xFF
			bl			SPI1_Transfer
			subs		r4, #1
			bne			0b

			@ Deselect the chip
			ldr			r2, =GPIOD_BSRR
			movs		r1, (1 << 6)
			str			r1, [r2]

			@ Disable the SPI and return to normal mode
			bl			SPI1_DisableDefault

			@ Restore registers and return
			pop			{r4, pc}





			.section	.text.SDCARD_Read
			.type		SDCARD_Read, "function"
SDCARD_Read:

			@ Argument:
			@ r0: block number

			@ Return values
			@ r0: status (0: error)

			@ Save registers
			push		{r4, lr}

			@ Compare with currently cached block
			movs		r4, #1
			ldr			r1, =SDCARD_CachedBlock
			ldr			r2, [r1]
			cmp			r2, r0
			beq			_sdcard_read_finished_
			str			r0, [r1]

			@ Block must be loaded, get exclusive access
			cpy			r4, r0
			movs		r0, SDCARD_SPI_BAUDRATE
			bl			SPI1_GetExclusiveAccess

			@ Calculate byte address
			lsls		r1, r4, SDCARD_BLOCK_SIZE_LOG
			movs		r0, SDCARD_CMD17
			bl			SDCARD_Command
			movs		r4, #0
			cmp			r0, #0
			bne			_sdcard_read_error_

			@ Enable the SPI
			bl			SPI1_EnableDefault

			@ Select the chip to continue the transfer
			ldr			r0, =GPIOD_BRR
			movs		r1, (1 << 6)
			str			r1, [r0]

			@ Wait for the token
			ldr			r4, =SDCARD_READ_TOKEN_TIMEOUT
0:			subs		r4, #1
			beq			_sdcard_read_late_error_
			movs		r0, #0xFF
			bl			SPI1_Transfer
			cmp			r0, #0xFF
			beq			0b
			movs		r4, #0
			tst			r0, #0xE0
			beq			_sdcard_read_late_error_

			@ Disable the SPI to setup the DMA
			bl			SPI1_DisableDefault

			@ Setup the DMA
			ldr			r0, =SDCARD_ReadBuffer
			movs		r1, SDCARD_BLOCK_SIZE
			bl			SPI1_EnableRXOnlyWithDMA

			@ Wait for the DMA transfers to complete
			bl			SPI1_WaitRXOnlyWithDMA

			@ No error
			movs		r4, #1

_sdcard_read_late_error_:

			@ Deselect the chip
			ldr			r2, =GPIOD_BSRR
			movs		r1, (1 << 6)
			str			r1, [r2]

			@ Disable the SPI and return to normal mode
			bl			SPI1_DisableRXOnlyWithDMA

_sdcard_read_error_:

			@ Clear exclusive access
			bl			SPI1_ClearExclusiveAccess

			@ Invalidate cached block in case of an error
			cbnz		r4, _sdcard_read_finished_
			ldr			r0, =SDCARD_CachedBlock
			movs		r1, SDCARD_NO_BLOCK_CACHED
			str			r1, [r0]

_sdcard_read_finished_:

			@ Restore registers and return status
			cpy			r0, r4
			pop			{r4, pc}





			.section	.text.SDCARD_Write
			.type		SDCARD_Write, "function"
SDCARD_Write:

			@ Argument:
			@ r0: block number

			@ Return values:
			@ r0: status (0: error)

			@ Save registers
			push		{r4, lr}

			@ Invalidate cached block if address matches
			ldr			r1, =SDCARD_CachedBlock
			movs		r3, SDCARD_NO_BLOCK_CACHED
			ldr			r2, [r1]
			cmp			r2, r0
			it			eq
			streq		r3, [r1]

			@ Get exclusive access
			cpy			r4, r0
			movs		r0, SDCARD_SPI_BAUDRATE
			bl			SPI1_GetExclusiveAccess

			@ Calculate byte address
			lsls		r1, r4, SDCARD_BLOCK_SIZE_LOG
			movs		r0, SDCARD_CMD24
			bl			SDCARD_Command
			movs		r4, #0
			cmp			r0, #0
			bne			_sdcard_write_error_

			@ Provide additional byte
			movs		r0, #1
			bl			SDCARD_Delay

			@ Select the chip to continue the transfer
			ldr			r0, =GPIOD_BRR
			movs		r1, (1 << 6)
			str			r1, [r0]

			@ Enable the SPI with DMA
			@ Send token 0xFE + 512 bytes + 2 bytes CRC
			ldr			r0, =(SDCARD_WriteBuffer - 1)
			movw		r1, (SDCARD_BLOCK_SIZE + 3)
			bl			SPI1_EnableTXOnlyWithDMA

			@ Wait for the DMA transfers to complete
			bl			SPI1_WaitTXOnlyWithDMA

			@ Disable the SPI and return to normal mode
			bl			SPI1_DisableTXOnlyWithDMA

			@ Deselect the chip
			ldr			r2, =GPIOD_BSRR
			movs		r1, (1 << 6)
			str			r1, [r2]

			@ No error
			movs		r4, #1

_sdcard_write_error_:

			@ Clear exclusive access
			bl			SPI1_ClearExclusiveAccess

			@ Restore registers and return status
			cpy			r0, r4
			pop			{r4, pc}




