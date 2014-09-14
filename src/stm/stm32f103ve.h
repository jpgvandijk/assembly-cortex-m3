/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _STM32F103VE_H_
#define _STM32F103VE_H_

//----------------------------------------------------
// RCC
//----------------------------------------------------

// Base address
#define STM_RCC 		0x40021000

// Registers
#define RCC_CR 			(STM_RCC + 0x00)
#define RCC_CFGR 		(STM_RCC + 0x04)
#define RCC_CIR 		(STM_RCC + 0x08)
#define RCC_APB2RSTR 	(STM_RCC + 0x0C)
#define RCC_APB1RSTR 	(STM_RCC + 0x10)
#define RCC_AHBENR 		(STM_RCC + 0x14)
#define RCC_APB2ENR 	(STM_RCC + 0x18)
#define RCC_APB1ENR 	(STM_RCC + 0x1C)
#define RCC_BDCR 		(STM_RCC + 0x20)
#define RCC_CSR 		(STM_RCC + 0x24)

// Peripherals
#define PERIPHERAL_DMA1 	0
#define PERIPHERAL_DMA2 	1
#define PERIPHERAL_SRAM 	2
#define PERIPHERAL_FLITF 	4
#define PERIPHERAL_CRC 		6
#define PERIPHERAL_FSMC 	8
#define PERIPHERAL_SDIO 	10

#define PERIPHERAL_AFIO 	32
#define PERIPHERAL_IOPA 	34
#define PERIPHERAL_IOPB 	35
#define PERIPHERAL_IOPC 	36
#define PERIPHERAL_IOPD 	37
#define PERIPHERAL_IOPE 	38
#define PERIPHERAL_IOPF 	39
#define PERIPHERAL_IOPG 	40
#define PERIPHERAL_ADC1 	41
#define PERIPHERAL_ADC2 	42
#define PERIPHERAL_TIM1 	43
#define PERIPHERAL_SPI1 	44
#define PERIPHERAL_TIM8 	45
#define PERIPHERAL_USART1 	46
#define PERIPHERAL_ADC3 	47
#define PERIPHERAL_TIM9 	51
#define PERIPHERAL_TIM10 	52
#define PERIPHERAL_TIM11 	53

#define PERIPHERAL_TIM2 	64
#define PERIPHERAL_TIM3 	65
#define PERIPHERAL_TIM4 	66
#define PERIPHERAL_TIM5 	67
#define PERIPHERAL_TIM6 	68
#define PERIPHERAL_TIM7 	69
#define PERIPHERAL_TIM12 	70
#define PERIPHERAL_TIM13 	71
#define PERIPHERAL_TIM14 	72
#define PERIPHERAL_WWDG 	75
#define PERIPHERAL_SPI2 	78
#define PERIPHERAL_SPI3 	79
#define PERIPHERAL_USART2 	81
#define PERIPHERAL_USART3 	82
#define PERIPHERAL_USART4 	83
#define PERIPHERAL_USART5 	84
#define PERIPHERAL_I2C1 	85
#define PERIPHERAL_I2C2 	86
#define PERIPHERAL_USB 		87
#define PERIPHERAL_CAN 		89
#define PERIPHERAL_BKP 		91
#define PERIPHERAL_PWR 		92
#define PERIPHERAL_DAC 		93

//----------------------------------------------------
// FLASH
//----------------------------------------------------

// Base address
#define STM_FLASH 		0x40022000

// Registers
#define FLASH_ACR 		(STM_FLASH + 0x00)

//----------------------------------------------------
// GPIO
//----------------------------------------------------

// Base address
#define STM_GPIOx 		0x40010800
#define STM_GPIOA 		0x40010800
#define STM_GPIOB 		0x40010C00
#define STM_GPIOC 		0x40011000
#define STM_GPIOD 		0x40011400
#define STM_GPIOE 		0x40011800
#define STM_GPIOF 		0x40011C00
#define STM_GPIOG 		0x40012000

// Registers
#define GPIOx_CRL 		(0x00)
#define GPIOx_CRH 		(0x04)
#define GPIOx_IDR 		(0x08)
#define GPIOx_ODR 		(0x0C)
#define GPIOx_BSRR 		(0x10)
#define GPIOx_BRR 		(0x14)
#define GPIOx_LCKR 		(0x18)

#define GPIOA_CRL 		(STM_GPIOA + 0x00)
#define GPIOA_CRH 		(STM_GPIOA + 0x04)
#define GPIOA_IDR 		(STM_GPIOA + 0x08)
#define GPIOA_ODR 		(STM_GPIOA + 0x0C)
#define GPIOA_BSRR 		(STM_GPIOA + 0x10)
#define GPIOA_BRR 		(STM_GPIOA + 0x14)
#define GPIOA_LCKR 		(STM_GPIOA + 0x18)

#define GPIOB_CRL 		(STM_GPIOB + 0x00)
#define GPIOB_CRH 		(STM_GPIOB + 0x04)
#define GPIOB_IDR 		(STM_GPIOB + 0x08)
#define GPIOB_ODR 		(STM_GPIOB + 0x0C)
#define GPIOB_BSRR 		(STM_GPIOB + 0x10)
#define GPIOB_BRR 		(STM_GPIOB + 0x14)
#define GPIOB_LCKR 		(STM_GPIOB + 0x18)

#define GPIOC_CRL 		(STM_GPIOC + 0x00)
#define GPIOC_CRH 		(STM_GPIOC + 0x04)
#define GPIOC_IDR 		(STM_GPIOC + 0x08)
#define GPIOC_ODR 		(STM_GPIOC + 0x0C)
#define GPIOC_BSRR 		(STM_GPIOC + 0x10)
#define GPIOC_BRR 		(STM_GPIOC + 0x14)
#define GPIOC_LCKR 		(STM_GPIOC + 0x18)

#define GPIOD_CRL 		(STM_GPIOD + 0x00)
#define GPIOD_CRH 		(STM_GPIOD + 0x04)
#define GPIOD_IDR 		(STM_GPIOD + 0x08)
#define GPIOD_ODR 		(STM_GPIOD + 0x0C)
#define GPIOD_BSRR 		(STM_GPIOD + 0x10)
#define GPIOD_BRR 		(STM_GPIOD + 0x14)
#define GPIOD_LCKR 		(STM_GPIOD + 0x18)

#define GPIOE_CRL 		(STM_GPIOE + 0x00)
#define GPIOE_CRH 		(STM_GPIOE + 0x04)
#define GPIOE_IDR 		(STM_GPIOE + 0x08)
#define GPIOE_ODR 		(STM_GPIOE + 0x0C)
#define GPIOE_BSRR 		(STM_GPIOE + 0x10)
#define GPIOE_BRR 		(STM_GPIOE + 0x14)
#define GPIOE_LCKR 		(STM_GPIOE + 0x18)

#define GPIOF_CRL 		(STM_GPIOF + 0x00)
#define GPIOF_CRH 		(STM_GPIOF + 0x04)
#define GPIOF_IDR 		(STM_GPIOF + 0x08)
#define GPIOF_ODR 		(STM_GPIOF + 0x0C)
#define GPIOF_BSRR 		(STM_GPIOF + 0x10)
#define GPIOF_BRR 		(STM_GPIOF + 0x14)
#define GPIOF_LCKR 		(STM_GPIOF + 0x18)

#define GPIOG_CRL 		(STM_GPIOG + 0x00)
#define GPIOG_CRH 		(STM_GPIOG + 0x04)
#define GPIOG_IDR 		(STM_GPIOG + 0x08)
#define GPIOG_ODR 		(STM_GPIOG + 0x0C)
#define GPIOG_BSRR 		(STM_GPIOG + 0x10)
#define GPIOG_BRR 		(STM_GPIOG + 0x14)
#define GPIOG_LCKR 		(STM_GPIOG + 0x18)

// Configuration values
#define PIN_INPUT_ANALOG 					0b0000
#define PIN_INPUT_FLOATING 					0b0100
#define PIN_INPUT_PULL 						0b1000

#define PIN_OUTPUT_NORMAL_10MHz 			0b0001
#define PIN_OUTPUT_OPENDRAIN_10MHz 			0b0101
#define PIN_AF_OUTPUT_NORMAL_10MHz 			0b1001
#define PIN_AF_OUTPUT_OPENDRAIN_10MHz 		0b1101

#define PIN_OUTPUT_NORMAL_2MHz 				0b0010
#define PIN_OUTPUT_OPENDRAIN_2MHz 			0b0110
#define PIN_AF_OUTPUT_NORMAL_2MHz 			0b1010
#define PIN_AF_OUTPUT_OPENDRAIN_2MHz 		0b1110

#define PIN_OUTPUT_NORMAL_50MHz 			0b0011
#define PIN_OUTPUT_OPENDRAIN_50MHz 			0b0111
#define PIN_AF_OUTPUT_NORMAL_50MHz 			0b1011
#define PIN_AF_OUTPUT_OPENDRAIN_50MHz 		0b1111

#define GPIOA 								0
#define GPIOB 								1
#define GPIOC 								2
#define GPIOD 								3
#define GPIOE 								4
#define GPIOF 								5
#define GPIOG 								6

//----------------------------------------------------
// AFIO
//----------------------------------------------------

// Base address
#define STM_AFIO		0x40010000

// Registers
#define AFIO_EVCR		(STM_AFIO + 0x00)
#define AFIO_MAPR		(STM_AFIO + 0x04)
#define AFIO_EXTICR1	(STM_AFIO + 0x08)
#define AFIO_EXTICR2	(STM_AFIO + 0x0C)
#define AFIO_EXTICR3	(STM_AFIO + 0x10)
#define AFIO_EXTICR4	(STM_AFIO + 0x14)
#define AFIO_MAPR2		(STM_AFIO + 0x1C)

//----------------------------------------------------
// EXTI
//----------------------------------------------------

// Base address
#define STM_EXTI		0x40010400

// Registers
#define EXTI_IMR		(STM_EXTI + 0x00)
#define EXTI_EMR		(STM_EXTI + 0x04)
#define EXTI_RTSR		(STM_EXTI + 0x08)
#define EXTI_FTSR		(STM_EXTI + 0x0C)
#define EXTI_SWIER		(STM_EXTI + 0x10)
#define EXTI_PR			(STM_EXTI + 0x14)

//----------------------------------------------------
// TIM2 to TIM7
//----------------------------------------------------

// Base address
#define STM_TIMx 		0x40000000
#define STM_TIM2 		0x40000000
#define STM_TIM3 		0x40000400
#define STM_TIM4 		0x40000800
#define STM_TIM5 		0x40000C00
#define STM_TIM6 		0x40001000
#define STM_TIM7 		0x40001400

// Registers
#define TIMx_CR1 		(0x00)
#define TIMx_CR2 		(0x04)
#define TIMx_SMCR 		(0x08)
#define TIMx_DIER 		(0x0C)
#define TIMx_SR 		(0x10)
#define TIMx_EGR 		(0x14)
#define TIMx_CCMR1 		(0x18)
#define TIMx_CCMR2 		(0x1C)
#define TIMx_CCER 		(0x20)
#define TIMx_CNT 		(0x24)
#define TIMx_PSC 		(0x28)
#define TIMx_ARR 		(0x2C)
#define TIMx_CCR1 		(0x34)
#define TIMx_CCR2 		(0x38)
#define TIMx_CCR3 		(0x3C)
#define TIMx_CCR4 		(0x40)

//----------------------------------------------------
// INTERRUPT DEFINITIONS
//----------------------------------------------------

// IRQ numbers (exception number - 16)
#define WWDG_IRQn                    0
#define PVD_IRQn                     1
#define TAMPER_IRQn                  2
#define RTC_IRQn                     3
#define FLASH_IRQn                   4
#define RCC_IRQn                     5
#define EXTI0_IRQn                   6
#define EXTI1_IRQn                   7
#define EXTI2_IRQn                   8
#define EXTI3_IRQn                   9
#define EXTI4_IRQn                   10
#define DMA1_Channel1_IRQn           11
#define DMA1_Channel2_IRQn           12
#define DMA1_Channel3_IRQn           13
#define DMA1_Channel4_IRQn           14
#define DMA1_Channel5_IRQn           15
#define DMA1_Channel6_IRQn           16
#define DMA1_Channel7_IRQn           17
#define ADC1_2_IRQn                  18
#define USB_HP_CAN1_TX_IRQn          19
#define USB_LP_CAN1_RX0_IRQn         20
#define CAN1_RX1_IRQn                21
#define CAN1_SCE_IRQn                22
#define EXTI9_5_IRQn                 23
#define TIM1_BRK_IRQn                24
#define TIM1_UP_IRQn                 25
#define TIM1_TRG_COM_IRQn            26
#define TIM1_CC_IRQn                 27
#define TIM2_IRQn                    28
#define TIM3_IRQn                    29
#define TIM4_IRQn                    30
#define I2C1_EV_IRQn                 31
#define I2C1_ER_IRQn                 32
#define I2C2_EV_IRQn                 33
#define I2C2_ER_IRQn                 34
#define SPI1_IRQn                    35
#define SPI2_IRQn                    36
#define USART1_IRQn                  37
#define USART2_IRQn                  38
#define USART3_IRQn                  39
#define EXTI15_10_IRQn               40
#define RTCAlarm_IRQn                41
#define USBWakeUp_IRQn               42
#define TIM8_BRK_IRQn                43
#define TIM8_UP_IRQn                 44
#define TIM8_TRG_COM_IRQn            45
#define TIM8_CC_IRQn                 46
#define ADC3_IRQn                    47
#define FSMC_IRQn                    48
#define SDIO_IRQn                    49
#define TIM5_IRQn                    50
#define SPI3_IRQn                    51
#define UART4_IRQn                   52
#define UART5_IRQn                   53
#define TIM6_IRQn                    54
#define TIM7_IRQn                    55
#define DMA2_Channel1_IRQn           56
#define DMA2_Channel2_IRQn           57
#define DMA2_Channel3_IRQn           58
#define DMA2_Channel4_5_IRQn         59

//----------------------------------------------------
// FSMC
//----------------------------------------------------

// Base address
#define STM_FSMC_Bank1 		0xA0000000
#define STM_FSMC_Bank1E 	0xA0000104

// Registers
#define FSMC_Bank1_BTCR0 	(STM_FSMC_Bank1 + 0x00)
#define FSMC_Bank1_BTCR1 	(STM_FSMC_Bank1 + 0x04)
#define FSMC_Bank1_BTCR2 	(STM_FSMC_Bank1 + 0x08)
#define FSMC_Bank1_BTCR3 	(STM_FSMC_Bank1 + 0x0C)
#define FSMC_Bank1_BTCR4 	(STM_FSMC_Bank1 + 0x10)
#define FSMC_Bank1_BTCR5 	(STM_FSMC_Bank1 + 0x14)
#define FSMC_Bank1_BTCR6 	(STM_FSMC_Bank1 + 0x18)
#define FSMC_Bank1_BTCR7 	(STM_FSMC_Bank1 + 0x1C)

#define FSMC_Bank1E_BWTR0 	(STM_FSMC_Bank1E + 0x00)
#define FSMC_Bank1E_BWTR1 	(STM_FSMC_Bank1E + 0x04)
#define FSMC_Bank1E_BWTR2 	(STM_FSMC_Bank1E + 0x08)
#define FSMC_Bank1E_BWTR3 	(STM_FSMC_Bank1E + 0x0C)
#define FSMC_Bank1E_BWTR4 	(STM_FSMC_Bank1E + 0x10)
#define FSMC_Bank1E_BWTR5 	(STM_FSMC_Bank1E + 0x14)
#define FSMC_Bank1E_BWTR6 	(STM_FSMC_Bank1E + 0x18)

//----------------------------------------------------
// SPI
//----------------------------------------------------

// Base address
#define STM_SPI1 			(0x40013000)
#define STM_SPI2 			(0x40003800)
#define STM_SPI3 			(0x40003C00)

// Registers
#define SPIx_CR1 			(0x00)
#define SPIx_CR2 			(0x04)
#define SPIx_SR 			(0x08)
#define SPIx_DR 			(0x0C)
#define SPIx_CRCPR 			(0x10)
#define SPIx_RXCRCR 		(0x14)
#define SPIx_TXCRCR 		(0x18)
#define SPIx_I2SCFGR 		(0x1C)
#define SPIx_I2SPR 			(0x20)

//----------------------------------------------------
// DMA
//----------------------------------------------------

// Base address
#define STM_DMA1 			(0x40020000)
#define STM_DMA2 			(0x40020400)

// Registers
#define DMAx_ISR 			(0x00)
#define DMAx_IFCR 			(0x04)

#define DMAx_CCR1 			(0x08)
#define DMAx_CNDTR1 		(0x0C)
#define DMAx_CPAR1 			(0x10)
#define DMAx_CMAR1 			(0x14)

#define DMAx_CCR2 			(0x1C)
#define DMAx_CNDTR2 		(0x20)
#define DMAx_CPAR2 			(0x24)
#define DMAx_CMAR2 			(0x28)

#define DMAx_CCR3 			(0x30)
#define DMAx_CNDTR3 		(0x34)
#define DMAx_CPAR3 			(0x38)
#define DMAx_CMAR3 			(0x3C)

#define DMAx_CCR4 			(0x44)
#define DMAx_CNDTR4 		(0x48)
#define DMAx_CPAR4 			(0x4C)
#define DMAx_CMAR4 			(0x50)

#define DMAx_CCR5 			(0x58)
#define DMAx_CNDTR5 		(0x5C)
#define DMAx_CPAR5 			(0x60)
#define DMAx_CMAR5 			(0x64)

#define DMAx_CCR6 			(0x6C)
#define DMAx_CNDTR6 		(0x70)
#define DMAx_CPAR6 			(0x74)
#define DMAx_CMAR6 			(0x78)

#define DMAx_CCR7 			(0x80)
#define DMAx_CNDTR7 		(0x84)
#define DMAx_CPAR7 			(0x88)
#define DMAx_CMAR7 			(0x8C)

#endif//_STM32F103VE_H_
