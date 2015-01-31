/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"ethernet.h"
			
			#ifdef		_USE_ETHERNET_





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Functions
			.global		ETH_AnalyzePacket
			.global		ETH_PrepareEthernetHeader
			.global		ETH_PrepareIPHeader
			.global		ETH_PrepareTCPHeader
			.global		ETH_CalculateChecksum
			.global		ETH_SendARPReply
			.global		ETH_SendICMPReply
			.global		ETH_SendTCP
			.global		ETH_SendTCPData
			.global		ETH_SendTCPSYN

			@ Constants
			.global		ENC_DEVICE_MAC
			.global		ENC_DEVICE_IP
			.global		ENC_SERVER_MAC
			.global		ENC_SERVER_IP

			@ Variables
			.global		ETH_Buffer
			.global		ETH_Size
			.global		ETH_SequenceNumber





@-----------------------------------------------------------@
@ CONSTANTS													@
@-----------------------------------------------------------@

			.section	.rodata.ETH_Constants
			.type		ENC_SERVER_IP, "object"
			.type		ENC_DEVICE_IP, "object"
			.type		ENC_SERVER_MAC, "object"
			.type		ENC_DEVICE_MAC, "object"
			.align		2
ENC_SERVER_IP:
			.byte		SERVER_IP0
			.byte		SERVER_IP1
			.byte		SERVER_IP2
			.byte		SERVER_IP3
ENC_DEVICE_IP:
			.byte		ENC_IP0
			.byte		ENC_IP1
			.byte		ENC_IP2
			.byte		ENC_IP3
ENC_SERVER_MAC:
			.byte		SERVER_MAC0
			.byte		SERVER_MAC1
			.byte		SERVER_MAC2
			.byte		SERVER_MAC3
			.byte		SERVER_MAC4
			.byte		SERVER_MAC5
ENC_DEVICE_MAC:
			.byte		ENC_MAC0
			.byte		ENC_MAC1
			.byte		ENC_MAC2
			.byte		ENC_MAC3
			.byte		ENC_MAC4
			.byte		ENC_MAC5





@-----------------------------------------------------------@
@ VARIABLES													@
@-----------------------------------------------------------@

			.section	.noinit.ETH_Variables
			.type		ETH_Buffer, "object"
			.type		ETH_Size, "object"
			.type		ETH_SequenceNumber, "object"
			.align		2
ETH_Buffer:
			.space		ETH_BUFFER_SIZE
ETH_Size:
			.space		2
ETH_SequenceNumber:
			.space		1





@-----------------------------------------------------------@
@ FUNCTIONS													@
@-----------------------------------------------------------@

			.section	.text.ETH_AnalyzePacket
			.type		ETH_AnalyzePacket, "function"
ETH_AnalyzePacket:

			@ Return values:
			@ r0: packet type

			@ Any packet should at least be 42 bytes in size to have a valid header
			@ This also discards packets that were not received ok (size = 0)
			ldr			r0, =ETH_Size
			ldrh		r0, [r0]
			cmp			r0, #42
			blo			_eth_analyze_packet_error_

			@ Get the ethernet type field and our IP address
			ldr			r0, =ETH_Buffer
			ldrh		r1, [r0, ETH_TYPE]
			ldr			r2, =ENC_DEVICE_IP
			ldr			r2, [r2]

			@ Check for ARP type
			cmp			r1, ETH_TYPE_ARP_LE
			bne			0f

			@ Check the IP address in the ARP header
			ldr			r1, [r0, ETH_ARP_DST_IP]
			cmp			r1, r2
			bne			_eth_analyze_packet_error_

			@ A valid ARP packet was received, return
			movs		r0, ETH_ANALYZE_TYPE_ARP
			bx			lr

			@ Check for IP type
0:			cmp			r1, ETH_TYPE_IP_LE
			bne			3f

			@ Check the IP version
			ldrb		r1, [r0, ETH_IP_HLEN_VER]
			cmp			r1, #0x45
			bne			_eth_analyze_packet_error_

			@ Check the IP address in the IP header
			ldr			r1, [r0, ETH_IP_DST_IP]
			cmp			r1, r2
			bne			_eth_analyze_packet_error_

			@ A valid IP packet was received, analyze further
			@ Get the IP protocol field
			ldrb		r1, [r0, ETH_IP_PROTOCOL]

			#if defined(ETH_SUPPORT_ICMP)

			@ Check for ICMP protocol
			cmp			r1, ETH_IP_PROTOCOL_ICMP
			bne			1f

			@ Check ICMP type
			ldrb		r1, [r0, ETH_ICMP_TYPE]
			cmp			r1, ETH_ICMP_TYPE_REQUEST
			bne			_eth_analyze_packet_error_

			@ A valid ICMP echo request was received, return
			movs		r0, ETH_ANALYZE_TYPE_ICMP_REQUEST
			bx			lr

			#endif
1:
			#if defined(ETH_SUPPORT_TCP_CLIENT) || defined(ETH_SUPPORT_TCP_SERVER)

			@ Check for TCP protocol
			cmp			r1, ETH_IP_PROTOCOL_TCP
			bne			3f

			@ Get the TCP destination port
			ldrh		r1, [r0, ETH_TCP_DST_PORT]

			#if defined(ETH_SUPPORT_TCP_CLIENT)

			@ Check the port
			cmp			r1, ENC_DEVICE_CLIENT_PORT_LE
			bne			2f

			@ Check the source IP
			ldr			r1, [r0, ETH_IP_SRC_IP]
			ldr			r2, =ENC_SERVER_IP
			ldr			r2, [r2]
			cmp			r1, r2
			bne			_eth_analyze_packet_error_

			@ A valid TCP packet for the client was received, return
			movs		r0, ETH_ANALYZE_TYPE_TCP_CLIENT
			bx			lr

			#endif
2:
			#if defined(ETH_SUPPORT_TCP_SERVER)

			@ Check the port
			cmp			r1, ENC_DEVICE_SERVER_PORT_LE
			bne			3f

			@ A valid TCP packet for the server was received, return
			movs		r0, ETH_ANALYZE_TYPE_TCP_SERVER
			bx			lr

			#endif
			#endif

			@ Incorrect packet, return
			@ Unsupported ethernet type or IP protocol, return
_eth_analyze_packet_error_:
3:			movs		r0, ETH_ANALYZE_TYPE_ERROR
			bx			lr





			.section	.text.ETH_PrepareEthernetHeader
			.type		ETH_PrepareEthernetHeader, "function"
ETH_PrepareEthernetHeader:

			@ Set the source as destination, and set our MAC as source
			ldr			r0, =ETH_Buffer
			ldr			r1, =ENC_DEVICE_MAC
			ldrh		r2, [r0, ETH_SRC_MAC]
			ldr			r3, [r0, ETH_SRC_MAC+2]
			strh		r2, [r0, ETH_DST_MAC]
			str			r3, [r0, ETH_DST_MAC+2]
			ldrh		r2, [r1, #0]
			ldr			r3, [r1, #2]
			strh		r2, [r0, ETH_SRC_MAC]
			str			r3, [r0, ETH_SRC_MAC+2]
			bx			lr





			.section	.text.ETH_PrepareIPHeader
			.type		ETH_PrepareIPHeader, "function"
ETH_PrepareIPHeader:

			@ Arguments:
			@ r0: length
			
			@ Save registers
			push		{lr}

			@ Set the source as destination, and set our IP as source
			ldr			r1, =ETH_Buffer
			ldr			r2, =ENC_DEVICE_IP
			ldr			r3, [r1, ETH_IP_SRC_IP]
			str			r3, [r1, ETH_IP_DST_IP]
			ldr			r3, [r2, #0]
			str			r3, [r1, ETH_IP_SRC_IP]

			@ Set the total length
			rev16		r0, r0
			strh		r0, [r1, ETH_IP_TOTLEN]

			@ No fragments
			movs		r0, #0x0040
			strh		r0, [r1, ETH_IP_FLAGS]

			@ Set TTL
			movs		r0, #64
			strb		r0, [r1, ETH_IP_TTL]

			@ Set checksum
			movs		r0, #0
			strh		r0, [r1, ETH_IP_CHECKSUM]
			adds		r0, r1, ETH_IP
			movs		r1, ETH_HEADER_LENGTH_IP
			movs		r2, ETH_CHECKSUM_IP
			bl			ETH_CalculateChecksum
			rev16		r0, r0
			ldr			r1, =ETH_Buffer
			strh		r0, [r1, ETH_IP_CHECKSUM]

			@ Return
			pop			{pc}





			.section	.text.ETH_PrepareTCPHeader
			.type		ETH_PrepareTCPHeader, "function"
ETH_PrepareTCPHeader:

			@ Arguments:
			@ r0: number of acknowledgements
			@ r1: flags

			@ Save registers
			push		{lr}

			@ Update the sequence and acknowledge numbers
			ldr			r2, =ETH_Buffer
			ldr			r3, [r2, ETH_TCP_SEQ]
			rev			r3, r3
			adds		r0, r3
			rev			r0, r0
			ldr			r3, [r2, ETH_TCP_ACK]
			str			r0, [r2, ETH_TCP_ACK]

			@ Generate a new sequence number for SYN packets
			tst			r1, ETH_TCP_FLAGS_SYN
			beq			0f
			ldr			r2, =ETH_SequenceNumber
			ldrb		r0, [r2]
			adds		r0, #1
			strb		r0, [r2]
			ldr			r2, =ETH_Buffer
			bfi			r3, r0, #4, #8
0:			str			r3, [r2, ETH_TCP_SEQ]

			@ Swap the source and destination ports
			ldrh		r3, [r2, ETH_TCP_DST_PORT]
			ldrh		r0, [r2, ETH_TCP_SRC_PORT]
			strh		r0, [r2, ETH_TCP_DST_PORT]
			strh		r3, [r2, ETH_TCP_SRC_PORT]

			@ Set the flags
			strb		r1, [r2, ETH_TCP_FLAGS]

			@ Update the length for SYN packets
			tst			r1, ETH_TCP_FLAGS_SYN
			ittee		eq
			moveq		r0, #0x50
			moveq		r1, #0
			movne		r0, #0x60
			movne		r1, #4

			@ Set the header length
			strb		r0, [r2, ETH_TCP_HLEN]

			@ Set checksum
			movs		r0, #0
			strh		r0, [r2, ETH_TCP_CHECKSUM]
			adds		r0, r2, ETH_IP_SRC_IP
			adds		r1, (ETH_HEADER_LENGTH_TCP + 8)
			movs		r2, ETH_CHECKSUM_TCP
			bl			ETH_CalculateChecksum
			rev16		r0, r0
			ldr			r1, =ETH_Buffer
			strh		r0, [r1, ETH_TCP_CHECKSUM]

			@ Return
			pop			{pc}





			.section	.text.ETH_CalculateChecksum
			.type		ETH_CalculateChecksum, "function"
ETH_CalculateChecksum:

			@ Arguments:
			@ r0: buffer
			@ r1: length
			@ r2: type

			@ Correction for type
			cmp			r2, ETH_CHECKSUM_TCP
			ite			eq
			subeq		r3, r1, #2
			movne		r3, #0

			@ Sum
			subs		r1, #1
			cmp			r1, #0
			ble			1f
0:			ldrh		r2, [r0], #2
			rev16		r2, r2
			adds		r3, r2
			subs		r1, #2
			bgt			0b

			@ Possibly add a last byte
1:			itt			eq
			ldrbeq		r2, [r0]
			addeq		r3, r3, r2, LSL #8

			@ Correct for one's complement sum
			movw		r1, #0xFFFF
2:			ubfx		r2, r3, #16, #16
			cbz			r2, 3f
			ands		r3, r1
			adds		r3, r2
			b			2b

			@ Return one's complement
3:			mvns		r0, r3
			bx			lr





			.section	.text.ETH_SendARPReply
			.type		ETH_SendARPReply, "function"
ETH_SendARPReply:

			@ Save registers
			push		{lr}

			@ Add the ethernet header
			bl			ETH_PrepareEthernetHeader

			@ Set the ARP opcode
			ldr			r0, =ETH_Buffer
			movs		r1, ETH_ARP_OPCODE_REPLY_LE
			strh		r1, [r0, ETH_ARP_OPCODE]

			@ Set the source as destination, and set our MAC as source
			ldr			r1, =ENC_DEVICE_MAC
			ldrh		r2, [r0, ETH_ARP_SRC_MAC]
			ldr			r3, [r0, ETH_ARP_SRC_MAC+2]
			strh		r2, [r0, ETH_ARP_DST_MAC]
			str			r3, [r0, ETH_ARP_DST_MAC+2]
			ldrh		r2, [r1, #0]
			ldr			r3, [r1, #2]
			strh		r2, [r0, ETH_ARP_SRC_MAC]
			str			r3, [r0, ETH_ARP_SRC_MAC+2]

			@ Set the source as destination, and set our IP as source
			ldr			r1, =ENC_DEVICE_IP
			ldr			r2, [r0, ETH_ARP_SRC_IP]
			str			r2, [r0, ETH_ARP_DST_IP]
			ldr			r2, [r1, #0]
			str			r2, [r0, ETH_ARP_SRC_IP]

			@ Send the packet
			movs		r1, #42
			bl			ENC_TransmitPacket

			@ Return
			pop			{pc}





			.section	.text.ETH_SendICMPReply
			.type		ETH_SendICMPReply, "function"
ETH_SendICMPReply:

			@ Save registers
			push		{lr}

			@ Add ethernet and IP header
			bl			ETH_PrepareEthernetHeader
			ldr			r0, =ETH_Buffer
			ldrh		r0, [r0, ETH_IP_TOTLEN]
			rev16		r0, r0
			bl			ETH_PrepareIPHeader

			@ Only change the type field from request to reply
			ldr			r0, =ETH_Buffer
			movs		r1, ETH_ICMP_TYPE_REPLY
			strb		r1, [r0, ETH_ICMP_TYPE]

			@ Correct the checksum
			ldrh		r1, [r0, ETH_ICMP_CHECKSUM]
			adds		r1, #8
			strh		r1, [r0, ETH_ICMP_CHECKSUM]

			@ Send the packet
			ldr			r1, =ETH_Size
			ldrh		r1, [r1]
			bl			ENC_TransmitPacket

			@ Return
			pop			{pc}





			.section	.text.ETH_SendTCP
			.type		ETH_SendTCP, "function"
ETH_SendTCP:

			@ Arguments:
			@ r0: number of acknowledgements
			@ r1: flags

			@ Save registers and arguments
			push		{r0, r1, lr}

			@ Add MSS option if SYN packet
			tst			r1, ETH_TCP_FLAGS_SYN
			beq			0f
			ldr			r0, =ETH_Buffer
			ldr			r1, =0x80050402
			str			r1, [r0, ETH_TCP_OPTIONS]

			@ Add the ethernet header
0:			bl			ETH_PrepareEthernetHeader

			@ Calculate the length (depends on MSS option)
			ldr			r0, [sp, #4]
			tst			r0, ETH_TCP_FLAGS_SYN
			ite			eq
			moveq		r0, (ETH_HEADER_LENGTH_IP + ETH_HEADER_LENGTH_TCP + 0)
			movne		r0, (ETH_HEADER_LENGTH_IP + ETH_HEADER_LENGTH_TCP + 4)

			@ Set the transmit packet size
			adds		r2, r0, ETH_HEADER_LENGTH
			ldr			r1, =ETH_Size
			strh		r2, [r1]

			@ Add the IP header, using the calculated length
			bl			ETH_PrepareIPHeader

			@ Add the TCP header
			pop			{r0, r1}
			bl			ETH_PrepareTCPHeader

			@ Send the packet
			ldr			r0, =ETH_Buffer
			ldr			r1, =ETH_Size
			ldrh		r1, [r1]
			bl			ENC_TransmitPacket

			@ Return
			pop			{pc}





			.section	.text.ETH_SendTCPData
			.type		ETH_SendTCPData, "function"
ETH_SendTCPData:

			@ Arguments:
			@ r0: payloadlength
			@ r1: last packet

			@ Save registers and arguments
			push		{r4, r5, r6, lr}
			adds		r4, r0, (ETH_HEADER_LENGTH_IP + ETH_HEADER_LENGTH_TCP)
			cpy			r5, r1
			ldr			r6, =ETH_Buffer

			@ IP header already ok, except for total length field
			rev16		r0, r4
			strh		r0, [r6, ETH_IP_TOTLEN]

			@ Update checksum
			movs		r0, #0
			strh		r0, [r6, ETH_IP_CHECKSUM]
			adds		r0, r6, ETH_IP
			movs		r1, ETH_HEADER_LENGTH_IP
			movs		r2, ETH_CHECKSUM_IP
			bl			ETH_CalculateChecksum
			rev16		r0, r0
			strh		r0, [r6, ETH_IP_CHECKSUM]

			@ TCP header already ok, except for flags
			cmp			r5, #0
			ite			eq
			moveq		r0, (ETH_TCP_FLAGS_ACK)
			movne		r0, (ETH_TCP_FLAGS_ACK | ETH_TCP_FLAGS_PUSH | ETH_TCP_FLAGS_FIN)
			strb		r0, [r6, ETH_TCP_FLAGS]

			@ Update checksum
			movs		r0, #0
			strh		r0, [r6, ETH_TCP_CHECKSUM]
			adds		r0, r6, ETH_IP_SRC_IP
			subs		r1, r4, (ETH_HEADER_LENGTH_IP - 8)
			movs		r2, ETH_CHECKSUM_TCP
			bl			ETH_CalculateChecksum
			rev16		r0, r0
			strh		r0, [r6, ETH_TCP_CHECKSUM]

			@ Send the packet
			cpy			r0, r6
			adds		r1, r4, ETH_HEADER_LENGTH
			bl			ENC_TransmitPacket

			@ Increment the sequence number if it was not the last packet
			cbnz		r5, 0f
			ldr			r0, [r6, ETH_TCP_SEQ]
			rev			r0, r0
			subs		r4, (ETH_HEADER_LENGTH_IP + ETH_HEADER_LENGTH_TCP)
			adds		r0, r4
			rev			r0, r0
			str			r0, [r6, ETH_TCP_SEQ]

			@ Restore registers and return
0:			pop			{r4, r5, r6, pc}





			.section	.text.ETH_SendTCPSYN
			.type		ETH_SendTCPSYN, "function"
ETH_SendTCPSYN:

			@ Arguments:
			@ r0: server MAC (pointer)
			@ r1: server IP (pointer)
			@ r2: server port

			@ Save registers
			push		{r4, lr}
			ldr			r4, =ETH_Buffer

			@ Create the ethernet header
			ldr			r3, [r0, #0]
			str			r3, [r4, ETH_DST_MAC]
			ldrh		r3, [r0, #4]
			strh		r3, [r4, ETH_DST_MAC+4]
			ldr			r0, =ENC_DEVICE_MAC
			ldr			r3, [r0, #0]
			str			r3, [r4, ETH_SRC_MAC]
			ldrh		r3, [r0, #4]
			strh		r3, [r4, ETH_SRC_MAC+4]
			movs		r3, ETH_TYPE_IP_LE
			strh		r3, [r4, ETH_TYPE]

			@ Create the IP header
			movs		r3, #0x0045
			strh		r3, [r4, ETH_IP_HLEN_VER]
			movs		r3, (44 << 8)
			strh		r3, [r4, ETH_IP_TOTLEN]
			movs		r3, #0
			strh		r3, [r4, ETH_IP_TOTLEN + 2]
			strh		r3, [r4, ETH_IP_CHECKSUM]
			movs		r3, #0x0040
			strh		r3, [r4, ETH_IP_FLAGS]
			movs		r3, #0x40
			strb		r3, [r4, ETH_IP_TTL]
			movs		r3, ETH_IP_PROTOCOL_TCP
			strb		r3, [r4, ETH_IP_PROTOCOL]
			ldr			r3, [r1]
			str			r3, [r4, ETH_IP_DST_IP]
			ldr			r1, =ENC_DEVICE_IP
			ldr			r3, [r1]
			str			r3, [r4, ETH_IP_SRC_IP]

			@ Create the TCP header
			strh		r2, [r4, ETH_TCP_DST_PORT]
			movs		r2, ENC_DEVICE_CLIENT_PORT_LE
			strh		r2, [r4, ETH_TCP_SRC_PORT]
			movs		r3, #0
			str			r3, [r4, ETH_TCP_CHECKSUM]
			str			r3, [r4, ETH_TCP_ACK]
			ldr			r2, =ETH_SequenceNumber
			ldrb		r0, [r2]
			adds		r0, #1
			strb		r0, [r2]
			bfi			r3, r0, #4, #8
			str			r3, [r4, ETH_TCP_SEQ]
			movs		r3, #0x60
			strb		r3, [r4, ETH_TCP_HLEN]
			movs		r3, ETH_TCP_FLAGS_SYN
			strb		r3, [r4, ETH_TCP_FLAGS]
			movs		r3, #0x0004
			strh		r3, [r4, ETH_TCP_WIN_SIZE]

			@ Create the MSS option
			ldr			r3, =0x80050402
			str			r3, [r4, ETH_TCP_OPTIONS]

			@ Set IP checksum
			adds		r0, r4, ETH_IP
			movs		r1, ETH_HEADER_LENGTH_IP
			movs		r2, ETH_CHECKSUM_IP
			bl			ETH_CalculateChecksum
			rev16		r0, r0
			strh		r0, [r4, ETH_IP_CHECKSUM]

			@ Set TCP checksum
			adds		r0, r4, ETH_IP_SRC_IP
			movs		r1, (ETH_HEADER_LENGTH_TCP + 8 + 4)
			movs		r2, ETH_CHECKSUM_TCP
			bl			ETH_CalculateChecksum
			rev16		r0, r0
			strh		r0, [r4, ETH_TCP_CHECKSUM]

			@ Send the packet
			cpy			r0, r4
			movs		r1, (ETH_HEADER_LENGTH + ETH_HEADER_LENGTH_IP + ETH_HEADER_LENGTH_TCP + 4)
			bl			ENC_TransmitPacket

			@ Restore registers and return
			pop			{r4, pc}





			#endif
			