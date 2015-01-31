/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _TCP_H_
#define _TCP_H_

// Includes
#include <stdint.h>
#include "ethernet.h"
#include "config.h"

#ifdef _USE_TCP_

// Definitions
#define TCP_CLIENT_STATE_CLOSED			0
#define TCP_CLIENT_STATE_SYN_SENT		1
#define TCP_CLIENT_STATE_OPEN			2
#define TCP_CLIENT_STATE_RESET			3

// Callback functions
extern void TCP_HandleClientRequest (void);
extern void TCP_HandleServerRequest (uint32_t headerLength, uint32_t payloadLength);

// Function prototypes
void TCP_ActiveOpenClient (void);
void TCP_HandleClient (void);
void TCP_HandleServer (void);

#endif//_USE_TCP_

#endif//_TCP_H_
