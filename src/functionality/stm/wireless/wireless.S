/************************************************************************************
*
* Author: J.P.G. van Dijk
*
* Transmitter only for now. In case a receiver is also required the timer should
* always be kept running.
*
* FIXME: exclusive access + priority
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"wireless.h"
			
			#ifdef		_USE_WIRELESS_





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Variables
			.global		WIRELESS_TransferData
			.global		WIRELESS_TransferWord
			.global		WIRELESS_TransferSpecs
			.global		WIRELESS_TransferBits
			.global		WIRELESS_TransferRepeat
			.global		WIRELESS_TransferPulsewidth
			.global		WIRELESS_TransferPin
			.global		WIRELESS_TransferCallbackFunction
			.global		WIRELESS_TransferInternalCount
			.global		WIRELESS_TransferInternalStateAndLock

			@ Functions
			.global		WIRELESS_Init
			.global		WIRELESS_InitPin
			.global		WIRELESS_Tx
			.global		WIRELESS_TimerHandler





@-----------------------------------------------------------@
@ VARIABLES													@
@-----------------------------------------------------------@

			#ifdef		DEBUG
			.section	.bss.WIRELESS_TransferData
			#else
			.section	.noinit.WIRELESS_TransferData
			#endif
			.align		2
WIRELESS_TransferData:

			@ uint32_t WIRELESS_TransferWord
			.type		WIRELESS_TransferWord, "object"
WIRELESS_TransferWord:
			.space		4

			@ uint32_t WIRELESS_TransferSpecs
			.type		WIRELESS_TransferSpecs, "object"
WIRELESS_TransferSpecs:
WIRELESS_TransferBits:
			.space		1
WIRELESS_TransferRepeat:
			.space		1
WIRELESS_TransferPulsewidth:
			.space		2

			@ uint32_t WIRELESS_TransferPin
			.type		WIRELESS_TransferPin, "object"
WIRELESS_TransferPin:
			.space		4

			@ uint32_t WIRELESS_TransferCallbackFunction
			.type		WIRELESS_TransferCallbackFunction, "object"
WIRELESS_TransferCallbackFunction:
			.space		4

			@ uint8_t WIRELESS_TransferInternalCount
			.type		WIRELESS_TransferInternalCount, "object"
WIRELESS_TransferInternalCount:
			.space		1

			@ uint8_t WIRELESS_TransferInternalStateAndLock
			.type		WIRELESS_TransferInternalStateAndLock, "object"
WIRELESS_TransferInternalStateAndLock:
			.space		1





@-----------------------------------------------------------@
@ FUNCTIONS													@
@-----------------------------------------------------------@

			.section	.text.WIRELESS_Init
			.type		WIRELESS_Init, "function"
WIRELESS_Init:

			@ Save registers
			push		{lr}

			@ Enable timer peripheral
			movs		r0, WIRELESS_TimerPeripheral
			bl			SystemEnablePeripheral

			@ Init timer registers (prescaler 1:72, up counter, preload disabled)
			ldr			r0, =WIRELESS_Timer
			movs		r1, #0
			str			r1, [r0, TIMx_CR1]			@ Enable bit
			str			r1, [r0, TIMx_CR2]
			str			r1, [r0, TIMx_SMCR]
			str			r1, [r0, TIMx_DIER]			@ Interrupt enable bits
			str			r1, [r0, TIMx_SR]			@ Interrupt flags, clear by writing 0
			str			r1, [r0, TIMx_CCMR1]		@ Compare mode, preload disabled
			str			r1, [r0, TIMx_CCMR2]
			str			r1, [r0, TIMx_CCER]			@ Compare channel enable bits
			movs		r1, #71
			str			r1, [r0, TIMx_PSC]			@ Prescaler 1:72

			@ All functionality (timer/compares/interrupts) disabled, hence:
			@ TIMx_CNT	<< Not cleared
			@ TIMx_ARR	<< Not initialized
			@ TIMx_CCR1	<< Not initialized
			@ TIMx_CCR2	<< Not initialized
			@ TIMx_CCR3	<< Not initialized
			@ TIMx_CCR4	<< Not initialized

			@ Enable interrupt in the NVIC after clearing the pending status
			movs		r0, WIRELESS_TimerIRQn
			bl			NVIC_IRQClearPending
			movs		r0, WIRELESS_TimerIRQn
			bl			NVIC_IRQEnable

			@ Set module state to unused
			ldr			r0, =WIRELESS_TransferInternalStateAndLock
			bl			KERNEL_ClearExclusiveAccess

			@ Restore registers and return
			pop			{pc}





			.section	.text.WIRELESS_InitPin
			.type		WIRELESS_InitPin, "function"
WIRELESS_InitPin:

			@ Arguments:
			@ r0: port
			@ r1: pin

			@ Return values:
			@ r0: pin reference

			@ Save registers and arguments
			push		{r0, r1, lr}

			@ Configure pin
			movs		r2, PIN_OUTPUT_NORMAL_50MHz
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





			.section	.text.WIRELESS_Tx
			.type		WIRELESS_Tx, "function"
WIRELESS_Tx:

			@ Arguments:
			@ r0: pin
			@ r1: data
			@ r2: bits, repeat, pulsewidth
			@ r3: callback function

			@ Return values:
			@ r0: Status, 0 = OK, 1 = ERROR

			@ Save registers
			push		{r4, r5, lr}

			@ Check if the module is idle and a new transfer can be started
			ldr			r4, =WIRELESS_TransferData
			ldrb		r5, [r4, (WIRELESS_TransferInternalStateAndLock - WIRELESS_TransferData)]
			cmp			r5, WIRELESS_StateIdle
			itt			ne
			movne		r0, WIRELESS_Error
			popne		{r4, r5, pc}

			@ Store parameters
			str			r0, [r4, (WIRELESS_TransferPin - WIRELESS_TransferData)]
			str			r1, [r4, (WIRELESS_TransferWord - WIRELESS_TransferData)]
			str			r2, [r4, (WIRELESS_TransferSpecs - WIRELESS_TransferData)]
			str			r3, [r4, (WIRELESS_TransferCallbackFunction - WIRELESS_TransferData)]

			@ Reset and enable the timer, and clear the interrupts
			ldr			r0, =WIRELESS_Timer
			movs		r1, #0
			str			r1, [r0, TIMx_ARR]
			str			r1, [r0, TIMx_CNT]
			str			r1, [r0, TIMx_SR]
			movs		r1, #0x0011
			str			r1, [r0, TIMx_CCER]
			movs		r1, #1
			str			r1, [r0, TIMx_CR1]

			@ Prepare internal state and counter
			cpy			r0, r4
			movs		r1, WIRELESS_StateBusy
			strb		r1, [r0, (WIRELESS_TransferInternalStateAndLock - WIRELESS_TransferData)]
			movs		r1, #0
			strb		r1, [r0, (WIRELESS_TransferInternalCount - WIRELESS_TransferData)]

			@ Prepare next cycle, using code in the timer handler (arguments: r0, r1)
			bl			WIRELESS_PrepareNextCycle
			movs		r0, WIRELESS_OK
			pop			{r4, r5, pc}





			.section	.text.WIRELESS_TimerHandler
			.type		WIRELESS_TimerHandler, "function"
WIRELESS_TimerHandler:

			@ Clear all interrupts, preserving the cause
			ldr			r0, =WIRELESS_Timer
			movs		r2, #0
			ldr			r1, [r0, TIMx_SR]
			str			r2, [r0, TIMx_SR]

			@ Load pointer to transfer data
			ldr			r0, =WIRELESS_TransferData

			@ Determine the cause of the timer interrupt
			tst			r1, #1
			bne			_wireless_timer_handler_match_0_

_wireless_timer_handler_match_1_:

			@ Make pin high
			ldrh		r1, [r0, (WIRELESS_TransferPin - WIRELESS_TransferData)]
			ldrh		r2, [r0, (WIRELESS_TransferPin - WIRELESS_TransferData + 2)]
			movt		r2, #0x4001
			str			r1, [r2, GPIOx_BSRR]

			@ Return
			bx			lr

_wireless_timer_handler_match_0_:

			@ Increment the internal transfer counter
			ldrb		r1, [r0, (WIRELESS_TransferInternalCount - WIRELESS_TransferData)]
			adds		r1, #1
			strb		r1, [r0, (WIRELESS_TransferInternalCount - WIRELESS_TransferData)]

			@-----------------------------------------------------------@
			@ Prepare next cycle										@
			@-----------------------------------------------------------@

			@ r0: WIRELESS_TransferData
			@ r1: WIRELESS_TransferInternalCount

			.type		WIRELESS_PrepareNextCycle, "function"
WIRELESS_PrepareNextCycle:

			@ Load the transfer counter and the transfer state and branch accordingly
			ldrb		r2, [r0, (WIRELESS_TransferInternalStateAndLock - WIRELESS_TransferData)]
			tbb			[pc, r2]
_wireless_prepare_next_cycle_table_:
			.byte		((_wireless_prepare_next_cycle_state_unused_ - _wireless_prepare_next_cycle_table_) / 2)
			.byte		((_wireless_prepare_next_cycle_state_idle_ - _wireless_prepare_next_cycle_table_) / 2)
			.byte		((_wireless_prepare_next_cycle_state_busy_ - _wireless_prepare_next_cycle_table_) / 2)
			.byte		((_wireless_prepare_next_cycle_state_sync_ - _wireless_prepare_next_cycle_table_) / 2)
			.align		1

_wireless_prepare_next_cycle_state_busy_:

			@ Check if all bits have been transmitted
			ldrb		r2, [r0, (WIRELESS_TransferBits - WIRELESS_TransferData)]
			cmp			r2, r1
			bne			_wireless_prepare_next_cycle_bit_

			@ Change state
			movs		r2, WIRELESS_StateSync
			strb		r2, [r0, (WIRELESS_TransferInternalStateAndLock - WIRELESS_TransferData)]

			@ Determine the syncbit
			@ sync24: r2 = 1 * pulsewidth, r3 = 32 * pulsewidth
			@ sync28: r2 = 1 * pulsewidth, r3 = 16 * pulsewidth
			@ r0: pointer
			@ r1: count (can be changed)
			ldrh		r2, [r0, (WIRELESS_TransferPulsewidth - WIRELESS_TransferData)]
			cmp			r1, #24
			ite			eq
			lsleq		r3, r2, #5
			lslne		r3, r2, #4
			b			_wireless_prepare_next_cycle_hardware_

_wireless_prepare_next_cycle_state_sync_:

			@ Update the repeat, restart if more transmissions required
			ldrb		r2, [r0, (WIRELESS_TransferRepeat - WIRELESS_TransferData)]
			subs		r2, #1
			strb		r2, [r0, (WIRELESS_TransferRepeat - WIRELESS_TransferData)]
			bne			_wireless_prepare_next_cycle_repeat_

_wireless_prepare_next_cycle_state_finished_:

			@ Change state
			movs		r2, WIRELESS_StateIdle
			strb		r2, [r0, (WIRELESS_TransferInternalStateAndLock - WIRELESS_TransferData)]

			@ Stop the timer
			ldr			r1, =WIRELESS_Timer
			movs		r2, #0
			str			r2, [r1, TIMx_CR1]

			@ Notify user using the callback function, then return
			push		{lr}
			ldr			r1, [r0, (WIRELESS_TransferCallbackFunction - WIRELESS_TransferData)]
			cbz			r1, 0f
			blx			r1
0:			pop			{pc}

_wireless_prepare_next_cycle_repeat_:

			@ Change state
			movs		r2, WIRELESS_StateBusy
			strb		r2, [r0, (WIRELESS_TransferInternalStateAndLock - WIRELESS_TransferData)]

			@ Reset the counter
			movs		r1, #0
			strb		r1, [r0, (WIRELESS_TransferInternalCount - WIRELESS_TransferData)]

_wireless_prepare_next_cycle_bit_:

			@ Determine the databit
			@ 0		: r2 = 1 * pulsewidth,  r3 = 4 * pulsewidth
			@ 1		: r2 = 3 * pulsewidth,  r3 = 4 * pulsewidth
			@ r0: pointer
			@ r1: count (can be changed)
			ldrh		r3, [r0, (WIRELESS_TransferPulsewidth - WIRELESS_TransferData)]
			ldr			r2, [r0, (WIRELESS_TransferWord - WIRELESS_TransferData)]
			lsrs		r2, r1
			ands		r2, #0x01
			ite			eq
			moveq		r2, r3
			addne		r2, r3, r3, LSL #1
			lsls		r3, #2

_wireless_prepare_next_cycle_hardware_:

			@ Drive the pin low
			ldrh		r1, [r0, (WIRELESS_TransferPin - WIRELESS_TransferData)]
			ldrh		r0, [r0, (WIRELESS_TransferPin - WIRELESS_TransferData + 2)]
			movt		r0, #0x4001
			strne		r1, [r0, GPIOx_BRR]

			@ Setup timer registers and return
			ldr			r0, =WIRELESS_Timer
			str			r2, [r0, TIMx_CCR1]
			str			r3, [r0, TIMx_ARR]
			movs		r1, #0x0003
			str			r1, [r0, TIMx_DIER]

_wireless_prepare_next_cycle_state_unused_:
_wireless_prepare_next_cycle_state_idle_:

			@ Return
			bx			lr





			#endif
			