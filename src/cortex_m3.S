/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"cortex_m3.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Functions
			.global		NVIC_IRQClearPending
			.global		NVIC_IRQSetPending
			.global		NVIC_IRQDisable
			.global		NVIC_IRQEnable
			.global		NVIC_IRQIsActive
			.global		NVIC_IRQIsPending
			.global		NVIC_IRQIsEnabled
			.global		NVIC_IRQSetPriority
			.global		NVIC_IRQGetPriority
			.global		NVIC_IRQTrigger

			.global		NVIC_EXCSetPendingNMI
			.global		NVIC_EXCClearPendingSysTick
			.global		NVIC_EXCSetPendingSysTick
			.global		NVIC_EXCClearPendingPendSV
			.global		NVIC_EXCSetPendingPendSV
			.global		NVIC_EXCIsPendingNMI
			.global		NVIC_EXCIsPendingSysTick
			.global		NVIC_EXCIsPendingPendSV
			.global		NVIC_EXCSetPriority
			.global		NVIC_EXCGetPriority

			.global		NVIC_SetPriorityGrouping
			.global		NVIC_SystemReset

			.global		ITM_SendPort0





@-----------------------------------------------------------@
@ IRQ enable, pending, active functions						@
@-----------------------------------------------------------@

			.section	.text.NVIC_IRQControlStatusBits
NVIC_IRQControlStatusBits:

@-----------------------------------------------------------@
@ NVIC_IRQClearPending										@
@ NVIC_IRQSetPending										@
@ NVIC_IRQDisable											@
@ NVIC_IRQEnable											@
@-----------------------------------------------------------@
@															@
@ These functions can enable/disable IRQs and set/clear the	@
@ pending status of the IRQs.								@
@															@
@ > Arguments:			r0: IRQ number						@
@ > Return values:		<none>								@
@ > Changed registers:	r0, r1, r2							@
@ > Changed variables:	<none>								@
@ > Stack usage:		1									@
@-----------------------------------------------------------@

			@ Add 1024 to get 128 bytes higher address offset
			@ Fall-through instead of branch, because of branch penalty
			.type		NVIC_IRQClearPending, "function"
			.type		NVIC_IRQSetPending, "function"
			.type		NVIC_IRQDisable, "function"
			.type		NVIC_IRQEnable, "function"
NVIC_IRQClearPending:
			add			r0, r0, #1024
NVIC_IRQSetPending:
			add			r0, r0, #1024
NVIC_IRQDisable:
			add			r0, r0, #1024
NVIC_IRQEnable:
			push		{lr}
			bl			NumberToBitInWord
			movs		r2, #1
			lsls		r2, r0
			ldr			r0, =CM3_NVIC
			str			r2, [r0, r1]
			pop			{pc}

@-----------------------------------------------------------@
@ NVIC_IRQIsActive											@
@ NVIC_IRQIsPending											@
@ NVIC_IRQIsEnabled											@
@-----------------------------------------------------------@
@															@
@ These functions can check the enable, pending and active	@
@ status of the IRQs.										@
@															@
@ > Arguments:			r0: IRQ number						@
@ > Return values:		flags: zero if interrupt is not		@
@						enabled/pending/active				@
@ > Changed registers:	r0, r1, r2							@
@ > Changed variables:	<none>								@
@ > Stack usage:		1									@
@-----------------------------------------------------------@

			@ Add 2048 to get 256 bytes higher address offset
			@ Fall-through instead of branch, because of branch penalty
			.type		NVIC_IRQIsActive, "function"
			.type		NVIC_IRQIsPending, "function"
			.type		NVIC_IRQIsEnabled, "function"
NVIC_IRQIsActive:
			add			r0, r0, #2048
NVIC_IRQIsPending:
			add			r0, r0, #2048
NVIC_IRQIsEnabled:
			push		{lr}
			bl			NumberToBitInWord
			movs		r2, #1
			lsls		r2, r0
			ldr			r0, =CM3_NVIC
			ldr			r0, [r0, r1]
			ands		r0, r2
			pop			{pc}

NVIC_IRQControlStatusBits_END:

			@ Calculate function group size
			.set		NVIC_IRQControlStatusBits_SIZE, NVIC_IRQControlStatusBits_END - NVIC_IRQControlStatusBits





@-----------------------------------------------------------@
@ IRQ priority functions									@
@-----------------------------------------------------------@

			.section	.text.NVIC_IRQPriority
NVIC_IRQPriority:

@-----------------------------------------------------------@
@ NVIC_IRQSetPriority										@
@-----------------------------------------------------------@
@															@
@ This function sets the priority of an IRQ.				@
@															@
@ > Arguments:			r0: IRQ number						@
@						r1: Priority 0 to 31 (5-bits)		@
@ > Return values:		<none>								@
@ > Changed registers:	r1, r2								@
@ > Changed variables:	<none>								@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			.type		NVIC_IRQSetPriority, "function"
NVIC_IRQSetPriority:
			lsls		r1, #3
			ldr			r2, =IPR0
			strb		r1, [r2, r0]
			bx			lr

@-----------------------------------------------------------@
@ NVIC_IRQGetPriority										@
@-----------------------------------------------------------@
@															@
@ This function gets the priority of an IRQ.				@
@															@
@ > Arguments:			r0: IRQ number						@
@ > Return values:		r0: Priority 0 to 31 (5-bits)		@
@ > Changed registers:	r0, r1								@
@ > Changed variables:	<none>								@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			.type		NVIC_IRQGetPriority, "function"
NVIC_IRQGetPriority:
			ldr			r1, =IPR0
			ldrb		r0, [r1, r0]
			lsrs		r0, #3
			bx			lr

NVIC_IRQPriority_END:

			@ Calculate function group size
			.set		NVIC_IRQPriority_SIZE, NVIC_IRQPriority_END - NVIC_IRQPriority





@-----------------------------------------------------------@
@ NVIC_IRQTrigger											@
@-----------------------------------------------------------@
@															@
@ This function can be used to trigger any interrupt from	@
@ software, just like pending the IRQ.						@
@															@
@ > Arguments:			r0: IRQ number						@
@ > Return values:		<none>								@
@ > Changed registers:	r1									@
@ > Changed variables:	<none>								@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			.section	.text.NVIC_IRQTrigger
			.type		NVIC_IRQTrigger, "function"
NVIC_IRQTrigger:
			ldr			r1, =STIR
			str			r0, [r1]
			bx			lr

NVIC_IRQTrigger_END:

			@ Calculate function size
			.set		NVIC_IRQTrigger_SIZE, NVIC_IRQTrigger_END - NVIC_IRQTrigger





@-----------------------------------------------------------@
@ EXC enable, pending, active functions						@
@-----------------------------------------------------------@

			.section	.text.NVIC_EXCControlStatusBits
NVIC_EXCControlStatusBits:

@-----------------------------------------------------------@
@ NVIC_EXCSetPendingNMI										@
@ NVIC_EXCClearPendingSysTick								@
@ NVIC_EXCSetPendingSysTick									@
@ NVIC_EXCClearPendingPendSV								@
@ NVIC_EXCSetPendingPendSV									@
@-----------------------------------------------------------@
@															@
@ These functions can set/clear the pending status of some	@
@ of the system exceptions.									@
@ TODO: SHCSR register functions							@
@															@
@ > Arguments:			<none>								@
@ > Return values:		<none>								@
@ > Changed registers:	r0, r1								@
@ > Changed variables:	<none>								@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			@ NVIC_EXCSetPendingPendSV has no branch as it is probably most often used
			.type		NVIC_EXCSetPendingNMI, "function"
			.type		NVIC_EXCClearPendingSysTick, "function"
			.type		NVIC_EXCSetPendingSysTick, "function"
			.type		NVIC_EXCClearPendingPendSV, "function"
			.type		NVIC_EXCSetPendingPendSV, "function"
NVIC_EXCSetPendingNMI:
			mov			r0, (1 << 31)
			b			0f
NVIC_EXCClearPendingSysTick:
			mov			r0, (1 << 25)
			b			0f
NVIC_EXCSetPendingSysTick:
			mov			r0, (1 << 26)
			b			0f
NVIC_EXCClearPendingPendSV:
			mov			r0, (1 << 27)
			b			0f
NVIC_EXCSetPendingPendSV:
			mov			r0, (1 << 28)
0:			ldr			r1, =CM3_SCB
			str			r0, [r1, (ICSR - CM3_SCB)]
			bx			lr

@-----------------------------------------------------------@
@ NVIC_EXCIsPendingNMI										@
@ NVIC_EXCIsPendingSysTick									@
@ NVIC_EXCIsPendingPendSV									@
@-----------------------------------------------------------@
@															@
@ These functions can check the pending status of some of	@
@ the system exceptions.									@
@															@
@ > Arguments:			<none>								@
@ > Return values:		flags: zero if interrupt is not		@
@						pending								@
@ > Changed registers:	r0, r1								@
@ > Changed variables:	<none>								@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			.type		NVIC_EXCIsPendingNMI, "function"
			.type		NVIC_EXCIsPendingSysTick, "function"
			.type		NVIC_EXCIsPendingPendSV, "function"
NVIC_EXCIsPendingNMI:
			mov			r0, (1 << 31)
			b			0f
NVIC_EXCIsPendingSysTick:
			mov			r0, (1 << 26)
			b			0f
NVIC_EXCIsPendingPendSV:
			mov			r0, (1 << 28)
0:			ldr			r1, =CM3_SCB
			ldr			r1, [r1, (ICSR - CM3_SCB)]
			ands		r0, r1
			bx			lr

NVIC_EXCControlStatusBits_END:

			@ Calculate function group size
			.set		NVIC_EXCControlStatusBits_SIZE, NVIC_EXCControlStatusBits_END - NVIC_EXCControlStatusBits





@-----------------------------------------------------------@
@ EXC priority functions									@
@-----------------------------------------------------------@

			.section	.text.NVIC_EXCPriority
NVIC_EXCPriority:

@-----------------------------------------------------------@
@ NVIC_EXCSetPriority										@
@-----------------------------------------------------------@
@															@
@ This function sets the priority of a system exception.	@
@															@
@ > Arguments:			r0: EXC number						@
@						r1: Priority 0 to 31 (5-bits)		@
@ > Return values:		<none>								@
@ > Changed registers:	r1, r2								@
@ > Changed variables:	<none>								@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			@ Not SHPR1 as base address, because of an offset of 4 exceptions
			.type		NVIC_EXCSetPriority, "function"
NVIC_EXCSetPriority:
			lsls		r1, #3
			ldr			r2, =0xE000ED14
			strb		r1, [r2, r0]
			bx			lr

@-----------------------------------------------------------@
@ NVIC_EXCGetPriority										@
@-----------------------------------------------------------@
@															@
@ This function gets the priority of a system exception.	@
@															@
@ > Arguments:			r0: EXC number						@
@ > Return values:		r0: Priority 0 to 31 (5-bits)		@
@ > Changed registers:	r0, r1								@
@ > Changed variables:	<none>								@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			@ Not SHPR1 as base address, because of an offset of 4 exceptions
			.type		NVIC_EXCGetPriority, "function"
NVIC_EXCGetPriority:
			ldr			r1, =0xE000ED14
			ldrb		r0, [r1, r0]
			lsrs		r0, #3
			bx			lr

NVIC_EXCPriority_END:

			@ Calculate function group size
			.set		NVIC_EXCPriority_SIZE, NVIC_EXCPriority_END - NVIC_EXCPriority





@-----------------------------------------------------------@
@ NVIC control functions									@
@-----------------------------------------------------------@

			.section	.text.NVIC_ControlFunctions
NVIC_ControlFunctions:

@-----------------------------------------------------------@
@ NVIC_SetPriorityGrouping									@
@-----------------------------------------------------------@
@															@
@ This function sets the NVIC priority grouping.			@
@															@
@ > Arguments:			r0: priority grouping (3-bits)		@
@ > Return values:		<none>								@
@ > Changed registers:	r0, r1								@
@ > Changed variables:	<none>								@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			@ Store priority grouping, value ranging from 0 to 7 (3-bits)
			@ Top halfword must contain the access key
			.type		NVIC_SetPriorityGrouping, "function"
NVIC_SetPriorityGrouping:
			lsls		r0, #8
			movt		r0, 0x05FA
			ldr			r1, =CM3_SCB
			str			r0, [r1, (AIRCR - CM3_SCB)]
			bx			lr

@-----------------------------------------------------------@
@ NVIC_SystemReset											@
@-----------------------------------------------------------@
@															@
@ This function resets the microcontroller.					@
@															@
@ > Arguments:			<none>								@
@ > Return values:		this function does not return		@
@ > Changed registers:	r0, r1								@
@ > Changed variables:	<none>								@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			.type		NVIC_SystemReset, "function"
NVIC_SystemReset:
			dsb
			ldr			r1, =CM3_SCB
			ldr			r0, [r1, (AIRCR - CM3_SCB)]
			orr			r0, r0, (1 << 2)
			movt		r0, 0x05FA
			str			r0, [r1, (AIRCR - CM3_SCB)]
			dsb
			b			.

NVIC_ControlFunctions_END:

			@ Calculate function group size
			.set		NVIC_ControlFunctions_SIZE, NVIC_ControlFunctions_END - NVIC_ControlFunctions





@-----------------------------------------------------------@
@ ITM functions												@
@-----------------------------------------------------------@

			.section	.text.ITM_SendPort0
			.type		ITM_SendPort0, "function"
ITM_SendPort0:

			@ Arguments:
			@ r0: character to send

			@ First check if tracing, the ITM and the port are enabled
			ldr			r1, =DEMCR
			ldr			r2, [r1]
			tst			r2, #(1 << 24)
			beq			1f
			ldr			r1, =CM3_ITM
			ldr			r2, [r1, (TCR - CM3_ITM)]
			tst			r2, #(1 << 0)
			beq			1f
			ldr			r2, [r1, (TER - CM3_ITM)]
			tst			r2, #(1 << 0)
			beq			1f

			@ Wait for the previous transfer to complete
0:			ldr			r2, [r1, (PORT0 - CM3_ITM)]
			cmp			r2, #0
			beq			0b

			@ Write the character
			strb		r0, [r1, (PORT0 - CM3_ITM)]

			@ Return
1:			bx			lr




