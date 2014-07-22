/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"system.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Variables
			.global		SystemClock

			@ Functions
			.global		SystemInitClock
			.global		SystemGetClock
			.global		SystemDelayMs
			.global		SystemDisablePeripheral
			.global		SystemEnablePeripheral
			.global		SystemResetPeripheral





@-----------------------------------------------------------@
@ uint32_t SystemClock = 0									@
@-----------------------------------------------------------@

			.section	.bss.SystemClock
			.type		SystemClock, "object"
SystemClock:
			.space		4





@-----------------------------------------------------------@
@ SystemInitClock											@
@-----------------------------------------------------------@
@															@
@ This function initializes all internal clocks. Core clock	@
@ is initialized to 72 MHz, using an external 8 MHz OSC.	@
@ Flash access time is set accordingly.						@
@															@
@ > Arguments:			<none>								@
@ > Return values:		<none>								@
@ > Changed registers:	r0, r1								@
@ > Changed variables:	<none>								@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			.section	.text.SystemInitClock
			.type		SystemInitClock, "function"
SystemInitClock:
			
			@ Enable prefetch buffer with 2 wait states
			ldr			r0, =STM_FLASH
			movs		r1, #0x12
			str			r1, [r0, (FLASH_ACR - STM_FLASH)]
			
			@ Enable HSE and wait till it is ready
			ldr			r0, =STM_RCC
			movs		r1, #0x01
			strb		r1, [r0, (RCC_CR - STM_RCC + 2)]
0:			ldrb		r1, [r0, (RCC_CR - STM_RCC + 2)]
			tst			r1, #0x02
			beq			0b
			
			@ Set the maximum allowed clock frequencies
			@ HCLK = SYSCLK, PCLK1 = HCLK / 2, PCLK2 = HCLK, ADCCLK = PCLK2 / 6
			@ USBCLK = PLLCLK / 1.5, PLLCLK = HSE * 9
			movs		r1, #0x8400
			strh		r1, [r0, (RCC_CFGR - STM_RCC + 0)]
			movs		r1, #0x1D
			strb		r1, [r0, (RCC_CFGR - STM_RCC + 2)]
			
			@ Enable PLL and wait till it is ready
			movs		r1, #0x01
			strb		r1, [r0, (RCC_CR - STM_RCC + 3)]
1:			ldrb		r1, [r0, (RCC_CR - STM_RCC + 3)]
			tst			r1, #0x02
			beq			1b
			
			@ Select PLL as system clock source and wait till it is used
			movs		r1, #0x02
			strb		r1, [r0, (RCC_CFGR - STM_RCC + 0)]
2:			ldrb		r1, [r0, (RCC_CFGR - STM_RCC + 0)]
			tst			r1, 0x08
			beq			2b
			
			@ Return
			bx			lr

			
			
			

@-----------------------------------------------------------@
@ SystemGetClock											@
@-----------------------------------------------------------@
@															@
@ This function determines the core clock frequency and		@
@ stores the result in the variable SystemClock [Hz].		@
@															@
@ > Arguments:			<none>								@
@ > Return values:		<none>								@
@ > Changed registers:	r0, r1, r2							@
@ > Changed variables:	SystemClock							@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			.section	.text.SystemGetClock
			.type		SystemGetClock, "function"
SystemGetClock:
			
			@ Load base frequency, only correct for HSE = HSI = 8 MHz
			ldr			r2, =8000000
			
			@ Load the system clock settings
			ldr			r0, =STM_RCC
			ldr			r0, [r0, (RCC_CFGR - STM_RCC)]
			
			@ AHB prescaler
			tst			r0, #(1 << 7)
			beq			0f
			ubfx		r1, r0, #4, #3
			tst			r1, #(1 << 2)
			ite			eq
			addeq		r1, #1
			addne		r1, #2
			lsrs		r2, r1
			
			@ Determine the system clock source
0:			tst			r0, #(1 << 3)
			beq			1f
			
			@ PLL is used as the system clock
			ubfx		r1, r0, #18, #4
			adds		r1, #2
			muls		r2, r1
			ubfx		r1, r0, #16, #2
			cmp			r1, #0x01
			it			ne
			lsrne		r2, #1
			
			@ Store result in RAM and return
1:			ldr			r0, =SystemClock
			str			r2, [r0, #0]
			bx			lr

			


			
@-----------------------------------------------------------@
@ SystemDelayMs												@
@-----------------------------------------------------------@
@															@
@ This function waits a specified number of milliseconds	@
@ (value of 0 equals 2^32!) and is only correct for a core	@
@ clock frequency of 72MHz and uninterrupted execution.		@
@															@
@ > Arguments:			r0: number of milliseconds to wait	@
@ > Return values:		<none>								@
@ > Changed registers:	r0, r1								@
@ > Changed variables:	<none>								@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			.section	.text.SystemDelayMs
			.type		SystemDelayMs, "function"
SystemDelayMs:

			@--- ~1ms ---@
0:			movw		r1, 23999
1:			subs		r1, 1
			bne			1b
			@--- ~1ms ---@
			subs		r0, 1
			bne			0b
			bx			lr

			
			
			
			
@-----------------------------------------------------------@
@ SystemDisablePeripheral									@
@ SystemEnablePeripheral									@
@ SystemResetPeripheral										@
@-----------------------------------------------------------@
@															@
@ This function disables/enables/resets the peripheral.		@
@															@
@ > Arguments:			r0: peripheral (0...95)				@
@ > Return values:		<none>								@
@ > Changed registers:	r1, r2								@
@ > Changed variables:	<none>								@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			.section	.text.SystemDisablePeripheral
			.type		SystemDisablePeripheral, "function"
SystemDisablePeripheral:

			@ Disable the peripheral using the bitband alias
			ldr			r2, =(0x42000000 + 32 * (RCC_AHBENR - 0x40000000))
			movs		r1, #0
			str			r1, [r2, r0, LSL #2]
			bx			lr
			
			.section	.text.SystemEnablePeripheral
			.type		SystemEnablePeripheral, "function"
SystemEnablePeripheral:

			@ Enable the peripheral using the bitband alias
			ldr			r2, =(0x42000000 + 32 * (RCC_AHBENR - 0x40000000))
			movs		r1, #1
			str			r1, [r2, r0, LSL #2]
			bx			lr		
			
			.section	.text.SystemResetPeripheral
			.type		SystemResetPeripheral, "function"
SystemResetPeripheral:

			@ Reset the peripheral using the bitband alias
			ldr			r2, =(0x42000000 + 32 * (RCC_CIR - 0x40000000))
			movs		r1, #1
			str			r1, [r2, r0, LSL #2]
			movs		r1, #0
			str			r1, [r2, r0, LSL #2]
			bx			lr		
		



