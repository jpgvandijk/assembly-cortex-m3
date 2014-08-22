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

// Definitions
#define SDCARD_SPI_BAUDRATE_INIT		7
#define SDCARD_SPI_BAUDRATE				0

#define SDCARD_BLOCK_SIZE				512
#define SDCARD_BLOCK_SIZE_LOG			9

#define SDCARD_CRC_BYTE					0x95

#define SDCARD_CARD_DETECTION_PERIOD	500
#define SDCARD_CARD_DETECTION_DELAY		1000
#define SDCARD_INIT_DELAY_MS			2
#define SDCARD_INIT_DELAY_CYCLES		20
#define SDCARD_INIT_IDLE_DELAY_MS		10

#define SDCARD_READ_TOKEN_TIMEOUT		100000

#define SDCARD_COMMAND_TIMEOUT			10
#define SDCARD_COMMAND_TIMEOUT_RESPONSE	(-1)

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
extern void SDCARD_Read (uint32_t block);
extern void SDCARD_Write (uint32_t block);

// Global variables
extern uint8_t SDCARD_ReadBuffer[SDCARD_BLOCK_SIZE];
extern uint8_t SDCARD_WriteBuffer[SDCARD_BLOCK_SIZE];

#endif//__ASSEMBLER__

#endif//_SDCARD_H_
