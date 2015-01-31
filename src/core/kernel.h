/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _KERNEL_H_
#define _KERNEL_H_

// Includes
#include "config.h"

// Make it possible to use only the heap
#ifdef _USE_KERNEL_HEAP_ONLY_
	#define _USE_KERNEL_HEAP_
#endif
#ifdef _USE_KERNEL_
	#define _USE_KERNEL_HEAP_
#endif

#ifdef _USE_KERNEL_HEAP_

/************************************************************
* Definitions												*
************************************************************/

// Definitions for the heap
#define KERNEL_HeapLinkStructFieldNext 				0	// Must be 0!
#define KERNEL_HeapLinkStructFieldSize 				4
#define KERNEL_HeapLinkStructSize 					8
#define KERNEL_HeapMinFragmentSize 					(KERNEL_HeapLinkStructSize + 4)

#ifndef __ASSEMBLER__

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
extern uint32_t KERNEL_Heap[CONFIG_HeapSize / 4];
extern KERNEL_HeapLinkStruct * KERNEL_HeapEmptyList;

// Global functions
extern void KERNEL_InitHeap (void);
extern uint32_t * KERNEL_Alloc (uint32_t size);
extern void KERNEL_Free (uint32_t * block);

#endif//__ASSEMBLER__

#endif//_USE_KERNEL_HEAP_

#ifdef _USE_KERNEL_

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

// Queue control structure definitions
#define KERNEL_QueueStructureFieldLock				0
#define KERNEL_QueueStructureFieldLockDelay			1
#define KERNEL_QueueStructureFieldRxIndex			2
#define KERNEL_QueueStructureFieldTxIndex			3
#define KERNEL_QueueStructureFieldBufferSize		4
#define KERNEL_QueueStructureFieldElementSize		5
#define KERNEL_QueueStructureFieldBuffer			6

// Queue element size definitions
#define KERNEL_QueueElementSizeByte					0
#define KERNEL_QueueElementSizeHalfword				1
#define KERNEL_QueueElementSizeWord					2

// Buffer specs packing
#define KERNEL_QueueBufferSpecs(BufferSize, ElementSize)		(((ElementSize) << 8) | ((BufferSize) - 1))

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
extern KERNEL_TaskTableEntry KERNEL_TaskTable[CONFIG_TaskTableEntries];
extern KERNEL_TaskTableEntry * KERNEL_TaskReadyLists[CONFIG_ImplementedPriorities];
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

/************************************************************
* KERNEL_QUEUE.S											*
************************************************************/

// Structures
typedef struct
{
	uint8_t Lock;
	uint8_t LockDelay;
	uint8_t RxIndex;
	uint8_t TxIndex;
	uint8_t BufferSize;
	uint8_t ElementSize;
	void * Buffer;
} KERNEL_QueueStructure;

// Global functions
extern void KERNEL_QueueInit (KERNEL_QueueStructure * structure, uint8_t LockDelay, uint16_t BufferSpecs, void * buffer);
extern void KERNEL_QueueSend (KERNEL_QueueStructure * structure, uint32_t Element);
extern uint32_t KERNEL_QueueReceive (KERNEL_QueueStructure * structure, uint32_t WaitForData);

/************************************************************
* KERNEL_DEBUG.S											*
************************************************************/

// Global functions
extern void KERNEL_DEBUG_Init (void);
extern void KERNEL_DEBUG_TaskSwitch (uint32_t reserved0, uint32_t reserved1, KERNEL_TaskTableEntry * task);

#endif//__ASSEMBLER__

#endif//_USE_KERNEL_

#endif//_KERNEL_H_
