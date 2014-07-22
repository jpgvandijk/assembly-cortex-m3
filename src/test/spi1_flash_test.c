/************************************************************************************
*
* Author: J.P.G. van Dijk
*
* N.B.: the SPI1 functions are actually to be used with the kernel. When exclusive
* access can not be granted other tasks continue. For the sake of simplicity the
* kernel is not started here!
*
************************************************************************************/

#ifdef STM

// Includes
#include <stdint.h>
#include "stm32f103ve.h"
#include "system.h"
#include "spi1.h"
#include "flash.h"

// Linker script
extern uint32_t __ext_StartAddress;

// Flash memory
uint8_t data[8] __attribute__ ((section (".ext"))) = { 7, 6, 5, 4, 3, 2, 1, 0 };

// Buffers
uint8_t buffer1[4];
uint8_t buffer2[16];
uint8_t buffer3;

void spi1_flash_test (void)
{
	// Enable the DMA1
	SystemEnablePeripheral(PERIPHERAL_DMA1);
	
	// Init the FLASH chip and SPI module
	FLASH_Init();
	SPI1_Init();

	// Get exclusive access to the SPI module
	SPI1_GetExclusiveAccess(FLASH_SPI_BAUDRATE);
	
	// Read data from the FLASH
	FLASH_ReadBytes(0, buffer1, 1);
	FLASH_ReadBytes(data - __ext_StartAddress, buffer2, 16);
	buffer3 = FLASH_ReadByte(0);

	// Clear access to the module
	SPI1_ClearExclusiveAccess();
}

#endif//STM
