/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"print.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Functions
			.global		Print





@-----------------------------------------------------------@
@ PRINT FUNCTION											@
@-----------------------------------------------------------@

			@ Private helper buffer
			.section	.noinit.PrintBuffer
			.type		PrintBuffer, "object"
PrintBuffer:
			.space		9

			.section	.text.Print
			.type		Print, "function"
Print:
			@ Arguments:
			@ r0: character printing function
			@ r1: format
			@ r2: argument

			@ Save registers
			push		{r4, r5, r6, lr}
			cpy			r4, r0

			@ Determine argument format
			ands		r3, r1, PRINT_FORMAT_MASK
			cmp			r3, PRINT_LASTFORMAT
			bhi			_print_exit_
			tbb			[pc, r3]
_print_format_table_:
			.byte		((_print_text_ - _print_format_table_) / 2)
			.byte		((_print_signed_ - _print_format_table_) / 2)
			.byte		((_print_unsigned_ - _print_format_table_) / 2)
			.byte		((_print_hex_ - _print_format_table_) / 2)
			.byte		((_print_binary_ - _print_format_table_) / 2)
			.align		1

_print_text_:

			@ Determine termination type
			lsrs		r5, r1, PRINT_FORMAT_SHIFT
			cpy			r6, r2
			cbz			r5, _print_text_null_terminated_

			@ Print certain number of characters
0:			ldrb		r0, [r6], #1
			blx			r4
			subs		r5, #1
			bne			0b
			b			_print_exit_

_print_text_null_terminated_:

			@ Print null terminated string
			ldrb		r0, [r6], #1
			cbz			r0, _print_exit_
			blx			r4
			b			_print_text_null_terminated_

_print_signed_:

			@ Sign extend
			lsrs		r1, PRINT_FORMAT_SHIFT
			cbz			r1, 1f
			cmp			r1, #1
			ite			eq
			sxtheq		r2, r2
			sxtbne		r2, r2
1:			negs		r5, r2
			ble			_print_unsigned_
			movs		r0, '-'
			blx			r4
			movs		r2, r5

_print_unsigned_:

			@ Print the unsigned number in r2 using function in r4
			ldr			r6, =PrintBuffer
			cpy			r5, r6
			movs		r1, #10
			cpy			r0, r2
2:			udiv		r2, r1
			mls			r0, r2, r1, r0
			adds		r0, '0'
			strb		r0, [r6], #1
			movs		r0, r2
			bne			2b
			b			_print_buffer_

_print_hex_:

			@ Convert nibbles, number of nibbles is coded in the format
			ldr			r6, =PrintBuffer
			cpy			r5, r6
			lsrs		r1, PRINT_FORMAT_SHIFT
3:			ands		r0, r2, #0x0F
			lsrs		r2, #4
			cmp			r0, #10
			ite			lo
			addlo		r0, '0'
			addhs		r0, ('A' - 10)
			strb		r0, [r6], #1
			subs		r1, #1
			bne			3b

_print_buffer_:

			@ Print from r6 to r5
4:			ldrb		r0, [r6, #-1]!
			blx			r4
			cmp			r5, r6
			bne			4b
			b			_print_exit_

_print_binary_:

			@ Without print buffer, since highly inefficient for 32-bit numbers
			lsrs		r1, PRINT_FORMAT_SHIFT
			movs		r5, #1
			lsls		r5, r1
			cpy			r6, r2
5:			tst			r5, r6
			ite			eq
			moveq		r0, '0'
			movne		r0, '1'
			blx			r4
			lsrs		r5, #1
			bne			5b

_print_exit_:

			@ Restore registers and return the function pointer
			cpy			r0, r4
			pop			{r4, r5, r6, pc}




