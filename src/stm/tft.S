/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"tft.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Functions
			.global		TFT_Init
			.global		TFT_WriteMultipleRegisters
			.global		TFT_SetPixel
			.global		TFT_PrepareWindow
			.global		TFT_SetArea
			.global		TFT_SetLine
			.global		TFT_SetChar
			.global		TFT_SelectFont
			.global		TFT_PrintString

			@ Variables
			.global		TFT_Data
			.global		TFT_Color
			.global		TFT_CachedFont
			.global		TFT_CachedChar
			.global		TFT_FontInfo
			.global		TFT_FontWidth
			.global		TFT_FontHeight
			.global		TFT_CharHeight
			.global		TFT_FontFirstChar
			.global		TFT_FontCharCount
			.global		TFT_CharWidth
			.global		TFT_CacheWidth
			.global		TFT_CacheChar





@-----------------------------------------------------------@
@ TFT DATA + CACHES											@
@-----------------------------------------------------------@

			#ifdef		DEBUG
			.section	.bss.TFT_Data
			#else
			.section	.noinit.TFT_Data
			#endif
			.align		2
TFT_Data:

			@ uint8_t * TFT_CachedFont
			.type		TFT_CachedFont, "object"
TFT_CachedFont:
			.space		4

			@ uint16_t TFT_Color
			.type		TFT_Color, "object"
TFT_Color:
			.space		2

			@ uint8_t TFT_CachedChar
			.type		TFT_CachedChar, "object"
TFT_CachedChar:
			.space		1

TFT_FontInfo:

			@ uint8_t TFT_FontWidth
			.type		TFT_FontWidth, "object"
TFT_FontWidth:
			.space		1
			
			@ uint8_t TFT_FontHeight == TFT_CharHeight
			.type		TFT_FontHeight, "object"
			.type		TFT_CharHeight, "object"
TFT_FontHeight:
TFT_CharHeight:
			.space		1
			
			@ uint8_t TFT_FontFirstChar
			.type		TFT_FontFirstChar, "object"
TFT_FontFirstChar:
			.space		1

			@ uint8_t TFT_FontCharCount
			.type		TFT_FontCharCount, "object"
TFT_FontCharCount:
			.space		1

			@ uint8_t TFT_CharWidth
			.type		TFT_CharWidth, "object"
TFT_CharWidth:
			.space		1

			@ uint8_t TFT_CacheWidth[TFT_CACHE_WIDTH_SIZE]
			.type		TFT_CacheWidth, "object"
TFT_CacheWidth:
			.space		TFT_CACHE_WIDTH_SIZE

			@ uint8_t TFT_CacheChar[TFT_CACHE_CHAR_SIZE]
			.type		TFT_CacheChar, "object"
TFT_CacheChar:
			.space		TFT_CACHE_CHAR_SIZE





@-----------------------------------------------------------@
@ TFT INITIALIZATION										@
@-----------------------------------------------------------@
			
			.section	.text.TFT_Init
			.type		TFT_Init, "function"
TFT_Init:

			@ Save registers
			push		{r4, lr}

			@ Configure the reset pin
			movs		r0, GPIOE
			movs		r1, 1
			movs		r2, PIN_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure

			@ Configure FSMC pins and make them high
			ldr			r2, =_tft_init_data_pins_

			ldr			r0, =STM_GPIOD
			ldr			r1, [r0, GPIOx_CRL]
			ldmia		r2!, {r3, r4}
			bics		r1, r3
			orrs		r1, r4
			str			r1, [r0, GPIOx_CRL]
			ldr			r1, [r0, GPIOx_CRH]
			ldmia		r2!, {r3, r4}
			bics		r1, r3
			orrs		r1, r4
			str			r1, [r0, GPIOx_CRH]
			movw		r3, #0b1100111110110011
			str			r3, [r0, GPIOx_BSRR]

			add			r0, (STM_GPIOE - STM_GPIOD)
			ldr			r1, [r0, GPIOx_CRL]
			ldmia		r2!, {r3, r4}
			bics		r1, r3
			orrs		r1, r4
			str			r1, [r0, GPIOx_CRL]
			ldr			r1, [r0, GPIOx_CRH]
			ldmia		r2!, {r3, r4}
			bics		r1, r3
			orrs		r1, r4
			str			r1, [r0, GPIOx_CRH]
			movw		r3, #0b1111111110000000
			str			r3, [r0, GPIOx_BSRR]

			@ Enable FSMC clock
			movs		r0, PERIPHERAL_FSMC
			bl			SystemEnablePeripheral

			@ Configure FSMC module
			ldr			r0, =STM_FSMC_Bank1
			movw		r1, 0x00001058
			str			r1, [r0, (FSMC_Bank1_BTCR0 - STM_FSMC_Bank1)]
			ldr			r1, =0x10000502
			str			r1, [r0, (FSMC_Bank1_BTCR1 - STM_FSMC_Bank1)]
			ldr			r1, =0x0FFFFFFF
			str			r1, [r0, (FSMC_Bank1E_BWTR0 - STM_FSMC_Bank1)]

			@ Enable FSMC Bank1 SRAM Bank
			movw		r1, 0x00001059
			str			r1, [r0, (FSMC_Bank1_BTCR0 - STM_FSMC_Bank1)]

			@ Reset TFT
			ldr			r4, =STM_GPIOE
			movs		r2, #(1 << 1)
			movs		r0, SVC_ForceContextSwitchDelay
			str			r2, [r4, GPIOx_BRR]
			movs		r1, #5
			svc			SVC_ForceContextSwitch
			str			r2, [r4, GPIOx_BSRR]
			movs		r1, #15
			svc			SVC_ForceContextSwitch

			@ Configure display controller: ILI9331
			ldr			r0, =_tft_init_data_regs_
			movs		r1, #14
			bl			TFT_WriteMultipleRegisters
			cpy			r4, r0
			movs		r0, SVC_ForceContextSwitchDelay
			movs		r1, #20
			svc			SVC_ForceContextSwitch
			cpy			r0, r4
			movs		r1, #2
			bl			TFT_WriteMultipleRegisters
			cpy			r4, r0
			movs		r0, SVC_ForceContextSwitchDelay
			movs		r1, #5
			svc			SVC_ForceContextSwitch
			cpy			r0, r4
			movs		r1, #1
			bl			TFT_WriteMultipleRegisters
			cpy			r4, r0
			movs		r0, SVC_ForceContextSwitchDelay
			movs		r1, #5
			svc			SVC_ForceContextSwitch
			cpy			r0, r4
			movs		r1, #3
			bl			TFT_WriteMultipleRegisters
			cpy			r4, r0
			movs		r0, SVC_ForceContextSwitchDelay
			movs		r1, #5
			svc			SVC_ForceContextSwitch
			cpy			r0, r4
			movs		r1, #18
			bl			TFT_WriteMultipleRegisters

			@ Reset variables
			ldr			r0, =TFT_Data
			movs		r1, #0
			strb		r1, [r0, (TFT_CachedChar - TFT_Data)]
			subs		r1, #1
			str			r1, [r0, (TFT_CachedFont - TFT_Data)]

			@ Restore registers and return
			pop			{r4, pc}

_tft_init_data_regs_:

			@ 14 instructions, then 20 ms delay
			.byte		0xE7
			.short		0x1014
			.byte		0x01
			.short		0x0100
			.byte		0x02
			.short		0x0200
			.byte		0x03
			.short		0x1038
			.byte		0x08
			.short		0x0202
			.byte		0x09
			.short		0x0000
			.byte		0x0A
			.short		0x0000
			.byte		0x0C
			.short		0x0001
			.byte		0x0D
			.short		0x0000
			.byte		0x0F
			.short		0x0000
			.byte		0x10
			.short		0x0000
			.byte		0x11
			.short		0x0007
			.byte		0x12
			.short		0x0000
			.byte		0x13
			.short		0x0000

			@ 2 instructions, then 5 ms delay
			.byte		0x10
			.short		0x1690
			.byte		0x11
			.short		0x0227

			@ 1 instruction, then 5 ms delay
			.byte		0x12
			.short		0x000C

			@ 3 instructions, then 5 ms delay
			.byte		0x13
			.short		0x0800
			.byte		0x29
			.short		0x0011
			.byte		0x2B
			.short		0x000B

			@ 18 instructions, last turns display on
TFT_ResetWindow:
			.byte		TFT_WindowHorizontalRAMAddressStart
			.short		0
			.byte		TFT_WindowHorizontalRAMAddressEnd
			.short		240-1
			.byte		TFT_WindowVerticalRAMAddressStart
			.short		0
			.byte		TFT_WindowVerticalRAMAddressEnd
			.short		320-1
			.byte		TFT_RAMHorizontalAddressSet
			.short		0x0000
			.byte		TFT_RAMVerticalAddressSet
			.short		0x0000
			.byte		0x60
			.short		0xA700
			.byte		0x61
			.short		0x0001
			.byte		0x6A
			.short		0x0000
			.byte		0x80
			.short		0x0000
			.byte		0x81
			.short		0x0000
			.byte		0x82
			.short		0x0000
			.byte		0x83
			.short		0x0000
			.byte		0x84
			.short		0x0000
			.byte		0x85
			.short		0x0000
			.byte		0x90
			.short		0x0010
			.byte		0x92
			.short		0x0600
			.byte		0x07
			.short		0x0133

			.align		2
_tft_init_data_pins_:

			@ GPIOD and GPIOE
			.word		0xF0FF00FF
			.word		0xB0BB00BB
			.word		0xFF00FFFF
			.word		0xBB00BBBB
			.word		0xF0000000
			.word		0xB0000000
			.word		0xFFFFFFFF
			.word		0xBBBBBBBB





@-----------------------------------------------------------@
@ TFT READ/WRITE FUNCTIONS									@
@-----------------------------------------------------------@

			.section	.text.TFT_ReadWriteFunctions
			.type		TFT_WriteMultipleRegisters, "function"
TFT_WriteMultipleRegisters:

			@ Write the list of (index, data)-pairs
			push		{r4, lr}

			ldr			r3, =0x60000000
			ldr			r4, =0x60020000

0:			ldrb		r2, [r0], #1
			strh		r2, [r3]
			ldrh		r2, [r0], #2
			strh		r2, [r4]
			subs		r1, #1
			bne			0b

			pop			{r4, pc}





			.section	.text.TFT_ReadWriteFunctions
			.type		TFT_SetPixel, "function"
TFT_SetPixel:

			@ Arguments and return values:
			@ r0: x
			@ r1: y
			@ r2: unchanged
			@ r3: unchanged
			push		{r2, r3, r4, lr}

			ldr			r3, =0x60000000
			ldr			r4, =0x60020000

			movs		r2, TFT_RAMVerticalAddressSet
			strh		r2, [r3]
			strh		r0, [r4]
			movs		r2, TFT_RAMHorizontalAddressSet
			strh		r2, [r3]
			strh		r1, [r4]
			movs		r2, TFT_RAMData
			strh		r2, [r3]
			ldr			r2, =TFT_Data
			ldrh		r2, [r2, (TFT_Color - TFT_Data)]
			strh		r2, [r4]

			pop			{r2, r3, r4, pc}





			.section	.text.TFT_ReadWriteFunctions
			.type		TFT_PrepareWindow, "function"
TFT_PrepareWindow:
			
			@ Arguments and return values
			@ r0: xmin
			@ r1: xmax
			@ r2: ymin
			@ r3: ymax
			
			push		{r4, r5, r6, lr}

			ldr			r4, =0x60000000
			ldr			r5, =0x60020000

			@ Set window and cursor
			movs		r6, TFT_WindowVerticalRAMAddressStart
			strh		r6, [r4]
			strh		r0, [r5]
			movs		r6, TFT_WindowVerticalRAMAddressEnd
			strh		r6, [r4]
			strh		r1, [r5]
			movs		r6, TFT_WindowHorizontalRAMAddressStart
			strh		r6, [r4]
			strh		r2, [r5]
			movs		r6, TFT_WindowHorizontalRAMAddressEnd
			strh		r6, [r4]
			strh		r3, [r5]
			movs		r6, TFT_RAMVerticalAddressSet
			strh		r6, [r4]
			strh		r0, [r5]
			movs		r6, TFT_RAMHorizontalAddressSet
			strh		r6, [r4]
			strh		r2, [r5]
			movs		r6, TFT_RAMData
			strh		r6, [r4]

			pop			{r4, r5, r6, pc}
			
			
			
			
			
@-----------------------------------------------------------@
@ TFT DRAWING FUNCTIONS										@
@-----------------------------------------------------------@

			.section	.text.TFT_SetArea
			.type		TFT_SetArea, "function"
TFT_SetArea:

			@ Arguments
			@ r0: xmin
			@ r1: xmax
			@ r2: ymin
			@ r3: ymax

			push		{lr}

			@ Pass arguments to set window and cursor
			@ The arguments will also be returned!
			bl			TFT_PrepareWindow

			@ Calculate amount of data to be written
			subs		r1, r0
			adds		r1, #1
			subs		r3, r2
			adds		r3, #1
			muls		r1, r3

			@ Write color repeatedly
			ldr			r2, =0x60020000
			ldr			r0, =TFT_Data
			ldrh		r0, [r0, (TFT_Color - TFT_Data)]
0:			strh		r0, [r2]
			subs		r1, #1
			bne			0b

			@ Reset window
			ldr			r0, =TFT_ResetWindow
			movs		r1, #4
			bl			TFT_WriteMultipleRegisters
			
			pop			{pc}





			.section	.text.TFT_SetLine
			.type		TFT_SetLine, "function"
TFT_SetLine:

			@ Arguments
			@ r0: x1
			@ r1: y1
			@ r2: x2
			@ r3: y2

			@ Check for horizontal line
			cmp			r1, r3
			bne			0f
			cmp			r0, r2
			bhs			1f
			cpy			r1, r2
			cpy			r2, r3
			b			2f
1:			cpy			r1, r0
			cpy			r0, r2
			cpy			r2, r3
			b			2f

0:			@ Check for vertical line
			cmp			r0, r2
			bne			3f
			cmp			r1, r3
			bhs			4f
			cpy			r2, r1
			cpy			r1, r0
			b			2f
4:			cpy			r2, r3
			cpy			r3, r1
			cpy			r1, r0

2:			@ Draw horizontal/vertical line
			push		{lr}
			bl			TFT_SetArea
			pop			{pc}

3:			@ Other lines
			push		{r4, r5, r6, lr}

			@ r0: x
			@ r1: y
			@ r2: x endpoint
			@ r3: y endpoint
			@ r4: dx
			@ r5: dy
			subs		r4, r2, r0
			bpl			5f
			rsbs		r4, r4, #0
			cpy			r5, r0
			cpy			r0, r2
			cpy			r2, r5
			cpy			r5, r1
			cpy			r1, r3
			cpy			r3, r5
5:			subs		r5, r3, r1
			it			mi
			rsbmi		r5, r5, #0		
			
			@ Set first pixel
			bl			TFT_SetPixel
			
			@ Check for line under 45 degrees or more/less
			cmp			r4, r5
			blo			7f
			bhi			8f
			
			@ Line under 45 degrees
6:			cmp			r0, r2
			bhs			9f
			adds		r0, #1
			cmp			r1, r3
			ite			hi
			subhi		r1, #1
			addls		r1, #1
			bl			TFT_SetPixel
			b			6b
			
7:			@ Line with dx < dy
			lsls		r4, #1
			subs		r2, r4, r5
			subs		r5, r2, r5
			movs		r6, #1
			cmp			r1, r3
			it			hs
			rsbhs		r6, r6, #0

			@ Check if finished, otherwise update y (in opposite order!)
10:			cmp			r1, r3
			beq			9f
			adds		r1, r6
			cmp			r2, #0
			itee		lt
			addlt		r2, r4
			addge		r2, r5
			addge		r0, #1
			bl			TFT_SetPixel
			b			10b

8:			@ Line with dx > dy
			lsls		r5, #1
			subs		r6, r5, r4
			subs		r4, r6, r4
			cmp			r1, r3
			ite			lo
			movlo		r3, #1
			movhs		r3, #-1

			@ Check if finished, otherwise update
11:			cmp			r0, r2
			bhs			9f
			adds		r0, #1
			cmp			r6, #0
			itee		lt
			addlt		r6, r5
			addge		r6, r4
			addge		r1, r3
			bl			TFT_SetPixel
			b			11b

			@ Restore registers and return
9:			pop			{r4, r5, r6, pc}





@-----------------------------------------------------------@
@ TFT DRAWING FUNCTIONS (TEXT)								@
@-----------------------------------------------------------@

			.section	.text.TFT_SetChar
			.type		TFT_SetChar, "function"
TFT_SetChar:

			@ Prints the character loaded in TFT_CacheChar using TFT_CharWidth and TFT_CharHeight.
			@ First byte: MSB is topleft pixel, LSB is to the right.
			@ Hence, first scan from left to right, then top to bottom from given coordinate (topleft).
			
			@ Arguments:
			@ r0: x
			@ r1: y
			
			@ Save registers
			push		{r4, r5, r6, lr}
			
			@ Load the font width, height and RAM address
			ldr			r6, =TFT_Data
			ldrb		r4, [r6, (TFT_CharWidth - TFT_Data)]
			ldrb		r5, [r6, (TFT_CharHeight - TFT_Data)]

			@ Set window for the character (register contents unchanged)
			cpy			r2, r1
			subs		r1, r4, #1
			adds		r1, r0
			subs		r3, r5, #1
			adds		r3, r2
			bl			TFT_PrepareWindow

			@ Set certain pixels in this window, loading bytes of data
			@ r0: color to write
			@ r6: cache addres
			@ r2: pixel mask
			@ r3: pixels info
			@ r4: pixel counter
			@ r5: tft data register
			ldrh		r0, [r6, (TFT_Color - TFT_Data)]
			adds		r6, (TFT_CacheChar - TFT_Data)
			muls		r4, r5
			ldr			r5, =0x60020000
0:			ldrb		r3, [r6], #1
			movs		r2, #(1 << 7)
1:			tst			r3, r2
			iteee		ne
			strhne		r0, [r5]
			ldrheq		r1, [r5]
			ldrheq		r1, [r5]
			strheq		r1, [r5]
			subs		r4, #1
			beq			2f
			lsrs		r2, #1
			bne			1b
			b			0b

			@ Reset window
2:			ldr			r0, =TFT_ResetWindow
			movs		r1, #4
			bl			TFT_WriteMultipleRegisters

			@ Restore registers and return
			pop			{r4, r5, r6, pc}





			.section	.text.TFT_SelectFont
			.type		TFT_SelectFont, "function"
TFT_SelectFont:

			@ Arguments:
			@ r0: address of the font

			@ Correct address for SPI flash
			ldr			r1, =0x001FFFFF
			ands		r0, r1

			@ Only update the cached font info if necessary
			ldr			r1, =TFT_Data
			ldr			r2, [r1, (TFT_CachedFont - TFT_Data)]
			cmp			r0, r2
			it			eq
			bxeq		lr

			@ Save registers
			push		{r4, lr}

			@ Get exclusive access to the SPI module
			cpy			r4, r0
			movs		r0, #FLASH_SPI_BAUDRATE
			bl			SPI1_GetExclusiveAccess
			cpy			r0, r4

			@ Load the new font
			ldr			r4, =TFT_Data
			str			r0, [r4, (TFT_CachedFont - TFT_Data)]
			adds		r1, r4, (TFT_FontInfo - TFT_Data)
			movs		r2, #4
			bl			FLASH_ReadBytes

			@ Also load the width information in case of non-monospacing
			ldrb		r0, [r4, (TFT_FontWidth - TFT_Data)]
			cmp			r0, TFT_FONT_WIDTH_VARIABLE
			bne			1f
			ldr			r0, [r4, (TFT_CachedFont - TFT_Data)]
			adds		r0, #4
			adds		r1, r4, (TFT_CacheWidth - TFT_Data)
			ldrb		r2, [r4, (TFT_FontCharCount - TFT_Data)]
			bl			FLASH_ReadBytes

			@ Release exclusive access to the SPI module
1:			bl			SPI1_ClearExclusiveAccess

			@ Restore registers and return
			pop			{r4, pc}





			.section	.text.TFT_PrintString
			.type		TFT_PrintString, "function"
TFT_PrintString:

			@ Arguments:
			@ r0: x
			@ r1: y
			@ r2: text

			@ Save registers and arguments (stored last)
			push		{r0, r1, r2, r4, r5, r6, lr}
			ldr			r4, =TFT_Data
			adds		r5, r4, (TFT_CacheWidth - TFT_Data)

			@ Try to get exclusive access to the SPI module
			movs		r0, #FLASH_SPI_BAUDRATE
			bl			SPI1_GetExclusiveAccess

			@ Print until terminating null character encountered
0:			ldr			r0, [sp, #8]
			ldrb		r1, [r0], #1
			cbz			r1, 1f
			str			r0, [sp, #8]

			@ Only update character buffer if necessary
			ldrb		r0, [r4, (TFT_CachedChar - TFT_Data)]
			cmp			r1, r0
			beq			2f

			@ Check if the character exists, otherwise continue to the next character
			ldrb		r0, [r4, (TFT_FontFirstChar - TFT_Data)]
			subs		r3, r1, r0
			bmi			0b
			ldrb		r0, [r4, (TFT_FontCharCount - TFT_Data)]
			cmp			r3, r0
			bhs			0b

			@ Set new character
			strb		r1, [r4, (TFT_CachedChar - TFT_Data)]

			@ Check for mono-spacing font
			ldrb		r2, [r4, (TFT_FontWidth - TFT_Data)]
			cpy			r1, r2
			cmp			r2, TFT_FONT_WIDTH_VARIABLE
			it			eq
			ldrbeq		r2, [r5, r3]
			strb		r2, [r4, (TFT_CharWidth - TFT_Data)]
			cmp			r2, #0
			beq			0b

			@ Determine the number of bytes to read
			ldrb		r6, [r4, (TFT_CharHeight - TFT_Data)]
			muls		r2, r6
			subs		r2, #1
			lsrs		r2, #3
			adds		r2, #1

			@ Check for mono-spacing font
			cmp			r1, TFT_FONT_WIDTH_VARIABLE
			bne			3f

			@ ---------------------------------------------------
			@ Non-monospacing

			@ Determine the read address
			ldr			r1, [r4, (TFT_CachedFont - TFT_Data)]
			adds		r0, r1
			adds		r0, #4

			@ Accumulate upto desired character
4:			subs		r3, #1
			bmi			5f
			ldrb		r1, [r5, r3]
			muls		r1, r6
			beq			4b
			subs		r1, #1
			lsrs		r1, #3
			adds		r1, #1
			adds		r0, r1
			b			4b

			@ Read the character from external flash
5:			adds		r1, r5, (TFT_CacheChar - TFT_CacheWidth)
			bl			FLASH_ReadBytes
			b			2f

			@ ---------------------------------------------------
			@ Monospacing

			@ Determine the read address
3:			ldr			r0, [r4, (TFT_CachedFont - TFT_Data)]
			adds		r0, #4
			muls		r3, r2
			adds		r0, r3

			@ Read the character from external flash
			adds		r1, r5, (TFT_CacheChar - TFT_CacheWidth)
			bl			FLASH_ReadBytes

			@ Determine cursor increment
2:			ldrb		r2, [r4, (TFT_CharWidth - TFT_Data)]
			adds		r2, TFT_CHAR_SPACING

			@ Print the character and move the cursor
			ldmia		sp, {r0, r1}
			adds		r6, r0, r2
			bl			TFT_SetChar
			str			r6, [sp, #0]

			@ Continue to next character
			b			0b

			@ Release access to the SPI module
1:			bl			SPI1_ClearExclusiveAccess

			@ Restore registers and return
			pop			{r0, r1, r2, r4, r5, r6, pc}




