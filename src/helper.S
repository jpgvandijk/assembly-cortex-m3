/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"helper.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Functions
			.global		NumberToBitInWord
			.global		NumberTo2BitsInWord
			.global		NumberTo4BitsInWord





@-----------------------------------------------------------@
@ NumberToBitInWord											@
@ NumberTo2BitsInWord										@
@ NumberTo4BitsInWord										@
@-----------------------------------------------------------@
@															@
@ These functions calculate the bit number (lsb) in a word	@
@ and the word address offset, given any number.			@
@															@
@ >> For example, number 62 results in:						@
@															@
@ NumberToBitInWord:	bit 30								@
@						offset 4 bytes (1 word)				@
@ NumberTo2BitsInWord:	bit 28 (: 29)						@
@						offset 12 bytes (3 words)			@
@ NumberTo4BitsInWord:	bit 24 (: 27)						@
@						offset 28 bytes (7 words)			@
@															@
@ > Arguments:			r0: number							@
@ > Return values:		r0: bit number						@
@						r1: address offset					@
@ > Changed registers:	r0, r1								@
@ > Changed variables:	<none>								@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			.section	.text.NumberToBitInWord
			.type		NumberToBitInWord, "function"
			.type		NumberTo2BitsInWord, "function"
			.type		NumberTo4BitsInWord, "function"

NumberTo4BitsInWord:	@ As if the number was four times as big
			lsls		r0, r0, #1

NumberTo2BitsInWord:	@ As if the number was twice as big
			lsls		r0, r0, #1

NumberToBitInWord:		@ Calculate bit number and address offset
			bic			r1, r0, #31		@ r1 = r0 & ~0b11111
			lsrs		r1, r1, #3		@ r1 = (r1 >> 5) * 4
			and			r0, r0, #31		@ r0 = r0 &  0b11111
			bx			lr




