/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

// Includes
#include "controls_handler.h"

// Dummy functions for testing
void Controls_InitHandler (void) {
	Controls_Init();
	Controls_TemperatureOutsideLabelUpdate();
	Controls_TemperatureRoomLabelUpdate();
}

void Task_WirelessSend (uint32_t value) {

}

void Task_EntranceLightOn (void) {

}

void Task_EntranceLightOff (void) {

}

void Task_TemperatureSetSet (uint32_t value) {

}

void Task_BuildingDoorOpen (void) {

}

void Task_DoorOpen (void) {

}

void DS18B20_TemperatureToString (int16_t Temperature, uint8_t * String)
{
	// 0x07D0  125.00
	// 0x0550  85.00
	// 0x0191  25.06
	// 0x00A2  10.12
	// 0x0008  0.50
	// 0x0000  0.00
	// 0xFFF8  -0.50
	// 0xFF5E  -10.12
	// 0xFE6F  -25.06
	// 0xFC90  -55.00
	// 16000   Error

	// Local variables
	uint8_t StringIndex = 0;
	uint8_t TemperatureInteger;
	uint16_t TemperatureFraction;
	uint8_t TempInt;
	uint8_t TempDiv;

	// If too high or too low, then return an error
	if ((Temperature > (125 * 16)) || (Temperature < (-55 * 16)))
	{
		String[0] = 'E';
		String[1] = 'r';
		String[2] = 'r';
		String[3] = 'o';
		String[4] = 'r';
		String[5] = 0;
		return;
	}

	// Correct for sign
	if (Temperature < 0)
	{
		Temperature *= -1;
		String[StringIndex++] = '-';
	}

	// Split temperature in integer and fractional part
	TemperatureInteger = Temperature >> 4;
	TemperatureFraction = (Temperature & 0x0F) * 625;

	// Print integer part
	TempInt = TemperatureInteger;
	if (TemperatureInteger > 99)
	{
		TempInt -= 100;
		String[StringIndex++] = '1';
	}
	if (TemperatureInteger > 9)
	{
		TempDiv = TempInt / 10;
		TempInt -= 10 * TempDiv;
		String[StringIndex++] = '0' + TempDiv;
	}
	String[StringIndex++] = '0' + TempInt;

	// Print '.'
	String[StringIndex++] = '.';

	// Print fractional part
	TempInt = TemperatureFraction / 1000;
	TemperatureFraction -= 1000 * TempInt;
	String[StringIndex++] = '0' + TempInt;

	TempInt = TemperatureFraction / 100;
	String[StringIndex++] = '0' + TempInt;

	// Print termination character 0
	String[StringIndex] = 0;
}
