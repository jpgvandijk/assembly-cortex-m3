/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _HTTP_CONFIG_H_
#define _HTTP_CONFIG_H_

// Includes
#include "http.h"
#include "webserver.h"
#include "data/Web.h"

// Definitions
#define HTTP_SERVER_URLS			6 // (sizeof(HTTP_Server) / sizeof(HTTP_URL))

// Global variables
extern HTTP_URL HTTP_Server[];
extern HTTP_Page Page_Error;
extern HTTP_Page Page_Login;
extern HTTP_Page Page_Data;
extern HTTP_Page Page_Door;
extern HTTP_Page Page_Main;

// Function prototypes
void HTTP_Init (void);

#endif//_HTTP_CONFIG_H_
