/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

			.thumb
			.syntax		unified

			#include	"startup.h"





@-----------------------------------------------------------@
@ GLOBALS													@
@-----------------------------------------------------------@

			@ Constants
			.global		InterruptVectors
			.global		SectionTable
			#ifdef		LPC
			.global		CRPWord
			#endif

			@ Functions
			.global		InitDataSection
			.global		InitBssSection
			.global		Reset_Handler





@-----------------------------------------------------------@
@ VECTOR TABLE												@
@-----------------------------------------------------------@

			.section	.interrupt_vectors
			.type		InterruptVectors, "object"
InterruptVectors:

			@ Initial stack pointer (provided by the linker)
			#ifdef		LPC
			.word		__top_LocalSRAM
			#endif
			#ifdef		STM
			.word		__top_SRAM
			#endif

			@ The least-significant bit of each vector must be 1,
			@ indicating that the exception handler is Thumb code

			@ Core Level - CM3
			.word		Reset_Handler			@ The reset handler
			.word		NMI_Handler				@ The NMI handler
			.word		HardFault_Handler		@ The hard fault handler
			.word		MemManage_Handler		@ The MPU fault handler
			.word		BusFault_Handler		@ The bus fault handler
			.word		UsageFault_Handler		@ The usage fault handler
			.word		0						@ Reserved
			.word		0						@ Reserved
			.word		0						@ Reserved
			.word		0						@ Reserved
			.word		SVC_Handler				@ SVCall handler
			.word		DebugMon_Handler		@ Debug monitor handler
			.word		0						@ Reserved
			.word		PendSV_Handler			@ The PendSV handler
			.word		SysTick_Handler			@ The SysTick handler

			#ifdef		LPC

			@ Chip Level - LPC1769
			.word		WDT_IRQHandler			@ 16, 0x40 - WDT
			.word		TIMER0_IRQHandler		@ 17, 0x44 - TIMER0
			.word		TIMER1_IRQHandler		@ 18, 0x48 - TIMER1
			.word		TIMER2_IRQHandler		@ 19, 0x4c - TIMER2
			.word		TIMER3_IRQHandler		@ 20, 0x50 - TIMER3
			.word		UART0_IRQHandler		@ 21, 0x54 - UART0
			.word		UART1_IRQHandler		@ 22, 0x58 - UART1
			.word		UART2_IRQHandler		@ 23, 0x5c - UART2
			.word		UART3_IRQHandler		@ 24, 0x60 - UART3
			.word		PWM1_IRQHandler			@ 25, 0x64 - PWM1
			.word		I2C0_IRQHandler			@ 26, 0x68 - I2C0
			.word		I2C1_IRQHandler			@ 27, 0x6c - I2C1
			.word		I2C2_IRQHandler			@ 28, 0x70 - I2C2
			.word		SPI_IRQHandler			@ 29, 0x74 - SPI
			.word		SSP0_IRQHandler			@ 30, 0x78 - SSP0
			.word		SSP1_IRQHandler			@ 31, 0x7c - SSP1
			.word		PLL0_IRQHandler			@ 32, 0x80 - PLL0 (Main PLL)
			.word		RTC_IRQHandler			@ 33, 0x84 - RTC
			.word		EINT0_IRQHandler		@ 34, 0x88 - EINT0
			.word		EINT1_IRQHandler		@ 35, 0x8c - EINT1
			.word		EINT2_IRQHandler		@ 36, 0x90 - EINT2
			.word		EINT3_IRQHandler		@ 37, 0x94 - EINT3
			.word		ADC_IRQHandler			@ 38, 0x98 - ADC
			.word		BOD_IRQHandler			@ 39, 0x9c - BOD
			.word		USB_IRQHandler			@ 40, 0xA0 - USB
			.word		CAN_IRQHandler			@ 41, 0xa4 - CAN
			.word		DMA_IRQHandler			@ 42, 0xa8 - GP DMA
			.word		I2S_IRQHandler			@ 43, 0xac - I2S
			.word		ENET_IRQHandler			@ 44, 0xb0 - Ethernet
			.word		RIT_IRQHandler			@ 45, 0xb4 - RITINT
			.word		MCPWM_IRQHandler		@ 46, 0xb8 - Motor Control PWM
			.word		QEI_IRQHandler			@ 47, 0xbc - Quadrature Encoder
			.word		PLL1_IRQHandler			@ 48, 0xc0 - PLL1 (USB PLL)
			.word		USBActivity_IRQHandler	@ 49, 0xc4 - USB Activity interrupt to wakeup
			.word		CANActivity_IRQHandler	@ 50, 0xc8 - CAN Activity interrupt to wakeup

			#endif
			#ifdef		STM

			@ Chip Level - STM32F103VE
			.word		WWDG_IRQHandler            @ Window Watchdog
			.word		PVD_IRQHandler             @ PVD through EXTI Line detect
			.word		TAMPER_IRQHandler          @ Tamper
			.word		RTC_IRQHandler             @ RTC
			.word		FLASH_IRQHandler           @ Flash
			.word		RCC_IRQHandler             @ RCC
			.word		EXTI0_IRQHandler           @ EXTI Line 0
			.word		EXTI1_IRQHandler           @ EXTI Line 1
			.word		EXTI2_IRQHandler           @ EXTI Line 2
			.word		EXTI3_IRQHandler           @ EXTI Line 3
			.word		EXTI4_IRQHandler           @ EXTI Line 4
			.word		DMA1_Channel1_IRQHandler   @ DMA1 Channel 1
			.word		DMA1_Channel2_IRQHandler   @ DMA1 Channel 2
			.word		DMA1_Channel3_IRQHandler   @ DMA1 Channel 3
			.word		DMA1_Channel4_IRQHandler   @ DMA1 Channel 4
			.word		DMA1_Channel5_IRQHandler   @ DMA1 Channel 5
			.word		DMA1_Channel6_IRQHandler   @ DMA1 Channel 6
			.word		DMA1_Channel7_IRQHandler   @ DMA1 Channel 7
			.word		ADC1_2_IRQHandler          @ ADC1 & ADC2
			.word		USB_HP_CAN1_TX_IRQHandler  @ USB High Priority or CAN1 TX
			.word		USB_LP_CAN1_RX0_IRQHandler @ USB Low  Priority or CAN1 RX0
			.word		CAN1_RX1_IRQHandler        @ CAN1 RX1
			.word		CAN1_SCE_IRQHandler        @ CAN1 SCE
			.word		EXTI9_5_IRQHandler         @ EXTI Line 9..5
			.word		TIM1_BRK_IRQHandler        @ TIM1 Break
			.word		TIM1_UP_IRQHandler         @ TIM1 Update
			.word		TIM1_TRG_COM_IRQHandler    @ TIM1 Trigger and Commutation
			.word		TIM1_CC_IRQHandler         @ TIM1 Capture Compare
			.word		TIM2_IRQHandler            @ TIM2
			.word		TIM3_IRQHandler            @ TIM3
			.word		TIM4_IRQHandler            @ TIM4
			.word		I2C1_EV_IRQHandler         @ I2C1 Event
			.word		I2C1_ER_IRQHandler         @ I2C1 Error
			.word		I2C2_EV_IRQHandler         @ I2C2 Event
			.word		I2C2_ER_IRQHandler         @ I2C2 Error
			.word		SPI1_IRQHandler            @ SPI1
			.word		SPI2_IRQHandler            @ SPI2
			.word		USART1_IRQHandler          @ USART1
			.word		USART2_IRQHandler          @ USART2
			.word		USART3_IRQHandler          @ USART3
			.word		EXTI15_10_IRQHandler       @ EXTI Line 15..10
			.word		RTCAlarm_IRQHandler        @ RTC Alarm through EXTI Line
			.word		USBWakeUp_IRQHandler       @ USB Wakeup from suspend
			.word		TIM8_BRK_IRQHandler        @ TIM8 Break
			.word		TIM8_UP_IRQHandler         @ TIM8 Update
			.word		TIM8_TRG_COM_IRQHandler    @ TIM8 Trigger and Commutation
			.word		TIM8_CC_IRQHandler         @ TIM8 Capture Compare
			.word		ADC3_IRQHandler            @ ADC3
			.word		FSMC_IRQHandler            @ FSMC
			.word		SDIO_IRQHandler            @ SDIO
			.word		TIM5_IRQHandler            @ TIM5
			.word		SPI3_IRQHandler            @ SPI3
			.word		UART4_IRQHandler           @ UART4
			.word		UART5_IRQHandler           @ UART5
			.word		TIM6_IRQHandler            @ TIM6
			.word		TIM7_IRQHandler            @ TIM7
			.word		DMA2_Channel1_IRQHandler   @ DMA2 Channel1
			.word		DMA2_Channel2_IRQHandler   @ DMA2 Channel2
			.word		DMA2_Channel3_IRQHandler   @ DMA2 Channel3
			.word		DMA2_Channel4_5_IRQHandler @ DMA2 Channel4 & Channel5

			#endif





@-----------------------------------------------------------@
@ SECTION TABLE												@
@-----------------------------------------------------------@

			@ Placement information is generated by the linker
			@ Table is aligned for use with load-multiple instructions

			.section	.section_table
			.type		SectionTable, "object"
SectionTable:
			.word		__data_LoadAddress		@ Load address in flash for initializing the data section
			.word		__data_StartAddress		@ Start address of the data section
			.word		__data_EndAddress		@ End address of the data section
			#ifdef		LPC
			.word		__data_AHB_LoadAddress	@ Load address in flash for initializing the data section in AHB ram
			.word		__data_AHB_StartAddress	@ Start address of the data section in AHB ram
			.word		__data_AHB_EndAddress	@ End address of the data section in AHB ram
			#endif
			.word		__bss_StartAddress		@ Start address of the bss section
			.word		__bss_EndAddress		@ End address of the bss section
			#ifdef		LPC
			.word		__bss_AHB_StartAddress	@ Start address of the bss section in AHB ram
			.word		__bss_AHB_EndAddress	@ End address of the bss section in AHB ram
			#endif





@-----------------------------------------------------------@
@ CODE READ PROTECT DATA									@
@-----------------------------------------------------------@

			#ifdef		LPC
			.section	.crp
			.type		CRPWord, "object"
CRPWord:
			.word		CRP_WORD
			#endif





@-----------------------------------------------------------@
@ DEFAULT EXCEPTION HANDLERS								@
@-----------------------------------------------------------@

			.section	.after_vectors.DefaultExceptionHandlers

			.type		NMI_Handler, "function"
			.weak		NMI_Handler
NMI_Handler:

			.type		HardFault_Handler, "function"
			.weak		HardFault_Handler
HardFault_Handler:

			.type		MemManage_Handler, "function"
			.weak		MemManage_Handler
MemManage_Handler:

			.type		BusFault_Handler, "function"
			.weak		BusFault_Handler
BusFault_Handler:

			.type		UsageFault_Handler, "function"
			.weak		UsageFault_Handler
UsageFault_Handler:

			.type		SVC_Handler, "function"
			.weak		SVC_Handler
SVC_Handler:

			.type		DebugMon_Handler, "function"
			.weak		DebugMon_Handler
DebugMon_Handler:

			.type		PendSV_Handler, "function"
			.weak		PendSV_Handler
PendSV_Handler:

			.type		SysTick_Handler, "function"
			.weak		SysTick_Handler
SysTick_Handler:

			@ Enter infinite loop
			b.n			.





@-----------------------------------------------------------@
@ DEFAULT INTERRUPT HANDLERS								@
@-----------------------------------------------------------@

			.section	.after_vectors.DefaultInterruptHandlers

			#ifdef		LPC

			.type		WDT_IRQHandler, "function"
			.weak		WDT_IRQHandler
WDT_IRQHandler:

			.type		TIMER0_IRQHandler, "function"
			.weak		TIMER0_IRQHandler
TIMER0_IRQHandler:

			.type		TIMER1_IRQHandler, "function"
			.weak		TIMER1_IRQHandler
TIMER1_IRQHandler:

			.type		TIMER2_IRQHandler, "function"
			.weak		TIMER2_IRQHandler
TIMER2_IRQHandler:

			.type		TIMER3_IRQHandler, "function"
			.weak		TIMER3_IRQHandler
TIMER3_IRQHandler:

			.type		UART0_IRQHandler, "function"
			.weak		UART0_IRQHandler
UART0_IRQHandler:

			.type		UART1_IRQHandler, "function"
			.weak		UART1_IRQHandler
UART1_IRQHandler:

			.type		UART2_IRQHandler, "function"
			.weak		UART2_IRQHandler
UART2_IRQHandler:

			.type		UART3_IRQHandler, "function"
			.weak		UART3_IRQHandler
UART3_IRQHandler:

			.type		PWM1_IRQHandler, "function"
			.weak		PWM1_IRQHandler
PWM1_IRQHandler:

			.type		I2C0_IRQHandler, "function"
			.weak		I2C0_IRQHandler
I2C0_IRQHandler:

			.type		I2C1_IRQHandler, "function"
			.weak		I2C1_IRQHandler
I2C1_IRQHandler:

			.type		I2C2_IRQHandler, "function"
			.weak		I2C2_IRQHandler
I2C2_IRQHandler:

			.type		SPI_IRQHandler, "function"
			.weak		SPI_IRQHandler
SPI_IRQHandler:

			.type		SSP0_IRQHandler, "function"
			.weak		SSP0_IRQHandler
SSP0_IRQHandler:

			.type		SSP1_IRQHandler, "function"
			.weak		SSP1_IRQHandler
SSP1_IRQHandler:

			.type		PLL0_IRQHandler, "function"
			.weak		PLL0_IRQHandler
PLL0_IRQHandler:

			.type		RTC_IRQHandler, "function"
			.weak		RTC_IRQHandler
RTC_IRQHandler:

			.type		EINT0_IRQHandler, "function"
			.weak		EINT0_IRQHandler
EINT0_IRQHandler:

			.type		EINT1_IRQHandler, "function"
			.weak		EINT1_IRQHandler
EINT1_IRQHandler:

			.type		EINT2_IRQHandler, "function"
			.weak		EINT2_IRQHandler
EINT2_IRQHandler:

			.type		EINT3_IRQHandler, "function"
			.weak		EINT3_IRQHandler
EINT3_IRQHandler:

			.type		ADC_IRQHandler, "function"
			.weak		ADC_IRQHandler
ADC_IRQHandler:

			.type		BOD_IRQHandler, "function"
			.weak		BOD_IRQHandler
BOD_IRQHandler:

			.type		USB_IRQHandler, "function"
			.weak		USB_IRQHandler
USB_IRQHandler:

			.type		CAN_IRQHandler, "function"
			.weak		CAN_IRQHandler
CAN_IRQHandler:

			.type		DMA_IRQHandler, "function"
			.weak		DMA_IRQHandler
DMA_IRQHandler:

			.type		I2S_IRQHandler, "function"
			.weak		I2S_IRQHandler
I2S_IRQHandler:

			.type		ENET_IRQHandler, "function"
			.weak		ENET_IRQHandler
ENET_IRQHandler:

			.type		RIT_IRQHandler, "function"
			.weak		RIT_IRQHandler
RIT_IRQHandler:

			.type		MCPWM_IRQHandler, "function"
			.weak		MCPWM_IRQHandler
MCPWM_IRQHandler:

			.type		QEI_IRQHandler, "function"
			.weak		QEI_IRQHandler
QEI_IRQHandler:

			.type		PLL1_IRQHandler, "function"
			.weak		PLL1_IRQHandler
PLL1_IRQHandler:

			.type		USBActivity_IRQHandler, "function"
			.weak		USBActivity_IRQHandler
USBActivity_IRQHandler:

			.type		CANActivity_IRQHandler, "function"
			.weak		CANActivity_IRQHandler
CANActivity_IRQHandler:

			#endif
			#ifdef		STM

			.type		WWDG_IRQHandler, "function"
			.weak		WWDG_IRQHandler
WWDG_IRQHandler:

			.type		PVD_IRQHandler, "function"
			.weak		PVD_IRQHandler
PVD_IRQHandler:

			.type		TAMPER_IRQHandler, "function"
			.weak		TAMPER_IRQHandler
TAMPER_IRQHandler:

			.type		RTC_IRQHandler, "function"
			.weak		RTC_IRQHandler
RTC_IRQHandler:

			.type		FLASH_IRQHandler, "function"
			.weak		FLASH_IRQHandler
FLASH_IRQHandler:

			.type		RCC_IRQHandler, "function"
			.weak		RCC_IRQHandler
RCC_IRQHandler:

			.type		EXTI0_IRQHandler, "function"
			.weak		EXTI0_IRQHandler
EXTI0_IRQHandler:

			.type		EXTI1_IRQHandler, "function"
			.weak		EXTI1_IRQHandler
EXTI1_IRQHandler:

			.type		EXTI2_IRQHandler, "function"
			.weak		EXTI2_IRQHandler
EXTI2_IRQHandler:

			.type		EXTI3_IRQHandler, "function"
			.weak		EXTI3_IRQHandler
EXTI3_IRQHandler:

			.type		EXTI4_IRQHandler, "function"
			.weak		EXTI4_IRQHandler
EXTI4_IRQHandler:

			.type		DMA1_Channel1_IRQHandler, "function"
			.weak		DMA1_Channel1_IRQHandler
DMA1_Channel1_IRQHandler:

			.type		DMA1_Channel2_IRQHandler, "function"
			.weak		DMA1_Channel2_IRQHandler
DMA1_Channel2_IRQHandler:

			.type		DMA1_Channel3_IRQHandler, "function"
			.weak		DMA1_Channel3_IRQHandler
DMA1_Channel3_IRQHandler:

			.type		DMA1_Channel4_IRQHandler, "function"
			.weak		DMA1_Channel4_IRQHandler
DMA1_Channel4_IRQHandler:

			.type		DMA1_Channel5_IRQHandler, "function"
			.weak		DMA1_Channel5_IRQHandler
DMA1_Channel5_IRQHandler:

			.type		DMA1_Channel6_IRQHandler, "function"
			.weak		DMA1_Channel6_IRQHandler
DMA1_Channel6_IRQHandler:

			.type		DMA1_Channel7_IRQHandler, "function"
			.weak		DMA1_Channel7_IRQHandler
DMA1_Channel7_IRQHandler:

			.type		ADC1_2_IRQHandler, "function"
			.weak		ADC1_2_IRQHandler
ADC1_2_IRQHandler:

			.type		USB_HP_CAN1_TX_IRQHandler, "function"
			.weak		USB_HP_CAN1_TX_IRQHandler
USB_HP_CAN1_TX_IRQHandler:

			.type		USB_LP_CAN1_RX0_IRQHandler, "function"
			.weak		USB_LP_CAN1_RX0_IRQHandler
USB_LP_CAN1_RX0_IRQHandler:

			.type		CAN1_RX1_IRQHandler, "function"
			.weak		CAN1_RX1_IRQHandler
CAN1_RX1_IRQHandler:

			.type		CAN1_SCE_IRQHandler, "function"
			.weak		CAN1_SCE_IRQHandler
CAN1_SCE_IRQHandler:

			.type		EXTI9_5_IRQHandler, "function"
			.weak		EXTI9_5_IRQHandler
EXTI9_5_IRQHandler:

			.type		TIM1_BRK_IRQHandler, "function"
			.weak		TIM1_BRK_IRQHandler
TIM1_BRK_IRQHandler:

			.type		TIM1_UP_IRQHandler, "function"
			.weak		TIM1_UP_IRQHandler
TIM1_UP_IRQHandler:

			.type		TIM1_TRG_COM_IRQHandler, "function"
			.weak		TIM1_TRG_COM_IRQHandler
TIM1_TRG_COM_IRQHandler:

			.type		TIM1_CC_IRQHandler, "function"
			.weak		TIM1_CC_IRQHandler
TIM1_CC_IRQHandler:

			.type		TIM2_IRQHandler, "function"
			.weak		TIM2_IRQHandler
TIM2_IRQHandler:

			.type		TIM3_IRQHandler, "function"
			.weak		TIM3_IRQHandler
TIM3_IRQHandler:

			.type		TIM4_IRQHandler, "function"
			.weak		TIM4_IRQHandler
TIM4_IRQHandler:

			.type		I2C1_EV_IRQHandler, "function"
			.weak		I2C1_EV_IRQHandler
I2C1_EV_IRQHandler:

			.type		I2C1_ER_IRQHandler, "function"
			.weak		I2C1_ER_IRQHandler
I2C1_ER_IRQHandler:

			.type		I2C2_EV_IRQHandler, "function"
			.weak		I2C2_EV_IRQHandler
I2C2_EV_IRQHandler:

			.type		I2C2_ER_IRQHandler, "function"
			.weak		I2C2_ER_IRQHandler
I2C2_ER_IRQHandler:

			.type		SPI1_IRQHandler, "function"
			.weak		SPI1_IRQHandler
SPI1_IRQHandler:

			.type		SPI2_IRQHandler, "function"
			.weak		SPI2_IRQHandler
SPI2_IRQHandler:

			.type		USART1_IRQHandler, "function"
			.weak		USART1_IRQHandler
USART1_IRQHandler:

			.type		USART2_IRQHandler, "function"
			.weak		USART2_IRQHandler
USART2_IRQHandler:

			.type		USART3_IRQHandler, "function"
			.weak		USART3_IRQHandler
USART3_IRQHandler:

			.type		EXTI15_10_IRQHandler, "function"
			.weak		EXTI15_10_IRQHandler
EXTI15_10_IRQHandler:

			.type		RTCAlarm_IRQHandler, "function"
			.weak		RTCAlarm_IRQHandler
RTCAlarm_IRQHandler:

			.type		USBWakeUp_IRQHandler, "function"
			.weak		USBWakeUp_IRQHandler
USBWakeUp_IRQHandler:

			.type		TIM8_BRK_IRQHandler, "function"
			.weak		TIM8_BRK_IRQHandler
TIM8_BRK_IRQHandler:

			.type		TIM8_UP_IRQHandler, "function"
			.weak		TIM8_UP_IRQHandler
TIM8_UP_IRQHandler:

			.type		TIM8_TRG_COM_IRQHandler, "function"
			.weak		TIM8_TRG_COM_IRQHandler
TIM8_TRG_COM_IRQHandler:

			.type		TIM8_CC_IRQHandler, "function"
			.weak		TIM8_CC_IRQHandler
TIM8_CC_IRQHandler:

			.type		ADC3_IRQHandler, "function"
			.weak		ADC3_IRQHandler
ADC3_IRQHandler:

			.type		FSMC_IRQHandler, "function"
			.weak		FSMC_IRQHandler
FSMC_IRQHandler:

			.type		SDIO_IRQHandler, "function"
			.weak		SDIO_IRQHandler
SDIO_IRQHandler:

			.type		TIM5_IRQHandler, "function"
			.weak		TIM5_IRQHandler
TIM5_IRQHandler:

			.type		SPI3_IRQHandler, "function"
			.weak		SPI3_IRQHandler
SPI3_IRQHandler:

			.type		UART4_IRQHandler, "function"
			.weak		UART4_IRQHandler
UART4_IRQHandler:

			.type		UART5_IRQHandler, "function"
			.weak		UART5_IRQHandler
UART5_IRQHandler:

			.type		TIM6_IRQHandler, "function"
			.weak		TIM6_IRQHandler
TIM6_IRQHandler:

			.type		TIM7_IRQHandler, "function"
			.weak		TIM7_IRQHandler
TIM7_IRQHandler:

			.type		DMA2_Channel1_IRQHandler, "function"
			.weak		DMA2_Channel1_IRQHandler
DMA2_Channel1_IRQHandler:

			.type		DMA2_Channel2_IRQHandler, "function"
			.weak		DMA2_Channel2_IRQHandler
DMA2_Channel2_IRQHandler:

			.type		DMA2_Channel3_IRQHandler, "function"
			.weak		DMA2_Channel3_IRQHandler
DMA2_Channel3_IRQHandler:

			.type		DMA2_Channel4_5_IRQHandler, "function"
			.weak		DMA2_Channel4_5_IRQHandler
DMA2_Channel4_5_IRQHandler:

			#endif

			@ Enter infinite loop
			b.n			.





@-----------------------------------------------------------@
@ InitDataSection											@
@-----------------------------------------------------------@
@															@
@ This function copies data from one location to another.	@
@ (measured approx. 7 cycles/word for flash to ram copy)	@
@															@
@ > Arguments:			r0: data load address				@
@						r1: data store start address		@
@						r2: data store end address			@
@ > Return values:		<none>								@
@ > Changed registers:	r0, r1, r2, r3						@
@ > Changed variables:	<none>								@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			@ Temporary register renaming
			rDataLoad	.req	r0
			rDataStart	.req	r1
			rDataEnd	.req	r2
			rDataValue	.req	r3

			.section	.after_vectors.InitDataSection
			.type		InitDataSection, "function"
InitDataSection_START:

			@ Save registers
			@push		{}

			@-----------------------------------------------------------@

			@ Copy data section
0:			ldr			rDataValue, [rDataLoad], 4
			str			rDataValue, [rDataStart], 4
InitDataSection:
			cmp			rDataStart, rDataEnd
			blo			0b

			@-----------------------------------------------------------@

			@ Restore registers and return
			@pop		{}
			bx			lr

InitDataSection_END:

			@ Destroy temporary register renaming
			.unreq		rDataLoad
			.unreq		rDataStart
			.unreq		rDataEnd
			.unreq		rDataValue

			@ Calculate function size
			.set		InitDataSection_SIZE, InitDataSection_END - InitDataSection_START





@-----------------------------------------------------------@
@ InitBssSection											@
@-----------------------------------------------------------@
@															@
@ This function initializes a section with a specified		@
@ value. (measured approx. 5 cycles/word)					@
@															@
@ > Arguments:			r0: bss start address				@
@						r1: bss end address					@
@						r2: bss clear value					@
@ > Return values:		<none>								@
@ > Changed registers:	r0, r1, r2							@
@ > Changed variables:	<none>								@
@ > Stack usage:		0									@
@-----------------------------------------------------------@

			@ Temporary register renaming
			rBssStart	.req	r0
			rBssEnd		.req	r1
			rBssFill	.req	r2

			.section	.after_vectors.InitBssSection
			.type		InitBssSection, "function"
InitBssSection_START:

			@ Save registers
			@push		{}

			@-----------------------------------------------------------@

			@ Clear bss section
0:			str			rBssFill, [rBssStart], 4
InitBssSection:
			cmp			rBssStart, rBssEnd
			blo			0b

			@-----------------------------------------------------------@

			@ Restore registers and return
			@pop		{}
			bx			lr

InitBssSection_END:

			@ Destroy temporary register renaming
			.unreq		rBssStart
			.unreq		rBssEnd
			.unreq		rBssFill

			@ Calculate function size
			.set		InitBssSection_SIZE, InitBssSection_END - InitBssSection_START





@-----------------------------------------------------------@
@ RESET HANDLER (ENTRY POINT)								@
@-----------------------------------------------------------@
@															@
@ Execution starts here as privileged execution in thread	@
@ mode, using the MSP.										@
@ This function initializes the data and bss sections and	@
@ branches to the main routine, which should never return.	@
@															@
@-----------------------------------------------------------@

			@ Temporary register renaming
			rTable		.req	r4
			rDataLoad	.req	r0
			rDataStart	.req	r1
			rDataEnd	.req	r2
			rBssStart	.req	r0
			rBssEnd		.req	r1
			rBssFill	.req	r2
			rBase		.req	r0
			rValue		.req	r1
			rTemp		.req	r2
			rMainArg	.req	r0

			.section	.after_vectors.Reset_Handler
			.type		Reset_Handler, "function"
Reset_Handler:

			@ Save registers
			@push		{}

			@-----------------------------------------------------------@

			@ Load section table address (rTable is preserved!)
			#ifdef		LPC
			@ FIXME:	hardcoded address
			movs		rTable, #0xCC
			#else
			ldr			rTable, =SectionTable
			#endif

			@ Init data and data_AHB (LPC only) sections (rTable incremented)
			ldmia		rTable!, {rDataLoad, rDataStart, rDataEnd}
			bl			InitDataSection
			#ifdef		LPC
			ldmia		rTable!, {rDataLoad, rDataStart, rDataEnd}
			bl			InitDataSection
			#endif

			@ Fill bss and bss_AHB (LPC only) sections with 0 (rTable incremented)
			movs		rBssFill, #0
			ldmia		rTable!, {rBssStart, rBssEnd}
			bl			InitBssSection
			#ifdef		LPC
			ldmia		rTable!, {rBssStart, rBssEnd}
			bl			InitBssSection
			#endif

			#ifdef		LPC

			@ Jump to the correct main function
			.extern		main		@ (int power_cycle)
			.extern		main_BOD	@ (void)
			.extern		main_WDT	@ (void)

			@ Determine the source of reset using the RSID register
			@ Immediately clear this register for the next reset
			ldr			rBase, =RSID
			ldr			rValue, [rBase]
			movs		rTemp, #0b1111
			str			rTemp, [rBase]

			@ If POR, go to main and tell there was a power cycle
			movs		rMainArg, #1
			tst			rValue, #0b0001
			bne			main

			@ If BOD tripped, go to special main_BOD
			tst			rValue, #0b1000
			bne			main_BOD

			@ If watchdog timer timed out, go to special main_WDT
			tst			rValue, #0b0100
			bne			main_WDT

			@ If none of the above, or if an external reset was applied, go to main
			movs		rMainArg, #0
			b			main

			#else

			@ Jump to the main function
			.extern		main
			b			main

			#endif

			@-----------------------------------------------------------@

			@ Restore registers and return
			@pop		{}
			@bx			lr

Reset_Handler_END:

			@ Destroy temporary register renaming
			.unreq		rTable
			.unreq		rDataLoad
			.unreq		rDataStart
			.unreq		rDataEnd
			.unreq		rBssStart
			.unreq		rBssEnd
			.unreq		rBssFill
			.unreq		rBase
			.unreq		rValue
			.unreq		rTemp
			.unreq		rMainArg

			@ Calculate function size
			.set		Reset_Handler_SIZE, Reset_Handler_END - Reset_Handler




