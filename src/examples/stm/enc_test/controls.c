/************************************************************************************
*
* Author: J.P.G. van Dijk
*
* This file is an interface to the controls and their status
*
************************************************************************************/

// Includes
#include "controls.h"

void Controls_Init (void) {

	// Set the initial state after start-up of the system
	Controls_RelayAOff();
	Controls_RelayBOff();
	Controls_RelayCOff();
	Controls_RelayDOff();
	Controls_LightEntranceOff();
	Controls_LightKitchenOff();
	Controls_DimmerSet(0);
	Controls_TemperatureSetSet(CONTROLS_DEFAULT_TEMPERATURE);
}

/************************************************************
* DOORS (timed relays)										*
************************************************************/

inline void Controls_OpenDoor (void) {
	Task_DoorOpen();
}

inline void Controls_OpenBuildingDoor (void) {
	Task_BuildingDoorOpen();
}

/************************************************************
* RELAYS (wireless)											*
************************************************************/

inline void Controls_RelayAOn (void) {
	Task_WirelessSend(TASK_WIRELESS_RELAY_A_ON);
}

inline void Controls_RelayAOff (void) {
	Task_WirelessSend(TASK_WIRELESS_RELAY_A_OFF);
}

inline void Controls_RelayBOn (void) {
	Task_WirelessSend(TASK_WIRELESS_RELAY_B_ON);
}

inline void Controls_RelayBOff (void) {
	Task_WirelessSend(TASK_WIRELESS_RELAY_B_OFF);
}

inline void Controls_RelayCOn (void) {
	Task_WirelessSend(TASK_WIRELESS_RELAY_C_ON);
}

inline void Controls_RelayCOff (void) {
	Task_WirelessSend(TASK_WIRELESS_RELAY_C_OFF);
}

inline void Controls_RelayDOn (void) {
	Task_WirelessSend(TASK_WIRELESS_RELAY_D_ON);
}

inline void Controls_RelayDOff (void) {
	Task_WirelessSend(TASK_WIRELESS_RELAY_D_OFF);
}

/************************************************************
* LIGHT (relay)												*
************************************************************/

// Private global variables
static uint8_t Controls_LightEntrance;

inline void Controls_LightEntranceOn (void) {
	Controls_LightEntrance = 1;
	Task_EntranceLightOn();
}

inline void Controls_LightEntranceOff (void) {
	Controls_LightEntrance = 0;
	Task_EntranceLightOff();
}

inline uint32_t Controls_LightEntranceStatus (void) {
	return Controls_LightEntrance;
}

/************************************************************
* LIGHT (wireless)											*
************************************************************/

// Private global variables
static uint8_t Controls_LightKitchen;

inline void Controls_LightKitchenOn (void) {
	Controls_LightKitchen = 1;
	Task_WirelessSend(TASK_WIRELESS_LIGHT_KITCHEN_ON);
}

inline void Controls_LightKitchenOff (void) {
	Controls_LightKitchen = 0;
	Task_WirelessSend(TASK_WIRELESS_LIGHT_KITCHEN_OFF);
}

inline uint32_t Controls_LightKitchenStatus (void) {
	return Controls_LightKitchen;
}

/************************************************************
* DIMMER (wireless)											*
************************************************************/

// Private global variables
static uint8_t Controls_DimmerLock;
static uint8_t Controls_DimmerLabel[2];

inline void Controls_DimmerSet (uint32_t value) {
	Controls_DimmerLabelUpdate(value);
	Task_WirelessSend(TASK_WIRELESS_DIMMER_SET(value));
}

void Controls_DimmerLabelUpdate (uint32_t value) {

	// Lock the label buffer
	while (KERNEL_GetExclusiveAccess(&Controls_DimmerLock))
		KERNEL_SVCForceContextSwitchDelay(CONTROLS_LABEL_LOCK_TIMEOUT);

	// TODO: add on/off
	if (value >= 10) {
		Controls_DimmerLabel[0] = '1';
		value -= 10;
	} else {
		Controls_DimmerLabel[0] = ' ';
	}
	Controls_DimmerLabel[1] = '0' + value;

	// Unlock the label buffer
	KERNEL_ClearExclusiveAccess(&Controls_DimmerLock);
}

void Controls_DimmerLabelCopy (uint8_t * string) {

	// Lock the label buffer
	while (KERNEL_GetExclusiveAccess(&Controls_DimmerLock))
		KERNEL_SVCForceContextSwitchDelay(CONTROLS_LABEL_LOCK_TIMEOUT);

	// Copy the label
	string[0] = Controls_DimmerLabel[0];
	string[1] = Controls_DimmerLabel[1];

	// Unlock the label buffer
	KERNEL_ClearExclusiveAccess(&Controls_DimmerLock);
}

/************************************************************
* TEMPERATURE												*
************************************************************/

// External variables (will never be set by multiple tasks)
#define Controls_TemperatureValve			0 // FIXME: implement
#define Controls_TemperaturePump			0 // FIXME: implement
#define Controls_TemperatureOutside			(-4.25*16.0) // FIXME: implement
#define Controls_TemperatureRoom			(24.1*16.0) // FIXME: implement

// Private global variables
static int16_t Controls_TemperatureSet;
static uint8_t Controls_TemperatureSetLock;
static uint8_t Controls_TemperatureSetLabel[7];
static uint8_t Controls_TemperatureOutsideLock;
static uint8_t Controls_TemperatureOutsideLabel[7];
static uint8_t Controls_TemperatureRoomLock;
static uint8_t Controls_TemperatureRoomLabel[7];

inline void Controls_TemperatureSetSet (uint32_t value) {
	Controls_TemperatureSet = value;
	Controls_TemperatureSetLabelUpdate();
	Task_TemperatureSetSet(value);
}

inline uint32_t Controls_TemperatureSetStatus (void) {
	return Controls_TemperatureSet;
}

void Controls_TemperatureSetLabelUpdate (void) {

	// Lock the label buffer
	while (KERNEL_GetExclusiveAccess(&Controls_TemperatureSetLock))
		KERNEL_SVCForceContextSwitchDelay(CONTROLS_LABEL_LOCK_TIMEOUT);

	// Update the label
	DS18B20_TemperatureToString(Controls_TemperatureSet, Controls_TemperatureSetLabel);

	// Unlock the label buffer
	KERNEL_ClearExclusiveAccess(&Controls_TemperatureSetLock);
}

void Controls_TemperatureSetLabelCopy (uint8_t * string) {

	// Lock the label buffer
	while (KERNEL_GetExclusiveAccess(&Controls_TemperatureSetLock))
		KERNEL_SVCForceContextSwitchDelay(CONTROLS_LABEL_LOCK_TIMEOUT);

	// Copy the label
	uint32_t i = 0;
	while (Controls_TemperatureSetLabel[i]) {
		string[i] = Controls_TemperatureSetLabel[i];
		i++;
	}

	// Unlock the label buffer
	KERNEL_ClearExclusiveAccess(&Controls_TemperatureSetLock);
}

void Controls_TemperatureOutsideLabelUpdate (void) {

	// Lock the label buffer
	while (KERNEL_GetExclusiveAccess(&Controls_TemperatureOutsideLock))
		KERNEL_SVCForceContextSwitchDelay(CONTROLS_LABEL_LOCK_TIMEOUT);

	// Update the label
	DS18B20_TemperatureToString(Controls_TemperatureOutside, Controls_TemperatureOutsideLabel);

	// Unlock the label buffer
	KERNEL_ClearExclusiveAccess(&Controls_TemperatureOutsideLock);
}

void Controls_TemperatureOutsideLabelCopy (uint8_t * string) {

	// Lock the label buffer
	while (KERNEL_GetExclusiveAccess(&Controls_TemperatureOutsideLock))
		KERNEL_SVCForceContextSwitchDelay(CONTROLS_LABEL_LOCK_TIMEOUT);

	// Copy the label
	uint32_t i = 0;
	while (Controls_TemperatureOutsideLabel[i]) {
		string[i] = Controls_TemperatureOutsideLabel[i];
		i++;
	}

	// Unlock the label buffer
	KERNEL_ClearExclusiveAccess(&Controls_TemperatureOutsideLock);
}

void Controls_TemperatureRoomLabelUpdate (void) {

	// Lock the label buffer
	while (KERNEL_GetExclusiveAccess(&Controls_TemperatureRoomLock))
		KERNEL_SVCForceContextSwitchDelay(CONTROLS_LABEL_LOCK_TIMEOUT);

	// Update the label
	DS18B20_TemperatureToString(Controls_TemperatureRoom, Controls_TemperatureRoomLabel);

	// Unlock the label buffer
	KERNEL_ClearExclusiveAccess(&Controls_TemperatureRoomLock);
}

void Controls_TemperatureRoomLabelCopy (uint8_t * string) {

	// Lock the label buffer
	while (KERNEL_GetExclusiveAccess(&Controls_TemperatureRoomLock))
		KERNEL_SVCForceContextSwitchDelay(CONTROLS_LABEL_LOCK_TIMEOUT);

	// Copy the label
	uint32_t i = 0;
	while (Controls_TemperatureRoomLabel[i]) {
		string[i] = Controls_TemperatureRoomLabel[i];
		i++;
	}

	// Unlock the label buffer
	KERNEL_ClearExclusiveAccess(&Controls_TemperatureRoomLock);
}

inline uint32_t Controls_TemperatureValveStatus (void) {
	return Controls_TemperatureValve;
}

inline uint32_t Controls_TemperaturePumpStatus (void) {
	return Controls_TemperaturePump;
}
