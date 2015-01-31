/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

// Includes
#include "tcp.h"

#ifdef _USE_TCP_

// Global variables
static uint8_t TCP_ClientState = TCP_CLIENT_STATE_CLOSED;

void TCP_ActiveOpenClient (void)
{
	// Actively open the TCP port
	ETH_SendTCPSYN((uint8_t*) ENC_SERVER_MAC, (uint8_t*) ENC_SERVER_IP, SERVER_PORT_LE);
	TCP_ClientState = TCP_CLIENT_STATE_SYN_SENT;
}

void TCP_HandleClient (void)
{
	// Determine TCP header and payload length
	uint8_t headerLength = ETH_Buffer[ETH_TCP_HLEN] >> 2;
	uint16_t payloadLength = ((ETH_Buffer[ETH_IP_TOTLEN] << 8) | (ETH_Buffer[ETH_IP_TOTLEN+1] & 0xff)) - ETH_HEADER_LENGTH_IP - headerLength;
	uint8_t flags = ETH_Buffer[ETH_TCP_FLAGS];

	// No more acknowledgements if connection terminated
	if (TCP_ClientState == TCP_CLIENT_STATE_CLOSED)
		return;

	// Handle RST flag
	if (flags & ETH_TCP_FLAGS_RST) {
		TCP_ClientState = TCP_CLIENT_STATE_CLOSED;
		return;
	}

	// Handle FIN flag
	if (flags & ETH_TCP_FLAGS_FIN) {
		ETH_SendTCP(payloadLength + 1, ETH_TCP_FLAGS_ACK | ETH_TCP_FLAGS_PUSH | ETH_TCP_FLAGS_FIN);
		TCP_ClientState = TCP_CLIENT_STATE_CLOSED;
		return;
	}

	// Waiting for the connection to open
	if (TCP_ClientState == TCP_CLIENT_STATE_SYN_SENT) {
		if ((flags & ETH_TCP_FLAGS_SYN) && (flags & ETH_TCP_FLAGS_ACK)) {

			// SYN+ACK received, acknowledge and start sending data
			ETH_SendTCP(1, ETH_TCP_FLAGS_ACK);
			TCP_HandleClientRequest();
			TCP_ClientState = TCP_CLIENT_STATE_OPEN;
			return;
		} else {
			ETH_SendTCP((flags & ETH_TCP_FLAGS_ACK) ? 0 : (payloadLength + 1), ETH_TCP_FLAGS_ACK | ETH_TCP_FLAGS_RST);
			TCP_ClientState = TCP_CLIENT_STATE_RESET;
			return;
		}
	}

	// Ack any packet
	if (payloadLength > 0) {
		ETH_SendTCP(payloadLength, ETH_TCP_FLAGS_ACK);
	}
}

void TCP_HandleServer (void)
{
	// Determine TCP header and payload length
	uint8_t headerLength = ETH_Buffer[ETH_TCP_HLEN] >> 2;
	uint16_t payloadLength = ((ETH_Buffer[ETH_IP_TOTLEN] << 8) | (ETH_Buffer[ETH_IP_TOTLEN+1] & 0xff)) - ETH_HEADER_LENGTH_IP - headerLength;
	uint8_t flags = ETH_Buffer[ETH_TCP_FLAGS];

	// Handle SYN flag
	if (flags & ETH_TCP_FLAGS_SYN) {
		ETH_SendTCP(1, ETH_TCP_FLAGS_SYNACK);
	}

	// Handle ACK flag
	if (flags & ETH_TCP_FLAGS_ACK) {
		if (payloadLength == 0) {
			if (flags & ETH_TCP_FLAGS_FIN) {
				ETH_SendTCP(1, ETH_TCP_FLAGS_ACK);
			}
		} else {

			// Acknowledge and start sending data
			ETH_SendTCP(payloadLength ? payloadLength : 1, ETH_TCP_FLAGS_ACK);
			TCP_HandleServerRequest(headerLength, payloadLength);
		}
	}
}

#endif//_USE_TCP_
