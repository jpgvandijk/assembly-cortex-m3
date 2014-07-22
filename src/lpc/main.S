/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"lpc1769.h"





@-----------------------------------------------------------@
@ main														@
@-----------------------------------------------------------@
@															@
@ This is the standard main function. It should never		@
@ return!													@
@ Processor mode: privileged thread using MSP				@
@															@
@ > Arguments:			r0: power_cycle (0/1)				@
@-----------------------------------------------------------@

			.section	.text.main
			.global		main
			.type		main, "function"
main:
			@ Change core clock to 120 MHz
			bl			SystemInitClock
			bl			SystemGetClock

			@ Branch to the test application
			@bl			DEBUG_HeapTest
			@bl			DEBUG_HeapTestMerge
			@bl			onewire_test

			@ Enter an infinite loop in case the test application returns
			b			.





@-----------------------------------------------------------@
@ main_BOD													@
@-----------------------------------------------------------@
@															@
@ This is an alternate main function that will be called	@
@ when the device reset was triggered by a BOD. This		@
@ function should never return!								@
@															@
@ > Arguments:			<none>								@
@-----------------------------------------------------------@

			.section	.text.main_BOD
			.global		main_BOD
			.type		main_BOD, "function"
main_BOD:
			@ Infinite loop
			b			.





@-----------------------------------------------------------@
@ main_WDT													@
@-----------------------------------------------------------@
@															@
@ This is an alternate main function that will be called	@
@ when the device reset was triggered by a watchdog timer	@
@ timeout. This function should never return!				@
@															@
@ > Arguments:			<none>								@
@-----------------------------------------------------------@

			.section	.text.main_WDT
			.global		main_WDT
			.type		main_WDT, "function"
main_WDT:
			@ Infinite loop
			b			.




