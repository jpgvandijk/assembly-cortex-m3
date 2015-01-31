/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

// Includes
#include <stdint.h>
#include "stm32f103ve.h"
#include "cortex_m3.h"
#include "config.h"
#include "system.h"
#include "kernel.h"
#include "pin.h"

#define BUZZER_FrequencyToTone(n)				((72000000 / BUZZER_PRESCALER / 2) / (n))

void BUZZER_Init (void)
{
	// Init buzzer pin
	PIN_Configure(BUZZER_GPIO, BUZZER_PIN, PIN_OUTPUT_NORMAL_50MHz);
	
	// Init timer 6/7 with interrupt
	SystemEnablePeripheral(BUZZER_PERIPHERAL);
	(*(volatile uint32_t *) (BUZZER_TIMER_BASE + TIMx_CR1)) = 0x84;
	(*(volatile uint32_t *) (BUZZER_TIMER_BASE + TIMx_DIER)) = 0x01;
	(*(volatile uint32_t *) (BUZZER_TIMER_BASE + TIMx_PSC)) = BUZZER_PRESCALER-1;
	NVIC_IRQEnable(NVIC_IRQSetPriority(BUZZER_IRQ, BUZZER_Priority));
}

inline void BUZZER_On (void) {
	(*(volatile uint32_t *) (BUZZER_TIMER_BASE + TIMx_CR1)) |= 0x01;
}

inline void BUZZER_Off (void) {
	(*(volatile uint32_t *) (BUZZER_TIMER_BASE + TIMx_CR1)) &= ~0x01;
}

inline void BUZZER_SetTone (uint16_t tone) {
	(*(volatile uint32_t *) (BUZZER_TIMER_BASE + TIMx_ARR)) = tone;
}

void BUZZER_IRQHandler (void) {
	(*(volatile uint32_t *) (BUZZER_TIMER_BASE + TIMx_SR)) = 0x00;
	if (PIN_ReadOutput(BUZZER_GPIO, BUZZER_PIN))
		PIN_Reset(BUZZER_GPIO, BUZZER_PIN);
	else
		PIN_Set(BUZZER_GPIO, BUZZER_PIN);
}

// Main
void main (void)
{
	// Init the system clock
	SystemInitClock();
	
	// Enable the peripherals
	SystemEnablePeripheral(PERIPHERAL_AFIO);
	SystemEnablePeripheral(PERIPHERAL_IOPA);
	SystemEnablePeripheral(PERIPHERAL_IOPB);
	SystemEnablePeripheral(PERIPHERAL_IOPC);
	SystemEnablePeripheral(PERIPHERAL_IOPD);
	SystemEnablePeripheral(PERIPHERAL_IOPE);

	// Test the buzzer
	BUZZER_Init();
	BUZZER_SetTone(BUZZER_FrequencyToTone(1000));
	BUZZER_On();
	SystemDelayMs(2000);
	BUZZER_Off();
	
	// Infinite loop
	while (1);
}
