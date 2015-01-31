/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _ETHERNET_H_
#define _ETHERNET_H_

// Includes
#include "stm32f103ve.h"
#include "config.h"

#ifdef _USE_ETHERNET_

// Definitions
#define ETH_ANALYZE_TYPE_ERROR			0
#define ETH_ANALYZE_TYPE_ARP			1
#define ETH_ANALYZE_TYPE_ICMP_REQUEST	2
#define ETH_ANALYZE_TYPE_TCP_CLIENT		3
#define ETH_ANALYZE_TYPE_TCP_SERVER		4

#define ETH_CHECKSUM_IP					0
#define ETH_CHECKSUM_TCP				1

#ifndef __ASSEMBLER__

// Global constants
extern const uint8_t ENC_DEVICE_MAC[6];
extern const uint8_t ENC_DEVICE_IP[4];
extern const uint8_t ENC_SERVER_MAC[6];
extern const uint8_t ENC_SERVER_IP[4];

// Global variables
extern uint8_t ETH_Buffer[ETH_BUFFER_SIZE];
extern uint16_t ETH_Size;

// Global functions
extern uint32_t ETH_AnalyzePacket (void);
extern void ETH_PrepareEthernetHeader (void);
extern void ETH_PrepareIPHeader (uint32_t length);
extern void ETH_PrepareTCPHeader (uint32_t acks, uint32_t flags);
extern uint32_t ETH_CalculateChecksum (uint8_t * buffer, uint32_t length, uint32_t type);
extern void ETH_SendARPReply (void);
extern void ETH_SendICMPReply (void);
extern void ETH_SendTCP (uint32_t acks, uint32_t flags);
extern void ETH_SendTCPData (uint32_t payloadlength, uint32_t last);
extern void ETH_SendTCPSYN (uint8_t * server_MAC, uint8_t * server_IP, uint16_t server_port);

#endif//__ASSEMBLER__

/************************************************************
* ETHERNET DEFINITIONS										*
************************************************************/

#define ETH_HEADER_LENGTH				14
#define ETH_HEADER_LENGTH_IP			20
#define ETH_HEADER_LENGTH_TCP			20

#define ETH_DST_MAC						0
#define ETH_SRC_MAC						6
#define ETH_TYPE						12
#define ETH_TYPE_ARP_LE					0x0608
#define ETH_TYPE_IP_LE					0x0008

#define ETH_ARP_OPCODE					20
#define ETH_ARP_OPCODE_REPLY_LE			0x0200
#define ETH_ARP_SRC_MAC					22
#define ETH_ARP_SRC_IP					28
#define ETH_ARP_DST_MAC					32
#define ETH_ARP_DST_IP					38

#define ETH_IP							14
#define ETH_IP_HLEN_VER					14
#define ETH_IP_TOTLEN					16
#define ETH_IP_FLAGS					20
#define ETH_IP_TTL						22
#define ETH_IP_PROTOCOL					23
#define ETH_IP_PROTOCOL_ICMP			0x01
#define ETH_IP_PROTOCOL_TCP				0x06
#define ETH_IP_CHECKSUM					24
#define ETH_IP_SRC_IP					26
#define ETH_IP_DST_IP					30

#define ETH_ICMP_TYPE					34
#define ETH_ICMP_TYPE_REQUEST			0x08
#define ETH_ICMP_TYPE_REPLY				0x00
#define ETH_ICMP_CODE					35
#define ETH_ICMP_CHECKSUM				36

#define ETH_TCP_SRC_PORT				34
#define ETH_TCP_DST_PORT				36
#define ETH_TCP_SEQ						38
#define ETH_TCP_ACK						42
#define ETH_TCP_HLEN					46
#define ETH_TCP_FLAGS					47
#define ETH_TCP_FLAGS_FIN				0x01
#define ETH_TCP_FLAGS_SYN				0x02
#define ETH_TCP_FLAGS_RST				0x04
#define ETH_TCP_FLAGS_PUSH				0x08
#define ETH_TCP_FLAGS_SYNACK			0x12
#define ETH_TCP_FLAGS_ACK				0x10
#define ETH_TCP_FLAGS_PSHACK			0x18
#define ETH_TCP_WIN_SIZE				48
#define ETH_TCP_CHECKSUM				50
#define ETH_TCP_OPTIONS					54

#endif//_USE_ETHERNET_

#endif//_ETHERNET_H_
