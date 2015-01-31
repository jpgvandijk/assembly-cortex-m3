/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _CONFIG_H_
#define _CONFIG_H_

// Select the target
#define STM

/************************************************************
* BUZZER													*
************************************************************/

// Buzzer configuration
#define BUZZER_PIN									0
#define BUZZER_GPIO									GPIOE
#define BUZZER_PRESCALER							8
#define BUZZER_PERIPHERAL							PERIPHERAL_TIM6
#define BUZZER_TIMER_BASE							STM_TIM6
#define BUZZER_IRQ									TIM6_IRQn
#define BUZZER_Priority								0
#define BUZZER_IRQHandler							TIM6_IRQHandler

#endif//_CONFIG_H_
