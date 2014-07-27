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
const KERNEL_TaskDescriptor TaskDescriptor_TaskTouchTFT = {TaskTouchTFT, 0, (KERNEL_MinimumTaskStackSpace + 96), 1, "TFT"};

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
	// Local variables
	TouchMessage_TypeDef touch;
	uint16_t x_old, y_old;

	// Init the TFT (in task, since svc delays required)
	TFT_Init();
	TFT_Color = 0xFFFF;
	TFT_SetArea(0, 319, 0, 239);
	TFT_SelectFont(SystemFont);

	// Show touch results
	while (1)
	{
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
			TFT_SetPixel(touch.x, touch.y);
			break;
		case TOUCH_TYPE_TAP_DOUBLE:
			TFT_PrintString(5, 5, "Double Tap");
			TFT_SetPixel(touch.x, touch.y);
			break;
		case TOUCH_TYPE_HOLD_BEGIN:
			TFT_PrintString(5, 5, "Hold (begin)");
			TFT_SetPixel(touch.x, touch.y);
			break;
		case TOUCH_TYPE_HOLD_END:
			TFT_PrintString(5, 5, "Hold (end)");
			TFT_SetPixel(touch.x, touch.y);
			break;
		case TOUCH_TYPE_SWIPE_RIGHT:
			TFT_PrintString(5, 5, "Swype right");
			TFT_SetLine(0, touch.y, touch.x_speed, touch.y);
			break;
		case TOUCH_TYPE_SWIPE_LEFT:
			TFT_PrintString(5, 5, "Swype left");
			TFT_SetLine(0, touch.y, touch.x_speed, touch.y);
			break;
		case TOUCH_TYPE_SWIPE_DOWN:
			TFT_PrintString(5, 5, "Swype down");
			TFT_SetLine(touch.x, 0, touch.x, touch.y_speed);
			break;
		case TOUCH_TYPE_SWIPE_UP:
			TFT_PrintString(5, 5, "Swype up");
			TFT_SetLine(touch.x, 0, touch.x, touch.y_speed);
			TaskTouch_Mode = TASK_TOUCH_MODE_RAW;		// Change mode!
			break;
		case TOUCH_TYPE_RAW:
			if (x_old != 0xFFFF)
				TFT_SetLine(x_old, y_old, touch.x, touch.y);
			x_old = touch.x;
			y_old = touch.y;
			break;
		case TOUCH_TYPE_RAW_END:
			x_old = 0xFFFF;
			TaskTouch_Mode = TASK_TOUCH_MODE_ANALYSE;	// Change mode!
			break;
		default:
			TFT_PrintString(5, 5, "---");
			break;
		}
	}
}

#endif//STM
