/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"onewire.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Variables
			.global		OW_TransferData
			.global		OW_TransferInternalCount
			.global		OW_TransferInternalStateAndLock
			.global		OW_TransferResetAndStatus
			.global		OW_TransferWriteNBits
			.global		OW_TransferReadNBits
			.global		OW_TransferPin
			.global		OW_TransferCallbackFunction
			.global		OW_TransferBuffers
			.global		OW_TransferWriteBuffer
			.global		OW_TransferReadBuffer

			@ Variables - search
			.global		OWSearch_Data
			.global		OWSearch_CallbackFunction
			.global		OWSearch_CountAndStatus
			.global		OWSearch_LastZero
			.global		OWSearch_LastDiscrepancy
			.global		OWSearch_ROM

			@ Functions
			.global		OW_TimerHandler
			.global		OW_StartTransfer
			.global		OW_Init
			.global		OW_InitPin

			@ Functions - search
			.global		OWSearch_Init
			.global		OWSearch_Reset
			.global		OWSearch_Next
			.global		OWSearch_Algorithm

			@ Functions - check
			.global		OW_CheckCRC8





@-----------------------------------------------------------@
@ OW Transfer data											@
@-----------------------------------------------------------@

			#ifdef		DEBUG
			.section	.bss.OW_TransferData
			#else
			.section	.noinit.OW_TransferData
			#endif
			.align		2
OW_TransferData:

			@ uint16_t OW_TransferInternalCount
			.type		OW_TransferInternalCount, "object"
OW_TransferInternalCount:
			.space		2

			@ uint8_t OW_TransferInternalStateAndLock
			.type		OW_TransferInternalStateAndLock, "object"
OW_TransferInternalStateAndLock:
			.space		1

			@ uint8_t OW_TransferResetAndStatus
			.type		OW_TransferResetAndStatus, "object"
OW_TransferResetAndStatus:
			.space		1

			@ uint16_t OW_TransferWriteNBits
			.type		OW_TransferWriteNBits, "object"
OW_TransferWriteNBits:
			.space		2

			@ uint16_t OW_TransferReadNBits
			.type		OW_TransferReadNBits, "object"
OW_TransferReadNBits:
			.space		2

			@ uint32_t OW_TransferPin
			.type		OW_TransferPin, "object"
OW_TransferPin:
			.space		4

			@ uint32_t OW_TransferCallbackFunction
			.type		OW_TransferCallbackFunction, "object"
OW_TransferCallbackFunction:
			.space		4





@-----------------------------------------------------------@
@ OW Transfer buffers										@
@-----------------------------------------------------------@

			#ifdef		DEBUG
			.section	.bss.bitband.OW_TransferBuffers
			#else
			.section	.noinit.bitband.OW_TransferBuffers
			#endif
OW_TransferBuffers:

			@ uint8_t OW_TransferWriteBuffer[OW_WriteBufferSize]
			.type		OW_TransferWriteBuffer, "object"
OW_TransferWriteBuffer:
			.space		OW_WriteBufferSize

			@ uint8_t OW_TransferReadBuffer[OW_ReadBufferSize]
			.type		OW_TransferReadBuffer, "object"
OW_TransferReadBuffer:
			.space		OW_ReadBufferSize





@-----------------------------------------------------------@
@ 1-Wire Timer Handler										@
@-----------------------------------------------------------@

			.section	.text.OW_TimerHandler
			.type		OW_TimerHandler, "function"
OW_TimerHandler:

			@ Clear all interrupts, preserving the cause
			#ifdef		LPC
			ldr			r0, =OW_Timer
			movs		r2, #0x3F
			ldr			r1, [r0, TnIR]
			str			r2, [r0, TnIR]
			#endif
			#ifdef		STM
			ldr			r0, =OW_Timer
			movs		r2, #0
			ldr			r1, [r0, TIMx_SR]
			str			r2, [r0, TIMx_SR]
			#endif

			@ Load pointer to transfer data
			ldr			r0, =OW_TransferData

			@ Determine the cause of the timer interrupt
			#ifdef		LPC
			tst			r1, #1
			bne			_ow_timer_handler_match_0_
			tst			r1, #2
			bne			_ow_timer_handler_match_1_
			#endif
			#ifdef		STM
			tst			r1, #1
			bne			_ow_timer_handler_match_0_
			tst			r1, #2
			bne			_ow_timer_handler_match_1_
			#endif

_ow_timer_handler_match_2_:

			@ Read pin value
			#ifdef		LPC
			ldr			r3, [r0, (OW_TransferPin - OW_TransferData)]
			ldr			r3, [r3]
			#endif
			#ifdef		STM
			ldrh		r3, [r0, (OW_TransferPin - OW_TransferData + 2)]	@ Read compressed address, always 0x4001 xxxx
			movt		r3, #0x4001
			ldr			r3, [r3, GPIOx_IDR]
			ldrh		r1, [r0, (OW_TransferPin - OW_TransferData)]		@ Read bitmask
			tst			r1, r3
			ite			eq
			moveq		r3, #0
			movne		r3, #1
			#endif

			@ Place to store and size depend on state
			ldrb		r1, [r0, (OW_TransferInternalStateAndLock - OW_TransferData)]
			cmp			r1, OW_StateReset
			itt			eq

			@ Store pin value in reset and status variable and return
			strbeq		r3, [r0, (OW_TransferResetAndStatus - OW_TransferData)]
			bxeq		lr

			@ Store pin value in the read buffer at count and return
			ldrh		r1, [r0, (OW_TransferInternalCount - OW_TransferData)]
			ldr			r2, =OW_TransferReadBufferBitband
			str			r3, [r2, r1, LSL #2]
			bx			lr

_ow_timer_handler_match_1_:

			@ Release the pin from ground
			#ifdef		LPC
			movs		r1, #1
			ldr			r2, [r0, (OW_TransferPin - OW_TransferData)]
			str			r1, [r2]
			#endif
			#ifdef		STM
			ldrh		r1, [r0, (OW_TransferPin - OW_TransferData)]
			ldrh		r2, [r0, (OW_TransferPin - OW_TransferData + 2)]
			movt		r2, #0x4001
			str			r1, [r2, GPIOx_BSRR]
			#endif

			@ Return
			bx			lr

_ow_timer_handler_match_0_:

			@ Increment the internal transfer counter
			ldrh		r1, [r0, (OW_TransferInternalCount - OW_TransferData)]
			adds		r1, #1
			strh		r1, [r0, (OW_TransferInternalCount - OW_TransferData)]

			@-----------------------------------------------------------@
			@ Prepare next cycle										@
			@-----------------------------------------------------------@

			@ r0: OW_TransferData
			@ r1: OW_TransferInternalCount

			.type		OW_PrepareNextCycle, "function"
OW_PrepareNextCycle:

			@ Load the transfer counter and the transfer state and branch accordingly
			ldrb		r2, [r0, (OW_TransferInternalStateAndLock - OW_TransferData)]
			tbb			[pc, r2]
_ow_prepare_next_cycle_table_:
			.byte		((_ow_prepare_next_cycle_state_unused_ - _ow_prepare_next_cycle_table_) / 2)
			.byte		((_ow_prepare_next_cycle_state_idle_ - _ow_prepare_next_cycle_table_) / 2)
			.byte		((_ow_prepare_next_cycle_state_reset_ - _ow_prepare_next_cycle_table_) / 2)
			.byte		((_ow_prepare_next_cycle_state_write_ - _ow_prepare_next_cycle_table_) / 2)
			.byte		((_ow_prepare_next_cycle_state_read_ - _ow_prepare_next_cycle_table_) / 2)
			.align		1

_ow_prepare_next_cycle_state_unused_:
_ow_prepare_next_cycle_state_idle_:

			@ FIXME: Reuse other bx lr instruction if possible
			bx			lr

_ow_prepare_next_cycle_state_reset_:

			@ Check whether we do need to generate a reset
			@ Or a reset was generated, but no devices are present
			ldrb		r2, [r0, (OW_TransferResetAndStatus - OW_TransferData)]
			cbz			r2, _ow_prepare_next_cycle_state_reset_finished_
			cbnz		r1, _ow_prepare_next_cycle_state_finished_

			@ Prepare reset cycle
			push		{r4, lr}
			#ifdef		LPC
			movs		r1, #0113
			ldr			r2, =OW_PeriodReset
			movw		r3, OW_DelayResetRelease
			ldr			r4, =OW_DelayResetSample
			#endif
			#ifdef		STM
			movs		r1, #0x0007
			movw		r2, OW_PeriodReset
			movw		r3, OW_DelayResetRelease
			movw		r4, OW_DelayResetSample
			#endif
			b			_ow_prepare_next_cycle_hardware_

_ow_prepare_next_cycle_state_reset_finished_:

			@ Change state and fall through
			movs		r1, #0
			strh		r1, [r0, (OW_TransferInternalCount - OW_TransferData)]
			movs		r2, OW_StateWrite
			strb		r2, [r0, (OW_TransferInternalStateAndLock - OW_TransferData)]

_ow_prepare_next_cycle_state_write_:

			@ Check whether we do need to send more bits
			ldrh		r2, [r0, (OW_TransferWriteNBits - OW_TransferData)]
			cmp			r2, r1
			bls			_ow_prepare_next_cycle_state_write_finished_

			@ Prepare write cycle
			ldr			r3, =OW_TransferWriteBufferBitband
			ldr			r3, [r3, r1, LSL #2]
			cmp			r3, #0
			ite			eq
			#ifdef		LPC
			movweq		r3, OW_DelayWrite0Release
			movwne		r3, OW_DelayWrite1Release
			#endif
			#ifdef		STM
			movweq		r3, OW_DelayWrite0Release
			movwne		r3, OW_DelayWrite1Release
			#endif
			push		{r4, lr}
			#ifdef		LPC
			movs		r1, #013
			movw		r2, OW_Period
			#endif
			#ifdef		STM
			movs		r1, #0x0003
			movw		r2, OW_Period
			#endif
			b			_ow_prepare_next_cycle_hardware_

_ow_prepare_next_cycle_state_write_finished_:

			@ Change state and fall through
			movs		r1, #0
			strh		r1, [r0, (OW_TransferInternalCount - OW_TransferData)]
			movs		r2, OW_StateRead
			strb		r2, [r0, (OW_TransferInternalStateAndLock - OW_TransferData)]

_ow_prepare_next_cycle_state_read_:

			@ Check whether we do need to receive more bits
			ldrh		r2, [r0, (OW_TransferReadNBits - OW_TransferData)]
			cmp			r2, r1
			bls			_ow_prepare_next_cycle_state_read_finished_

			@ Prepare read cycle
			push		{r4, lr}
			#ifdef		LPC
			movs		r1, #0113
			movw		r2, OW_Period
			movw		r3, OW_DelayReadRelease
			movw		r4, OW_DelayReadSample
			#endif
			#ifdef		STM
			movs		r1, #0x0007
			movw		r2, OW_Period
			movw		r3, OW_DelayReadRelease
			movw		r4, OW_DelayReadSample
			#endif
			b			_ow_prepare_next_cycle_hardware_

_ow_prepare_next_cycle_state_read_finished_:
_ow_prepare_next_cycle_state_finished_:

			@ Change state
			movs		r2, OW_StateIdle
			strb		r2, [r0, (OW_TransferInternalStateAndLock - OW_TransferData)]

			@ Stop the timer
			#ifdef		LPC
			ldr			r1, =OW_Timer
			movs		r2, #0x02
			str			r2, [r1, TnTCR]
			#endif
			#ifdef		STM
			ldr			r1, =OW_Timer
			movs		r2, #0
			str			r2, [r1, TIMx_CR1]
			#endif

			@ Notify user using the callback function, then return
			push		{lr}
			ldr			r1, [r0, (OW_TransferCallbackFunction - OW_TransferData)]
			cbz			r1, 0f
			blx			r1
0:			pop			{pc}

_ow_prepare_next_cycle_hardware_:

			@ Drive the pin low
			#ifdef		LPC
			movs		r12, #0
			ldr			r0, [r0, (OW_TransferPin - OW_TransferData)]
			str			r12, [r0]
			#endif
			#ifdef		STM
			ldrh		r12, [r0, (OW_TransferPin - OW_TransferData)]
			ldrh		r0, [r0, (OW_TransferPin - OW_TransferData + 2)]
			movt		r0, #0x4001
			str			r12, [r0, GPIOx_BRR]
			#endif

			@ Setup timer registers
			#ifdef		LPC
			ldr			r0, =(OW_Timer + TnMCR)
			stmia		r0!, {r1, r2, r3, r4}
			#endif
			#ifdef		STM
			ldr			r0, =OW_Timer
			str			r3, [r0, TIMx_CCR1]
			str			r4, [r0, TIMx_CCR2]
			str			r2, [r0, TIMx_ARR]
			str			r1, [r0, TIMx_DIER]
			#endif

			@ Return
			pop			{r4, pc}





@-----------------------------------------------------------@
@ 1-Wire Start Transfer										@
@-----------------------------------------------------------@

			.section	.text.OW_StartTransfer
			.type		OW_StartTransfer, "function"
OW_StartTransfer:

			@ Arguments
			@ r0: Pin
			@ r1: Reset #
			@ r2: Read # Write #
			@ r3: Callback function

			@ Return values:
			@ r0: Status, 0 = OK, 1 = ERROR

			@ Save registers
			push		{r4, r5, lr}

			@ Check if the module is idle and a new transfer can be started
			ldr			r4, =OW_TransferData
			ldrb		r5, [r4, (OW_TransferInternalStateAndLock - OW_TransferData)]
			cmp			r5, OW_StateIdle
			itt			ne
			movne		r0, OW_Error
			popne		{r4, r5, pc}

			@ Store parameters
			str			r0, [r4, (OW_TransferPin - OW_TransferData)]
			strb		r1, [r4, (OW_TransferResetAndStatus - OW_TransferData)]
			str			r2, [r4, (OW_TransferWriteNBits - OW_TransferData)]
			str			r3, [r4, (OW_TransferCallbackFunction - OW_TransferData)]

			@ Reset and enable the timer, and clear the interrupts
			#ifdef		LPC
			ldr			r0, =OW_Timer
			movs		r1, #0x02
			str			r1, [r0, TnTCR]
			movs		r1, #0x01
			str			r1, [r0, TnTCR]
			movs		r1, #0x3F
			str			r1, [r0, TnIR]
			#endif
			#ifdef		STM
			ldr			r0, =OW_Timer
			movs		r1, #0
			str			r1, [r0, TIMx_ARR]
			str			r1, [r0, TIMx_CNT]
			str			r1, [r0, TIMx_SR]
			movs		r1, #0x0011
			str			r1, [r0, TIMx_CCER]
			movs		r1, #1
			str			r1, [r0, TIMx_CR1]
			#endif

			@ Prepare internal state and counter
			cpy			r0, r4
			movs		r1, OW_StateReset
			strb		r1, [r0, (OW_TransferInternalStateAndLock - OW_TransferData)]
			movs		r1, #0
			strh		r1, [r0, (OW_TransferInternalCount - OW_TransferData)]

			@ Prepare next cycle, using code in the timer handler (arguments: r0, r1)
			bl			OW_PrepareNextCycle
			movs		r0, OW_OK
			pop			{r4, r5, pc}





@-----------------------------------------------------------@
@ 1-Wire Initialization										@
@-----------------------------------------------------------@

			.section	.text.OW_Init
			.type		OW_Init, "function"
OW_Init:

			@ Save registers
			push		{lr}

			#ifdef		LPC

			@ Init timer with no clock division
			movs		r0, OW_TimerPeripheral
			movs		r1, PCLKSEL_CCLK_DIV_1
			bl			SystemInitPeripheral

			@ Init timer registers (no prescaler, timer mode, CCR = 0, EMR = 0)
			ldr			r0, =OW_Timer
			movs		r1, #0
			str			r1, [r0, TnPR]
			str			r1, [r0, TnCTCR]
			str			r1, [r0, TnCCR]
			str			r1, [r0, TnEMR]

			#endif
			#ifdef		STM

			@ Enable timer peripheral
			movs		r0, OW_TimerPeripheral
			bl			SystemEnablePeripheral

			@ Init timer registers (prescaler 1:2, up counter, preload disabled)
			ldr			r0, =OW_Timer
			movs		r1, #0
			str			r1, [r0, TIMx_CR1]			@ Enable bit
			str			r1, [r0, TIMx_CR2]
			str			r1, [r0, TIMx_SMCR]
			str			r1, [r0, TIMx_DIER]			@ Interrupt enable bits
			str			r1, [r0, TIMx_SR]			@ Interrupt flags, clear by writing 0
			str			r1, [r0, TIMx_CCMR1]		@ Compare mode, preload disabled
			str			r1, [r0, TIMx_CCMR2]
			str			r1, [r0, TIMx_CCER]			@ Compare channel enable bits
			movs		r1, #1
			str			r1, [r0, TIMx_PSC]			@ Prescaler 1:2

			@ All functionality (timer/compares/interrupts) disabled, hence:
			@ TIMx_CNT	<< Not cleared
			@ TIMx_ARR	<< Not initialized
			@ TIMx_CCR1	<< Not initialized
			@ TIMx_CCR2	<< Not initialized
			@ TIMx_CCR3	<< Not initialized
			@ TIMx_CCR4	<< Not initialized

			#endif

			@ Enable interrupt in the NVIC after clearing the pending status
			movs		r0, OW_TimerIRQn
			bl			NVIC_IRQClearPending
			movs		r0, OW_TimerIRQn
			bl			NVIC_IRQEnable

			@ Set module state to unused
			ldr			r0, =OW_TransferInternalStateAndLock
			bl			KERNEL_ClearExclusiveAccess

			@ Restore registers and return
			pop			{pc}





@-----------------------------------------------------------@
@ 1-Wire Initialization of a pin							@
@-----------------------------------------------------------@

			.section	.text.OW_InitPin
			.type		OW_InitPin, "function"
OW_InitPin:

			#ifdef		LPC

			@ Save registers
			push		{r0, r1, lr}

			@ Set function GPIO
			movs		r2, PINSEL_GPIO
			bl			PIN_SetFunction

			@ Set input mode no pull
			ldmia		sp, {r0, r1}
			movs		r2, PINMODE_NO_PULL
			bl			PIN_SetInputMode

			@ Set output mode open-drain
			ldmia		sp, {r0, r1}
			movs		r2, PINMODE_OD_OPENDRAIN
			bl			PIN_SetOutputMode

			@ Set as output and make pin high
			@ Using bitband region + 4 * (256 * r0 + r1) for direction and pin
			pop			{r0, r1}
			add			r0, r1, r0, LSL #8
			ldr			r1, =(0x22000000 + 32 * (FIO0DIR - 0x20000000))
			add			r0, r1, r0, LSL #2
			movs		r1, #1
			str			r1, [r0]
			add			r0, 32 * (FIO0PIN - FIO0DIR)
			str			r1, [r0]

			@ Restore registers and return with address of pin in bitband region
			pop			{pc}

			#endif
			#ifdef		STM

			@ Save registers
			push		{r0, r1, lr}

			@ Configure pin
			movs		r2, PIN_OUTPUT_OPENDRAIN_50MHz
			bl			PIN_Configure
			pop			{r0, r1}

			@ Create bitmask
			movs		r2, #1
			lsls		r2, r1

			@ Load base address
			ldr			r1, =STM_GPIOx
			add			r0, r1, r0, LSL #10

			@ Make pin high
			str			r2, [r0, GPIOx_BSRR]

			@ Return compressed pin address (address low half-word | bitmask)
			orr			r0, r2, r0, LSL #16

			@ Restore registers and return
			pop			{pc}

			#endif





@-----------------------------------------------------------@
@ OW Search data											@
@-----------------------------------------------------------@

			#ifdef		DEBUG
			.section	.bss.OWSearch_Data
			#else
			.section	.noinit.OWSearch_Data
			#endif
			.align		2
OWSearch_Data:

			@ uint32_t OWSearch_CallbackFunction
			.type		OWSearch_CallbackFunction, "object"
OWSearch_CallbackFunction:
			.space		4

			@ uint8_t OWSearch_CountAndStatus
			.type		OWSearch_CountAndStatus, "object"
OWSearch_CountAndStatus:
			.space		1

			@ int8_t OWSearch_LastZero
			.type		OWSearch_LastZero, "object"
OWSearch_LastZero:
			.space		1

			@ int8_t OWSearch_LastDiscrepancy
			.type		OWSearch_LastDiscrepancy, "object"
OWSearch_LastDiscrepancy:
			.space		1





@-----------------------------------------------------------@
@ OW Search buffers											@
@-----------------------------------------------------------@

			#ifdef		DEBUG
			.section	.bss.bitband.OWSearch_ROM
			#else
			.section	.noinit.bitband.OWSearch_ROM
			#endif
			.type		OWSearch_ROM, "object"

			@ uint64_t OWSearch_ROM
OWSearch_ROM:
			.space		8





@-----------------------------------------------------------@
@ OW Search initialization & reset							@
@-----------------------------------------------------------@

			.section	.text.OWSearch_InitReset
			.type		OWSearch_Init, "function"
OWSearch_Init:
			.type		OWSearch_Reset, "function"
OWSearch_Reset:

			@ Reset the last discrepancy
			ldr			r0, =OWSearch_Data
			movs		r1, #255 @ byte -1
			strb		r1, [r0, (OWSearch_LastDiscrepancy - OWSearch_Data)]





@-----------------------------------------------------------@
@ OW Search next											@
@-----------------------------------------------------------@

			.section	.text.OWSearch_Next
			.type		OWSearch_Next, "function"
OWSearch_Next:

			@ Arguments
			@ r0: Pin
			@ r1: Callback function

			@ Return values
			@ Same as OW_StartTransfer

			@ Save registers
			push		{lr}

			@ Save the callback function
			ldr			r2, =OWSearch_Data
			str			r1, [r2, (OWSearch_CallbackFunction - OWSearch_Data)]

			@ Setup a new search
			movs		r1, #0
			strb		r1, [r2, (OWSearch_CountAndStatus - OWSearch_Data)]
			movs		r1, #255 @ byte -1
			strb		r1, [r2, (OWSearch_LastZero - OWSearch_Data)]

			@ Setup the first transfer
			ldr			r1, =OW_TransferWriteBuffer
			movs		r2, #0xF0
			strb		r2, [r1, #0]
			@cpy		r0, r0
			movs		r1, #1
			ldr			r2, =((2 << 16) | 8)
			ldr			r3, =OWSearch_Algorithm
			bl			OW_StartTransfer

			@ Restore registers and return
			pop			{pc}





@-----------------------------------------------------------@
@ OW Search algorithm										@
@-----------------------------------------------------------@

			.section	.text.OWSearch_Algorithm
			.type		OWSearch_Algorithm, "function"
OWSearch_Algorithm:

			@ r0: OW_TransferData

			@ Check whether the search just started
			ldr			r1, =OWSearch_Data
			ldrb		r2, [r1, (OWSearch_CountAndStatus - OWSearch_Data)]
			cbnz		r2, _owsearch_algorithm_not_first_

			@ The search just started, check the presence pulse
			ldrb		r2, [r0, (OW_TransferResetAndStatus - OW_TransferData)]
			cbz			r2, _owsearch_algorithm_not_first_

			@ No device present on the onewire bus
			movs		r0, #OW_Error
			strb		r0,  [r1, (OWSearch_CountAndStatus - OWSearch_Data)]

			@ Call the callback function if required with r0: status, r1: OWSearch_Data
			ldr			r2, [r1, (OWSearch_CallbackFunction - OWSearch_Data)]
			cbz			r2, 0f
			blx			r2

			@ Return
0:			bx			lr

_owsearch_algorithm_not_first_:

			@ r0: OW_TransferData
			@ r1: OWSearch_Data

			@ Check the bit and complement bit
			ldr			r2, =OW_TransferBuffers
			ldr			r2, [r2, (OW_TransferReadBuffer - OW_TransferBuffers)]
			ands		r2, #0x03

			@ Both bits are different (both high is accepted error)
			itt			ne
			andne		r2, #0x01
			bne			_owsearch_algorithm_direction_determined_

			@ Devices with a 0 and a 1 are present, compare count and last discrepancy
			ldrb		r2, [r1, (OWSearch_CountAndStatus - OWSearch_Data)]
			ldrsb		r3, [r1, (OWSearch_LastDiscrepancy - OWSearch_Data)]
			cmp			r2, r3
			itt			eq
			moveq		r2, #1
			beq			_owsearch_algorithm_direction_determined_
			itt			gt
			movgt		r2, #0
			bgt			_owsearch_algorithm_direction_determined_pre_
			ldr			r3, =OWSearch_ROMBitband
			ldr			r2, [r3, r2, LSL #2]
			cbnz		r2, _owsearch_algorithm_direction_determined_

_owsearch_algorithm_direction_determined_pre_:

			@ Update last zero to current bit position
			ldrb		r3, [r1, (OWSearch_CountAndStatus - OWSearch_Data)]
			strb		r3, [r1, (OWSearch_LastZero - OWSearch_Data)]

_owsearch_algorithm_direction_determined_:

			@ Save registers
			push		{r4, lr}
			cpy			r4, r0
			ldrb		r0, [r1, (OWSearch_CountAndStatus - OWSearch_Data)]

			@ r0: count
			@ r1: OWSearch_Data
			@ r2: search direction (0/1)
			@ r4: OW_TransferData

			@ Store direction in ROM address
			ldr			r3, =OWSearch_ROMBitband
			str			r2, [r3, r0, LSL #2]

			@ Increment the count and check whether the search is finished
			adds		r0, #1
			cmp			r0, #64
			bhs			_owsearch_algorithm_finished_
			strb		r0, [r1, (OWSearch_CountAndStatus - OWSearch_Data)]

			@ Confirm the search direction
			ldr			r3, =OW_TransferBuffers
			strb		r2, [r3, (OW_TransferWriteBuffer - OW_TransferBuffers)]

			@ Start new transfer
			ldr			r0, [r4, (OW_TransferPin - OW_TransferData)]
			movs		r1, #0
			ldr			r2, =((2 << 16) | 1)
			ldr			r3, =OWSearch_Algorithm
			bl			OW_StartTransfer

			@ Restore registers and return
			pop			{r4, pc}

_owsearch_algorithm_finished_:

			@ Update last discrepancy
			ldrsb		r3, [r1, (OWSearch_LastZero - OWSearch_Data)]
			strb		r3, [r1, (OWSearch_LastDiscrepancy - OWSearch_Data)]
			@cmp		r3, #-1
			adds		r3, #1
			ite			eq
			moveq		r0, #OW_Last
			movne		r0, #OW_OK
			strb		r0,  [r1, (OWSearch_CountAndStatus - OWSearch_Data)]

			@ Call the callback function if required with r0: status, r1: OWSearch_Data
			ldr			r2, [r1, (OWSearch_CallbackFunction - OWSearch_Data)]
			cbz			r2, 0f
			blx			r2

			@ Restore registers and return
0:			pop			{r4, pc}





@-----------------------------------------------------------@
@ OW CRC Check												@
@-----------------------------------------------------------@

			.section	.text.OW_CheckCRC8
			.type		OW_CheckCRC8, "function"
OW_CheckCRC8:

			@ Arguments
			@ r0: address
			@ r1: number of bytes

			@ Return
			@ r0: crc8

			push		{r4, r5, lr}
			adds		r1, r0
			movs		r2, #0
0:			ldrb		r3, [r0], #1
			movs		r4, #8
1:			eor			r5, r3, r2
			lsrs		r2, #1
			tst			r5, #1
			it			ne
			eorne		r2, #0x8C
			lsrs		r3, #1
			subs		r4, #1
			bne			1b
			cmp			r0, r1
			blo			0b
			cpy			r0, r2
			pop			{r4, r5, pc}




