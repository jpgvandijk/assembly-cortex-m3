/************************************************************************************
*
* Author: J.P.G. van Dijk
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
			.global		SDCARD_Error





@-----------------------------------------------------------@
@ SDCARD Functions											@
@-----------------------------------------------------------@

			.section	.text.SDCARD_Init
			.type		SDCARD_Init, "function"
SDCARD_Init:

			@ Function waits until an SD-card is inserted and initialized correctly

			@ Save registers
			push		{lr}

#ifdef SDCARD_AUTODETECT

			@ Initialize the SS pin as open-drain to detect a card
			movs		r0, SDCARD_GPIO
			movs		r1, SDCARD_PIN
			movs		r2, PIN_OUTPUT_OPENDRAIN_50MHz
			bl			PIN_Configure
			b			0f
#else
			b			3f
#endif

			@ Clear exclusive access from previous error
4:			bl			SDCARD_SPI_CLEAR_EXCLUSIVE_ACCESS

#ifdef SDCARD_AUTODETECT

			@ Initialize the SS pin as open-drain to detect a card
			movs		r0, SDCARD_GPIO
			movs		r1, SDCARD_PIN
			movs		r2, PIN_OUTPUT_OPENDRAIN_50MHz
			bl			PIN_Configure

			@ Check once in a while
1:			movs		r0, SVC_ForceContextSwitchDelay
			movs		r1, SDCARD_CARD_DETECTION_PERIOD
			svc			SVC_ForceContextSwitch

			@ Pull the SS pin low for a short time
0:			ldr			r0, =SDCARD_GPIO_REGS
			movs		r1, (1 << SDCARD_PIN)
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

#endif

			@ Configure SS pin properly
3:			movs		r0, SDCARD_GPIO
			movs		r1, SDCARD_PIN
			movs		r2, PIN_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure

			@ Deselect the chip
			ldr			r0, =SDCARD_GPIO_REGS
			movs		r1, (1 << SDCARD_PIN)
			str			r1, [r0, GPIOx_BSRR]

			@ Wait minimum time before starting initialization
			movs		r0, SVC_ForceContextSwitchDelay
			movs		r1, SDCARD_INIT_DELAY_MS
			svc			SVC_ForceContextSwitch

			@ Get exclusive access with low clock frequency
			movs		r0, SDCARD_SPI_BAUDRATE_INIT
			bl			SDCARD_SPI_GET_EXCLUSIVE_ACCESS

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
5:			bl			SDCARD_SPI_CLEAR_EXCLUSIVE_ACCESS
			movs		r0, SVC_ForceContextSwitchDelay
			movs		r1, SDCARD_INIT_IDLE_DELAY_MS
			svc			SVC_ForceContextSwitch
			movs		r0, SDCARD_SPI_BAUDRATE_INIT
			bl			SDCARD_SPI_GET_EXCLUSIVE_ACCESS

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
			bl			SDCARD_SPI_CLEAR_EXCLUSIVE_ACCESS

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
			bl			SDCARD_SPI_ENABLE_DEFAULT

			@ Select the chip
			ldr			r0, =SDCARD_BRR
			movs		r1, (1 << SDCARD_PIN)
			str			r1, [r0]

			@ Wait until the card is not busy + resynchronize
0:			movs		r0, #0xFF
			bl			SDCARD_SPI_TRANSFER
			cmp			r0, #0xFF
			bne			0b

			@ Write command
			ands		r0, r4, #0xFF
			bl			SDCARD_SPI_TRANSFER

			@ Write argument (4 bytes)
			movs		r6, #24
1:			lsrs		r0, r5, r6
			bl			SDCARD_SPI_TRANSFER
			cbz			r6, 2f
			subs		r6, #8
			b			1b

			@ Write fixed CRC
2:			movs		r0, SDCARD_CRC_BYTE
			bl			SDCARD_SPI_TRANSFER

			@ Wait for response
			movs		r5, SDCARD_COMMAND_TIMEOUT_RESPONSE
			movs		r6, SDCARD_COMMAND_TIMEOUT
3:			subs		r6, #1
			beq			5f
			movs		r0, #0xFF
			bl			SDCARD_SPI_TRANSFER
			tst			r0, #0x80
			bne			3b

			@ First byte of response received
			cpy			r5, r0
			lsrs		r4, #8
			beq			5f
4:			movs		r0, #0xFF
			bl			SDCARD_SPI_TRANSFER
			lsls		r5, #8
			orrs		r5, r0
			subs		r4, #1
			bne			4b

			@ Deselect the chip
5:			ldr			r2, =SDCARD_BSRR
			movs		r1, (1 << SDCARD_PIN)
			str			r1, [r2]

			@ Disable the SPI and return to normal mode
			bl			SDCARD_SPI_DISABLE_DEFAULT
			
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
			bl			SDCARD_SPI_ENABLE_DEFAULT

			@ Select the chip
			ldr			r0, =SDCARD_BRR
			movs		r1, (1 << SDCARD_PIN)
			str			r1, [r0]

			@ Delay
0:			movs		r0, #0xFF
			bl			SDCARD_SPI_TRANSFER
			subs		r4, #1
			bne			0b

			@ Deselect the chip
			ldr			r2, =SDCARD_BSRR
			movs		r1, (1 << SDCARD_PIN)
			str			r1, [r2]

			@ Disable the SPI and return to normal mode
			bl			SDCARD_SPI_DISABLE_DEFAULT

			@ Restore registers and return
			pop			{r4, pc}





			.section	.text.SDCARD_Read
			.type		SDCARD_Read, "function"
SDCARD_Read:

			@ Argument:
			@ r0: block number to read
			@ r1: address of the buffer

			@ Save registers and arguments
			push		{r4, r5, lr}
			cpy			r4, r0
			cpy			r5, r1

			@ Block must be loaded, get exclusive access
			movs		r0, SDCARD_SPI_BAUDRATE
			bl			SDCARD_SPI_GET_EXCLUSIVE_ACCESS

			@ Calculate byte address
			lsls		r1, r4, SDCARD_BLOCK_SIZE_LOG
			movs		r0, SDCARD_CMD17
			bl			SDCARD_Command
			movs		r4, #0
			cmp			r0, #0
			bne			_sdcard_read_error_

			@ Enable the SPI
			bl			SDCARD_SPI_ENABLE_DEFAULT

			@ Select the chip to continue the transfer
			ldr			r0, =SDCARD_BRR
			movs		r1, (1 << SDCARD_PIN)
			str			r1, [r0]

			@ Wait for the token
			ldr			r4, =SDCARD_READ_TOKEN_TIMEOUT
0:			subs		r4, #1
			beq			_sdcard_read_late_error_
			movs		r0, #0xFF
			bl			SDCARD_SPI_TRANSFER
			cmp			r0, #0xFF
			beq			0b
			movs		r4, #0
			tst			r0, #0xE0
			beq			_sdcard_read_late_error_

			@ Disable the SPI to setup the DMA
			bl			SDCARD_SPI_DISABLE_DEFAULT

			@ Setup the DMA
			cpy			r0, r5
			movs		r1, SDCARD_BLOCK_SIZE
			bl			SDCARD_SPI_ENABLE_RX_ONLY_DMA

			@ Wait for the DMA transfers to complete
			bl			SDCARD_SPI_WAIT_RX_ONLY_DMA

			@ No error
			movs		r4, #1

_sdcard_read_late_error_:

			@ Deselect the chip
			ldr			r2, =SDCARD_BSRR
			movs		r1, (1 << SDCARD_PIN)
			str			r1, [r2]

			@ Disable the SPI and return to normal mode
			bl			SDCARD_SPI_DISABLE_RX_ONLY_DMA

_sdcard_read_error_:

			@ Clear exclusive access
			bl			SDCARD_SPI_CLEAR_EXCLUSIVE_ACCESS

			@ Check if an error has occured
			cmp			r4, #0
			it			eq
			bleq		SDCARD_Error

_sdcard_read_finished_:

			@ Restore registers and return
			pop			{r4, r5, pc}





			.section	.text.SDCARD_Write
			.type		SDCARD_Write, "function"
SDCARD_Write:

			@ Argument:
			@ r0: block number to write
			@ r1: address of the buffer (must be 1 byte longer to include the start token, 0xFE)

			@ Save registers and arguments
			push		{r4, r5, lr}
			cpy			r4, r0
			cpy			r5, r1

			@ Get exclusive access
			movs		r0, SDCARD_SPI_BAUDRATE
			bl			SDCARD_SPI_GET_EXCLUSIVE_ACCESS

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
			ldr			r0, =SDCARD_BRR
			movs		r1, (1 << SDCARD_PIN)
			str			r1, [r0]

			@ Enable the SPI with DMA
			@ Send token 0xFE + 512 bytes + 2 bytes CRC
			cpy			r0, r5
			movw		r1, (SDCARD_BLOCK_SIZE + 3)
			bl			SDCARD_SPI_ENABLE_TX_ONLY_DMA

			@ Wait for the DMA transfers to complete
			bl			SDCARD_SPI_WAIT_TX_ONLY_DMA

			@ Disable the SPI and return to normal mode
			bl			SDCARD_SPI_DISABLE_TX_ONLY_DMA

			@ Deselect the chip
			ldr			r2, =SDCARD_BSRR
			movs		r1, (1 << SDCARD_PIN)
			str			r1, [r2]

			@ No error
			movs		r4, #1

_sdcard_write_error_:

			@ Clear exclusive access
			bl			SDCARD_SPI_CLEAR_EXCLUSIVE_ACCESS

			@ Check if an error has occured
			cmp			r4, #0
			it			eq
			bleq		SDCARD_Error

			@ Restore registers and return
			pop			{r4, r5, pc}





			.section	.text.SDCARD_Error
			.type		SDCARD_Error, "function"
			.weak		SDCARD_Error
SDCARD_Error:

			@ Enter infinite loop
			b.n			.




