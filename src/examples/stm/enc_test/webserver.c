/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

// Includes
#include "webserver.h"
#include "http_config.h"

/************************************************************
* PAGE ACTION HANDLER										*
************************************************************/

void Page_ActionHandler (HTTP_Page * page)
{
	// This function is called after the page has been send,
	// and can be used to create a side-effect for the page request
	if (page == &Page_Door) {
		Controls_OpenDoor();
	}
}

/************************************************************
* MAIN PAGE ACTION											*
************************************************************/

static enum {
	Page_MainActionOpenDoor = 0,
	Page_MainActionOpenBuildingDoor = 1,
	Page_MainActionRelayAOff = 2,
	Page_MainActionRelayAOn = 3,
	Page_MainActionRelayBOff = 4,
	Page_MainActionRelayBOn = 5,
	Page_MainActionRelayCOff = 6,
	Page_MainActionRelayCOn = 7,
	Page_MainActionRelayDOff = 8,
	Page_MainActionRelayDOn = 9,
	Page_MainActionEntranceLightOff = 10,
	Page_MainActionEntranceLightOn = 11,
	Page_MainActionKitchenLightOff = 12,
	Page_MainActionKitchenLightOn = 13,
} Page_MainAction;

uint8_t * Page_MainActionAnalyzer (uint8_t * buffer)
{
	// Analyze the 2 character string
	// Possibilities: OD, OB, A0, A1, B0, B1, C0, C1, D0, D1, E0, E1, K0, K1

	// Check for a door action
	if (buffer[0] == 'O') {
		if (buffer[1] == 'D')
			Page_MainAction = Page_MainActionOpenDoor;
		else if (buffer[1] == 'B')
			Page_MainAction = Page_MainActionOpenBuildingDoor;
		else
			return HTTP_ANALYZE_ERROR;

		// Set the new index
		return (buffer + 2);
	}

	// Simplify the rest of the analysis
	if (buffer[0] == 'K')
		buffer[0] = 'F';

	// Check for the other actions: letter + 0/1
	if ((buffer[0] >= 'A') && (buffer[0] <= 'F'))
	{
		Page_MainAction = Page_MainActionRelayAOff + ((buffer[0] - 'A') << 1);
		if (buffer[1] == '0');
		else if (buffer[1] == '1')
			Page_MainAction += 1;
		else
			return HTTP_ANALYZE_ERROR;

		// Set the new index
		return (buffer + 2);
	}

	// Unsupported action
	return HTTP_ANALYZE_ERROR;
}

void Page_MainActionProcessor (void)
{
	switch (Page_MainAction)
	{
	case Page_MainActionOpenDoor:			Controls_OpenDoor();			break;
	case Page_MainActionOpenBuildingDoor:	Controls_OpenBuildingDoor();	break;
	case Page_MainActionRelayAOff:			Controls_RelayAOff();			break;
	case Page_MainActionRelayAOn:			Controls_RelayAOn();			break;
	case Page_MainActionRelayBOff:			Controls_RelayBOff();			break;
	case Page_MainActionRelayBOn:			Controls_RelayBOn();			break;
	case Page_MainActionRelayCOff:			Controls_RelayCOff();			break;
	case Page_MainActionRelayCOn:			Controls_RelayCOn();			break;
	case Page_MainActionRelayDOff:			Controls_RelayDOff();			break;
	case Page_MainActionRelayDOn:			Controls_RelayDOn();			break;
	case Page_MainActionEntranceLightOff:	Controls_LightEntranceOff();	break;
	case Page_MainActionEntranceLightOn:	Controls_LightEntranceOn();		break;
	case Page_MainActionKitchenLightOff:	Controls_LightKitchenOff();		break;
	case Page_MainActionKitchenLightOn:		Controls_LightKitchenOn();		break;
	}
}

/************************************************************
* MAIN PAGE TEMPERATURE										*
************************************************************/

#define WEB_TEMPERATURE_MAX		((uint32_t)(100.0 * 16))

static uint16_t Page_MainTemperature;

uint8_t * Page_MainTemperatureAnalyzer (uint8_t * buffer)
{
	// Temperature could be a float, must be positive
	uint32_t j;
	int32_t dot = -1;
	Page_MainTemperature = 0;
	for (j = 0; j < 5; j++)
	{
		// Check for dot, cannot start or end with it
		// And of course only a single dot is allowed
		if ((j != 0) && (j != 5) && (dot == -1))
		{
			if (buffer[j] == '.')
			{
				dot = j;
				continue;
			}
		}
		
		// Check for digit
		if ((buffer[j] < '0') || (buffer[j] > '9'))
		{
			// Not a digit, only allowed if not first character
			// and not immediately following a dot
			if (j > (dot + 1))
			{
				// OK
				break;
			}
			else
				return HTTP_ANALYZE_ERROR;
		}
		
		// Update the temperature
		Page_MainTemperature *= 10;
		Page_MainTemperature += buffer[j] - '0';
	}
	
	// Store as integer: 16 * float value
	Page_MainTemperature <<= 4;
	
	// Correct for the position of the dot
	if (dot != -1)
	{
		uint32_t k;
		for (k = 0; k < (j - dot - 1); k++)
			Page_MainTemperature /= 10;
	}
	
	// Check with maximum
	if (Page_MainTemperature >= WEB_TEMPERATURE_MAX)
		return HTTP_ANALYZE_ERROR;
		
	// Set the new index
	return (buffer + j);
}

void Page_MainTemperatureProcessor (void)
{
	// Update the temperature
	Controls_TemperatureSetSet(Page_MainTemperature);
}

/************************************************************
* MAIN PAGE DIMMER											*
************************************************************/

#define WEB_DIMMER_MAX			15

static uint8_t Page_MainDimmer;

uint8_t * Page_MainDimmerAnalyzer (uint8_t * buffer)
{
	// Dimmer should be an integer, 1 or 2 digits
	Page_MainDimmer = 0;

	// Check first character
	if ((buffer[0] < '0') || (buffer[0] > '9'))
		return HTTP_ANALYZE_ERROR;
	else
		Page_MainDimmer = buffer[0] - '0';

	// Check second character
	if ((buffer[1] < '0') || (buffer[1] > '9'))
		return (buffer + 1);
	else
	{
		// 2 digit integer
		Page_MainDimmer = 10 * Page_MainDimmer + buffer[1] - '0';

		// Check with maximum
		if (Page_MainDimmer > WEB_DIMMER_MAX)
			return HTTP_ANALYZE_ERROR;
		else
			return (buffer + 2);
	}
}

void Page_MainDimmerProcessor (void)
{
	// Update the dimmer
	Controls_DimmerSet(Page_MainDimmer);
}

/************************************************************
* TEXT INSERTERS											*
************************************************************/

void Page_DataInserter (uint8_t * buffer)
{
	// TODO: Write the data
	buffer[0] = 'a';
	buffer[1] = 'b';
}

void Page_MainInserterOutsideTemperature (uint8_t * buffer)
{
	// Copy the label
	Controls_TemperatureOutsideLabelCopy(buffer);

}

void Page_MainInserterRoomTemperature (uint8_t * buffer)
{
	// Copy the label
	Controls_TemperatureRoomLabelCopy(buffer);
}

void Page_MainInserterSetTemperature (uint8_t * buffer)
{
	// Copy the label
	Controls_TemperatureSetLabelCopy(buffer);
}

void Page_MainInserterValve (uint8_t * buffer)
{
	// Write on/off
	buffer[0] = 'O';
	if (Controls_TemperatureValveStatus()) {
		buffer[1] = 'n';
	} else {
		buffer[1] = 'f';
		buffer[2] = 'f';
	}
}

void Page_MainInserterPump (uint8_t * buffer)
{
	// Write on/off
	buffer[0] = 'O';
	if (Controls_TemperaturePumpStatus()) {
		buffer[1] = 'n';
	} else {
		buffer[1] = 'f';
		buffer[2] = 'f';
	}
}

void Page_MainInserterEntranceLink (uint8_t * buffer)
{
	// Set the correct action
	buffer[0] = 'E';
	if (Controls_LightEntranceStatus()) {
		buffer[1] = '0';
	} else {
		buffer[1] = '1';
	}
}

void Page_MainInserterEntranceValue (uint8_t * buffer)
{
	// Write on/off
	buffer[0] = 'O';
	if (Controls_LightEntranceStatus()) {
		buffer[1] = 'n';
	} else {
		buffer[1] = 'f';
		buffer[2] = 'f';
	}
}

void Page_MainInserterKitchenLink (uint8_t * buffer)
{
	// Set the correct action
	buffer[0] = 'K';
	if (Controls_LightKitchenStatus()) {
		buffer[1] = '0';
	} else {
		buffer[1] = '1';
	}
}

void Page_MainInserterKitchenValue (uint8_t * buffer)
{
	// Write on/off
	buffer[0] = 'O';
	if (Controls_LightKitchenStatus()) {
		buffer[1] = 'n';
	} else {
		buffer[1] = 'f';
		buffer[2] = 'f';
	}
}

void Page_MainInserterDimmerValue (uint8_t * buffer)
{
	// Copy the label
	Controls_DimmerLabelCopy(buffer);
}
