/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

// Includes
#include "task_touch.h"

#ifdef _USE_TASK_TOUCH_

// Global constants
const KERNEL_TaskDescriptor TaskDescriptor_TaskTouch = {TaskTouch, 0, TASK_TOUCH_STACK_SIZE, TASK_TOUCH_PRIORITY, "Touch"};

// Global variables
volatile uint8_t TaskTouch_Mode = TASK_TOUCH_MODE_ANALYSE;		// No lock, since only read in this task (always atomic)

// Private global variables
static KERNEL_TaskTableEntry * task;
static KERNEL_QueueStructure queue;
static uint32_t queue_buffer[TASK_TOUCH_QUEUE_SIZE];
static uint8_t touch_type;
static uint16_t touch_x, touch_y;

// Private functions
void TaskTouch_Send (void);

// This function must be called before starting the kernel
void TaskTouch_Init (void)
{
	// Initialise the TOUCH chip
	TOUCH_Init();

	// Initialise the queue
	KERNEL_QueueInit(&queue, TASK_TOUCH_LOCK_TIMEOUT, KERNEL_QueueBufferSpecs(TASK_TOUCH_QUEUE_SIZE, KERNEL_QueueElementSizeWord), queue_buffer);
}

void TaskTouch_Send (void)
{
	// Pack and send the data: 8-bit type, 12-bit x, 12-bit y
	uint32_t data = touch_type | (touch_x << 8) | (touch_y << 20);
	KERNEL_QueueSend(&queue, data);
}

void TaskTouch_Receive (TouchMessage_TypeDef * message)
{
	// Wait for data reception and unpack
	uint32_t data = KERNEL_QueueReceive(&queue, 1);
	message->type = data & 0xFF;
	message->x = (data >> 8) & 0xFFF;
	message->y = (data >> 20) & 0xFFF;
}

void TaskTouch (uint32_t arg)
{
	// Local variables
	uint32_t time;
	uint16_t measurement[4];
	uint32_t pressure;
	uint16_t x, y;
	int16_t dx, dy;
	uint16_t abs_dx, abs_dy;

	touch_type = TOUCH_TYPE_INTERNAL_RESET;
	while (1)
	{
		// Check if screen is no longer touched
		if (PIN_Read(TOUCH_IRQ_GPIO, TOUCH_IRQ_PIN))
		{
			// Send movement analysis result
			switch (touch_type)
			{
			case TOUCH_TYPE_TAP:

				// Ignore if too few measurements
				if (time >= TOUCH_TAP_MIN_TIME)
				{
					// Can be either a tap or a double tap
					// Wait a certain maximum time for a new touch before entering sleep
					KERNEL_SVCForceContextSwitchPeriodic(TOUCH_DOUBLE_TAP_MIN_TIME*TASK_TOUCH_PERIOD);
					time = TOUCH_DOUBLE_TAP_MIN_TIME;
					do {
						KERNEL_SVCForceContextSwitchPeriodic(TASK_TOUCH_PERIOD);
						time++;
						if (!PIN_Read(TOUCH_IRQ_GPIO, TOUCH_IRQ_PIN))
						{
							// Early touch
							// FIXME: goto is terrible
							touch_type = TOUCH_TYPE_TAP_DOUBLE;
							goto _measure_;
						}
					} while (time < TOUCH_DOUBLE_TAP_MAX_TIME);

					// No other touch, hence it was a tap
					TaskTouch_Send();
				}
				break;

			case TOUCH_TYPE_TAP_DOUBLE:

				// Second touch failed to be properly registered, assume single tap
				touch_type = TOUCH_TYPE_TAP;
				TaskTouch_Send();
				break;

			case TOUCH_TYPE_HOLD_BEGIN:

				touch_type = TOUCH_TYPE_HOLD_END;
				TaskTouch_Send();
				break;

			case TOUCH_TYPE_SWIPE_RIGHT:

				// Report average line + speed
				touch_y = (touch_y + y) >> 1;
				touch_x = abs_dx / time;
				TaskTouch_Send();
				break;

			case TOUCH_TYPE_SWIPE_LEFT:

				// Report average line + speed
				touch_y = (touch_y + y) >> 1;
				touch_x = abs_dx / time;
				TaskTouch_Send();
				break;

			case TOUCH_TYPE_SWIPE_DOWN:

				// Report average line + speed
				touch_x = (touch_x + x) >> 1;
				touch_y = abs_dy / time;
				TaskTouch_Send();
				break;

			case TOUCH_TYPE_SWIPE_UP:

				// Report average line + speed
				touch_x = (touch_x + x) >> 1;
				touch_y = abs_dy / time;
				TaskTouch_Send();
				break;

			case TOUCH_TYPE_RAW:

				// Send end signal
				touch_type = TOUCH_TYPE_RAW_END;
				TaskTouch_Send();
				break;

			default:
				break;
			}

			// Auto wake-up when touch interrupt occurs (no time-out)
			task = KERNEL_TaskRunning;
			KERNEL_SVCIRQEnable(TOUCH_IRQ_NUMBER);
			KERNEL_SVCForceContextSwitchIndefinitely();
			KERNEL_SVCIRQDisable(TOUCH_IRQ_NUMBER);
			task = 0;

			// Change operating mode if necessary
			if (TaskTouch_Mode == TASK_TOUCH_MODE_ANALYSE)
			{
				// Start new analyses
				touch_type = TOUCH_TYPE_INTERNAL_BEGIN;
			}
			else
			{
				// Send RAW data
				touch_type = TOUCH_TYPE_RAW;
			}
		}

_measure_:

		// Screen is touched, measure x, y, z1 and z2
		TOUCH_Read(measurement, 4);

		// Determine the pressure
		pressure = 0;
		if ((measurement[2] != 0) && (measurement[3] > measurement[2]))
		{
			pressure = measurement[0] * TOUCH_SCREEN_RESISTANCE;
			pressure *= measurement[3] - measurement[2];
			pressure /= measurement[2];
			pressure /= 4096;
		}

		// Only update coordinate if pressure is high enough
		// AND Only update if coordinates within bounds
		if (((pressure != 0) && (pressure < TOUCH_MIN_PRESSURE)) &&
			((measurement[1] >= TOUCH_X_MIN) && (measurement[0] >= TOUCH_Y_MIN) && (measurement[1] < TOUCH_X_MAX) && (measurement[0] < TOUCH_Y_MAX)))
		{
			// Determine the coordinate
			x = 319 - (measurement[1] - TOUCH_X_MIN) / TOUCH_X_SCALE;
			y = (measurement[0] - TOUCH_Y_MIN) / TOUCH_Y_SCALE;
			dx = x - touch_x;
			dy = y - touch_y;
			abs_dx = (dx < 0) ? -dx : dx;
			abs_dy = (dy < 0) ? -dy : dy;

			// Analyse movement
			time++;
			switch (touch_type)
			{
			case TOUCH_TYPE_INTERNAL_BEGIN:

				// Store start
				touch_x = x;
				touch_y = y;
				time = 0;
				touch_type = TOUCH_TYPE_TAP;
				break;

			case TOUCH_TYPE_TAP:

				// Check if still close
				if ((abs_dx < TOUCH_CLOSE_DISTANCE) && (abs_dy < TOUCH_CLOSE_DISTANCE))
				{
					touch_x = (touch_x + x) >> 1;
					touch_y = (touch_y + y) >> 1;

					// Long time at starting position?
					if (time > TOUCH_HOLD_THRESHOLD)
					{
						touch_type = TOUCH_TYPE_HOLD_BEGIN;
						TaskTouch_Send();
					}
				}
				else
				{
					// Determine direction of movement
					if (abs_dx > abs_dy)
						if (dx > 0)
							touch_type = TOUCH_TYPE_SWIPE_RIGHT;
						else
							touch_type = TOUCH_TYPE_SWIPE_LEFT;
					else
						if (dy > 0)
							touch_type = TOUCH_TYPE_SWIPE_DOWN;
						else
							touch_type = TOUCH_TYPE_SWIPE_UP;
				}
				break;

			case TOUCH_TYPE_TAP_DOUBLE:

				// Check if second tap is close to the first one
				if ((abs_dx < TOUCH_CLOSE_DISTANCE) && (abs_dy < TOUCH_CLOSE_DISTANCE))
				{
					TaskTouch_Send();
					touch_type = TOUCH_TYPE_INTERNAL_RESET;
				}
				else
				{
					// Other touch not close, hence it was a tap
					touch_type = TOUCH_TYPE_TAP;
					TaskTouch_Send();

					// Recover from this initial assumption to recognise the new movement
					touch_x = x;
					touch_y = y;
					time = 0;
					touch_type = TOUCH_TYPE_TAP;
				}

				break;

			case TOUCH_TYPE_HOLD_BEGIN:

				// Check if still close
				if ((abs_dx < TOUCH_CLOSE_DISTANCE) && (abs_dy < TOUCH_CLOSE_DISTANCE))
				{
					touch_x = (touch_x + x) >> 1;
					touch_y = (touch_y + y) >> 1;
				}
				else
				{
					touch_type = TOUCH_TYPE_HOLD_END;
					TaskTouch_Send();
					touch_type = TOUCH_TYPE_INTERNAL_RESET;
				}
				break;

			case TOUCH_TYPE_SWIPE_RIGHT:

				// Check if still moving in the same direction
				if (!(dx > 2*abs_dy))
					touch_type = TOUCH_TYPE_INTERNAL_RESET;
				break;

			case TOUCH_TYPE_SWIPE_LEFT:

				// Check if still moving in the same direction
				if (!(-dx > 2*abs_dy))
					touch_type = TOUCH_TYPE_INTERNAL_RESET;
				break;

			case TOUCH_TYPE_SWIPE_DOWN:

				// Check if still moving in the same direction
				if (!(dy > 2*abs_dx))
					touch_type = TOUCH_TYPE_INTERNAL_RESET;
				break;

			case TOUCH_TYPE_SWIPE_UP:

				// Check if still moving in the same direction
				if (!(-dy > 2*abs_dx))
					touch_type = TOUCH_TYPE_INTERNAL_RESET;
				break;

			case TOUCH_TYPE_RAW:

				// Send coordinate
				touch_x = x;
				touch_y = y;
				TaskTouch_Send();
				break;

			default:
				break;
			}
		}

		// Run every TASK_TOUCH_PERIOD ms
		KERNEL_SVCForceContextSwitchPeriodic(TASK_TOUCH_PERIOD);
	}
}

void TOUCH_IRQ_HANDLER (void)
{
	// Wake-up the touch task
	if (task != 0)
		KERNEL_AddTaskToReadyList(task);

	// Clear flag
	*((volatile uint32_t *) EXTI_PR) = (1 << TOUCH_IRQ_PIN);
}

#endif//_USE_TASK_TOUCH_
