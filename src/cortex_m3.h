/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _CORTEX_M3_H_
#define _CORTEX_M3_H_

#ifndef __ASSEMBLER__

// Global functions
extern void NVIC_IRQClearPending (uint32_t IRQ_number);
extern void NVIC_IRQSetPending (uint32_t IRQ_number);
extern void NVIC_IRQDisable (uint32_t IRQ_number);
extern void NVIC_IRQEnable (uint32_t IRQ_number);
extern void NVIC_IRQIsActive (uint32_t IRQ_number);
extern void NVIC_IRQIsPending (uint32_t IRQ_number);
extern void NVIC_IRQIsEnabled (uint32_t IRQ_number);
extern uint32_t NVIC_IRQSetPriority (uint32_t IRQ_number, uint32_t Priority);
extern uint32_t NVIC_IRQGetPriority (uint32_t IRQ_number);
extern uint32_t NVIC_IRQTrigger (uint32_t IRQ_number);
extern void NVIC_EXCSetPendingNMI (void);
extern void NVIC_EXCClearPendingSysTick (void);
extern void NVIC_EXCSetPendingSysTick (void);
extern void NVIC_EXCClearPendingPendSV (void);
extern void NVIC_EXCSetPendingPendSV (void);
extern void NVIC_EXCIsPendingNMI (void);
extern void NVIC_EXCIsPendingSysTick (void);
extern void NVIC_EXCIsPendingPendSV (void);
extern uint32_t NVIC_EXCSetPriority (uint32_t EXC_number, uint32_t Priority);
extern uint32_t NVIC_EXCGetPriority (uint32_t EXC_number);
extern void NVIC_SetPriorityGrouping (uint32_t PriorityGrouping);
extern void NVIC_SystemReset (void);
extern void ITM_SendPort0 (char character);

#endif//__ASSEMBLER__

//----------------------------------------------------
// GENERAL
//----------------------------------------------------

#define NULL 			0

//----------------------------------------------------
// NVIC
//----------------------------------------------------

// Base register
#define CM3_NVIC 		0xE000E100

// Interrupt Set-Enable Registers
#define ISER0  			0xE000E100
#define ISER1  			0xE000E104

// Interrupt Clear-Enable Registers
#define ICER0  			0xE000E180
#define ICER1  			0xE000E184

// Interrupt Set-Pending Registers
#define ISPR0  			0xE000E200
#define ISPR1  			0xE000E204

// Interrupt Clear-Pending Registers
#define ICPR0  			0xE000E280
#define ICPR1  			0xE000E284

// Interrupt Active Bit Registers
#define IABR0  			0xE000E300
#define IABR1  			0xE000E304

// Interrupt Priority Registers
#define IPR0  			0xE000E400
#define IPR1  			0xE000E404
#define IPR2  			0xE000E408
#define IPR3  			0xE000E40C
#define IPR4  			0xE000E410
#define IPR5  			0xE000E414
#define IPR6  			0xE000E418
#define IPR7  			0xE000E41C
#define IPR8  			0xE000E420

// Software Trigger Interrupt Register
#define STIR  			0xE000EF00

//----------------------------------------------------
// SCB
//----------------------------------------------------

// Base register
#define CM3_SCB 		0xE000ED00

// CPU ID Base Register
#define CPUID  			0xE000ED00

// Interrupt Control State Register
#define ICSR  			0xE000ED04

// Vector Table Offset Register
#define VTOR  			0xE000ED08

// Application Interrupt / Reset Control Register
#define AIRCR  			0xE000ED0C

// System Control Register
#define SCR  			0xE000ED10

// Configuration Control Register
#define CCR  			0xE000ED14

// System Handlers Priority Registers (4-7  8-11  12-15)
#define SHPR1 			0xE000ED18
#define SHPR2 			0xE000ED1C
#define SHPR3 			0xE000ED20

// System Handler Control and State Register
#define SHCSR  			0xE000ED24

// Configurable Fault Status Register
#define CFSR  			0xE000ED28

// Hard Fault Status Register
#define HFSR  			0xE000ED2C

// Debug Fault Status Register
#define DFSR  			0xE000ED30

// Mem Manage Address Register
#define MMFAR  			0xE000ED34

// Bus Fault Address Register
#define BFAR  			0xE000ED38

// Auxiliary Fault Status Register
#define AFSR  			0xE000ED3C

//----------------------------------------------------
// NVIC / SCB OTHERS
//----------------------------------------------------

// Base register
#define CM3_SCS 		0xE000E000

// Interrupt Control Type Register
#define ICTR 			0xE000E004

// Auxiliary Control Register
#define ACTLR 			0xE000E008

//----------------------------------------------------
// SYSTICK
//----------------------------------------------------

// SysTick Control and Status Register
#define SYST_CTRL 		0xE000E010

// SysTick Reload Value Register
#define SYST_LOAD 		0xE000E014

// SysTick Current Value Register
#define SYST_VAL 		0xE000E018

// SysTick Calibration Register
#define SYST_CALIB 		0xE000E01C

//----------------------------------------------------
// CORE DEBUG
//----------------------------------------------------

// Core Debug Registers
#define CM3_CoreDebug	0xE000EDF0

// Debug Halting Control and Status Register
#define DHCSR			0xE000EDF0

// Debug Core Register Selector Register
#define DCRSR			0xE000EDF4

// Debug Core Register Data Register
#define DCRDR			0xE000EDF8

// Debug Exception and Monitor Control Register
#define DEMCR			0xE000EDFC

//----------------------------------------------------
// ITM
//----------------------------------------------------

// Instrumentation Trace Macrocell Registers
#define CM3_ITM			0xE0000000

// ITM Stimulus Port Registers
#define PORT0			0xE0000000
#define PORT1			0xE0000004
#define PORT2			0xE0000008
#define PORT3			0xE000000C
#define PORT4			0xE0000010
#define PORT5			0xE0000014
#define PORT6			0xE0000018
#define PORT7			0xE000001C
#define PORT8			0xE0000020
#define PORT9			0xE0000024
#define PORT10			0xE0000028
#define PORT11			0xE000002C
#define PORT12			0xE0000030
#define PORT13			0xE0000034
#define PORT14			0xE0000038
#define PORT15			0xE000003C
#define PORT16			0xE0000040
#define PORT17			0xE0000044
#define PORT18			0xE0000048
#define PORT19			0xE000004C
#define PORT20			0xE0000050
#define PORT21			0xE0000054
#define PORT22			0xE0000058
#define PORT23			0xE000005C
#define PORT24			0xE0000060
#define PORT25			0xE0000064
#define PORT26			0xE0000068
#define PORT27			0xE000006C
#define PORT28			0xE0000070
#define PORT29			0xE0000074
#define PORT30			0xE0000078
#define PORT31			0xE000007C

// ITM Trace Enable Register
#define TER				0xE0000E00

// ITM Trace Privilege Register
#define TPR				0xE0000E40

// ITM Trace Control Register
#define TCR				0xE0000E80

//----------------------------------------------------
// DWT
//----------------------------------------------------

// Data Watchpoint and Trace Unit

// Control Register
#define DWT_CTRL		0xE0001000

// Cycle Count Register
#define DWT_CYCCNT		0xE0001004

// CPI Count Register
#define DWT_CPICNT		0xE0001008

// Exception Overhead Count Register
#define DWT_EXCCNT		0xE000100C

// Sleep Count Register
#define DWT_SLEEPCNT	0xE0001010

// LSU Count Register
#define DWT_LSUCNT		0xE0001014

// Folded-instruction Count Register
#define DWT_FOLDCNT		0xE0001018

// Program Counter Sample Register
#define DWT_PCSR		0xE000101C

//----------------------------------------------------
// EXCEPTION DEFINITIONS
//----------------------------------------------------

// Exception numbers
#define Reset_EXCn 							1
#define NMI_EXCn 							2
#define HardFault_EXCn 						3
#define MemManage_EXCn           			4
#define BusFault_EXCn                   	5
#define UsageFault_EXCn                 	6
#define SVC_EXCn                     		11
#define DebugMon_EXCn               		12
#define PendSV_EXCn                     	14
#define SysTick_EXCn                    	15

// Priority grouping options (5-bit priority)
#define PriorityGrouping_Preempt5Sub0 		2
#define PriorityGrouping_Preempt4Sub1 		3
#define PriorityGrouping_Preempt3Sub2 		4
#define PriorityGrouping_Preempt2Sub3 		5
#define PriorityGrouping_Preempt1Sub4 		6
#define PriorityGrouping_Preempt0Sub5 		7

#endif//_CORTEX_M3_H_
