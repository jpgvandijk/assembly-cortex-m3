/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"stm32f103ve.h"





@-----------------------------------------------------------@
@ main														@
@-----------------------------------------------------------@
@															@
@ This is the standard main function. It should never		@
@ return!													@
@ Processor mode: privileged thread using MSP				@
@															@
@-----------------------------------------------------------@

			.section	.text.main
			.global		main
			.type		main, "function"
main:
			@ Change core clock to 72 MHz
			bl			SystemInitClock
			bl			SystemGetClock

			@ Branch to the test application
			@bl			DEBUG_HeapTest
			bl			DEBUG_HeapTestMerge

			@ Enter an infinite loop in case the test application returns
			b			.




