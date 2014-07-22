/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _LPC1769_H_
#define _LPC1769_H_

//----------------------------------------------------
// CRP
//----------------------------------------------------

// Code read protect options
#define CRP_NO_CRP  	0xFFFFFFFF
#define CRP_NO_ISP  	0x4E697370

//----------------------------------------------------
// GPIO
//----------------------------------------------------

// Base registers
#define LPC_GPIO0 		0x2009C000
#define LPC_GPIO1 		0x2009C020
#define LPC_GPIO2 		0x2009C040
#define LPC_GPIO3 		0x2009C060
#define LPC_GPIO4 		0x2009C080

// Fast GPIO Port Direction control registers
#define FIO0DIR  		0x2009C000
#define FIO1DIR  		0x2009C020
#define FIO2DIR  		0x2009C040
#define FIO3DIR  		0x2009C060
#define FIO4DIR  		0x2009C080

// Fast Mask registers
#define FIO0MASK  		0x2009C010
#define FIO1MASK  		0x2009C030
#define FIO2MASK  		0x2009C050
#define FIO3MASK  		0x2009C070
#define FIO4MASK  		0x2009C090

// Fast Port Pin value registers
#define FIO0PIN  		0x2009C014
#define FIO1PIN  		0x2009C034
#define FIO2PIN  		0x2009C054
#define FIO3PIN  		0x2009C074
#define FIO4PIN  		0x2009C094

// Fast Port Output Set registers
#define FIO0SET  		0x2009C018
#define FIO1SET  		0x2009C038
#define FIO2SET  		0x2009C058
#define FIO3SET  		0x2009C078
#define FIO4SET  		0x2009C098

// Fast Port OutputClear registers
#define FIO0CLR  		0x2009C01C
#define FIO1CLR  		0x2009C03C
#define FIO2CLR  		0x2009C05C
#define FIO3CLR  		0x2009C07C
#define FIO4CLR  		0x2009C09C

//----------------------------------------------------
// SYSTEM CONTROL
//----------------------------------------------------

// Base register
#define LPC_SC 			0x400FC000

// Flash accelerator
#define FLASHCFG 		0x400FC000

// Phase Locked Loop (PLL0  Main PLL)
#define PLL0CON  		0x400FC080
#define PLL0CFG  		0x400FC084
#define PLL0STAT  		0x400FC088
#define PLL0FEED  		0x400FC08C

// Phase Locked Loop (PLL1  USB PLL)
#define PLL1CON  		0x400FC0A0
#define PLL1CFG  		0x400FC0A4
#define PLL1STAT  		0x400FC0A8
#define PLL1FEED  		0x400FC0AC

// Power control
#define PCON  			0x400FC0C0
#define PCONP  			0x400FC0C4

// Clock dividers/clock source selection
#define CCLKCFG  		0x400FC104
#define USBCLKCFG  		0x400FC108
#define CLKSRCSEL  		0x400FC10C

// Reset source identification register
#define RSID 			0x400FC180

// System controls and status
#define SCS 			0x400FC1A0

// Peripheral clock dividers
#define PCLKSEL0  		0x400FC1A8
#define PCLKSEL1  		0x400FC1AC

// Utility
#define CLKOUTCFG  		0x400FC1C8

//----------------------------------------------------
// SYSTEM CONTROL VALUE DEFINITIONS
//----------------------------------------------------

// Peripherals
#define PERIPHERAL_TIM0 		1
#define PERIPHERAL_TIM1 		2
#define PERIPHERAL_UART0 		3
#define PERIPHERAL_UART1 		4
#define PERIPHERAL_PWM1 		6
#define PERIPHERAL_I2C0 		7
#define PERIPHERAL_SPI 			8
#define PERIPHERAL_RTC 			9
#define PERIPHERAL_SSP1 		10
#define PERIPHERAL_ADC 			12
#define PERIPHERAL_CAN1 		13
#define PERIPHERAL_CAN2 		14
#define PERIPHERAL_GPIO 		15
#define PERIPHERAL_RIT 			16
#define PERIPHERAL_MCPWM 		17
#define PERIPHERAL_QEI 			18
#define PERIPHERAL_I2C1 		19
#define PERIPHERAL_SSP0 		21
#define PERIPHERAL_TIM2 		22
#define PERIPHERAL_TIM3 		23
#define PERIPHERAL_UART2 		24
#define PERIPHERAL_UART3 		25
#define PERIPHERAL_I2C2 		26
#define PERIPHERAL_I2S 			27
#define PERIPHERAL_GPDMA 		29
#define PERIPHERAL_ENET 		30
#define PERIPHERAL_USB 			31

// Peripheral clock dividers
#define PCLKSEL_CCLK_DIV_1 	0x01
#define PCLKSEL_CCLK_DIV_2 	0x02
#define PCLKSEL_CCLK_DIV_4 	0x00
#define PCLKSEL_CCLK_DIV_8 	0x03

//----------------------------------------------------
// PIN CONNECT BLOCK
//----------------------------------------------------

// Base register
#define LPC_PIN 		0x4002C000

// Pin function select registers
#define PINSEL0  		0x4002C000
#define PINSEL1  		0x4002C004
#define PINSEL2  		0x4002C008
#define PINSEL3  		0x4002C00C
#define PINSEL4  		0x4002C010
#define PINSEL7  		0x4002C01C
#define PINSEL8  		0x4002C020
#define PINSEL9  		0x4002C024
#define PINSEL10  		0x4002C028

// Pin mode select registers
#define PINMODE0  		0x4002C040
#define PINMODE1  		0x4002C044
#define PINMODE2  		0x4002C048
#define PINMODE3  		0x4002C04C
#define PINMODE4  		0x4002C050
#define PINMODE5  		0x4002C054
#define PINMODE6  		0x4002C058
#define PINMODE7  		0x4002C05C
#define PINMODE9  		0x4002C064

// Open drain mode control registers
#define PINMODE_OD0  	0x4002C068
#define PINMODE_OD1  	0x4002C06C
#define PINMODE_OD2  	0x4002C070
#define PINMODE_OD3  	0x4002C074
#define PINMODE_OD4  	0x4002C078

// I2C Pin Configuration register
#define I2CPADCFG  		0x4002C07C

//----------------------------------------------------
// PIN CONNECT BLOCK VALUE DEFINITIONS
//----------------------------------------------------

// Pin function select registers
#define PINSEL_GPIO 					0x00
#define PINSEL_AF0 						0x00
#define PINSEL_AF1 						0x01
#define PINSEL_AF2 						0x02
#define PINSEL_AF3 						0x03

// Pin mode select registers
#define PINMODE_PULL_UP 				0x00
#define PINMODE_REPEATER 				0x01
#define PINMODE_NO_PULL 				0x02
#define PINMODE_PULL_DOWN 				0x03

// Open drain mode control registers
#define PINMODE_OD_NORMAL 				0x00
#define PINMODE_OD_OPENDRAIN 			0x01

// I2C Pin Configuration register
#define PINI2C0_NO_I2C 					0b1010
#define PINI2C0_STANDARD_I2C 			0b0000
#define PINI2C0_FAST_MODE_I2C 			0b0000
#define PINI2C0_FAST_MODE_PLUS_I2C 		0b0101

//----------------------------------------------------
// I2C 0/1/2
//----------------------------------------------------

// Base registers
#define LPC_I2C0 		0x4001C000
#define LPC_I2C1 		0x4005C000
#define LPC_I2C2 		0x400A0000

// I2C Control Set Register
#define I2C0CONSET  	0x4001C000
#define I2C1CONSET  	0x4005C000
#define I2C2CONSET  	0x400A0000

// I2C Status Register
#define I2C0STAT  		0x4001C004
#define I2C1STAT  		0x4005C004
#define I2C2STAT  		0x400A0004

// I2C Data Register
#define I2C0DAT  		0x4001C008
#define I2C1DAT  		0x4005C008
#define I2C2DAT  		0x400A0008

// I2C Slave Address Register 0
#define I2C0ADR0  		0x4001C00C
#define I2C1ADR0  		0x4005C00C
#define I2C2ADR0  		0x400A000C

// SCH Duty Cycle Register High Half Word
#define I2C0SCLH  		0x4001C010
#define I2C1SCLH  		0x4005C010
#define I2C2SCLH  		0x400A0010

// SCL Duty Cycle Register Low Half Word
#define I2C0SCLL  		0x4001C014
#define I2C1SCLL  		0x4005C014
#define I2C2SCLL  		0x400A0014

// I2C Control Clear Register
#define I2C0CONCLR  	0x4001C018
#define I2C1CONCLR  	0x4005C018
#define I2C2CONCLR  	0x400A0018

// Monitor mode control register
#define I2C0MMCTRL  	0x4001C01C
#define I2C1MMCTRL  	0x4005C01C
#define I2C2MMCTRL  	0x400A001C

// I2C Slave Address Register 1
#define I2C0ADR1  		0x4001C020
#define I2C1ADR1  		0x4005C020
#define I2C2ADR1  		0x400A0020

// I2C Slave Address Register 2
#define I2C0ADR2  		0x4001C024
#define I2C1ADR2  		0x4005C024
#define I2C2ADR2  		0x400A0024

// I2C Slave Address Register 3
#define I2C0ADR3  		0x4001C028
#define I2C1ADR3  		0x4005C028
#define I2C2ADR3  		0x400A0028

// Data buffer register
#define I2C0DATA_BUFFER 0x4001C02C
#define I2C1DATA_BUFFER 0x4005C02C
#define I2C2DATA_BUFFER 0x400A002C

// I2C Slave address mask register 0
#define I2C0MASK0  		0x4001C030
#define I2C1MASK0  		0x4005C030
#define I2C2MASK0  		0x400A0030

// I2C Slave address mask register 1
#define I2C0MASK1  		0x4001C034
#define I2C1MASK1  		0x4005C034
#define I2C2MASK1  		0x400A0034

// I2C Slave address mask register 2
#define I2C0MASK2  		0x4001C038
#define I2C1MASK2  		0x4005C038
#define I2C2MASK2  		0x400A0038

// I2C Slave address mask register 3
#define I2C0MASK3  		0x4001C03C
#define I2C1MASK3  		0x4005C03C
#define I2C2MASK3  		0x400A003C

//----------------------------------------------------
// INTERRUPT DEFINITIONS
//----------------------------------------------------

// IRQ numbers (exception number - 16)
#define WDT_IRQn                        	0
#define TIMER0_IRQn                     	1
#define TIMER1_IRQn                     	2
#define TIMER2_IRQn                     	3
#define TIMER3_IRQn                     	4
#define UART0_IRQn                      	5
#define UART1_IRQn                      	6
#define UART2_IRQn                      	7
#define UART3_IRQn                      	8
#define PWM1_IRQn                       	9
#define I2C0_IRQn                       	10
#define I2C1_IRQn                       	11
#define I2C2_IRQn                       	12
#define SPI_IRQn                        	13
#define SSP0_IRQn                       	14
#define SSP1_IRQn                       	15
#define PLL0_IRQn                       	16
#define RTC_IRQn                        	17
#define EINT0_IRQn                      	18
#define EINT1_IRQn                      	19
#define EINT2_IRQn                      	20
#define EINT3_IRQn                      	21
#define ADC_IRQn                        	22
#define BOD_IRQn                        	23
#define USB_IRQn                        	24
#define CAN_IRQn                        	25
#define DMA_IRQn                        	26
#define I2S_IRQn                        	27
#define ENET_IRQn                       	28
#define RIT_IRQn                        	29
#define MCPWM_IRQn                      	30
#define QEI_IRQn                        	31
#define PLL1_IRQn                       	32
#define USBActivity_IRQn                	33
#define CANActivity_IRQn                	34

//----------------------------------------------------
// TIMER 0/1/2/3
//----------------------------------------------------

// Base registers
#define LPC_TIM0 		0x40004000
#define LPC_TIM1 		0x40008000
#define LPC_TIM2 		0x40090000
#define LPC_TIM3 		0x40094000

// Interrupt Register
#define TnIR 			0x0000

// Timer Control Register
#define TnTCR 			0x0004

// Timer Counter
#define TnTC 			0x0008

// Prescale Register
#define TnPR 			0x000C

// Prescale Counter
#define TnPC 			0x0010

// Match Control Register
#define TnMCR 			0x0014

// Match Register 0/1/2/3
#define TnMR0 			0x0018
#define TnMR1 			0x001C
#define TnMR2 			0x0020
#define TnMR3 			0x0024

// Capture Control Register
#define TnCCR 			0x0028

// Capture Register 0/1
#define TnCR0 			0x002C
#define TnCR1 			0x0030

// External Match Register
#define TnEMR 			0x003C

// Count Control Register
#define TnCTCR 			0x0070

#endif//_LPC1769_H_
