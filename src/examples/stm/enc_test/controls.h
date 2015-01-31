/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _CONTROLS_H_
#define _CONTROLS_H_

// Includes
#include <stdint.h>
#include "cortex_m3.h"
#include "kernel.h"
#include "controls_handler.h"

// Function prototypes
void Controls_Init (void);
void Controls_OpenDoor (void);
void Controls_OpenBuildingDoor (void);
void Controls_RelayAOn (void);
void Controls_RelayAOff (void);
void Controls_RelayBOn (void);
void Controls_RelayBOff (void);
void Controls_RelayCOn (void);
void Controls_RelayCOff (void);
void Controls_RelayDOn (void);
void Controls_RelayDOff (void);
void Controls_LightEntranceOn (void);
void Controls_LightEntranceOff (void);
uint32_t Controls_LightEntranceStatus (void);
void Controls_LightKitchenOn (void);
void Controls_LightKitchenOff (void);
uint32_t Controls_LightKitchenStatus (void);
void Controls_DimmerSet (uint32_t value);
void Controls_DimmerLabelUpdate (uint32_t value);
void Controls_DimmerLabelCopy (uint8_t * string);
void Controls_TemperatureSetSet (uint32_t value);
uint32_t Controls_TemperatureSetStatus (void);
void Controls_TemperatureSetLabelUpdate (void);
void Controls_TemperatureSetLabelCopy (uint8_t * string);
void Controls_TemperatureOutsideLabelUpdate (void);
void Controls_TemperatureOutsideLabelCopy (uint8_t * string);
void Controls_TemperatureRoomLabelUpdate (void);
void Controls_TemperatureRoomLabelCopy (uint8_t * string);
uint32_t Controls_TemperatureValveStatus (void);
uint32_t Controls_TemperaturePumpStatus (void);

#endif//_CONTROLS_H_
