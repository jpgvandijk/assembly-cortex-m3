/************************************************************************************
*
* Author: J.P.G. van Dijk
*
* Points of special interest in the errate sheet:
* 5:	Use the lower segment of the buffer memory for the receive buffer, starting
*		at address 0000h.
* 6:	If the receive packet pending interrupt is enabled, the INT pin will continue
*		to reliably become asserted when a packet arrives. This errata applies only
*		to the interrupt flag. If polling to see if a packet is pending, check the
*		value in EPKTCNT.
* 12:	Conditionally reset the internal transmit logic based on the Transmit Error
*		Interrupt Flag, the interrupt flag should be cleared after the Reset is
*		completed.
* 14:	Ensure that only odd addresses are written to the ERXRDPT registers (derive
*		a suitable value to write to ERXRDPT by subtracting one from the Next Packet
*		Pointer).
* 18:	Packets can be accepted that do not meet any of the enabled filter criteria.
*		This will occur if the receive packet is less than or equal to 64+EPMO bytes
*		long.
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"enc28j60.h"
			
			#ifdef		_USE_ETHERNET_





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Functions
			.global		ENC_Init
			.global		ENC_Reset
			.global		ENC_EnableReceiver
			.global		ENC_TaskWaitForPacketAvailable
			.global		ENC_IRQ_HANDLER
			.global		ENC_ReceivePacket
			.global		ENC_TransmitPacket
			.global		ENC_WritePhyRegister
			.global		ENC_WriteMultipleRegisters
			.global		ENC_ReadRegister
			.global		ENC_ReadBuffer
			.global		ENC_WriteRegister
			.global		ENC_WriteBuffer

			@ Variables
			.global		ENC_WritePhyRegisterScratch
			.global		ENC_Task
			.global		ENC_NextPacketPointer





@-----------------------------------------------------------@
@ VARIABLES													@
@-----------------------------------------------------------@

			.section	.noinit.ENC_Variables
			.type		ENC_Task, "object"
			.type		ENC_NextPacketPointer, "object"
			.align		2
ENC_Task:
			.space		4
ENC_NextPacketPointer:
			.space		2





@-----------------------------------------------------------@
@ FUNCTIONS													@
@-----------------------------------------------------------@

			.section	.text.ENC_Init
			.type		ENC_Init, "function"
ENC_Init:

			@ Save registers
			push		{lr}

			@ Initialize the SS pin
			movs		r0, ENC_SS_GPIO
			movs		r1, ENC_SS_PIN
			movs		r2, PIN_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure

			@ Deselect the chip
			ldr			r0, =ENC_SS_BSRR
			movs		r1, (1 << ENC_SS_PIN)
			str			r1, [r0]

			@ Initialize the reset pin
			movs		r0, ENC_RST_GPIO
			movs		r1, ENC_RST_PIN
			movs		r2, PIN_OUTPUT_NORMAL_50MHz
			bl			PIN_Configure

			@ Reset
			ldr			r0, =ENC_RST_BSRR
			movs		r1, (1 << ENC_RST_PIN)
			str			r1, [r0]

			@ Initialize the interrupt pin
			movs		r0, ENC_IRQ_GPIO
			movs		r1, ENC_IRQ_PIN
			movs		r2, PIN_INPUT_FLOATING
			bl			PIN_Configure

			@ Select port for IRQ external interrupt
			ldr			r0, =ENC_IRQ_EXTICR
			movs		r2, ENC_IRQ_GPIO
			ldr			r1, [r0]
			bfi			r1, r2, #ENC_IRQ_EXTICR_LSB, #4
			str			r1, [r0]

			@ EXTI Line interrupt on falling edge
			ldr			r0, =STM_EXTI
			movs		r2, #(1 << ENC_IRQ_PIN)
			ldr			r1, [r0, (EXTI_IMR - STM_EXTI)]
			orrs		r1, r2
			str			r1, [r0, (EXTI_IMR - STM_EXTI)]
			ldr			r1, [r0, (EXTI_EMR - STM_EXTI)]
			bics		r1, r2
			str			r1, [r0, (EXTI_EMR - STM_EXTI)]
			ldr			r1, [r0, (EXTI_RTSR - STM_EXTI)]
			bics		r1, r2
			str			r1, [r0, (EXTI_RTSR - STM_EXTI)]
			ldr			r1, [r0, (EXTI_FTSR - STM_EXTI)]
			orrs		r1, r2
			str			r1, [r0, (EXTI_FTSR - STM_EXTI)]

			@ Set EXTI priority, interrupt not yet enabled
			movs		r0, ENC_IRQ_NUMBER
			movs		r1, ENC_IRQ_PRIORITY
			bl			NVIC_IRQSetPriority

			@ Restore registers and return
			pop			{pc}





			.section	.text.ENC_Reset
			.type		ENC_Reset, "function"
ENC_Reset:

			@ Save registers
			push		{lr}

			@ Reset the state variables
			ldr			r0, =ENC_NextPacketPointer
			movs		r1, RXSTART_INIT
			strh		r1, [r0]

			@ Reset and configure the ethernet controller
			ldr			r0, =_enc_reset_data_
			movs		r1, #((_enc_reset_data_end_ - _enc_reset_data_) / 2)
			bl			ENC_WriteMultipleRegisters

			@ Configure the PHY
			movs		r0, PHCON1
			movs		r1, PHCON1_PDPXMD
			bl			ENC_WritePhyRegister
			movs		r0, PHCON2
			movs		r1, PHCON2_HDLDIS
			bl			ENC_WritePhyRegister
			movs		r0, PHLCON
			movw		r1, 0x07a4
			bl			ENC_WritePhyRegister

			@ Restore registers and return
			pop			{pc}

_enc_reset_data_:

			@ Reset
			.byte		ENC_INSTRUCTION_SC()
			.byte			ENC_INSTRUCTION_SC()

			@ Select bank 0
			.byte		ENC_INSTRUCTION_BFC(ECON1)
			.byte			(ECON1_BSEL1|ECON1_BSEL0)

			@ RX start, RX read pointer, RX end
			.byte		ENC_INSTRUCTION_WCR(ERXSTL)
			.byte			RXSTART_INIT & 0xFF
			.byte		ENC_INSTRUCTION_WCR(ERXSTH)
			.byte			RXSTART_INIT >> 8
			.byte		ENC_INSTRUCTION_WCR(ERXRDPTL)
			.byte			RXSTART_INIT & 0xFF
			.byte		ENC_INSTRUCTION_WCR(ERXRDPTH)
			.byte			RXSTART_INIT >> 8
			.byte		ENC_INSTRUCTION_WCR(ERXNDL)
			.byte			RXSTOP_INIT & 0xFF
			.byte		ENC_INSTRUCTION_WCR(ERXNDH)
			.byte			RXSTOP_INIT >> 8

			@ TX start, TX end
			.byte		ENC_INSTRUCTION_WCR(ETXSTL)
			.byte			TXSTART_INIT & 0xFF
			.byte		ENC_INSTRUCTION_WCR(ETXSTH)
			.byte			TXSTART_INIT >> 8
			.byte		ENC_INSTRUCTION_WCR(ETXNDL)
			.byte			TXSTOP_INIT & 0xFF
			.byte		ENC_INSTRUCTION_WCR(ETXNDH)
			.byte			TXSTOP_INIT >> 8

			@ Select bank 1
			.byte		ENC_INSTRUCTION_BFC(ECON1)
			.byte			(ECON1_BSEL1|ECON1_BSEL0)
			.byte		ENC_INSTRUCTION_BFS(ECON1)
			.byte			1

			@ Receive filter (only ARP broadcast, only matching MAC unicast, CRC must be correct)
			.byte		ENC_INSTRUCTION_WCR(ERXFCON)
			.byte			(ERXFCON_UCEN|ERXFCON_CRCEN|ERXFCON_PMEN)
			.byte		ENC_INSTRUCTION_WCR(EPMM0)
			.byte			0x3f										@ Check broadcast MAC
			.byte		ENC_INSTRUCTION_WCR(EPMM1)
			.byte			0x30										@ Check ARP type
			.byte		ENC_INSTRUCTION_WCR(EPMCSL)
			.byte			0xf9
			.byte		ENC_INSTRUCTION_WCR(EPMCSH)
			.byte			0xf7

			@ Select bank 2
			.byte		ENC_INSTRUCTION_BFC(ECON1)
			.byte			(ECON1_BSEL1|ECON1_BSEL0)
			.byte		ENC_INSTRUCTION_BFS(ECON1)
			.byte			2

			@ Bring the MAC out of reset
			.byte		ENC_INSTRUCTION_WCR(MACON2)
			.byte			0x00

			@ Enable flow control, and packet reception
			.byte		ENC_INSTRUCTION_WCR(MACON1)
			.byte			(MACON1_MARXEN|MACON1_TXPAUS|MACON1_RXPAUS)

			@ Automatic padding to 60 bytes, and FCS generation, check frame length, full-duplex operation
			.byte		ENC_INSTRUCTION_BFS(MACON3)
			.byte			(MACON3_PADCFG0|MACON3_TXCRCEN|MACON3_FRMLNEN|MACON3_FULDPX)

			@ Write the Non-Back-to-Back Inter-Packet Gap
			.byte		ENC_INSTRUCTION_WCR(MAIPGL)
			.byte			0x12
			.byte		ENC_INSTRUCTION_WCR(MAIPGH)
			.byte			0x0C

			@ Write the Back-to-Back Inter-Packet Gap
			.byte		ENC_INSTRUCTION_WCR(MABBIPG)
			.byte			0x12

			@ Set the maximum frame length
			.byte		ENC_INSTRUCTION_WCR(MAMXFLL)
			.byte			(MAX_FRAMELEN & 0xFF)
			.byte		ENC_INSTRUCTION_WCR(MAMXFLH)
			.byte			(MAX_FRAMELEN >> 8)

			@ Select bank 3
			.byte		ENC_INSTRUCTION_BFS(ECON1)
			.byte			3

			@ Set the local MAC address
			.byte		ENC_INSTRUCTION_WCR(MAADR5)
			.byte			ENC_MAC0
			.byte		ENC_INSTRUCTION_WCR(MAADR4)
			.byte			ENC_MAC1
			.byte		ENC_INSTRUCTION_WCR(MAADR3)
			.byte			ENC_MAC2
			.byte		ENC_INSTRUCTION_WCR(MAADR2)
			.byte			ENC_MAC3
			.byte		ENC_INSTRUCTION_WCR(MAADR1)
			.byte			ENC_MAC4
			.byte		ENC_INSTRUCTION_WCR(MAADR0)
			.byte			ENC_MAC5

			@ Enable the packet pending interrupt
			.byte		ENC_INSTRUCTION_BFS(EIE)
			.byte			(EIE_INTIE|EIE_PKTIE)

			@ Align
_enc_reset_data_end_:
			.align		1





			.section	.text.ENC_EnableReceiver
			.type		ENC_EnableReceiver, "function"
ENC_EnableReceiver:

			@ Save registers
			push		{lr}

			@ Enable the receiver in the MAC
			movs		r0, ENC_INSTRUCTION_BFS(ECON1)
			movs		r1, ECON1_RXEN
			bl			ENC_WriteRegister

			@ Clear the wake-up task
			ldr			r0, =ENC_Task
			movs		r1, #0
			str			r1, [r0]

			@ Enable the interrupt (task is non-privileged)
			movs		r0, ENC_IRQ_NUMBER
			movs		r1, SVC_IRQEnable
			svc			SVC_IRQ

			@ Restore registers and return
			pop			{pc}





			.section	.text.ENC_TaskWaitForPacketAvailable
			.type		ENC_TaskWaitForPacketAvailable, "function"
ENC_TaskWaitForPacketAvailable:

			@ Save registers
			push		{lr}

			@ Check the packet counter to see if there are additional packets
0:			movs		r0, ENC_INSTRUCTION_BFC(ECON1)
			movs		r1, (ECON1_BSEL1|ECON1_BSEL0)
			bl			ENC_WriteRegister
			movs		r0, ENC_INSTRUCTION_BFS(ECON1)
			movs		r1, 1
			bl			ENC_WriteRegister
			movs		r0, ENC_INSTRUCTION_RCR(EPKTCNT)
			bl			ENC_ReadRegister
			cbnz		r0, 1f

			@ Stop the task (task is non-privileged)
			ldr			r2, =ENC_Task
			ldr			r1, =KERNEL_TaskRunning
			ldr			r1, [r1]
			movs		r0, SVC_ForceContextSwitchIndefinitely
			str			r1, [r2]
			svc			SVC_ForceContextSwitch

			@ An interrupt has woken up the task, check for packet
			b			0b

			@ A packet was received, restore registers and return
1:			pop			{pc}





			.section	.text.ENC_IRQ_HANDLER
			.type		ENC_IRQ_HANDLER, "function"
ENC_IRQ_HANDLER:

			@ The IRQ handler should not communicate with the ENC
			@ as it might not be able to get exclusive access

			@ Save registers
			push		{lr}

			@ Wake-up the task if required
			ldr			r0, =ENC_Task
			ldr			r0, [r0]
			cbz			r0, 0f
			bl			KERNEL_AddTaskToReadyList
			ldr			r0, =ENC_Task
			movs		r1, #0
			str			r1, [r0]

			@ Clear the flag
0:			ldr			r0, =EXTI_PR
			movs		r1, #(1 << ENC_IRQ_PIN)
			str			r1, [r0]

			@ Restore registers and return
			pop			{pc}





			.section	.text.ENC_ReceivePacket
			.type		ENC_ReceivePacket, "function"
ENC_ReceivePacket:

			@ Arguments:
			@ r0: Buffer
			@ r1: Buffersize

			@ Return values:
			@ r0: Packetsize, 0 if error

			@ Save registers and arguments
			push		{r4, r5, r6, lr}
			cpy			r5, r0
			cpy			r6, r1

			@ Update the read pointer (bank 0) and the next packet pointer
			ldr			r4, =ENC_NextPacketPointer
			movs		r0, ENC_INSTRUCTION_BFC(ECON1)
			movs		r1, (ECON1_BSEL1|ECON1_BSEL0)
			bl			ENC_WriteRegister
			movs		r0, ENC_INSTRUCTION_WCR(ERDPTL)
			ldrb		r1, [r4, #0]
			bl			ENC_WriteRegister
			movs		r0, ENC_INSTRUCTION_WCR(ERDPTH)
			ldrb		r1, [r4, #1]
			bl			ENC_WriteRegister
			movs		r0, ENC_INSTRUCTION_RBM()
			bl			ENC_ReadRegister
			strb		r0, [r4, #0]
			movs		r0, ENC_INSTRUCTION_RBM()
			bl			ENC_ReadRegister
			strb		r0, [r4, #1]

			@ Read the packet length, remove the CRC and limit to the buffer size
			movs		r0, ENC_INSTRUCTION_RBM()
			bl			ENC_ReadRegister
			cpy			r4, r0
			movs		r0, ENC_INSTRUCTION_RBM()
			bl			ENC_ReadRegister
			bfi			r4, r0, #8, #8
			subs		r4, #4
			cmp			r4, r6
			it			hi
			movhi		r4, r6

			@ Read the receive status, check if the packet was received ok
			movs		r0, ENC_INSTRUCTION_RBM()
			bl			ENC_ReadRegister
			tst			r0, #(1 << 7)
			itt			eq
			moveq		r4, #0
			beq			0f
			movs		r0, ENC_INSTRUCTION_RBM()
			bl			ENC_ReadRegister

			@ Read the packet
			cpy			r0, r5
			cpy			r1, r4
			bl			ENC_ReadBuffer

			@ Free the memory
0:			ldr			r5, =ENC_NextPacketPointer
			ldrh		r5, [r5]
			subs		r5, #1
			movw		r0, RXSTOP_INIT
			cmp			r5, r0
			it			hi
			movhi		r5, r0
			movs		r0, ENC_INSTRUCTION_WCR(ERXRDPTL)
			cpy			r1, r5
			bl			ENC_WriteRegister
			movs		r0, ENC_INSTRUCTION_WCR(ERXRDPTH)
			lsrs		r1, r5, #8
			bl			ENC_WriteRegister

			@ Decrement the packet counter
			movs		r0, ENC_INSTRUCTION_BFS(ECON2)
			movs		r1, ECON2_PKTDEC
			bl			ENC_WriteRegister

			@ Restore registers and return with the packet size in r0
			cpy			r0, r4
			pop			{r4, r5, r6, pc}





			.section	.text.ENC_TransmitPacket
			.type		ENC_TransmitPacket, "function"
ENC_TransmitPacket:

			@ Arguments:
			@ r0: Buffer
			@ r1: Packetsize

			@ Save registers and arguments
			push		{r4, r5, lr}
			cpy			r4, r0
			cpy			r5, r1

			@ Wait for the previous transmission to finish
0:			movs		r0, ENC_INSTRUCTION_RCR(ECON1)
			bl			ENC_ReadRegister
			tst			r0, ECON1_TXRTS
			bne			0b

			@ Set the write pointer and transmit buffer end pointer (bank 0)
			movs		r0, ENC_INSTRUCTION_BFC(ECON1)
			movs		r1, (ECON1_BSEL1|ECON1_BSEL0)
			bl			ENC_WriteRegister
			movs		r0, ENC_INSTRUCTION_WCR(EWRPTL)
			movs		r1, (TXSTART_INIT & 0xFF)
			bl			ENC_WriteRegister
			movs		r0, ENC_INSTRUCTION_WCR(EWRPTH)
			movs		r1, (TXSTART_INIT >> 8)
			bl			ENC_WriteRegister
			movs		r0, ENC_INSTRUCTION_WCR(ETXNDL)
			movw		r1, TXSTART_INIT
			adds		r1, r5
			bl			ENC_WriteRegister
			movs		r0, ENC_INSTRUCTION_WCR(ETXNDH)
			movw		r1, TXSTART_INIT
			adds		r1, r5
			lsrs		r1, #8
			bl			ENC_WriteRegister

			@ Write the control byte (no override)
			movs		r0, ENC_INSTRUCTION_WBM()
			movs		r1, 0x00
			bl			ENC_WriteRegister

			@ Write the packet
			cpy			r0, r4
			cpy			r1, r5
			bl			ENC_WriteBuffer

			@ Reset the transmit logic if there was an error
			movs		r0, ENC_INSTRUCTION_RCR(EIR)
			bl			ENC_ReadRegister
			tst			r0, EIR_TXERIF
			beq			0f
			movs		r0, ENC_INSTRUCTION_BFS(ECON1)
			movs		r1, ECON1_TXRST
			bl			ENC_WriteRegister
			movs		r0, ENC_INSTRUCTION_BFC(ECON1)
			movs		r1, ECON1_TXRST
			bl			ENC_WriteRegister
			movs		r0, ENC_INSTRUCTION_BFC(EIR)
			movs		r1, EIR_TXERIF
			bl			ENC_WriteRegister

			@ Start the transmission
0:			movs		r0, ENC_INSTRUCTION_BFS(ECON1)
			movs		r1, ECON1_TXRTS
			bl			ENC_WriteRegister

			@ Restore registers and return
			pop			{r4, r5, pc}





			.section	.text.ENC_WritePhyRegister
			.type		ENC_WritePhyRegister, "function"
ENC_WritePhyRegister:

			@ Arguments:
			@ r0: register
			@ r1: data

			@ Save registers
			push		{lr}

			@ Update the scratch memory
			ldr			r2, =ENC_WritePhyRegisterScratch
			strb		r0, [r2, (_enc_write_phy_register_scratch_reg_ - ENC_WritePhyRegisterScratch)]
			strb		r1, [r2, (_enc_write_phy_register_scratch_datalow_ - ENC_WritePhyRegisterScratch)]
			lsrs		r1, #8
			strb		r1, [r2, (_enc_write_phy_register_scratch_datahigh_ - ENC_WritePhyRegisterScratch)]

			@ Send the list of instructions
			cpy			r0, r2
			movs		r1, #6
			bl			ENC_WriteMultipleRegisters

			@ Wait for the command to be processed by the PHY
0:			movs		r0, ENC_INSTRUCTION_RMMR(MISTAT)
			bl			ENC_ReadRegister
			tst			r0, MISTAT_BUSY
			bne			0b

			@ Restore registers and return
			pop			{pc}





			.section	.data.ENC_WritePhyRegisterSratch
			.type		ENC_WritePhyRegisterScratch, "object"
ENC_WritePhyRegisterScratch:

			@ Select Bank 2
			.byte		ENC_INSTRUCTION_BFC(ECON1)
			.byte			(ECON1_BSEL1|ECON1_BSEL0)
			.byte		ENC_INSTRUCTION_BFS(ECON1)
			.byte			2

			@ Select the register
			.byte		ENC_INSTRUCTION_WCR(MIREGADR)
_enc_write_phy_register_scratch_reg_:
			.byte			0x00

			@ Set the data
			.byte		ENC_INSTRUCTION_WCR(MIWRL)
_enc_write_phy_register_scratch_datalow_:
			.byte			0x00
			.byte		ENC_INSTRUCTION_WCR(MIWRH)
_enc_write_phy_register_scratch_datahigh_:
			.byte			0x00

			@ Select Bank 3
			.byte		ENC_INSTRUCTION_BFS(ECON1)
			.byte			3





			.section	.text.ENC_WriteMultipleRegisters
			.type		ENC_WriteMultipleRegisters, "function"
ENC_WriteMultipleRegisters:

			@ Write the list of (instruction, data)-pairs
			push		{r4, r5, lr}
			cpy			r4, r0
			cpy			r5, r1

0:			ldrb		r0, [r4], #1
			ldrb		r1, [r4], #1
			bl			ENC_WriteRegister
			subs		r5, #1
			bne			0b

			pop			{r4, r5, pc}





			.section	.text.ENC_ReadRegister
			.type		ENC_ReadRegister, "function"
ENC_ReadRegister:

			@ Arguments:
			@ r0: Instruction, bit 7 set if dummy read required (bit 7 is always transmitted as 0)

			@ Return values:
			@ r0: Data

			@ Save registers
			push		{r4, lr}

			@ Save argument
			cpy			r4, r0

			@ Get exclusive access
			movs		r0, ENC_SPI_BAUDRATE
			bl			ENC_SPI_GET_EXCLUSIVE_ACCESS

			@ Enable the SPI
			bl			ENC_SPI_ENABLE_DEFAULT

			@ Select the chip
			ldr			r0, =ENC_SS_BRR
			movs		r1, (1 << ENC_SS_PIN)
			str			r1, [r0]

			@ Write the instruction
			ands		r0, r4, #0x7F
			bl			ENC_SPI_TRANSFER

			@ Possibly write a dummy byte and read the data byte
			tst			r4, #(1 << 7)
			it			ne
			blne		ENC_SPI_TRANSFER
			bl			ENC_SPI_TRANSFER
			cpy			r4, r0

			@ Deselect the chip
			ldr			r2, =ENC_SS_BSRR
			movs		r1, (1 << ENC_SS_PIN)
			str			r1, [r2]

			@ Disable the SPI and return to normal mode
			bl			ENC_SPI_DISABLE_DEFAULT

			@ Clear exclusive access
			bl			ENC_SPI_CLEAR_EXCLUSIVE_ACCESS

			@ Restore registers and return with the data byte in r0
			cpy			r0, r4
			pop			{r4, pc}





			.section	.text.ENC_ReadBuffer
			.type		ENC_ReadBuffer, "function"
ENC_ReadBuffer:

			@ Arguments:
			@ r0: Buffer
			@ r1: Length

			@ Save registers and arguments
			push		{r0, r1, lr}

			@ Get exclusive access
			movs		r0, ENC_SPI_BAUDRATE
			bl			ENC_SPI_GET_EXCLUSIVE_ACCESS

			@ Enable the SPI
			bl			ENC_SPI_ENABLE_DEFAULT

			@ Select the chip
			ldr			r0, =ENC_SS_BRR
			movs		r1, (1 << ENC_SS_PIN)
			str			r1, [r0]

			@ Write instruction for buffer memory read
			movs		r0, ENC_INSTRUCTION_RBM()
			bl			ENC_SPI_TRANSFER

			@ Disable the SPI to setup the DMA
			bl			ENC_SPI_DISABLE_DEFAULT

			@ Setup the DMA
			pop			{r0, r1}
			bl			ENC_SPI_ENABLE_RX_ONLY_DMA

			@ Wait for the DMA transfers to complete
			bl			ENC_SPI_WAIT_RX_ONLY_DMA

			@ Deselect the chip
			ldr			r2, =ENC_SS_BSRR
			movs		r1, (1 << ENC_SS_PIN)
			str			r1, [r2]

			@ Disable the SPI and return to normal mode
			bl			ENC_SPI_DISABLE_RX_ONLY_DMA

			@ Clear exclusive access
			bl			ENC_SPI_CLEAR_EXCLUSIVE_ACCESS

			@ Restore registers and return
			pop			{pc}





			.section	.text.ENC_WriteRegister
			.type		ENC_WriteRegister, "function"
ENC_WriteRegister:

			@ Arguments:
			@ r0: Instruction
			@ r1: Data

			@ Save registers
			push		{r0, r1, lr}

			@ Get exclusive access
			movs		r0, ENC_SPI_BAUDRATE
			bl			ENC_SPI_GET_EXCLUSIVE_ACCESS

			@ Enable the SPI
			bl			ENC_SPI_ENABLE_DEFAULT

			@ Select the chip
			ldr			r0, =ENC_SS_BRR
			movs		r1, (1 << ENC_SS_PIN)
			str			r1, [r0]

			@ Write the instruction and the data byte
			pop			{r0}
			bl			ENC_SPI_TRANSFER
			pop			{r0}
			bl			ENC_SPI_TRANSFER

			@ Deselect the chip
			ldr			r2, =ENC_SS_BSRR
			movs		r1, (1 << ENC_SS_PIN)
			str			r1, [r2]

			@ Disable the SPI and return to normal mode
			bl			ENC_SPI_DISABLE_DEFAULT

			@ Clear exclusive access
			bl			ENC_SPI_CLEAR_EXCLUSIVE_ACCESS

			@ Restore registers and return
			pop			{pc}





			.section	.text.ENC_WriteBuffer
			.type		ENC_WriteBuffer, "function"
ENC_WriteBuffer:

			@ Arguments:
			@ r0: Buffer
			@ r1: Length

			@ Save registers
			push		{r0, r1, lr}

			@ Get exclusive access
			movs		r0, ENC_SPI_BAUDRATE
			bl			ENC_SPI_GET_EXCLUSIVE_ACCESS

			@ Enable the SPI
			bl			ENC_SPI_ENABLE_DEFAULT

			@ Select the chip
			ldr			r0, =ENC_SS_BRR
			movs		r1, (1 << ENC_SS_PIN)
			str			r1, [r0]

			@ Write the instruction
			movs		r0, ENC_INSTRUCTION_WBM()
			bl			ENC_SPI_TRANSFER

			@ Disable the SPI to setup the DMA
			bl			ENC_SPI_DISABLE_DEFAULT

			@ Setup the DMA
			pop			{r0, r1}
			bl			ENC_SPI_ENABLE_TX_ONLY_DMA

			@ Wait for the DMA transfers to complete
			bl			ENC_SPI_WAIT_TX_ONLY_DMA

			@ Disable the SPI and return to normal mode
			bl			ENC_SPI_DISABLE_TX_ONLY_DMA

			@ Deselect the chip
			ldr			r2, =ENC_SS_BSRR
			movs		r1, (1 << ENC_SS_PIN)
			str			r1, [r2]

			@ Clear exclusive access
			bl			ENC_SPI_CLEAR_EXCLUSIVE_ACCESS

			@ Restore registers and return
			pop			{pc}





			#endif
			