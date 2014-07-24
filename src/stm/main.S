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

			@ Enable required GPIO
			movs		r0, PERIPHERAL_AFIO
			bl			SystemEnablePeripheral
			movs		r0, PERIPHERAL_IOPA
			bl			SystemEnablePeripheral
			movs		r0, PERIPHERAL_IOPB
			bl			SystemEnablePeripheral
			movs		r0, PERIPHERAL_IOPC
			bl			SystemEnablePeripheral
			movs		r0, PERIPHERAL_IOPD
			bl			SystemEnablePeripheral
			movs		r0, PERIPHERAL_IOPE
			bl			SystemEnablePeripheral

			@ Branch to the test application
			@bl			DEBUG_HeapTest
			@bl			DEBUG_HeapTestMerge
			@bl			onewire_test
			@bl			spi1_flash_test
			@bl			tft_test
			@bl			touch_test

			@ Enter an infinite loop in case the test application returns
			b			.




