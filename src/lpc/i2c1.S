/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"i2c1.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Functions
			.global		I2C1_Init
			.global		I2C1_StartTransfer
			.global		I2C1_WaitEndTransfer
			.global		I2C1_IRQHandler

			@ Variables
			.global		I2C1_VariablesBase
			.global		I2C1_Timeout
			.global		I2C1_WriteLength
			.global		I2C1_ReadLength
			.global		I2C1_State
			.global		I2C1_Buffer





@-----------------------------------------------------------@
@ Variables													@
@-----------------------------------------------------------@

			.section 	.bss.AHB.I2C1_Variables
			.align		2
I2C1_VariablesBase:

			@ uint32_t I2C1_Timeout = 0
			.type		I2C1_Timeout, "object"
I2C1_Timeout:
			.space		4

			@ uint16_t I2C1_WriteLength = 0
			.type		I2C1_WriteLength, "object"
I2C1_WriteLength:
			.space		2

			@ uint16_t I2C1_ReadLength = 0
			.type		I2C1_ReadLength, "object"
I2C1_ReadLength:
			.space		2

			@ uint16_t I2C1_WriteIndex = 0 (private)
			.type		I2C1_WriteIndex, "object"
I2C1_WriteIndex:
			.space		2

			@ uint16_t I2C1_ReadIndex = 0 (private)
			.type		I2C1_ReadIndex, "object"
I2C1_ReadIndex:
			.space		2

			@ uint8_t I2C1_State = 0
			.type		I2C1_State, "object"
I2C1_State:
			.space 		1





@-----------------------------------------------------------@
@ Buffer													@
@-----------------------------------------------------------@

			#ifdef		DEBUG
			.section	.bss.AHB.I2C1_Buffer
			#else
			.section	.noinit.AHB.I2C1_Buffer
			#endif

I2C1_BufferBase:

			@ uint8_t I2C1_Buffer[I2C1_BUFFER_SIZE] = undefined
			.type		I2C1_Buffer, "object"
I2C1_Buffer:
			.space		I2C1_BUFFER_SIZE





@-----------------------------------------------------------@
@ I2C1_Init													@
@-----------------------------------------------------------@
@															@
@ This function initializes I2C1 (basic power, clock, pins,	@
@ interrupts) for master only function with a clock freq of	@
@ 400 kHz, 50% duty cycle (if the system clock is 120 MHz)	@
@															@
@ > Arguments:			<none>								@
@ > Return values:		<none>								@
@-----------------------------------------------------------@

			.section	.text.I2C1_Init
			.type		I2C1_Init, "function"
I2C1_Init:

			@ Save registers
			push		{lr}

			@-----------------------------------------------------------@

			@ Init peripheral I2C1 with no clock division
			movs		r0, PERIPHERAL_I2C1
			movs		r1, PCLKSEL_CCLK_DIV_1
			bl			SystemInitPeripheral

			@ Init I2C pins P0[20]:P0[19]
			@ Alternate function, open drain, no pull-up/down resistors
			@ Don't use the functions because all values are known and
			@ both pins can be initialized simultaneously
			ldr			r0, =LPC_PIN

			ldr			r1, [r0, (PINSEL1 - LPC_PIN)]
			orr			r1, (((PINSEL_AF3 << 2) | PINSEL_AF3) << 6)
			str			r1, [r0, (PINSEL1 - LPC_PIN)]

			movs		r2, ((PINMODE_NO_PULL << 2) | PINMODE_NO_PULL)
			ldr			r1, [r0, (PINMODE1 - LPC_PIN)]
			bfi			r1, r2, #6, #4
			str			r1, [r0, (PINMODE1 - LPC_PIN)]

			ldr			r1, [r0, (PINMODE_OD0 - LPC_PIN)]
			orr			r1, (((PINMODE_OD_OPENDRAIN << 1) | PINMODE_OD_OPENDRAIN) << 19)
			str			r1, [r0, (PINMODE_OD0 - LPC_PIN)]

			@ Enable interrupt in the NVIC
			movs		r0, I2C1_IRQn
			bl			NVIC_IRQEnable

			@ Init I2C1 registers
			@ Define serial clock frequency (400 kHz, 50% @ 120MHz PCLK)
			@ and enable master only function (first clear all bits)
			ldr			r0, =LPC_I2C1

			movs		r1, #150
			strh		r1, [r0, (I2C1SCLH - LPC_I2C1)]
			strh		r1, [r0, (I2C1SCLL - LPC_I2C1)]

			movs		r1, ((1 << 2) | (1 << 3) | (1 << 5) | (1 << 6))
			str			r1, [r0, (I2C1CONCLR - LPC_I2C1)]
			movs		r1, (1 << 6)
			str			r1, [r0, (I2C1CONSET - LPC_I2C1)]

			@ Restore registers and return
			pop			{pc}





@-----------------------------------------------------------@
@ I2C1_StartTransfer										@
@-----------------------------------------------------------@
@															@
@ This function starts a new transfer specified using the	@
@ variables.												@
@															@
@ > Arguments:			<none>								@
@ > Return values:		<none>								@
@-----------------------------------------------------------@

			.section	.text.I2C1_StartTransfer
			.type		I2C1_StartTransfer, "function"
I2C1_StartTransfer:

			@ Change state to busy
			ldr			r0, =I2C1_VariablesBase
			movs		r1, I2C1_STATE_BUSY
			strb		r1, [r0, (I2C1_State - I2C1_VariablesBase)]

			@ Reset timeout counter
			movs		r1, #0
			str			r1, [r0, (I2C1_Timeout - I2C1_VariablesBase)]

			@ Set start flag
			ldr			r0, =LPC_I2C1
			movs		r1, (1 << 5)
			str			r1, [r0, (I2C1CONSET - LPC_I2C1)]

			@ Restore registers and return
			bx			lr





@-----------------------------------------------------------@
@ I2C1_WaitEndTransfer										@
@-----------------------------------------------------------@
@															@
@ This function waits for the transfer to finish, waiting a @
@ maximum time specified using the timeout argument. The	@
@ timeout behaves as a watchdog timer that is reset every	@
@ time there is activity on the I2C bus.					@
@															@
@ > Arguments:			r0: timeout							@
@ > Return values:		r1: transfer result					@
@-----------------------------------------------------------@

			.section	.text.I2C1_WaitEndTransfer
			.type		I2C1_WaitEndTransfer, "function"
I2C1_WaitEndTransfer:

			@ Check transfer state: still busy?
			ldr			r1, =I2C1_VariablesBase
1:			ldrb		r2, [r1, (I2C1_State - I2C1_VariablesBase)]
			cmp			r2, I2C1_STATE_BUSY
			bne			0f

			@ Check timeout variable, temporarily disable interrupts!
			cpsid		i
			ldr			r2, [r1, (I2C1_Timeout - I2C1_VariablesBase)]
			adds		r2, #1
			str			r2, [r1, (I2C1_Timeout - I2C1_VariablesBase)]
			cpsie		i
			cmp			r2, r0
			bls			1b

			@ Timeout has occured, change state to error_timeout (and return state!)
			movs		r0, I2C1_STATE_ERROR_TIMEOUT
			strb		r0, [r1, (I2C1_State - I2C1_VariablesBase)]

			@ Clear start flag
			ldr			r1, =LPC_I2C1
			movs		r2, (1 << 5)
			str			r2, [r1, (I2C1CONCLR - LPC_I2C1)]

			@ Return transfer state, fall through, branch might have higher cost!
			cpy			r2, r0

			@ Return transfer state
0:			cpy			r0, r2
			bx			lr





@-----------------------------------------------------------@
@ I2C1_IRQHandler											@
@-----------------------------------------------------------@

			.section	.text.I2C1_IRQHandler
			.type		I2C1_IRQHandler, "function"
I2C1_IRQHandler:

			@ The registers PC, PSR, R0–R3, R12, and LR are pushed to the stack automatically
			push		{r4, lr}

			@ Load base addresses
			ldr			r0, =I2C1_VariablesBase
			ldr			r1, =LPC_I2C1
			ldr			r2, =I2C1_Buffer

			@ Reset timeout variable
			movs		r3, #0
			str			r3, [r0, (I2C1_Timeout - I2C1_VariablesBase)]

			@ Check I2C status register
			ldrb		r3, [r1, (I2C1STAT - LPC_I2C1)]
			lsrs		r3, #3

			@ Catch status code 0xF8 (no relevant state information available)
			cmp			r3, (0xF8 >> 3)
			beq			_i2c1stat_0xF8_

			@ Branch to specific handler code depending on the current status (master transmit/receive mode)
			tbb			[pc, r3]
_i2c1_branchtable_:
			.byte		((_i2c1stat_0x00_ - _i2c1_branchtable_) / 2) 	@ Bus error during MST or selected slave modes or I2C in undefined state
			.byte		((_i2c1stat_0x08_ - _i2c1_branchtable_) / 2)	@ A START condition has been transmitted
			.byte		((_i2c1stat_0x10_ - _i2c1_branchtable_) / 2)	@ A repeated START condition has been transmitted
			.byte		((_i2c1stat_0x18_ - _i2c1_branchtable_) / 2)	@ SLA+W has been transmitted; ACK has been received
			.byte		((_i2c1stat_0x20_ - _i2c1_branchtable_) / 2)	@ SLA+W has been transmitted; NOT ACK has been received
			.byte		((_i2c1stat_0x28_ - _i2c1_branchtable_) / 2)	@ Data byte in I2DAT has been transmitted; ACK has been received
			.byte		((_i2c1stat_0x30_ - _i2c1_branchtable_) / 2)	@ Data byte in I2DAT has been transmitted; NOT ACK has been received
			.byte		((_i2c1stat_0x38_ - _i2c1_branchtable_) / 2)	@ Arbitration lost in SLA+R/W or Data bytes / Arbitration lost in NOT ACK bit
			.byte		((_i2c1stat_0x40_ - _i2c1_branchtable_) / 2)	@ SLA+R has been transmitted; ACK has been received
			.byte		((_i2c1stat_0x48_ - _i2c1_branchtable_) / 2)	@ SLA+R has been transmitted; NOT ACK has been received
			.byte		((_i2c1stat_0x50_ - _i2c1_branchtable_) / 2)	@ Data byte has been received; ACK has been returned
			.byte		((_i2c1stat_0x58_ - _i2c1_branchtable_) / 2)	@ Data byte has been received; NOT ACK has been returned

_i2c1stat_0x08_: @ > A START condition has been transmitted

			@ Reset write index
			movs		r3, #0
			strh		r3, [r0, (I2C1_WriteIndex - I2C1_VariablesBase)]

			@ Fill I2C1DAT with data from the buffer and clear the start flag
			b			_i2c1_internal_read_buffer_exit_and_clear_start_flag_

_i2c1stat_0x10_: @ > A repeated START condition has been transmitted

			@ Reset read index
			movs		r3, #0
			strh		r3, [r0, (I2C1_ReadIndex - I2C1_VariablesBase)]

			@ Fill I2C1DAT with data from the buffer and clear the start flag
			b			_i2c1_internal_read_buffer_exit_and_clear_start_flag_

_i2c1stat_0x18_: @ > SLA+W has been transmitted; ACK has been received

			@ Check if I2C1_WriteLength equals 1
			ldrh		r3, [r0, (I2C1_WriteLength - I2C1_VariablesBase)]
			cmp			r3, #1

			@ Fill I2C1DAT with data from the buffer
			bne			_i2c1_internal_read_buffer_exit_

			@ Change state to idle and set stop flag
			b			_i2c1stat_exit_with_state_change_idle_and_stop_flag_

_i2c1stat_0x28_: @ > Data byte in I2DAT has been transmitted; ACK has been received

			@ Check I2C1_WriteIndex < I2C1_WriteLength
			ldrh		r3, [r0, (I2C1_WriteIndex - I2C1_VariablesBase)]
			ldrh		r4, [r0, (I2C1_WriteLength - I2C1_VariablesBase)]
			cmp			r3, r4

			@ Fill I2C1DAT with data from the buffer
			blo			_i2c1_internal_read_buffer_exit_

			@ Check I2CReadLength not 0, change state to idle and set stop flag
			ldrh		r3, [r0, (I2C1_ReadLength - I2C1_VariablesBase)]
			cbz			r3, _i2c1stat_exit_with_state_change_idle_and_stop_flag_

			@ Set repeated start flag
			movs		r3, (1 << 5)
			str			r3, [r1, (I2C1CONSET - LPC_I2C1)]

			@ Break
			b			_i2c1stat_exit_

_i2c1stat_0x50_: @ > Data byte has been received; ACK has been returned

			@ Store received byte in the buffer and fall through!
			bl			_i2c1_internal_write_buffer_

_i2c1stat_0x40_: @ > SLA+R has been transmitted; ACK has been received

			@ Check (I2C1_ReadIndex + 1) < I2C1_ReadLength
			ldrh		r3, [r0, (I2C1_ReadIndex - I2C1_VariablesBase)]
			adds		r3, #1
			ldrh		r4, [r0, (I2C1_ReadLength - I2C1_VariablesBase)]
			cmp			r3, r4

			@ Assert ACK/NACK after data is received
			mov			r3, (1 << 2)
			ite			lo
			strlo		r3, [r1, (I2C1CONSET - LPC_I2C1)]
			strhs		r3, [r1, (I2C1CONCLR - LPC_I2C1)]

			@ Break
			b			_i2c1stat_exit_

_i2c1stat_0x30_: @ > Data byte in I2DAT has been transmitted; NOT ACK has been received

			@ Change state to error (nack_data) and set stop flag
			movs		r3, I2C1_STATE_ERROR_NACK_DATA
			b			_i2c1stat_exit_with_state_change_and_stop_flag_

_i2c1stat_0x20_: @ > SLA+W has been transmitted; NOT ACK has been received
_i2c1stat_0x48_: @ > SLA+R has been transmitted; NOT ACK has been received

			@ Change state to error (nack_address) and set stop flag
			movs		r3, I2C1_STATE_ERROR_NACK_ADDRESS
			b			_i2c1stat_exit_with_state_change_and_stop_flag_

_i2c1stat_0x00_: @ Bus error during MST or selected slave modes or I2C in undefined state
_i2c1stat_0x38_: @ > Arbitration lost in SLA+R/W or Data bytes / Arbitration lost in NOT ACK bit
_i2c1stat_0xF8_: @ > No relevant state information available

			@ Change state to error
			movs		r3, I2C1_STATE_ERROR
			b			_i2c1stat_exit_with_state_change_

_i2c1stat_0x58_: @ > Data byte has been received; NOT ACK has been returned

			@ Store received byte in the buffer and fall through!
			bl			_i2c1_internal_write_buffer_

_i2c1stat_exit_with_state_change_idle_and_stop_flag_:

			@ Prepare idle state and fall through!
			movs		r3, I2C1_STATE_IDLE

_i2c1stat_exit_with_state_change_and_stop_flag_:

			@ Set stop flag (r3 must remain unchanged) and fall through!
			movs		r4, (1 << 4)
			str			r4, [r1, (I2C1CONSET - LPC_I2C1)]

_i2c1stat_exit_with_state_change_:

			@ Store new state before exiting (state in r3) and fall through!
			strb		r3, [r0, (I2C1_State - I2C1_VariablesBase)]

_i2c1stat_exit_:

			@ Clear control bits
			movs		r3, (1 << 3)
			str			r3, [r1, (I2C1CONCLR - LPC_I2C1)]

			@ Restore registers (some registers are automatically restored)
			@ And return from the interrupt service routine
			pop			{r4, pc}

_i2c1_internal_read_buffer_exit_and_clear_start_flag_:

			@ Clear start flag and fall through!
			movs		r3, (1 << 5)
			str			r3, [r1, (I2C1CONCLR - LPC_I2C1)]

_i2c1_internal_read_buffer_exit_:

			@ I2C1DAT = I2C1_Buffer[I2C1_WriteIndex++]
			ldrh		r3, [r0, (I2C1_WriteIndex - I2C1_VariablesBase)]
			ldrb		r4, [r2, r3]
			str			r4, [r1, (I2C1DAT - LPC_I2C1)]
			adds		r3, #1
			strh		r3, [r0, (I2C1_WriteIndex - I2C1_VariablesBase)]
			b			_i2c1stat_exit_

_i2c1_internal_write_buffer_:

			@ I2C1_Buffer[I2C1_ReadIndex++] = I2C1DAT
			ldrh		r3, [r0, (I2C1_ReadIndex - I2C1_VariablesBase)]
			ldrb		r4, [r1, (I2C1DAT - LPC_I2C1)]
			strb		r4, [r2, r3]
			adds		r3, #1
			strh		r3, [r0, (I2C1_ReadIndex - I2C1_VariablesBase)]
			bx			lr




