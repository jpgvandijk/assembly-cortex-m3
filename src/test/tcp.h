/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _TCP_H_
#define _TCP_H_

// Includes
#include <stdint.h>
#include "stm32f103ve.h"
#include "ethernet.h"
#include "flash.h"
#include "board.h"
#include "data/Web.h"

// Definitions
#define TCP_CLIENT_STATE_CLOSED			0
#define TCP_CLIENT_STATE_SYN_SENT		1
#define TCP_CLIENT_STATE_OPEN			2
#define TCP_CLIENT_STATE_RESET			3

// Function prototypes
void TCP_ActiveOpenClient (void);
void TCP_HandleClient (void);
void TCP_HandleClientRequest (void);
void TCP_HandleServer (void);
void TCP_HandleServerRequest (uint8_t headerLength);

#endif//_TCP_H_
