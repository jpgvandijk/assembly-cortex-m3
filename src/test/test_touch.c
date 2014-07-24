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

// Includes (data)
#include "data/SystemFont.h"

// Structures
typedef struct {
	uint16_t x;
	uint16_t y;
} Coordinate_TypeDef;

// Function prototypes
void TaskTouchTFT (uint32_t arg);
void TaskTouch (uint32_t arg);
void EXTI9_5_IRQHandler (void);

// Global variables
KERNEL_TaskTableEntry * taskTouch;
const KERNEL_TaskDescriptor TaskDescriptor_TaskTouchTFT = {TaskTouchTFT, 0, (KERNEL_MinimumTaskStackSpace + 64), 1, "TFT"};
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

void TaskTouchTFT (uint32_t arg)
{
	// Local buffer
	Coordinate_TypeDef coordinate;
	Coordinate_TypeDef coordinate_old;
	uint32_t newdata;

	// Init the TFT (in task, since svc delays required)
	TFT_Init();

	// Clear the TFT
	TFT_Color = 0xFFFF;
	TFT_SetArea(0, 319, 0, 239);

	// Set a pixel for each touch measurement
	while (1)
	{
		QUEUE_Lock();
		if (QUEUE_IsNotEmpty())
		{
			coordinate = QUEUE_Receive();
			newdata = 1;
		}
		QUEUE_Unlock();

		if (newdata)
		{
			if ((coordinate.x == 0xFFFF) && (coordinate.y == 0xFFFF))
			{
				TFT_Color = 0xFFFF;
				TFT_SetArea(0, 319, 0, 239);
				newdata = 0;
			}
			else
			{
				if ((coordinate_old.x == 0xFFFF) && (coordinate_old.y == 0xFFFF))
					coordinate_old = coordinate;
				
				TFT_Color = 0x0000;
				TFT_SetLine(coordinate_old.x, coordinate_old.y, coordinate.x, coordinate.y);
				newdata = 0;
			}
			coordinate_old = coordinate;
		}
	}
}

void TaskTouch (uint32_t arg)
{
	// Local buffer
	Coordinate_TypeDef coordinate;
	uint16_t measurement[4];

	// Run every 10 ms
	while (1)
	{
		// Check if screen is touched
		while (*((volatile uint32_t *) GPIOB_IDR) & (1 << 6))
		{
			// Add special coordinate to the queue
			coordinate.x = 0xFFFF;
			coordinate.y = 0xFFFF;
			QUEUE_Lock();
			if (QUEUE_IsNotFull())
				QUEUE_Send(coordinate);
			QUEUE_Unlock();

			// Store reference to the task for auto wake-up
			taskTouch = KERNEL_TaskRunning;
			
			// Screen is not touched, block until touch interrupt occurs
			KERNEL_SVCIRQEnable(TOUCH_IRQ_NUMBER);

			// Block with 10s timeout
			KERNEL_SVCForceContextSwitchDelay(10000);

			// Task restarted by touch or time-out
			KERNEL_SVCIRQDisable(TOUCH_IRQ_NUMBER);
			
			// Remove reference
			taskTouch = 0;
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
		if ((pressure != 0) && (pressure < 28))
		{
			// Determine x coordinate
			coordinate.x = 320 - (measurement[1] - 250) / 11;
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

		// Every 10 ms
		// FIXME: can't use periodic, since time fucked up?
		KERNEL_SVCForceContextSwitchDelay(10);
	}
}

void TOUCH_IRQ_HANDLER (void)
{
	// Wake-up the touch task
	if (taskTouch != 0)
		KERNEL_AddTaskToReadyList(KERNEL_RemoveTaskFromDelayedList(taskTouch));
	
	// Clear flag
	*((volatile uint32_t *) EXTI_PR) = (1 << 6);
}




/*
while (1)
{
	// Measure touch
	int32_t x, y, pressure;
	int32_t x1, x2, y1, y2;
	char text[10];


	// Clear the TFT
	TFT_Color = 0xFFFF;
	TFT_SetArea(0, 319, 0, 239);
	TFT_Color = 0x0000;

	// Print measurement
	TFT_SelectFont(SystemFont);
	text[0] = 'x';
	text[1] = ':';
	text[2] = ' ';
	text[3] = ' ';
	text[4] = '0' + buffer[0] / 1000;
	text[5] = '0' + (buffer[0] % 1000) / 100;
	text[6] = '0' + (buffer[0] % 100) / 10;
	text[7] = '0' + (buffer[0] % 10);
	text[8] = 0;
	TFT_PrintString(100, 100, text);
	text[0] = 'y';
	text[1] = ':';
	text[2] = ' ';
	text[3] = ' ';
	text[4] = '0' + buffer[1] / 1000;
	text[5] = '0' + (buffer[1] % 1000) / 100;
	text[6] = '0' + (buffer[1] % 100) / 10;
	text[7] = '0' + (buffer[1] % 10);
	text[8] = 0;
	TFT_PrintString(100, 116, text);
	text[0] = 'z';
	text[1] = '1';
	text[2] = ':';
	text[3] = ' ';
	text[4] = '0' + buffer[2] / 1000;
	text[5] = '0' + (buffer[2] % 1000) / 100;
	text[6] = '0' + (buffer[2] % 100) / 10;
	text[7] = '0' + (buffer[2] % 10);
	text[8] = 0;
	TFT_PrintString(100, 132, text);
	text[0] = 'z';
	text[1] = '2';
	text[2] = ':';
	text[3] = ' ';
	text[4] = '0' + buffer[3] / 1000;
	text[5] = '0' + (buffer[3] % 1000) / 100;
	text[6] = '0' + (buffer[3] % 100) / 10;
	text[7] = '0' + (buffer[3] % 10);
	text[8] = 0;
	TFT_PrintString(100, 148, text);

	// Draw rectangle
	x = 320 - (buffer[1] - 250) / 11;
	if (x < 0) x = 0;
	if (x > 319) x = 319;
	y = (buffer[0] - 250) / 14;
	if (y < 0) y = 0;
	if (y > 239) y = 239;

	pressure = 0;
	if (buffer[2])
	{
		pressure = buffer[0] * 16;
		pressure *= buffer[3] - buffer[2];
		pressure /= buffer[2];
		pressure /= 4096;
	}

	if ((pressure > 0) && (pressure < 30))
	{
		x1 = x - pressure;
		if (x1 < 0)
			x1 = 0;
		x2 = x + pressure;
		if (x2 > 319)
			x2 = 319;
		y1 = y - pressure;
		if (y1 < 0)
			y1 = 0;
		y2 = y + pressure;
		if (y2 > 239)
			y2 = 239;
		
		TFT_Color = 0x0010;
		TFT_SetArea(x1, x2, y1, y2);
	}

	// Wait
	KERNEL_SVCForceContextSwitchDelay(50);
}
*/

#endif//STM
