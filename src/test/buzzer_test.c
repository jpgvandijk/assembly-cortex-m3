/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifdef STM

// Includes
#include <stdint.h>
#include "stm32f103ve.h"
#include "cortex_m3.h"
#include "system.h"
#include "kernel.h"
#include "pin.h"

#define BUZZER_IRQHandler						TIM6_IRQHandler
#define BUZZER_PRESCALER						8
#define BUZZER_FrequencyToTone(n)				((72000000 / BUZZER_PRESCALER / 2) / (n))

void BUZZER_Init (void)
{
	// Init buzzer pin
	PIN_Configure(GPIOE, 0, PIN_OUTPUT_NORMAL_50MHz);
	
	// Init timer 6/7 with interrupt
	SystemEnablePeripheral(PERIPHERAL_TIM6);
	(*(volatile uint32_t *) (STM_TIM6 + TIMx_CR1)) = 0x84;
	(*(volatile uint32_t *) (STM_TIM6 + TIMx_DIER)) = 0x01;
	(*(volatile uint32_t *) (STM_TIM6 + TIMx_PSC)) = BUZZER_PRESCALER-1;
	NVIC_IRQEnable(NVIC_IRQSetPriority(TIM6_IRQn, 0));
}

inline void BUZZER_On (void) {
	(*(volatile uint32_t *) (STM_TIM6 + TIMx_CR1)) |= 0x01;
}

inline void BUZZER_Off (void) {
	(*(volatile uint32_t *) (STM_TIM6 + TIMx_CR1)) &= ~0x01;
}

inline void BUZZER_SetTone (uint16_t tone) {
	(*(volatile uint32_t *) (STM_TIM6 + TIMx_ARR)) = tone;
}

void BUZZER_IRQHandler (void) {
	(*(volatile uint32_t *) (STM_TIM6 + TIMx_SR)) = 0x00;
	if ((*(volatile uint32_t *) GPIOE_ODR) & (1 << 0))
		(*(volatile uint32_t *) GPIOE_BRR) = 1 << 0;
	else
		(*(volatile uint32_t *) GPIOE_BSRR) = 1 << 0;
}

void LED_Init (void)
{
	// Init LED pins
	PIN_Configure(GPIOC, 6, PIN_OUTPUT_NORMAL_50MHz);
	PIN_Configure(GPIOC, 7, PIN_OUTPUT_NORMAL_50MHz);
	PIN_Configure(GPIOD, 13, PIN_OUTPUT_NORMAL_50MHz);
	PIN_Configure(GPIOD, 6, PIN_OUTPUT_NORMAL_50MHz);

	// Turn LEDs off
	(*(volatile uint32_t *) GPIOC_BRR) = 1 << 6;
	(*(volatile uint32_t *) GPIOC_BRR) = 1 << 7;
	(*(volatile uint32_t *) GPIOD_BRR) = 1 << 13;
	(*(volatile uint32_t *) GPIOD_BRR) = 1 << 6;
}

// Main
void buzzer_test (void)
{
	BUZZER_Init();
	BUZZER_SetTone(BUZZER_FrequencyToTone(1000));
	BUZZER_On();

	LED_Init();
	SystemDelayMs(2000);
	(*(volatile uint32_t *) GPIOC_BSRR) = 1 << 6;
	SystemDelayMs(2000);
	(*(volatile uint32_t *) GPIOC_BSRR) = 1 << 7;
	SystemDelayMs(2000);
	(*(volatile uint32_t *) GPIOD_BSRR) = 1 << 13;
	SystemDelayMs(2000);
	(*(volatile uint32_t *) GPIOD_BSRR) = 1 << 6;
}

/*
void Button_Task (void)
{
	uint8_t state;

	// Init button pins as input
	PIN_Configure(GPIOE, 2, PIN_INPUT_FLOATING);
	PIN_Configure(GPIOE, 2, PIN_INPUT_FLOATING);
	PIN_Configure(GPIOE, 3, PIN_INPUT_FLOATING);
	PIN_Configure(GPIOE, 4, PIN_INPUT_FLOATING);

	// Set initial state
	state = (((*(volatile uint32_t *) GPIOE_IDR) >> 2) & 0x0F);

	while (1)
	{
		// Periodically check button state
		KERNEL_SVCForceContextSwitchPeriodic(20);
		uint8_t newState = (((*(volatile uint32_t *) GPIOE_IDR) >> 2) & 0x0F);
		uint8_t press = state & !newState;
		state = newState;

		// Button A pressed?
		if (press & 0x01)
			; // TODO: add to queue

		// Button B pressed?
		if (press & 0x02)
			; // TODO: add to queue

		// Button C pressed?
		if (press & 0x04)
			; // TODO: add to queue

		// Button D pressed?
		if (press & 0x08)
			; // TODO: add to queue
	}
}
*/

#endif//STM
