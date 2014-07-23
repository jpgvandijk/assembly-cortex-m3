/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifdef STM

// Includes
#include <stdint.h>
#include "stm32f103ve.h"
#include "kernel.h"
#include "system.h"
#include "spi1.h"
#include "flash.h"
#include "tft.h"

// Includes (data)
#include "data/SystemFont.h"
#include "data/Consolas10.h"
#include "data/Arial12.h"
#include "data/ComicSansMS24.h"
#include "data/Calibri80Subset.h"

// Function prototypes
void TaskTFT (uint32_t arg);
void TaskTFTPerformance (uint32_t arg);

// Global variables
const KERNEL_TaskDescriptor TaskDescriptor_TaskTFT = {TaskTFT, 0, (KERNEL_MinimumTaskStackSpace + 64), 0, "TFT"};
const KERNEL_TaskDescriptor TaskDescriptor_TaskTFTPerformance = {TaskTFTPerformance, 0, (KERNEL_MinimumTaskStackSpace + 64), 1, "Prfmn"};

// Main
void tft_test (void)
{
	// Enable the DMA1
	SystemEnablePeripheral(PERIPHERAL_DMA1);
	
	// Init the FLASH chip and SPI module
	FLASH_Init();
	SPI1_Init();
	
	// Init kernel
	KERNEL_Init();

	// Create tasks
	KERNEL_AddTask(&TaskDescriptor_TaskTFT);
	KERNEL_AddTask(&TaskDescriptor_TaskTFTPerformance);

	// Start kernel (this function never returns)
	KERNEL_Start();
}

// TFT task
void TaskTFT (uint32_t arg)
{
	uint32_t i, j;
	
	TFT_Init();
	TFT_Color = 0xFFFF;
	TFT_SetArea(0, 319, 0, 239);
	
	TFT_Color = 0x0000;
	TFT_SetLine(102, 100, 197, 100);
	KERNEL_SVCForceContextSwitchDelay(250);
	TFT_SetLine(199, 102, 199, 197);
	KERNEL_SVCForceContextSwitchDelay(250);
	TFT_SetLine(197, 199, 102, 199);
	KERNEL_SVCForceContextSwitchDelay(250);
	TFT_SetLine(100, 197, 100, 102);
	KERNEL_SVCForceContextSwitchDelay(250);
	
	TFT_Color = 0xF000;
	TFT_SetLine(102, 102, 147, 147);
	KERNEL_SVCForceContextSwitchDelay(250);
	TFT_SetLine(197, 102, 152, 147);
	KERNEL_SVCForceContextSwitchDelay(250);
	TFT_SetLine(197, 197, 152, 152);
	KERNEL_SVCForceContextSwitchDelay(250);
	TFT_SetLine(102, 197, 147, 152);
	KERNEL_SVCForceContextSwitchDelay(250);
	
	TFT_Color = 0x000F;
	TFT_SetLine(102, 98, 147, 25);
	KERNEL_SVCForceContextSwitchDelay(250);
	TFT_SetLine(197, 98, 152, 25);
	KERNEL_SVCForceContextSwitchDelay(250);
	TFT_SetLine(201, 102, 225, 147);
	KERNEL_SVCForceContextSwitchDelay(250);
	TFT_SetLine(201, 197, 225, 152);
	KERNEL_SVCForceContextSwitchDelay(250);
	TFT_SetLine(197, 201, 152, 225);
	KERNEL_SVCForceContextSwitchDelay(250);
	TFT_SetLine(102, 201, 147, 225);
	KERNEL_SVCForceContextSwitchDelay(250);
	TFT_SetLine(98, 197, 25, 152);
	KERNEL_SVCForceContextSwitchDelay(250);
	TFT_SetLine(98, 102, 25, 147);
	KERNEL_SVCForceContextSwitchDelay(250);
	
	TFT_SelectFont(Consolas10);
	TFT_PrintString(10, 10, "Hello, world!");
	TFT_SelectFont(Arial12);
	TFT_PrintString(10, 30, "Hello, world!");
	TFT_SelectFont(ComicSansMS24);
	TFT_PrintString(10, 50, "Hello, world!");
	KERNEL_SVCForceContextSwitchDelay(2000);
	
	TFT_Color = 0xFFFF;
	TFT_SetArea(0, 319, 0, 239);
	TFT_Color = (0x1F << 11);
	TFT_SelectFont(Calibri80);
	TFT_PrintString(20, 20, "1.783");
	TFT_SelectFont(SystemFont);
	TFT_PrintString(20, 192, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
	TFT_PrintString(20, 208, "abcdefghijklmnopqrstuvwxyz");
	TFT_PrintString(20, 224, "0123456789!@#$%^&*()_+-=[]{}");
	KERNEL_SVCForceContextSwitchDelay(10000);
	
	while (1)
	{
		KERNEL_SVCForceContextSwitchDelay(10);
		TFT_Color = 0xFFFF;
		//TFT_SetArea(100, 200, 150, 150);
		for (i = 0; i < 320; i++)
			for (j = 0; j < 240; j++)
				TFT_SetPixel(i, j);
		KERNEL_SVCForceContextSwitchDelay(10);
		TFT_Color = 0x0000;
		//TFT_SetArea(100, 200, 150, 150);
		for (i = 0; i < 320; i++)
			for (j = 0; j < 240; j++)
				TFT_SetPixel(i, j);
	}
}

// Performance task
void TaskTFTPerformance (uint32_t arg)
{
	volatile uint32_t i = 0;
	while (1) i++;
}

#endif//STM
