/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifdef STM

// Includes
#include "task_touch.h"

// Global constants
const KERNEL_TaskDescriptor TaskDescriptor_TaskTouch = {TaskTouch, 0, TASK_TOUCH_STACK_SIZE, TASK_TOUCH_PRIORITY, "Touch"};

// Global variables
volatile uint8_t TaskTouch_Mode = TASK_TOUCH_MODE_ANALYSE;		// No lock, since only read in this task (always atomic)

// Private global variables
static KERNEL_TaskTableEntry * task;
static struct
{
	uint8_t					lock;								// This structure may only be changed if access granted
	uint8_t					tx_index;							// Points to where it can immediately write
	uint8_t					rx_index;							// Points to where it can immediately read
	TouchMessage_TypeDef	messages[TASK_TOUCH_QUEUE_SIZE];	// The actual queue
} queue;

// Private global variables (since practically always active)
static TouchMessage_TypeDef touch;
static uint32_t time;
static uint16_t measurement[4];
static uint32_t pressure;
static uint16_t x;
static uint16_t y;
static int16_t dx;
static int16_t dy;
static uint16_t abs_dx;
static uint16_t abs_dy;

// Private functions
static void TaskTouch_Send (TouchMessage_TypeDef* message);





void TaskTouch_Init (void)
{
	// Initialise the TOUCH chip
	TOUCH_Init();

	// Initialise indices and lock
	queue.tx_index = 0;
	queue.rx_index = 0;
	queue.lock = 0;
}

static void TaskTouch_Send (TouchMessage_TypeDef* message)
{
	// Lock the queue
	while (KERNEL_GetExclusiveAccess(&queue.lock))
		KERNEL_SVCForceContextSwitchDelay(TASK_TOUCH_LOCK_TIMEOUT);

	// Check if the queue is full
	uint32_t full;
	if (queue.rx_index == 0)
		full = (queue.tx_index == TASK_TOUCH_QUEUE_SIZE - 1);
	else
		full = (queue.tx_index == queue.rx_index - 1);

	// Only send if not full
	if (!full)
	{
		// Add element and increment index
		queue.messages[queue.tx_index] = *message;
		queue.tx_index++;
		if (queue.tx_index == TASK_TOUCH_QUEUE_SIZE)
			queue.tx_index = 0;
	}

	// Unlock the queue
	KERNEL_ClearExclusiveAccess(&queue.lock);
}

uint32_t TaskTouch_Receive (TouchMessage_TypeDef* message)
{
	uint32_t new = 0;

	// Lock the queue
	while (KERNEL_GetExclusiveAccess(&queue.lock))
		KERNEL_SVCForceContextSwitchDelay(TASK_TOUCH_LOCK_TIMEOUT);

	// Check if the queue is empty
	uint32_t empty = (queue.tx_index == queue.rx_index);

	// Only receive if not empty
	if (!empty)
	{
		// Get element and increment index
		*message = queue.messages[queue.rx_index];
		queue.rx_index++;
		if (queue.rx_index == TASK_TOUCH_QUEUE_SIZE)
			queue.rx_index = 0;

		// Notify reception
		new = 1;
	}

	// Unlock the queue
	KERNEL_ClearExclusiveAccess(&queue.lock);

	// Return whether new data was received
	return new;
}

void TaskTouch (uint32_t arg)
{
	touch.type = TOUCH_TYPE_INTERNAL_RESET;
	while (1)
	{
		// Check if screen is no longer touched
		if (*((volatile uint32_t *) GPIOB_IDR) & (1 << 6))
		{
			// Send movement analysis result
			switch (touch.type)
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
						if (!(*((volatile uint32_t *) GPIOB_IDR) & (1 << 6)))
						{
							// Early touch
							// FIXME: goto is terrible
							touch.type = TOUCH_TYPE_TAP_DOUBLE;
							goto _measure_;
						}
					} while (time < TOUCH_DOUBLE_TAP_MAX_TIME);

					// No other touch, hence it was a tap
					TaskTouch_Send(&touch);
				}
				break;

			case TOUCH_TYPE_TAP_DOUBLE:

				// Second touch failed to be properly registered, assume single tap
				touch.type = TOUCH_TYPE_TAP;
				TaskTouch_Send(&touch);
				break;

			case TOUCH_TYPE_HOLD_BEGIN:

				touch.type = TOUCH_TYPE_HOLD_END;
				TaskTouch_Send(&touch);
				break;

			case TOUCH_TYPE_SWIPE_RIGHT:

				// Report average line + speed
				touch.y = (touch.y + y) >> 1;
				touch.x_speed = abs_dx / time;
				TaskTouch_Send(&touch);
				break;

			case TOUCH_TYPE_SWIPE_LEFT:

				// Report average line + speed
				touch.y = (touch.y + y) >> 1;
				touch.x_speed = abs_dx / time;
				TaskTouch_Send(&touch);
				break;

			case TOUCH_TYPE_SWIPE_DOWN:

				// Report average line + speed
				touch.x = (touch.x + x) >> 1;
				touch.y_speed = abs_dy / time;
				TaskTouch_Send(&touch);
				break;

			case TOUCH_TYPE_SWIPE_UP:

				// Report average line + speed
				touch.x = (touch.x + x) >> 1;
				touch.y_speed = abs_dy / time;
				TaskTouch_Send(&touch);
				break;

			case TOUCH_TYPE_RAW:

				// Send end signal
				touch.type = TOUCH_TYPE_RAW_END;
				TaskTouch_Send(&touch);
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
				touch.type = TOUCH_TYPE_INTERNAL_BEGIN;
			}
			else
			{
				// Send RAW data
				touch.type = TOUCH_TYPE_RAW;
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
			dx = x - touch.x;
			dy = y - touch.y;
			abs_dx = (dx < 0) ? -dx : dx;
			abs_dy = (dy < 0) ? -dy : dy;

			// Analyse movement
			time++;
			switch (touch.type)
			{
			case TOUCH_TYPE_INTERNAL_BEGIN:

				// Store start
				touch.x = x;
				touch.y = y;
				time = 0;
				touch.type = TOUCH_TYPE_TAP;
				break;

			case TOUCH_TYPE_TAP:

				// Check if still close
				if ((abs_dx < TOUCH_CLOSE_DISTANCE) && (abs_dy < TOUCH_CLOSE_DISTANCE))
				{
					touch.x = (touch.x + x) >> 1;
					touch.y = (touch.y + y) >> 1;

					// Long time at starting position?
					if (time > TOUCH_HOLD_THRESHOLD)
					{
						touch.type = TOUCH_TYPE_HOLD_BEGIN;
						TaskTouch_Send(&touch);
					}
				}
				else
				{
					// Determine direction of movement
					if (abs_dx > abs_dy)
						if (dx > 0)
							touch.type = TOUCH_TYPE_SWIPE_RIGHT;
						else
							touch.type = TOUCH_TYPE_SWIPE_LEFT;
					else
						if (dy > 0)
							touch.type = TOUCH_TYPE_SWIPE_DOWN;
						else
							touch.type = TOUCH_TYPE_SWIPE_UP;
				}
				break;

			case TOUCH_TYPE_TAP_DOUBLE:

				// Check if second tap is close to the first one
				if ((abs_dx < TOUCH_CLOSE_DISTANCE) && (abs_dy < TOUCH_CLOSE_DISTANCE))
				{
					TaskTouch_Send(&touch);
					touch.type = TOUCH_TYPE_INTERNAL_RESET;
				}
				else
				{
					// Other touch not close, hence it was a tap
					touch.type = TOUCH_TYPE_TAP;
					TaskTouch_Send(&touch);

					// Recover from this initial assumption to recognise the new movement
					touch.x = x;
					touch.y = y;
					time = 0;
					touch.type = TOUCH_TYPE_TAP;
				}

				break;

			case TOUCH_TYPE_HOLD_BEGIN:

				// Check if still close
				if ((abs_dx < TOUCH_CLOSE_DISTANCE) && (abs_dy < TOUCH_CLOSE_DISTANCE))
				{
					touch.x = (touch.x + x) >> 1;
					touch.y = (touch.y + y) >> 1;
				}
				else
				{
					touch.type = TOUCH_TYPE_HOLD_END;
					TaskTouch_Send(&touch);
					touch.type = TOUCH_TYPE_INTERNAL_RESET;
				}
				break;

			case TOUCH_TYPE_SWIPE_RIGHT:

				// Check if still moving in the same direction
				if (!(dx > 2*abs_dy))
					touch.type = TOUCH_TYPE_INTERNAL_RESET;
				break;

			case TOUCH_TYPE_SWIPE_LEFT:

				// Check if still moving in the same direction
				if (!(-dx > 2*abs_dy))
					touch.type = TOUCH_TYPE_INTERNAL_RESET;
				break;

			case TOUCH_TYPE_SWIPE_DOWN:

				// Check if still moving in the same direction
				if (!(dy > 2*abs_dx))
					touch.type = TOUCH_TYPE_INTERNAL_RESET;
				break;

			case TOUCH_TYPE_SWIPE_UP:

				// Check if still moving in the same direction
				if (!(-dy > 2*abs_dx))
					touch.type = TOUCH_TYPE_INTERNAL_RESET;
				break;

			case TOUCH_TYPE_RAW:

				// Send coordinate
				touch.x = x;
				touch.y = y;
				TaskTouch_Send(&touch);
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
	*((volatile uint32_t *) EXTI_PR) = (1 << 6);
}

#endif//STM
