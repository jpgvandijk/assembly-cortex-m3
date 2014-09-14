/************************************************************************************
*
* Author: J.P.G. van Dijk
*
* FIXME: disable interrupts/scheduler?
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"cortex_m3.h"
			#include	"kernel.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Variables
			.global		KERNEL_TaskTable
			.global		KERNEL_TaskReadyLists
			.global		KERNEL_TaskDelayedList
			.global		KERNEL_TaskDelayedListOverflow
			.global		KERNEL_TaskRunning
			.global		KERNEL_TaskIdleDescriptor

			@ Functions
			.global		KERNEL_Init
			.global		KERNEL_AddTask
			.global		KERNEL_AddTaskToReadyList
			.global		KERNEL_RemoveTaskFromReadyList
			.global		KERNEL_AddTaskToDelayedList
			.global		KERNEL_RemoveTaskFromDelayedList
			.global		KERNEL_Start
			.global		KERNEL_TaskIdle
			.global		KERNEL_KillTask





@-----------------------------------------------------------@
@ struct ... KERNEL_TaskTable[CONFIG_TaskTableEntries]		@
@-----------------------------------------------------------@

			#ifdef		DEBUG
			.section	.bss.KERNEL_TaskTable
			#else
			.section	.noinit.KERNEL_TaskTable
			#endif
			.type		KERNEL_TaskTable, "object"
			.align		2
KERNEL_TaskTable:
			@ Stores info about all tasks, entry is free if Descriptor = NULL
			.space		(KERNEL_TaskTableEntrySize * CONFIG_TaskTableEntries)





@-----------------------------------------------------------@
@ uint32_t KERNEL_TaskReadyLists[CONFIG_ImplementedPriorities] = {NULL}
@-----------------------------------------------------------@

			.section	.bss.KERNEL_TaskReadyLists
			.type		KERNEL_TaskReadyLists, "object"
			.align		2
KERNEL_TaskReadyLists:
			.space		(4 * CONFIG_ImplementedPriorities)





@-----------------------------------------------------------@
@ uint32_t KERNEL_TaskDelayedList = NULL					@
@ uint32_t KERNEL_TaskDelayedListOverflow = NULL			@
@-----------------------------------------------------------@

			.section	.bss.KERNEL_TaskDelayedList
			.type		KERNEL_TaskDelayedList, "object"
			.type		KERNEL_TaskDelayedListOverflow, "object"
			.align		2
KERNEL_TaskDelayedList:
			.space		4
KERNEL_TaskDelayedListOverflow:
			.space		4





@-----------------------------------------------------------@
@ uint32_t KERNEL_TaskRunning								@
@-----------------------------------------------------------@

			#ifdef		DEBUG
			.section	.bss.KERNEL_TaskRunning
			#else
			.section	.noinit.KERNEL_TaskRunning
			#endif
			.type		KERNEL_TaskRunning, "object"
			.align		2
KERNEL_TaskRunning:
			.space		4





@-----------------------------------------------------------@
@ const struct ... KERNEL_TaskIdleDescriptor				@
@-----------------------------------------------------------@

			.section	.rodata.TaskDescriptors
			.type		KERNEL_TaskIdleDescriptor, "object"
			.align		2
KERNEL_TaskIdleDescriptor:
			.word		KERNEL_TaskIdle						@ Function
			.word		0									@ Function argument
			.short		(KERNEL_MinimumTaskStackSpace + 0)	@ Stack size
			.byte		KERNEL_TaskIdlePriority				@ Priority
			.ascii		"IDLE "								@ Description (5 characters)





@-----------------------------------------------------------@
@ KERNEL_Init												@
@-----------------------------------------------------------@
@															@
@ This function initializes all kernel related variables	@
@ that need initialization. It should therefore be called	@
@ before using any kernel related function.					@
@															@
@ > Arguments:			<none>								@
@ > Return values:		<none>								@
@-----------------------------------------------------------@

			.section	.text.KERNEL_Init
			.type		KERNEL_Init, "function"
KERNEL_Init:

			@ Save registers
			push		{lr}

			@ Initialize debugging if used
			#ifdef		KERNEL_DEBUG
			bl			KERNEL_DEBUG_Init
			#endif

			@ Init the heap
			bl			KERNEL_InitHeap

			@ Free all entries of the TaskTable
			ldr			r0, =(KERNEL_TaskTable + KERNEL_TaskTableEntryFieldDescriptor)
			add			r1, r0, (KERNEL_TaskTableEntrySize * CONFIG_TaskTableEntries)
			movs		r2, #0
0:			str			r2, [r0], KERNEL_TaskTableEntrySize
			cmp			r0, r1
			bne			0b

			@ Create idle task
			ldr			r0, =KERNEL_TaskIdleDescriptor
			bl			KERNEL_AddTask

			@ Set idle task as the task to run
			ldr			r1, =KERNEL_TaskRunning
			str			r0, [r1]

			@ Restore registers and return
			pop			{pc}





@-----------------------------------------------------------@
@ KERNEL_AddTask											@
@-----------------------------------------------------------@
@															@
@ This function adds the task described by the argument's	@
@ TaskDescriptor to the task table and the correct task		@
@ ready list. Stack space is allocated and initialized for	@
@ the first context switch.									@
@															@
@ > Arguments:			r0: pointer to TaskDescriptor		@
@ > Return values:		r0: pointer to task table entry		@
@						or NULL in case of an error			@
@-----------------------------------------------------------@

			.section	.text.KERNEL_AddTask
			.type		KERNEL_AddTask, "function"
KERNEL_AddTask:

			@ Find empty spot in the task table
			ldr			r2, =(KERNEL_TaskTable + KERNEL_TaskTableEntryFieldDescriptor)
			add			r1, r2, (KERNEL_TaskTableEntrySize * CONFIG_TaskTableEntries)
0:			ldr			r3, [r2], KERNEL_TaskTableEntrySize
			cbz			r3, _kernel_add_task_empty_entry_found_
			cmp			r1, r2
			bne			0b

			@ If we arrive here then the task table is full and the task can not be added
			movs		r0, NULL
			bx			lr

_kernel_add_task_empty_entry_found_:

			@ Save registers
			push		{r4, r5, r6, lr}

			@ r4: pointer to TaskDescriptor
			@ r5: pointer to task table entry
			@ r6: pointer to the process stack
			cpy			r4, r0
			sub			r5, r2, (KERNEL_TaskTableEntrySize + KERNEL_TaskTableEntryFieldDescriptor)

			@ Get required stack space
			ldrh		r6, [r4, KERNEL_TaskDescriptorFieldStackSize]
			cpy			r0, r6
			bl			KERNEL_Alloc
			cbz			r0, _kernel_add_task_alloc_error_

			@ Pointer must point to the top of the space minus 64 bytes
			adds		r6, r0
			subs		r6, KERNEL_ContextSize

			@ Setup the stack for context switching:
			@ PC: task function
			@ R0: task function argument
			@ LR: KERNEL_KillTask
			@ xPSR: default PSR value (0x01000000)
			ldr			r0, [r4, KERNEL_TaskDescriptorFieldFunctionArgument]
			str			r0, [r6, KERNEL_ContextFieldR0]
			ldr			r0, =KERNEL_KillTask
			ldr			r1, [r4, KERNEL_TaskDescriptorFieldFunction]
			mov			r2, #0x01000000
			add			r3, r6, KERNEL_ContextFieldLR
			stmia		r3!, {r0, r1, r2} @ LR, PC, PSR

			@ Store the task in the task table (current kernel time, SP, descriptor)
			ldr			r1, =KERNEL_Time
			ldr			r1, [r1]
			str			r1, [r5, KERNEL_TaskTableEntryFieldTime]
			str			r6, [r5, KERNEL_TaskTableEntryFieldSP]
			str			r4, [r5, KERNEL_TaskTableEntryFieldDescriptor]

			@ Add task to the ready list with the correct priority
			@ and return pointer to the task table entry (r0 is not affected by the function!)
			cpy			r0, r5
			bl			KERNEL_AddTaskToReadyList
			pop			{r4, r5, r6, pc}

_kernel_add_task_alloc_error_:

			@ Stack space could not be allocated
			movs		r0, NULL
			pop			{r4, r5, r6, pc}





@-----------------------------------------------------------@
@ KERNEL_AddTaskToReadyList									@
@-----------------------------------------------------------@
@															@
@ This function adds the task to the correct task ready		@
@ list.														@
@															@
@ > Arguments:			r0: pointer to task table entry		@
@ > Return values:		r0: pointer to task table entry		@
@-----------------------------------------------------------@

			.section	.text.KERNEL_AddTaskToReadyList
			.type		KERNEL_AddTaskToReadyList, "function"
KERNEL_AddTaskToReadyList:

			@ Get task priority and get correct pointer in TaskReadyLists
			ldr			r2, [r0, KERNEL_TaskTableEntryFieldDescriptor]
			ldrb		r2, [r2, KERNEL_TaskDescriptorFieldPriority]
			ldr			r1, =KERNEL_TaskReadyLists
			add			r1, r1, r2, LSL #2

			@ Is the list empty?
			ldr			r2, [r1]
			cbz			r2, _kernel_add_task_to_ready_list_empty_

			@ The list already contains one or more items
			@ The task will be inserted right after the task pointed to by TaskReadyList
_kernel_add_task_to_ready_list_not_empty_:
			ldr			r1, [r2, KERNEL_TaskTableEntryFieldNext]
			str			r0, [r2, KERNEL_TaskTableEntryFieldNext]
			str			r1, [r0, KERNEL_TaskTableEntryFieldNext]
			bx			lr

			@ This is the first item to be added
			@ TaskReadyList should point to the task, the task next field should point to itself
_kernel_add_task_to_ready_list_empty_:
			str			r0, [r1]
			str			r0, [r0, KERNEL_TaskTableEntryFieldNext]
			bx			lr





@-----------------------------------------------------------@
@ KERNEL_RemoveTaskFromReadyList							@
@-----------------------------------------------------------@
@															@
@ This function removes the task from the correct task		@
@ ready list, leaving the same next task.					@
@ KERNEL_TaskRunning will not be updated, even if this is	@
@ the task being removed!									@
@															@
@ > Arguments:			r0: pointer to task table entry		@
@ > Return values:		r0: pointer to task table entry		@
@-----------------------------------------------------------@

			.section	.text.KERNEL_RemoveTaskFromReadyList
			.type		KERNEL_RemoveTaskFromReadyList, "function"
KERNEL_RemoveTaskFromReadyList:

			@ Get correct pointer in TaskReadyLists
			ldr			r2, [r0, KERNEL_TaskTableEntryFieldDescriptor]
			ldrb		r2, [r2, KERNEL_TaskDescriptorFieldPriority]
			ldr			r1, =KERNEL_TaskReadyLists
			add			r1, r1, r2, LSL #2

			@ Is it the only task in the list? Clear list and return
			ldr			r2, [r0, KERNEL_TaskTableEntryFieldNext]
			cmp			r2, r0
			ittt		eq
			moveq		r2, NULL
			streq		r2, [r1]
			bxeq		lr

			@ Find the task pointing to the task that needs to be removed
0:			cpy			r3, r2
			ldr			r2, [r3, KERNEL_TaskTableEntryFieldNext]
			cmp			r2, r0
			bne			0b

			@ If task ready list points to the task that needs to be removed, then point it to the task just found
			ldr			r2, [r1]
			cmp			r2, r0
			it			eq
			streq		r3, [r1]

			@ Remove the link from the chain
			ldr			r2, [r0, KERNEL_TaskTableEntryFieldNext]
			str			r2, [r3, KERNEL_TaskTableEntryFieldNext]

			@ Return
			bx			lr





@-----------------------------------------------------------@
@ KERNEL_AddTaskToDelayedList								@
@-----------------------------------------------------------@
@															@
@ This function adds the task to the delayed list (or the	@
@ overflowed delay list). This list will remain ordered on	@
@ time. The list ends with a NULL.							@
@															@
@ > Arguments:			r0: pointer to task table entry		@
@						r1: offset to select list (0/4)		@
@ > Return values:		r0: pointer to task table entry		@
@-----------------------------------------------------------@

			.section	.text.KERNEL_AddTaskToDelayedList
			.type		KERNEL_AddTaskToDelayedList, "function"
KERNEL_AddTaskToDelayedList:

			@ Get time of the link that needs to be added
			push		{r4, lr}
			ldr			r4, [r0, KERNEL_TaskTableEntryFieldTime]

			@ Find out where we need to add the task in the ordered list
			@ We don't check equality to lower the loop count
			ldr			r2, =KERNEL_TaskDelayedList
			add			r1, r2
0:			cpy			r2, r1
			ldr			r1, [r2, KERNEL_TaskTableEntryFieldNext]
			cbz			r1, 1f
			ldr			r3, [r1, KERNEL_TaskTableEntryFieldTime]
			cmp			r4, r3
			bhi			0b

			@ Insert before the link just found and return, or
1:			@ Append to the end of the list and return
			str			r0, [r2, KERNEL_TaskTableEntryFieldNext]
			str			r1, [r0, KERNEL_TaskTableEntryFieldNext]
			pop			{r4, pc}





@-----------------------------------------------------------@
@ KERNEL_RemoveTaskFromDelayedList							@
@-----------------------------------------------------------@
@															@
@ This function removes the task from the ordered delayed	@
@ task list.												@
@															@
@ > Arguments:			r0: pointer to task table entry		@
@ > Return values:		r0: pointer to task table entry		@
@-----------------------------------------------------------@

			.section	.text.KERNEL_RemoveTaskFromDelayedList
			.type		KERNEL_RemoveTaskFromDelayedList, "function"
KERNEL_RemoveTaskFromDelayedList:

			@ Check both delayed lists
			movs		r3, #0
2:			ldr			r2, =KERNEL_TaskDelayedList
			adds		r2, r3

			@ Check the list in r2
0:			cpy			r1, r2
			ldr			r2, [r1, KERNEL_TaskTableEntryFieldNext]
			cbz			r2, 1f
			cmp			r2, r0
			bne			0b

			@ Remove the task from the list and return
			ldr			r2, [r2, KERNEL_TaskTableEntryFieldNext]
			str			r2, [r1, KERNEL_TaskTableEntryFieldNext]
			bx			lr

1:			@ End of the list was reached, proceed to next list or stop
			adds		r3, #4
			cmp			r3, #8
			blo			2b

			@ Return if searched in both lists, apparently not found
			bx			lr





@-----------------------------------------------------------@
@ KERNEL_Start												@
@-----------------------------------------------------------@
@															@
@ This function starts the multitasking and never returns.	@
@															@
@ > Arguments:			<none>								@
@ > Return values:		<none>								@
@-----------------------------------------------------------@

			.section	.text.KERNEL_Start
			.type		KERNEL_Start, "function"
KERNEL_Start:

			@ Disable interrupts
			cpsid		i

			@ Set configuration and control register (4-byte stack alignment)
			movs		r0, #0
			ldr			r1, =CM3_SCB
			str			r0, [r1, (CCR - CM3_SCB)]

			@ Set priority grouping
			movs		r0, CONFIG_PriorityGrouping
			bl			NVIC_SetPriorityGrouping

			@ Set priorities for system exceptions
			movs		r0, SVC_EXCn
			movs		r1, CONFIG_PrioritySVC
			bl			NVIC_EXCSetPriority
			movs		r0, PendSV_EXCn
			movs		r1, CONFIG_PriorityPendSV
			bl			NVIC_EXCSetPriority
			movs		r0, SysTick_EXCn
			movs		r1, CONFIG_PrioritySysTick
			bl			NVIC_EXCSetPriority

			@ Setup systick for 1 ms tick at 120 MHz (LPC) / 72 MHz (STM)
			ldr			r0, =CM3_SCS
			movs		r1, #0x00			@ disable systick
			str			r1, [r0, (SYST_CTRL - CM3_SCS)]
			#ifdef		LPC
			ldr			r1, =(120000 - 1)	@ set reload value for 1 ms tick
			#endif
			#ifdef		STM
			ldr			r1, =(72000 - 1)	@ set reload value for 1 ms tick
			#endif
			str			r1, [r0, (SYST_LOAD - CM3_SCS)]
											@ clear counter and flag
			str			r1, [r0, (SYST_VAL - CM3_SCS)]

			@ Clear pending bits
			bl			NVIC_EXCClearPendingSysTick
			bl			NVIC_EXCClearPendingPendSV

			@ Enable interrupts
			cpsie		i

			@ Do a supervisor call to start the tasks
			svc			SVC_StartScheduler

			@ Infinite loop, execution should never reach this point
			b			.





@-----------------------------------------------------------@
@ KERNEL_TaskIdle											@
@-----------------------------------------------------------@
@															@
@ This is the idle task, which is always ready to run and	@
@ has the lowest priority.									@
@															@
@-----------------------------------------------------------@

			.section	.text.KERNEL_TaskIdle
			.type		KERNEL_TaskIdle, "function"
KERNEL_TaskIdle:
			@ Always enter sleep mode
			@ Should have reset values: PCON PM1:PM0 = 00, SCR SLEEPDEEP = 0 SLEEPONEXIT = 0
0:			wfi
			b			0b





@-----------------------------------------------------------@
@ KERNEL_KillTask											@
@-----------------------------------------------------------@
@															@
@ This function is called when a task returns. It should 	@
@ therefore kill the task and free the resources.			@
@															@
@-----------------------------------------------------------@

			.section	.text.KERNEL_KillTask
			.type		KERNEL_KillTask, "function"
KERNEL_KillTask:
			@ Kill the task using a supervisor call
			movs		r0, SVC_ForceContextSwitchEndTask
			svc			SVC_ForceContextSwitch
			b			KERNEL_KillTask




