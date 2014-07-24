/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _KERNEL_H_
#define _KERNEL_H_

/************************************************************
* Configuration												*
************************************************************/

// The amount of memory that can be dynamically allocated and freed
// Must be a multiple of 4 bytes!
// For 2048 bytes  max:
//	1 block of 2040 bytes (0 39% overhead  best-case)
//	170 blocks of 1 byte (92% overhead  worst-case)
#define CONFIG_HeapSize 							2048

// The maximum number of tasks alive  1 is used for the idle task
#define CONFIG_TaskTableEntries 					10

// The number of task priorities  the lowest priority must be reserved for the idle task
#define CONFIG_ImplementedPriorities 				4

// Configure the interrupt priorities
#define CONFIG_PriorityGrouping 					PriorityGrouping_Preempt2Sub3	// 4 preemption levels and 8 sublevels
#define CONFIG_PrioritySysTick 						((0 << 3) | 0)					// Highest priority (should not be missed and very fast handler)
#define CONFIG_PrioritySVC 							((2 << 3) | 0)					// Only preempts preempt priority 3 (lowest)
#define CONFIG_PriorityPendSV 						((3 << 3) | 7)					// Lowest priority

/************************************************************
* Definitions												*
************************************************************/

// The maximum SVC number that represents a valid action
#define SVC_StartScheduler 							0
#define SVC_ForceContextSwitch 						0
#define SVC_Alloc 									1
#define SVC_Free 									2
#define SVC_IRQ										3
#define KERNEL_SVCMaxAllowedNumber 					3

#define SVC_ForceContextSwitchSimple 				0
#define SVC_ForceContextSwitchDelay 				1
#define SVC_ForceContextSwitchPeriodic 				2
#define SVC_ForceContextSwitchIndefinitely			3
#define SVC_ForceContextSwitchEndTask 				4

#define SVC_IRQDisable								0
#define SVC_IRQEnable								1

// Definitions for the heap
#define KERNEL_HeapLinkStructFieldNext 				0	// Must be 0!
#define KERNEL_HeapLinkStructFieldSize 				4
#define KERNEL_HeapLinkStructSize 					8
#define KERNEL_HeapMinFragmentSize 					(KERNEL_HeapLinkStructSize + 4)

// Definitions for the task table entries
#define KERNEL_TaskTableEntryFieldNext 				0	// Must be 0!
#define KERNEL_TaskTableEntryFieldTime 				4
#define KERNEL_TaskTableEntryFieldSP 				8
#define KERNEL_TaskTableEntryFieldDescriptor 		12
#define KERNEL_TaskTableEntrySize 					16

// Definitions for the task descriptors
#define KERNEL_TaskDescriptorFieldFunction 			0
#define KERNEL_TaskDescriptorFieldFunctionArgument 	4
#define KERNEL_TaskDescriptorFieldStackSize 		8
#define KERNEL_TaskDescriptorFieldPriority 			10
#define KERNEL_TaskDescriptorFieldDescription 		11
#define KERNEL_TaskDescriptorSize 					16

// The exception entry stack
#define KERNEL_StackR0 								0
#define KERNEL_StackR1 								4
#define KERNEL_StackR2 								8
#define KERNEL_StackR3 								12
#define KERNEL_StackR12 							16
#define KERNEL_StackLR 								20
#define KERNEL_StackPC 								24
#define KERNEL_StackPSR 							28
#define KERNEL_StackSizeException 					32

// The processor context
#define KERNEL_ContextFieldR4 						0
#define KERNEL_ContextFieldR5 						4
#define KERNEL_ContextFieldR6 						8
#define KERNEL_ContextFieldR7 						12
#define KERNEL_ContextFieldR8 						16
#define KERNEL_ContextFieldR9 						20
#define KERNEL_ContextFieldR10 						24
#define KERNEL_ContextFieldR11 						28
#define KERNEL_ContextFieldR0 						32
#define KERNEL_ContextFieldR1 						36
#define KERNEL_ContextFieldR2 						40
#define KERNEL_ContextFieldR3 						44
#define KERNEL_ContextFieldR12 						48
#define KERNEL_ContextFieldLR 						52
#define KERNEL_ContextFieldPC 						56
#define KERNEL_ContextFieldPSR 						60
#define KERNEL_ContextSize 							64

// A minimum of 64 bytes (16 words) is required for saving the context
#define KERNEL_MinimumTaskStackSpace 				KERNEL_ContextSize

// The lowest priority is reserved for the idle task
#define KERNEL_TaskIdlePriority 					(CONFIG_ImplementedPriorities - 1)

#ifndef __ASSEMBLER__

/************************************************************
* SVC WRAPPERS FOR C										*
************************************************************/

#pragma GCC diagnostic ignored "-Wreturn-type"
#pragma GCC diagnostic ignored "-Wunused-function"

__attribute__ ((noinline)) static void KERNEL_SVCForceContextSwitch (uint32_t type, uint32_t ms)
{
	__asm __volatile ("svc %[immediate]"::[immediate] "I" (0x00));
}

__attribute__ ((noinline)) static uint32_t * KERNEL_SVCAlloc (uint32_t bytes)
{
	__asm __volatile ("svc %[immediate]"::[immediate] "I" (0x01));
}

__attribute__ ((noinline)) static void KERNEL_SVCFree (uint32_t * ptr)
{
	__asm __volatile ("svc %[immediate]"::[immediate] "I" (0x02));
}

__attribute__ ((noinline)) static void KERNEL_SVCIRQ (uint32_t IRQnumber, uint32_t state)
{
	__asm __volatile ("svc %[immediate]"::[immediate] "I" (0x03));
}

/************************************************************
* KERNEL_EXCEPTIONS.S										*
************************************************************/

// Definitions
#define KERNEL_SVCForceContextSwitchSimple()		KERNEL_SVCForceContextSwitch(0, 0)
#define KERNEL_SVCForceContextSwitchDelay(ms)		KERNEL_SVCForceContextSwitch(1, ms)
#define KERNEL_SVCForceContextSwitchPeriodic(ms)	KERNEL_SVCForceContextSwitch(2, ms)
#define KERNEL_SVCForceContextSwitchIndefinitely()	KERNEL_SVCForceContextSwitch(3, 0)

#define KERNEL_SVCIRQDisable(n)						KERNEL_SVCIRQ(n, 0)
#define KERNEL_SVCIRQEnable(n)						KERNEL_SVCIRQ(n, 1)

// Global variables
extern uint64_t KERNEL_Time;

// Global functions
extern void SVC_Handler (void);
extern void SysTick_Handler (void);
extern void PendSV_Handler (void);

// SVC functions
void KERNEL_SVCForceContextSwitch (uint32_t type, uint32_t ms);
uint32_t * KERNEL_SVCAlloc (uint32_t bytes);
void KERNEL_SVCFree (uint32_t * ptr);
void KERNEL_SVCIRQ (uint32_t IRQnumber, uint32_t state);

/************************************************************
* KERNEL_HEAP.S												*
************************************************************/

// Structures
typedef struct _HeapLinkStruct_
{
	struct _HeapLinkStruct_ * Next;
	uint16_t Size;
	uint16_t Reserved;
} KERNEL_HeapLinkStruct;

// Global variables
extern uint32_t KERNEL_Heap[2048 / 4];
extern KERNEL_HeapLinkStruct * KERNEL_HeapEmptyList;

// Global functions
extern void KERNEL_InitHeap (void);
extern uint32_t * KERNEL_Alloc (uint32_t size);
extern void KERNEL_Free (uint32_t * block);

/************************************************************
* KERNEL_SCHEDULER.S										*
************************************************************/

// Structures
typedef struct _TaskDescriptorType_
{
	void (*Function)(uint32_t FunctionArgument);
	uint32_t FunctionArgument;
	uint16_t StackSize;
	uint8_t Priority;
	uint8_t Description[5];
} KERNEL_TaskDescriptor;

typedef struct _TaskTableEntryType_
{
	struct _TaskTableEntryType_ * Next;
	uint32_t Time;
	uint32_t SP;
	struct _TaskDescriptorType_ * Descriptor;
} KERNEL_TaskTableEntry;

// Global variables
extern KERNEL_TaskTableEntry KERNEL_TaskTable[10];
extern KERNEL_TaskTableEntry * KERNEL_TaskReadyLists[4];
extern KERNEL_TaskTableEntry * KERNEL_TaskDelayedList;
extern KERNEL_TaskTableEntry * KERNEL_TaskDelayedListOverflow;
extern KERNEL_TaskTableEntry * KERNEL_TaskRunning;

// Global constants
extern KERNEL_TaskDescriptor KERNEL_TaskIdleDescriptor;

// Global functions
extern void KERNEL_Init (void);
extern KERNEL_TaskTableEntry * KERNEL_AddTask (const KERNEL_TaskDescriptor * task);
extern KERNEL_TaskTableEntry * KERNEL_AddTaskToReadyList (const KERNEL_TaskTableEntry * task);
extern KERNEL_TaskTableEntry * KERNEL_RemoveTaskFromReadyList (KERNEL_TaskTableEntry * task);
extern KERNEL_TaskTableEntry * KERNEL_AddTaskToDelayedList (KERNEL_TaskTableEntry * task, uint32_t list_offset);
extern KERNEL_TaskTableEntry * KERNEL_RemoveTaskFromDelayedList (KERNEL_TaskTableEntry * task);
extern void KERNEL_Start (void);
extern void KERNEL_TaskIdle (void);
extern void KERNEL_KillTask (void);

/************************************************************
* KERNEL_EXCLUSIVEACCESS.S									*
************************************************************/

// Global functions
extern uint32_t KERNEL_GetExclusiveAccess (uint8_t * lock);
extern void KERNEL_ClearExclusiveAccess (uint8_t * lock);

#endif//__ASSEMBLER__

#endif//_KERNEL_H_
