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
			.global		KERNEL_Time

			@ Functions
			.global		SVC_Handler
			.global		SysTick_Handler
			.global		PendSV_Handler





@-----------------------------------------------------------@
@ uint64_t KERNEL_Time = 0									@
@-----------------------------------------------------------@

			.section	.bss.KERNEL_Time
			.type		KERNEL_Time, "object"
			.align		2
KERNEL_Time:
			.space		8





@-----------------------------------------------------------@
@ SVC Handler												@
@-----------------------------------------------------------@

			.section	.text.SVC_Handler
			.type		SVC_Handler, "function"
SVC_Handler:

			@ Extract SVC number from instruction (via stacked PC)
			@ SVC number will be in r1 (in order to determine the action)
			@ SP value will be in r0 (in order to extract arguments)
			tst			lr, #0x04
			ite			eq
			moveq		r0, sp			@ MSP is not banked in handler!
			mrsne		r0, psp
			ldr			r1, [r0, KERNEL_StackPC]
			ldrb		r1, [r1, #-2]

			@ Check if the requested function is implemented
			cmp			r1, KERNEL_SVCMaxAllowedNumber
			bhi			SVC_HandlerInvalidRequest

			@ Branch to the requested function
			@ This function can use r0 to get and parse the arguments
			tbb			[pc, r1]
SVC_HandlerBranchTable:
			.byte		((SVC_HandlerScheduler - SVC_HandlerBranchTable) / 2)
			.byte		((SVC_HandlerAlloc - SVC_HandlerBranchTable) / 2)
			.byte		((SVC_HandlerFree - SVC_HandlerBranchTable) / 2)
			.byte		((SVC_HandlerIRQ - SVC_HandlerBranchTable) / 2)
			.align		1

			@-----------------------------------------------------------@

SVC_HandlerScheduler:

			@ SVC 0 (depends on LR):
			@ - if called from thread that uses the MSP: start task execution for the first time
			@ - if called from thread that uses the PSP: force context switch
			@ - if called from another handler: not allowed for now
			tst			lr, #0x04
			bne			SVC_HandlerScheduler_ForceContextSwitch
			tst			lr, #0x08
			beq			SVC_HandlerInvalidRequest

SVC_HandlerScheduler_StartTaskExecution:

			@ Restore MSP to the initial value as we will never return to a thread that uses the MSP
			movs		r0, #0
			ldr			sp, [r0]

			@ Switch to unprivileged
			movs		r0, #0x01
			msr			control, r0

			@ Enable systick and interrupt
			ldr			r0, =CM3_SCS
			movs		r1, #0x07
			str			r1, [r0, (SYST_CTRL - CM3_SCS)]

			@ Return using the context switching code
			@ It must now use the PSP
			orr			lr, #0x0D
			ldr			r0, =KERNEL_TaskRunning
			ldr			r2, [r0]
			b			_kernel_restore_context_and_return_

SVC_HandlerScheduler_ForceContextSwitch:

			@ Check arguments:
			@ r0: type of blocking (simple, delay, periodic, kill)
			@ r1: additional argument: delay, period
			push		{r4, lr}

			@ Determine reason of context switch
			ldr			r1, [r0, KERNEL_StackR0]
			cbz			r1, _svc_handler_scheduler_pendsv_
			cmp			r1, SVC_ForceContextSwitchIndefinitely
			beq			_svc_handler_scheduler_indefinitely_
			cmp			r1, SVC_ForceContextSwitchEndTask
			beq			_svc_handler_scheduler_kill_

_svc_handler_scheduler_delayed_:

			@ Load delay/period
			ldr			r2, [r0, KERNEL_StackR1]

			@ Get currently running task
			ldr			r0, =KERNEL_TaskRunning
			ldr			r0, [r0]

			@ Delay or periodic delay, difference is in start time
			cmp			r1, SVC_ForceContextSwitchDelay
			itee		ne
			ldrne		r3, [r0, KERNEL_TaskTableEntryFieldTime]
			ldreq		r3, =KERNEL_Time
			ldreq		r3, [r3]

			@ Add delay/period and check for overflow
			adds		r3, r2
			ite			cc
			movcc		r4, #0
			movcs		r4, #4
			str			r3, [r0, KERNEL_TaskTableEntryFieldTime]

			@ Remove from ready list and add to delayed list
			@ If periodic delay has already expired the next
			@ systick will immediately ready the task again
			bl			KERNEL_RemoveTaskFromReadyList
			cpy			r1, r4
			bl			KERNEL_AddTaskToDelayedList
			b			_svc_handler_scheduler_pendsv_

_svc_handler_scheduler_kill_:

			@ This task was currently running and needs to be killed:
			@ > set running task to NULL
			@ > remove task from the ready list
			@ > free the heap used for the stack
			@ > free the task table entry
			@ > force context switch
			@	(pendsv should not use the stack as it no longer exists)
			ldr			r1, =KERNEL_TaskRunning
			ldr			r0, [r1]
			movs		r4, NULL
			str			r4, [r1]

			@ Remove the task (pointer remains in r0)
			bl			KERNEL_RemoveTaskFromReadyList

			@ Free the heap and the task table entry
			ldr			r1, [r0, KERNEL_TaskTableEntryFieldDescriptor]
			str			r4, [r0, KERNEL_TaskTableEntryFieldDescriptor]
			ldrh		r1, [r1, KERNEL_TaskDescriptorFieldStackSize]
			mrs			r0, psp
			adds		r0, KERNEL_StackSizeException
			subs		r0, r1
			bl			KERNEL_Free
			b			_svc_handler_scheduler_pendsv_

_svc_handler_scheduler_indefinitely_:

			@ Get currently running task
			ldr			r0, =KERNEL_TaskRunning
			ldr			r0, [r0]
			bl			KERNEL_RemoveTaskFromReadyList

			@ Pend the PendSV exception for the context switch
			@ NVIC_EXCSetPendingPendSV copied to avoid branches etc.
_svc_handler_scheduler_pendsv_:
			mov			r0, (1 << 28)
			ldr			r1, =CM3_SCB
			str			r0, [r1, (ICSR - CM3_SCB)]
			pop			{r4, pc}

			@-----------------------------------------------------------@

SVC_HandlerAlloc:

			@ r0 contains the stack pointer used during the exception entry
			@ Use this to get and store the function arguments/return values
			push		{r4, lr}
			cpy			r4, r0
			ldr			r0, [r4, KERNEL_StackR0]
			bl			KERNEL_Alloc
			str			r0, [r4, KERNEL_StackR0]
			pop			{r4, pc}

			@-----------------------------------------------------------@

SVC_HandlerFree:

			@ r0 contains the stack pointer used during the exception entry
			@ Use this to get and store the function arguments/return values
			push		{lr}
			ldr			r0, [r0, KERNEL_StackR0]
			bl			KERNEL_Free
			pop			{pc}

			@-----------------------------------------------------------@
			
SVC_HandlerIRQ:

			@ r0 contains the stack pointer used during the exception entry
			@ Use this to get and store the function arguments/return values
				
			@ FIXME: protect some IRQs from changing state?
			push		{lr}
			ldr			r1, [r0, KERNEL_StackR1]
			ldr			r0, [r0, KERNEL_StackR0]
			cbz			r1, _svc_handler_irq_disable
_svc_handler_irq_enable:
			bl			NVIC_IRQEnable
			pop			{pc}
_svc_handler_irq_disable:
			bl			NVIC_IRQDisable
			pop			{pc}

			@-----------------------------------------------------------@
			
SVC_HandlerInvalidRequest:
			bx			lr





@-----------------------------------------------------------@
@ Systick Handler											@
@-----------------------------------------------------------@

			.section	.text.SysTick_Handler
			.type		SysTick_Handler, "function"
SysTick_Handler:

			@ Save registers
			push		{r4, r5, lr}

			@ Increment the kernel time
			ldr			r0, =KERNEL_Time
			ldrd		r4, r1, [r0]
			adds		r4, #1
			adc			r1, #0
			strd		r4, r1, [r0]
			ldr			r1, =KERNEL_TaskDelayedList
			bcc			_systick_handler_no_overflow_

_systick_handler_overflow_:

			@ Empty the delay list before swapping with the overflowed delay list
			ldr			r0, [r1]
0:			cbz			r0, 1f
			ldr			r5, [r0, KERNEL_TaskTableEntryFieldNext]
			bl			KERNEL_AddTaskToReadyList
			cpy			r0, r5
			b			0b

			@ Swap the lists, the delay list is empty (r0 = NULL)
1:			ldr			r1, =KERNEL_TaskDelayedList
			ldr			r2, [r1, #4]
			str			r2, [r1, #0]
			str			r0, [r1, #4]

_systick_handler_no_overflow_:

			@ Ready tasks from the delay list
			ldr			r0, [r1]
0:			cbz			r0, 1f
			ldr			r5, [r0, KERNEL_TaskTableEntryFieldNext]
			ldr			r1, [r0, KERNEL_TaskTableEntryFieldTime]
			cmp			r1, r4
			bhi			1f
			bl			KERNEL_AddTaskToReadyList
			cpy			r0, r5
			b			0b

			@ Update the delay list to the tasks that are not readied yet
1:			ldr			r1, =KERNEL_TaskDelayedList
			str			r0, [r1]

_systick_handler_pendsv_:

			@ Pend the PendSV exception for the context switch
			@ NVIC_EXCSetPendingPendSV copied to avoid branches etc.
			mov			r0, (1 << 28)
			ldr			r1, =CM3_SCB
			str			r0, [r1, (ICSR - CM3_SCB)]

			@ Restore registers and return
			pop			{r4, r5, pc}





@-----------------------------------------------------------@
@ PendSV Handler											@
@-----------------------------------------------------------@

			.section	.text.PendSV_Handler
			.type		PendSV_Handler, "function"
PendSV_Handler:

			@ Setup pointer
			ldr			r0, =KERNEL_TaskRunning

			@ If running task contains NULL it was just deleted
			ldr			r2, [r0]
			cbz			r2, _pendsv_handler_update_task_

			@-----------------------------------------------------------@

			@ xPSR, PC, LR, R12, R3, R2, R1, R0 are automatically stored using the PSP
			@ Also store R4-R11 using the PSP (this handler uses the MSP!)
			mrs			r1, psp
			stmdb		r1!, {r4-r11}

			@ And store the new PSP value in the task table (not in PSP register as this will be changed)
			str			r1, [r2, KERNEL_TaskTableEntryFieldSP]

			@-----------------------------------------------------------@

			@ Update running task with some kind of scheduler
_pendsv_handler_update_task_:

			@ Find first non-zero entry in the task ready lists array (idle task is always ready)
			ldr			r1, =(KERNEL_TaskReadyLists - 4)
0:			ldr			r2, [r1, #4]!
			cmp			r2, #0
			beq			0b

			@ Advance to the next task
			ldr			r2, [r2, KERNEL_TaskTableEntryFieldNext]
			str			r2, [r1]
			str			r2, [r0]

			@-----------------------------------------------------------@

_kernel_restore_context_and_return_:

			@ Get the PSP value for the new task
			@ldr		r2, [r0]
			ldr			r1, [r2, KERNEL_TaskTableEntryFieldSP]

			@ Restore R4-R11 using this PSP and set the PSP
			@ xPSR, PC, LR, R12, R3, R2, R1, R0 will be automatically restored using the PSP
			ldmia		r1!, {r4-r11}
			msr			psp, r1

			@-----------------------------------------------------------@

			@ Return to this new task
			bx			lr




