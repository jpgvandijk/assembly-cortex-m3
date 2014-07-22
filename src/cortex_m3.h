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
