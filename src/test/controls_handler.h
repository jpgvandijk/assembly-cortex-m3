/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _CONTROLS_HANDLER_H_
#define _CONTROLS_HANDLER_H_

// Includes
#include <stdint.h>
#include "controls.h"

// Configuration
#define CONTROLS_DEFAULT_TEMPERATURE			(18.00 * 16)
#define CONTROLS_LABEL_LOCK_TIMEOUT				(5)

// Definitions
#define TASK_WIRELESS_RELAY_A_ON				(0)
#define TASK_WIRELESS_RELAY_A_OFF				(1)
#define TASK_WIRELESS_RELAY_B_ON				(2)
#define TASK_WIRELESS_RELAY_B_OFF				(3)
#define TASK_WIRELESS_RELAY_C_ON				(4)
#define TASK_WIRELESS_RELAY_C_OFF				(5)
#define TASK_WIRELESS_RELAY_D_ON				(6)
#define TASK_WIRELESS_RELAY_D_OFF				(7)
#define TASK_WIRELESS_LIGHT_KITCHEN_ON			(8)
#define TASK_WIRELESS_LIGHT_KITCHEN_OFF			(9)
#define TASK_WIRELESS_DIMMER_SET(value)			(10 | (value << 4))

// Function prototypes
void Controls_InitHandler (void);
void Task_WirelessSend (uint32_t value);
void Task_EntranceLightOn (void);
void Task_EntranceLightOff (void);
void Task_TemperatureSetSet (uint32_t value);
void Task_BuildingDoorOpen (void);
void Task_DoorOpen (void);
void DS18B20_TemperatureToString (int16_t Temperature, uint8_t * String);

#endif//_CONTROLS_HANDLER_H_
