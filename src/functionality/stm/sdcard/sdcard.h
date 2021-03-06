/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _SDCARD_H_
#define _SDCARD_H_

// Includes
#include "stm32f103ve.h"
#include "kernel.h"
#include "config.h"

#ifdef _USE_SDCARD_

// Definitions
#define SDCARD_BLOCK_SIZE				512
#define SDCARD_BLOCK_SIZE_LOG			9
#define SDCARD_NO_BLOCK_CACHED			(-1)
#define SDCARD_CRC_BYTE					0x95
#define SDCARD_WRITE_TOKEN				0xFE
#define SDCARD_COMMAND_TIMEOUT_RESPONSE	(-1)

// Commands
#define SDCARD_CMD0						((0 << 8) | (0b01 << 6) | 0)
#define SDCARD_CMD1						((0 << 8) | (0b01 << 6) | 1)
#define SDCARD_ACMD41					((0 << 8) | (0b01 << 6) | 41)
#define SDCARD_CMD8						((4 << 8) | (0b01 << 6) | 8)
#define SDCARD_CMD9						((0 << 8) | (0b01 << 6) | 9)
#define SDCARD_CMD10					((0 << 8) | (0b01 << 6) | 10)
#define SDCARD_CMD12					((0 << 8) | (0b01 << 6) | 12)
#define SDCARD_CMD16					((0 << 8) | (0b01 << 6) | 16)
#define SDCARD_CMD17					((0 << 8) | (0b01 << 6) | 17)
#define SDCARD_CMD18					((0 << 8) | (0b01 << 6) | 18)
#define SDCARD_CMD23					((0 << 8) | (0b01 << 6) | 23)
#define SDCARD_ACMD23					((0 << 8) | (0b01 << 6) | 23)
#define SDCARD_CMD24					((0 << 8) | (0b01 << 6) | 24)
#define SDCARD_CMD25					((0 << 8) | (0b01 << 6) | 25)
#define SDCARD_CMD55					((0 << 8) | (0b01 << 6) | 55)
#define SDCARD_CMD58					((4 << 8) | (0b01 << 6) | 58)

#ifndef __ASSEMBLER__

// Global functions
extern void SDCARD_Init (void);
extern uint32_t SDCARD_Command (uint32_t command, uint32_t argument);
extern void SDCARD_Delay (uint32_t delay);
extern void SDCARD_Read (uint32_t block, uint8_t * buffer);
extern void SDCARD_Write (uint32_t block, uint8_t * buffer_with_token);
extern void SDCARD_Error (void);

#endif//__ASSEMBLER__

#endif//_USE_SDCARD_

#endif//_SDCARD_H_
