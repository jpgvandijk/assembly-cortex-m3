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
#include "touch.h"
#include "tft.h"

// Definitions
#define TASK_TOUCH_PERIOD		20
#define ABS(x)					((x) < 0 ? (-(x)) : (x))

// Includes (data)
#include "data/SystemFont.h"

// Structures
typedef union {
	struct {
		uint16_t x;
		uint16_t y;
	};
	uint32_t signal;
} Coordinate_TypeDef;

// Function prototypes
void TaskTouchTFT (uint32_t arg);
void TaskTouch (uint32_t arg);
void EXTI9_5_IRQHandler (void);

// Global variables
KERNEL_TaskTableEntry * taskTouch;
const KERNEL_TaskDescriptor TaskDescriptor_TaskTouchTFT = {TaskTouchTFT, 0, (KERNEL_MinimumTaskStackSpace + 128), 1, "TFT"};
const KERNEL_TaskDescriptor TaskDescriptor_TaskTouch = {TaskTouch, 0, (KERNEL_MinimumTaskStackSpace + 64), 0, "Touch"};

/***********************************************************************************/
// Dedicated queue to send coordinates from touch task to tft task!

#define QUEUE_SIZE			50
struct {
	Coordinate_TypeDef	elements[QUEUE_SIZE];	// The actual queue
	uint8_t				tx_index;				// Points to where it can immediately write
	uint8_t				rx_index;				// Points to where it can immediately read
	uint8_t				lock;					// This structure may only be changed if access granted
} queue;

void QUEUE_Init (void) {
	queue.tx_index = 0;
	queue.rx_index = 0;
	queue.lock = 0;
}

void QUEUE_Lock (void) {
	while (KERNEL_GetExclusiveAccess(&queue.lock))
		KERNEL_SVCForceContextSwitchDelay(1);
}

void QUEUE_Unlock (void) {
	KERNEL_ClearExclusiveAccess(&queue.lock);
}

uint32_t QUEUE_IsNotFull (void) {
	if (queue.rx_index == 0)
		return (queue.tx_index != QUEUE_SIZE - 1);
	else
		return (queue.tx_index != queue.rx_index - 1);
}

uint32_t QUEUE_IsNotEmpty (void) {
	return (queue.tx_index != queue.rx_index);
}

void QUEUE_Send (Coordinate_TypeDef element) {
	queue.elements[queue.tx_index] = element;
	queue.tx_index++;
	if (queue.tx_index == QUEUE_SIZE)
		queue.tx_index = 0;
}

Coordinate_TypeDef QUEUE_Receive (void) {
	Coordinate_TypeDef coordinate = queue.elements[queue.rx_index];
	queue.rx_index++;
	if (queue.rx_index == QUEUE_SIZE)
		queue.rx_index = 0;
	return coordinate;
}

/***********************************************************************************/

// Main
void touch_test (void)
{
	// Enable the DMA1
	SystemEnablePeripheral(PERIPHERAL_DMA1);

	// Init the FLASH/TOUCH chip and SPI module
	FLASH_Init();
	TOUCH_Init();
	SPI1_Init();
	
	// Init queue to communicate coordinates
	QUEUE_Init();

	// Init kernel
	KERNEL_Init();

	// Create tasks
	KERNEL_AddTask(&TaskDescriptor_TaskTouchTFT);
	KERNEL_AddTask(&TaskDescriptor_TaskTouch);

	// Start kernel (this function never returns)
	KERNEL_Start();
}

void debug (char * text)
{
	TFT_Color = 0xFFFF;
	TFT_SetArea(0, 319, 0, 239);
	TFT_Color = 0x0000;
	TFT_SelectFont(SystemFont);
	TFT_PrintString(5, 5, text);
}

void TaskTouchTFT (uint32_t arg)
{
	// Local variables
	uint32_t action = 0;
	uint32_t newdata;
	uint32_t time;
	Coordinate_TypeDef coordinate, start, coordinate_old;

	// Init the TFT (in task, since svc delays required)
	TFT_Init();

	// Clear the TFT
	TFT_Color = 0xFFFF;
	TFT_SetArea(0, 319, 0, 239);

	// Analyse the touch measurements
	while (1)
	{
		// Get new data
		newdata = 0;
		do {
			QUEUE_Lock();
			if (QUEUE_IsNotEmpty()) {
				coordinate = QUEUE_Receive();
				newdata = 1;
			}
			QUEUE_Unlock();
		} while (!newdata);

		if ((newdata) && (coordinate.signal != 0xFFFFFFFF)) {
			if (coordinate_old.signal == 0xFFFFFFFF)
				coordinate_old = coordinate;
			
			// Draw line
			TFT_Color = 0x0000;
			TFT_SetLine(coordinate_old.x, coordinate_old.y, coordinate.x, coordinate.y);
		}
		coordinate_old = coordinate;
		
		// End of touch?
		if (coordinate.signal == 0xFFFFFFFF)
		{
			uint32_t newaction = 0;
			
			// Report result
			if (action == 100) {
				debug("");
			} else if (action == 1) {
				if (time >= 1) {
					//debug("Tap or double-tap");
					KERNEL_SVCForceContextSwitchDelay(250);
					newdata = 0;
					QUEUE_Lock();
					if (QUEUE_IsNotEmpty()) {
						coordinate = QUEUE_Receive();
						newdata = 1;
					}
					QUEUE_Unlock();
					
					int16_t dx = coordinate.x - start.x;
					int16_t dy = coordinate.y - start.y;
					if ((newdata) && (ABS(dx) < 25) && (ABS(dy) < 25)) {
						debug("Double-tap");
						newaction = 101;
					}
					else
						debug("Tap");
				}
			} else if (action == 2) {
				debug("End of hold");
			} else if (action == 3) {
				debug("Swype right");
			} else if (action == 4) {
				debug("Swype left");
			} else if (action == 5) {
				debug("Swype down");
			} else if (action == 6) {
				debug("Swype up");
			}
			
			// Start new analysis unless double-tap
			action = newaction;
		}

		// First touch?
		else if (action == 0)
		{
			// Set variables
			start = coordinate;
			time = 0;
			action = 1;
		}

		// Continued touch
		else
		{
			// Determine displacement and increase time
			int16_t dx = coordinate.x - start.x;
			int16_t dy = coordinate.y - start.y;
			time++;

			if ((action == 1) || (action == 2))
			{
				//  Check if still at this position
				if ((ABS(dx) < 25) && (ABS(dy) < 25)) {
					start.x = (start.x + coordinate.x) >> 1;
					start.y = (start.y + coordinate.y) >> 1;
					if ((action == 1) && (time > 50)) {
						debug("Start of hold");
						action = 2;
					}
				} else {
					if (action == 2) {
						debug("End of hold");
						action = 100;
					} else {
						if (ABS(dx) > ABS(dy)) {
							if (dx > 0) {
								action = 3;
							} else {
								action = 4;
							}
						} else {
							if (dy > 0) {
								action = 5;
							} else {
								action = 6;
							}
						}
					}
				}
			} else if (action == 3) {
				if (!(dx > 2*ABS(dy))) {
					action = 100;
				}
			} else if (action == 4) {
				if (!(-dx > 2*ABS(dy))) {
					action = 100;
				}
			} else if (action == 5) {
				if (!(dy > 2*ABS(dx))) {
					action = 100;
				}
			} else if (action == 6) {
				if (!(-dy > 2*ABS(dx))) {
					action = 100;
				}
			}
		}
	}
}

void TaskTouch (uint32_t arg)
{
	// Local buffer
	Coordinate_TypeDef coordinate;
	uint16_t measurement[4];
	//uint64_t time;

	// Run every TASK_TOUCH_PERIOD ms
	while (1)
	{
		// Check if screen is no longer touched
		if (*((volatile uint32_t *) GPIOB_IDR) & (1 << 6))
		{
			// Signal end of touching and start measuring the untouched time
			coordinate.signal = 0xFFFFFFFF;
			QUEUE_Lock();
			if (QUEUE_IsNotFull())
				QUEUE_Send(coordinate);
			QUEUE_Unlock();
			//time = KERNEL_Time;

			// Auto wake-up when touch interrupt occurs (no time-out)
			taskTouch = KERNEL_TaskRunning;
			KERNEL_SVCIRQEnable(TOUCH_IRQ_NUMBER);
			KERNEL_SVCForceContextSwitchIndefinitely();
			KERNEL_SVCIRQDisable(TOUCH_IRQ_NUMBER);
			taskTouch = 0;
			
			// Signal the untouched time (normalized)
			//coordinate.signal = ((uint32_t)(KERNEL_Time - time) / TASK_TOUCH_PERIOD);
			//QUEUE_Lock();
			//if (QUEUE_IsNotFull())
			//	QUEUE_Send(coordinate);
			//QUEUE_Unlock();
		}

		// Screen is touched, measure x, y, z1 and z2
		TOUCH_Read(measurement, 4);

		// Determine the pressure
		uint32_t pressure = 0;
		if ((measurement[2] != 0) && (measurement[3] > measurement[2]))
		{
			pressure = measurement[0] * 16;
			pressure *= measurement[3] - measurement[2];
			pressure /= measurement[2];
			pressure /= 4096;
		}

		// Only update coordinate if pressure is high enough
		if ((pressure != 0) && (pressure < 30))
		{
			// Only update if coordinates within bounds
			if ((measurement[1] >= 250) && (measurement[0] >= 250) && (measurement[1] < 3770) && (measurement[0] < 3610))
			{		
				// Determine x coordinate
				coordinate.x = 319 - (measurement[1] - 250) / 11;
				if (coordinate.x < 0)
					coordinate.x = 0;
				if (coordinate.x > 319)
					coordinate.x = 319;

				// Determine y coordinate
				coordinate.y = (measurement[0] - 250) / 14;
				if (coordinate.y < 0)
					coordinate.y = 0;
				if (coordinate.y > 239)
					coordinate.y = 239;

				// Add coordinate to the queue
				QUEUE_Lock();
				if (QUEUE_IsNotFull())
					QUEUE_Send(coordinate);
				QUEUE_Unlock();
			}
		}

		// Run every TASK_TOUCH_PERIOD ms
		KERNEL_SVCForceContextSwitchPeriodic(TASK_TOUCH_PERIOD);
	}
}

void TOUCH_IRQ_HANDLER (void)
{
	// Wake-up the touch task
	if (taskTouch != 0)
		KERNEL_AddTaskToReadyList(taskTouch);
	
	// Clear flag
	*((volatile uint32_t *) EXTI_PR) = (1 << 6);
}

#endif//STM
