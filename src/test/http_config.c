/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

// Includes
#include "http_config.h"

char * Page_MainNames[] = {"action", "T", "d"};
HTTP_ValueAnalyzer Page_MainValueAnalyzers[] = {Page_MainActionAnalyzer, Page_MainTemperatureAnalyzer, Page_MainDimmerAnalyzer};
HTTP_ValueProcessor Page_MainValueProcessors[] = {Page_MainActionProcessor, Page_MainTemperatureProcessor, Page_MainDimmerProcessor};
HTTP_NameValue Page_MainNameValue = {3, Page_MainNames, Page_MainValueAnalyzers, Page_MainValueProcessors};

HTTP_TextInserter Page_DataInserters[] = {Page_DataInserter};
HTTP_TextInserter Page_MainInserters[] = {Page_MainInserterOutsideTemperature,
										Page_MainInserterRoomTemperature,
										Page_MainInserterSetTemperature,
										Page_MainInserterValve,
										Page_MainInserterPump,
										Page_MainInserterEntranceLink,
										Page_MainInserterEntranceValue,
										Page_MainInserterKitchenLink,
										Page_MainInserterKitchenValue,
										Page_MainInserterDimmerValue};

HTTP_Page Page_Error = {NULL, PAGE_ERROR_SIZE, NULL};
HTTP_Page Page_Login = {NULL, PAGE_LOGIN_SIZE, NULL};
HTTP_Page Page_Data = {NULL, PAGE_DATA_SIZE, Page_DataInserters};
HTTP_Page Page_Door = {NULL, PAGE_DOOR_SIZE, NULL};
HTTP_Page Page_Main = {NULL, PAGE_MAIN_SIZE, Page_MainInserters};

HTTP_URL HTTP_Server[] = {
	{"/", NULL, &Page_Login},
	{"/3", NULL, &Page_Data},
	{"/SomeDoor", NULL, &Page_Door},
	{"/SomeDoor.htm", NULL, &Page_Door},
	{"/SomeDoor.html", NULL, &Page_Door},
	{"/SomePassword", &Page_MainNameValue, &Page_Main}
};

// FIXME
void HTTP_Init (void)
{
	// Initialize the webpages
	Page_Error.address = PAGE_ERROR_ADDRESS;
	Page_Login.address = PAGE_LOGIN_ADDRESS;
	Page_Data.address = PAGE_DATA_ADDRESS;
	Page_Door.address = PAGE_DOOR_ADDRESS;
	Page_Main.address = PAGE_MAIN_ADDRESS;
}
