/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _TFT_H_
#define _TFT_H_

// Includes
#include "stm32f103ve.h"
#include "kernel.h"
#include "flash.h"
#include "board.h"

// Configuration and definitions
#define TFT_CACHE_WIDTH_SIZE					96
#define TFT_CACHE_CHAR_SIZE						384		// max: tft area/25!
#define TFT_CHAR_SPACING						1
#define TFT_FONT_WIDTH_VARIABLE					0xFF

// Register definitions
#define TFT_RAMHorizontalAddressSet 			0x20
#define TFT_RAMVerticalAddressSet 				0x21
#define TFT_RAMData 							0x22
#define TFT_WindowHorizontalRAMAddressStart 	0x50
#define TFT_WindowHorizontalRAMAddressEnd 		0x51
#define TFT_WindowVerticalRAMAddressStart 		0x52
#define TFT_WindowVerticalRAMAddressEnd 		0x53

#ifndef __ASSEMBLER__

// Global variables
extern uint16_t TFT_Color;
extern uint8_t * TFT_CachedFont;
extern uint8_t TFT_CachedChar;
extern uint8_t TFT_FontWidth;
extern uint8_t TFT_FontHeight;
extern uint8_t TFT_FontFirstChar;
extern uint8_t TFT_FontCharCount;
extern uint8_t TFT_CharWidth;
extern uint8_t TFT_CharHeight;
extern uint8_t TFT_CacheWidth[];
extern uint8_t TFT_CacheChar[];

// Global functions
extern void TFT_Init (void);
#ifdef STM_BOARD_CUSTOM
extern void TFT_BacklightOn (void);
extern void TFT_BacklightOff (void);
#endif
extern void * TFT_WriteMultipleRegisters (void * list, uint32_t count);
extern void TFT_SetPixel (uint16_t x, uint16_t y);
extern void TFT_PrepareWindow (uint16_t xmin, uint16_t xmax, uint16_t ymin, uint16_t ymax);
extern void TFT_SetArea (uint16_t xmin, uint16_t xmax, uint16_t ymin, uint16_t ymax);
extern void TFT_SetLine (uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2);
extern void TFT_SetChar (uint16_t x, uint16_t y);
extern void TFT_SelectFont (uint8_t * font);
extern void TFT_PrintString (uint16_t x, uint16_t y, char * text);

#endif//__ASSEMBLER__

#endif//_TFT_H_
