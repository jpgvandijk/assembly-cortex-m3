/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _PRINT_H_
#define _PRINT_H_

// Definitions
#define PRINT_CHARS				0
#define PRINT_SIGNED			1
#define PRINT_UNSIGNED			2
#define PRINT_HEX				3
#define PRINT_BINARY			4
#define PRINT_LASTFORMAT		4

#define PRINT_FORMAT_SHIFT		3
#define PRINT_FORMAT_MASK		0x07
#define PRINT_FORMAT(main,sub)	((sub << PRINT_FORMAT_SHIFT) | main)

#define PRINT_TEXT				PRINT_FORMAT(PRINT_CHARS, 0)
#define PRINT_CHARACTERS(n)		PRINT_FORMAT(PRINT_CHARS, n)
#define PRINT_SIGNED_32			PRINT_FORMAT(PRINT_SIGNED, 0)
#define PRINT_SIGNED_16			PRINT_FORMAT(PRINT_SIGNED, 1)
#define PRINT_SIGNED_8			PRINT_FORMAT(PRINT_SIGNED, 2)
#define PRINT_UNSIGNED_32		PRINT_FORMAT(PRINT_UNSIGNED, 0)
#define PRINT_UNSIGNED_16		PRINT_FORMAT(PRINT_UNSIGNED, 1)
#define PRINT_UNSIGNED_8		PRINT_FORMAT(PRINT_UNSIGNED, 2)
#define PRINT_HEX_32			PRINT_FORMAT(PRINT_HEX, 8)
#define PRINT_HEX_16			PRINT_FORMAT(PRINT_HEX, 4)
#define PRINT_HEX_8				PRINT_FORMAT(PRINT_HEX, 2)
#define PRINT_BINARY_32			PRINT_FORMAT(PRINT_BINARY, 31)
#define PRINT_BINARY_16			PRINT_FORMAT(PRINT_BINARY, 15)
#define PRINT_BINARY_8			PRINT_FORMAT(PRINT_BINARY, 7)

#ifndef __ASSEMBLER__

// Character printing function format
typedef void (*Printer)(char character);
typedef union {char * text; int8_t s8; int16_t s16; int32_t s32; uint8_t u8; uint16_t u16; uint32_t u32;} PrintArgument;

// Global functions
extern Printer Print (Printer function, uint32_t format, PrintArgument argument);

#endif//__ASSEMBLER__

#endif//_PRINT_H_
