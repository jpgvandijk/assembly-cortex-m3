/************************************************************************************
*
* Author: J.P.G. van Dijk
*
*
* FLASH DIFFERENCES:		LPC	STM
*
* interrupt_vectors			204	304
* section_table				40	20
* Reset_Handler				72	24
* CRPWord					4	0
* PIN_Config				56	32
* SystemInitClock			104	64
* SystemGetClock			88	72
* SystemPeripheral			48	16
* main						14	20
* main_other				4	0		+
* --------------------------------------
* TOTAL						634	552
*
* Timer_Handler				232	252
* OW_StartTransfer			64	68
* OW_Init					44	56
* OW_InitPin				56	32		+
* --------------------------------------
* TOTAL						396	408
*
************************************************************************************/

// Includes
#include <stdint.h>
#ifdef LPC
	#include "lpc1769.h"
#endif
#ifdef STM
	#include "stm32f103ve.h"
#endif
#include "kernel.h"
#include "onewire.h"

// Function prototypes
void TaskOW (uint32_t arg);
void TaskOWPerformance (uint32_t arg);
void OneWireCallbackFunction (uint32_t status, uint32_t * owsearch_data);

// Global variables
union {KERNEL_TaskTableEntry * task; uint32_t status;} OneWireTaskAndStatus;
const KERNEL_TaskDescriptor TaskDescriptor_TaskOW = {TaskOW, 0, (KERNEL_MinimumTaskStackSpace + 64), 0, "1Wire"};
const KERNEL_TaskDescriptor TaskDescriptor_TaskOWPerformance = {TaskOWPerformance, 0, (KERNEL_MinimumTaskStackSpace + 64), 1, "Prfmn"};

// Main
void onewire_test (void)
{
	// Init the onewire module
	OW_Init();
	OWSearch_Init();

	// Init kernel
	KERNEL_Init();

	// Create tasks
	KERNEL_AddTask(&TaskDescriptor_TaskOW);
	KERNEL_AddTask(&TaskDescriptor_TaskOWPerformance);

	// Start kernel (this function never returns)
	KERNEL_Start();
}

// Onewire task
void TaskOW (uint32_t arg)
{
	// Init onewire pin P2.12
	uint32_t check;
	uint32_t ow_pin = OW_InitPin(2, 12);

	// Try to get exclusive access to the onewire module
	// While module is in use, try again after some time (sleep 5 ms)
	while (KERNEL_GetExclusiveAccess(&OW_TransferInternalStateAndLock) != OW_Access)
		KERNEL_SVCForceContextSwitchDelay(5);

	// Exclusive access granted, now find all onewire devices
	do
	{
		// Setup the auto wake up and start a search
		OneWireTaskAndStatus.task = KERNEL_TaskRunning;
		while (OWSearch_Next(ow_pin, OneWireCallbackFunction) != OW_OK);

		// Sleep till it finishes or a timeout occurs
		// Search should take a little over 15 ms, set timeout to 20 ms
		KERNEL_SVCForceContextSwitchDelay(20);

	} while (OneWireTaskAndStatus.status == OW_OK);
	// Status: OW_Last, OW_Error or KERNEL_TaskRunning (a timeout occurred)

	// Check the last address
	check = OW_CheckCRC8((uint8_t *) &OWSearch_ROM, 8);

	// Clear exclusive access
	KERNEL_ClearExclusiveAccess(&OW_TransferInternalStateAndLock);
}

// Onewire search callback function
void OneWireCallbackFunction (uint32_t status, uint32_t * owsearch_data)
{
	// Get the reference to the task and wake it up
	KERNEL_AddTaskToReadyList(KERNEL_RemoveTaskFromDelayedList(OneWireTaskAndStatus.task));

	// Write back the wake up status in the same variable
	OneWireTaskAndStatus.status = status;
}

// Performance task
void TaskOWPerformance (uint32_t arg)
{
	volatile uint32_t i = 0;
	while (1) i++;
}
