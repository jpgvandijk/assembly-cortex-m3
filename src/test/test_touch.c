/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifdef STM

// Includes
#include <stdint.h>
#include "cortex_m3.h"
#include "stm32f103ve.h"
#include "kernel.h"
#include "system.h"
#include "spi1.h"
#include "flash.h"
#include "tft.h"
#include "task_touch.h"

// Includes (data)
#include "data/SystemFont.h"

// Function prototypes
void TaskTouchTFT (uint32_t arg);

// Global variables
const KERNEL_TaskDescriptor TaskDescriptor_TaskTouchTFT = {TaskTouchTFT, 0, (KERNEL_MinimumTaskStackSpace + 64), 1, "TFT"};

// Main
void touch_test (void)
{
	// Enable the DMA1
	SystemEnablePeripheral(PERIPHERAL_DMA1);

	// Init the FLASH chip and SPI module
	FLASH_Init();
	SPI1_Init();

	// Init the TOUCH chip and queue to communicate touch messages
	TaskTouch_Init();

	// Init kernel
	KERNEL_Init();

	// Create tasks
	KERNEL_AddTask(&TaskDescriptor_TaskTouchTFT);
	KERNEL_AddTask(&TaskDescriptor_TaskTouch);

	// Start kernel (this function never returns)
	KERNEL_Start();
}

void TaskTouchTFT (uint32_t arg)
{
	// Init the TFT (in task, since svc delays required)
	TFT_Init();
	TFT_Color = 0xFFFF;
	TFT_SetArea(0, 319, 0, 239);
	TFT_SelectFont(SystemFont);

	// Show touch results
	while (1)
	{
		// Local variables
		TouchMessage_TypeDef touch;

		// Wait for new data
		while (!TaskTouch_Receive(&touch));

		// Print result
		TFT_Color = 0xFFFF;
		TFT_SetArea(0, 319, 0, 239);
		TFT_Color = 0x0000;
		switch (touch.type)
		{
		case TOUCH_TYPE_TAP:
			TFT_PrintString(5, 5, "Tap");
			break;
		case TOUCH_TYPE_TAP_DOUBLE:
			TFT_PrintString(5, 5, "Double Tap");
			break;
		case TOUCH_TYPE_HOLD_BEGIN:
			TFT_PrintString(5, 5, "Hold (begin)");
			break;
		case TOUCH_TYPE_HOLD_END:
			TFT_PrintString(5, 5, "Hold (end)");
			break;
		case TOUCH_TYPE_SWIPE_RIGHT:
			TFT_PrintString(5, 5, "Swype right");
			break;
		case TOUCH_TYPE_SWIPE_LEFT:
			TFT_PrintString(5, 5, "Swype left");
			break;
		case TOUCH_TYPE_SWIPE_DOWN:
			TFT_PrintString(5, 5, "Swype down");
			break;
		case TOUCH_TYPE_SWIPE_UP:
			TFT_PrintString(5, 5, "Swype up");
			break;
		default:
			TFT_PrintString(5, 5, "---");
			break;
		}
	}
}

#endif//STM
