/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _WEBSERVER_H_
#define _WEBSERVER_H_

// Includes
#include <stdint.h>
#include "http.h"
#include "controls.h"

// Function prototypes
void Page_ActionHandler (HTTP_Page * page);
uint8_t * Page_MainActionAnalyzer (uint8_t * buffer);
void Page_MainActionProcessor (void);
uint8_t * Page_MainTemperatureAnalyzer (uint8_t * buffer);
void Page_MainTemperatureProcessor (void);
uint8_t * Page_MainDimmerAnalyzer (uint8_t * buffer);
void Page_MainDimmerProcessor (void);
void Page_DataInserter (uint8_t * buffer);
void Page_MainInserterOutsideTemperature (uint8_t * buffer);
void Page_MainInserterRoomTemperature (uint8_t * buffer);
void Page_MainInserterSetTemperature (uint8_t * buffer);
void Page_MainInserterValve (uint8_t * buffer);
void Page_MainInserterPump (uint8_t * buffer);
void Page_MainInserterEntranceLink (uint8_t * buffer);
void Page_MainInserterEntranceValue (uint8_t * buffer);
void Page_MainInserterKitchenLink (uint8_t * buffer);
void Page_MainInserterKitchenValue (uint8_t * buffer);
void Page_MainInserterDimmerValue (uint8_t * buffer);

#endif//_WEBSERVER_H_
