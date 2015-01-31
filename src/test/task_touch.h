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
#include "config.h"
#include "kernel.h"
#include "touch.h"
#include "pin.h"

#ifdef _USE_TASK_TOUCH_

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
#define TASK_TOUCH_MODE_ANALYSE				0
#define TASK_TOUCH_MODE_RAW					1

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
void TaskTouch_Receive (TouchMessage_TypeDef * message);
void TaskTouch (uint32_t arg);
void TOUCH_IRQ_HANDLER (void);

// Global constants/variables
extern const KERNEL_TaskDescriptor TaskDescriptor_TaskTouch;
extern volatile uint8_t TaskTouch_Mode;

#endif//_USE_TASK_TOUCH_

#endif//_TASK_TOUCH_H_
