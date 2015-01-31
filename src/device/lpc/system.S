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
			.global		SystemInitPeripheral





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
@ is initialized to 120 MHz, using an external 12 MHz OSC.	@
@ Flash access time is set accordingly.						@
@															@
@ > Arguments:			<none>								@
@ > Return values:		<none>								@
@ > Changed registers:	r0, r1, r2, r3						@
@ > Changed variables:	<none>								@
@ > Stack usage:		1									@
@-----------------------------------------------------------@

			@ Temporary register renaming
			rBaseLow	.req	r0
			rBaseHigh	.req	r1
			rValue		.req	r2
			rFeedAA		.req	r3
			rFeed55		.req	r4

			.section	.text.SystemInitClock
			.type		SystemInitClock, "function"
SystemInitClock:

			@ Save registers
			push		{r4, lr}

			@-----------------------------------------------------------@

			@ Use rBaseLow with FLASHCFG and PLL0CON, must be easily reloaded
			@ Use rBaseHigh once with SCS and later with CCLKCFG
			ldr			rBaseLow, =FLASHCFG
			add			rBaseHigh, rBaseLow, (SCS - FLASHCFG)

			@ HERE: 4MHz IRC divided by 1 as CPU clock

			@ Speedup flash access temporarily: 1 cycle, for up to 20 MHz
			ldr			rValue, [rBaseLow, (FLASHCFG - FLASHCFG)]
			bic			rValue, (0x0F << 12)
			str			rValue, [rBaseLow, (FLASHCFG - FLASHCFG)]

			@ Use rBaseLow with PLL0CON
			adds		rBaseLow, (PLL0CON - FLASHCFG)

			@ Enable the main oscillator, in frequency range 1MHz to 20MHz (12MHz)
			movs		rValue, ((0 << 4) | (1 << 5))
			str			rValue, [rBaseHigh]

			@ Wait for the main oscillator to be ready
0:			ldr			rValue, [rBaseHigh]
			tst			rValue, (1 << 6)
			beq			0b

			@ Use rBaseHigh with CCLKCFG
			subs		rBaseHigh, (SCS - CCLKCFG)

			@ Set PLL0 clock source: main oscillator
			movs		rValue, 0b01
			str			rValue, [rBaseHigh, (CLKSRCSEL - CCLKCFG)]

			@ HERE: 12MHz main oscillator divided by 1 as CPU clock

			@ Setup feed values
			movs		rFeedAA, 0xAA
			movs		rFeed55, 0x55

			@ Configure PLL0 (M = 120, N = 6)
			ldr			rValue, =(((6 - 1) << 16) | ((120 - 1) << 0))
			str			rValue, [rBaseLow, (PLL0CFG - PLL0CON)]
			str			rFeedAA, [rBaseLow, (PLL0FEED - PLL0CON)]
			str			rFeed55, [rBaseLow, (PLL0FEED - PLL0CON)]

			@ Enable PLL0
			movs		rValue, 0b01
			str			rValue, [rBaseLow, (PLL0CON - PLL0CON)]
			str			rFeedAA, [rBaseLow, (PLL0FEED - PLL0CON)]
			str			rFeed55, [rBaseLow, (PLL0FEED - PLL0CON)]

			@ Wait for PLL0 to lock
0:			ldr			rValue, [rBaseLow, (PLL0STAT - PLL0CON)]
			tst			rValue, (1 << 26)
			beq			0b

			@ Set clock divider (PLL0 clock : CPU clock = 4)
			movs		rValue, (4 - 1)
			str			rValue, [rBaseHigh, (CCLKCFG - CCLKCFG)]

			@ HERE: 12MHz main oscillator divided by 4 as CPU clock

			@ Use rBaseLow with FLASHCFG
			ldr			rBaseLow, =FLASHCFG

			@ Set flash access time: 5 cycles, for up to 120 MHz
			ldr			rValue, [rBaseLow, (FLASHCFG - FLASHCFG)]
			orr			rValue, ((5 - 1) << 12)
			str			rValue, [rBaseLow, (FLASHCFG - FLASHCFG)]

			@ Use rBaseLow with PLL0CON
			adds		rBaseLow, (PLL0CON - FLASHCFG)

			@ Now connect PLL0
			movs		rValue, 0b11
			str			rValue, [rBaseLow, (PLL0CON - PLL0CON)]
			str			rFeedAA, [rBaseLow, (PLL0FEED - PLL0CON)]
			str			rFeed55, [rBaseLow, (PLL0FEED - PLL0CON)]

			@ HERE: 480MHz PLL0 from main oscillator divided by 4 as CPU clock

			@ PLL0 will also be used to derive the USB clock (480MHz / 10 = 48MHz)
			movs		rValue, (10 - 1)
			str			rValue, [rBaseHigh, (USBCLKCFG - CCLKCFG)]

			@-----------------------------------------------------------@

			@ Restore registers and return
			pop			{r4, pc}
			@bx			lr

SystemInitClock_END:

			@ Destroy temporary register renaming
			.unreq		rBaseLow
			.unreq		rBaseHigh
			.unreq		rValue
			.unreq		rFeedAA
			.unreq		rFeed55

			@ Calculate function size
			.set		SystemInitClock_SIZE, SystemInitClock_END - SystemInitClock





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

			@ Temporary register renaming
			rValue		.req	r0
			rFreq		.req	r1
			rBase		.req	r2

			.section	.text.SystemGetClock
			.type		SystemGetClock, "function"
SystemGetClock:

			@ Save registers
			@push		{}

			@-----------------------------------------------------------@

			@ Setup register pointer
			ldr			rBase, =PLL0STAT

			@ Determine clock source frequency
			ldr			rValue, [rBase, (CLKSRCSEL - PLL0STAT)]
			and			rValue, 3
			ldr			rFreq, =4000000		@ Internal RC oscillator
			cmp			rValue, 1
			it			eq
			ldreq		rFreq, =12000000	@ Main oscillator
			cmp			rValue, 2
			it			eq
			movweq		rFreq, 32768		@ RTC oscillator

			@ Check if PLL0 is enabled and connected
			ldrb		rValue, [rBase, #3]
			and			rValue, 3
			cmp			rValue, 3
			bne			0f

			@ PLL0 is enabled and connected
			ldr			rValue, [rBase, #0]
			lsls		rValue, #1
			uxth		rValue, rValue
			adds		rValue, #2
			muls		rFreq, rValue

			ldrb		rValue, [rBase, #2]
			adds		rValue, #1
			udiv		rFreq, rFreq, rValue

0:			@ Divide by CPU clock divider (read word and extract byte for ldr range!)
			ldr			rValue, [rBase, (CCLKCFG - PLL0STAT)]
			uxtb		rValue, rValue
			adds		rValue, #1
			udiv		rFreq, rFreq, rValue

			@ Store result in RAM
			ldr			rBase, =SystemClock
			str			rFreq, [rBase, #0]

			@-----------------------------------------------------------@

			@ Restore registers and return
			@pop		{}
			bx			lr

SystemGetClock_END:

			@ Destroy temporary register renaming
			.unreq		rValue
			.unreq		rFreq
			.unreq		rBase

			@ Calculate function size
			.set		SystemGetClock_SIZE, SystemGetClock_END - SystemGetClock





@-----------------------------------------------------------@
@ SystemDelayMs												@
@-----------------------------------------------------------@
@															@
@ This function waits a specified number of milliseconds	@
@ (value of 0 equals 2^32!) and is only correct for a core	@
@ clock frequency of 120MHz and uninterrupted execution.	@
@															@
@ > Arguments:			r0: number of milliseconds to wait	@
@ > Return values:		<none>								@
@ > Changed registers:	r0, r1								@
@ > Changed variables:	<none>								@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			@ Temporary register renaming
			rArgument	.req	r0
			rCounter	.req	r1

			.section	.text.SystemDelayMs
			.type		SystemDelayMs, "function"
SystemDelayMs:

			@ Save registers
			@push		{}

			@-----------------------------------------------------------@

			@--- ~1ms ---@
0:			movw		rCounter, 39999
1:			subs		rCounter, 1
			bne			1b
			@--- ~1ms ---@
			subs		rArgument, 1
			bne			0b

			@-----------------------------------------------------------@

			@ Restore registers and return
			@pop		{}
			bx			lr

SystemDelayMs_END:

			@ Destroy temporary register renaming
			.unreq		rArgument
			.unreq		rCounter

			@ Calculate function size
			.set		SystemDelayMs_SIZE, SystemDelayMs_END - SystemDelayMs





@-----------------------------------------------------------@
@ SystemDisablePeripheral									@
@-----------------------------------------------------------@
@															@
@ This function disables the peripheral's clock (gated off) @
@ to conserve power using the PCONP register				@
@															@
@ > Arguments:			r0: peripheral (0...31)				@
@ > Return values:		<none>								@
@ > Changed registers:	r1, r2								@
@ > Changed variables:	<none>								@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			@ Temporary register renaming
			rPeripheral	.req	r0
			rBase		.req	r1
			rValue		.req	r2

			.section	.text.SystemDisablePeripheral
			.type		SystemDisablePeripheral, "function"
SystemDisablePeripheral:

			@ Save registers
			@push		{}

			@-----------------------------------------------------------@

			@ Use bit-band aliases of PCONP bits (base + 4 * bit)
			ldr			rBase, =(0x42000000 + 32 * (PCONP - 0x40000000))
			movs		rValue, #0
			str			rValue, [rBase, rPeripheral, LSL #2]

			@-----------------------------------------------------------@

			@ Restore registers and return
			@pop		{}
			bx			lr

SystemDisablePeripheral_END:

			@ Destroy temporary register renaming
			.unreq		rPeripheral
			.unreq		rBase
			.unreq		rValue

			@ Calculate function size
			.set		SystemDisablePeripheral_SIZE, SystemDisablePeripheral_END - SystemDisablePeripheral





@-----------------------------------------------------------@
@ SystemInitPeripheral										@
@-----------------------------------------------------------@
@															@
@ This function turns the power of a peripheral on and sets	@
@ the desired clock divider value.							@
@															@
@ > Arguments:			r0: peripheral (0...31)				@
@						r1: clock divider (0...3)			@
@ > Return values:		<none>								@
@ > Changed registers:	r0, r1, r2, r3						@
@ > Changed variables:	<none>								@
@ > Stack usage:		1									@
@-----------------------------------------------------------@

			@ Temporary register renaming
			rPeripheral	.req	r0
			rDivider	.req	r1
			rBase		.req	r2
			rValue		.req	r3
			rTemp		.req	r4

			.section	.text.SystemInitPeripheral
			.type		SystemInitPeripheral, "function"
SystemInitPeripheral:

			@ Save registers
			push		{r4, lr}

			@-----------------------------------------------------------@

			@ Enable clock (PCONP) using bit-band aliases of PCONP bits (base + 4 * bit)
			ldr			rBase, =(0x42000000 + 32 * (PCONP - 0x40000000))
			movs		rValue, #1
			str			rValue, [rBase, rPeripheral, LSL #2]

			@ Set clock divider (PCLKSEL0/PCLKSEL1) next, rPeripheral value may change now
			@ First determine the register address and bit numbers
			ldr			rBase, =PCLKSEL0
			cmp			rPeripheral, #15
			itt			hi
			addhi		rBase, #4
			subhi		rPeripheral, #16
			lsls		rPeripheral, #1

			@ Store rDivider value in rBase at bit rPeripheral (2 bits)
			movs		rTemp, 0b11
			lsls		rTemp, rPeripheral
			lsls		rDivider, rPeripheral
			ldr			rValue, [rBase]
			bics		rValue, rTemp
			orrs		rValue, rDivider
			str			rValue, [rBase]

			@-----------------------------------------------------------@

			@ Restore registers and return
			pop			{r4, pc}
			@bx			lr

SystemInitPeripheral_END:

			@ Destroy temporary register renaming
			.unreq		rPeripheral
			.unreq		rDivider
			.unreq		rBase
			.unreq		rValue

			@ Calculate function size
			.set		SystemInitPeripheral_SIZE, SystemInitPeripheral_END - SystemInitPeripheral




