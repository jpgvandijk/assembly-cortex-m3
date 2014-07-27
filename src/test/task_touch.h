/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _TASK_TOUCH_H_
#define _TASK_TOUCH_H_

// Includes
#include <stdint.h>
#include "stm32f103ve.h"
#include "kernel.h"
#include "touch.h"

// Structures
typedef struct
{
	uint8_t type;
	union
	{
		uint16_t x;
		uint16_t x_speed;
	};
	union
	{
		uint16_t y;
		uint16_t y_speed;
	};
} TouchMessage_TypeDef;

// Definitions
#define TASK_TOUCH_STACK_SIZE				(KERNEL_MinimumTaskStackSpace + 64)
#define TASK_TOUCH_PRIORITY					0
#define TASK_TOUCH_PERIOD					20
#define TASK_TOUCH_QUEUE_SIZE				32
#define TASK_TOUCH_LOCK_TIMEOUT				5

#define TASK_TOUCH_MODE_ANALYSE				0
#define TASK_TOUCH_MODE_RAW					1

#define TOUCH_TAP_MIN_TIME					1
#define TOUCH_DOUBLE_TAP_MIN_TIME			5
#define TOUCH_DOUBLE_TAP_MAX_TIME			15
#define TOUCH_SCREEN_RESISTANCE				16
#define TOUCH_MIN_PRESSURE					30
#define TOUCH_X_MIN							250
#define TOUCH_X_MAX							3770
#define TOUCH_X_SCALE						11
#define TOUCH_Y_MIN							250
#define TOUCH_Y_MAX							3610
#define TOUCH_Y_SCALE						14
#define TOUCH_CLOSE_DISTANCE				25
#define TOUCH_HOLD_THRESHOLD				100

// Touch message types / states
#define TOUCH_TYPE_INTERNAL_RESET			0
#define TOUCH_TYPE_INTERNAL_BEGIN			1
#define TOUCH_TYPE_TAP						2
#define TOUCH_TYPE_TAP_DOUBLE				3
#define TOUCH_TYPE_HOLD_BEGIN				4
#define TOUCH_TYPE_HOLD_END					5
#define TOUCH_TYPE_SWIPE_RIGHT				6
#define TOUCH_TYPE_SWIPE_LEFT				7
#define TOUCH_TYPE_SWIPE_DOWN				8
#define TOUCH_TYPE_SWIPE_UP					9
#define TOUCH_TYPE_RAW						10
#define TOUCH_TYPE_RAW_END					11

// Function prototypes
void TaskTouch_Init (void);
uint32_t TaskTouch_Receive (TouchMessage_TypeDef* message);
void TaskTouch (uint32_t arg);
void TOUCH_IRQ_HANDLER (void);

// Global constants/variables
extern const KERNEL_TaskDescriptor TaskDescriptor_TaskTouch;
extern volatile uint8_t TaskTouch_Mode;

#endif//_TASK_TOUCH_H_
