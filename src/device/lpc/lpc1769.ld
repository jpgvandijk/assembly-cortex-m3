/*************************************************************************************
* CONSTANTS/VARIABLES																 *
*************************************************************************************/

/* .rodata:			stored in FLASH only											*/
/* .data(.AHB):		loaded in (AHB)RAM at startup									*/
/* .bss(.AHB):		cleared in (AHB)RAM at startup									*/
/* .noinit(.AHB):	reserved in (AHB)RAM											*/

/*************************************************************************************
* C LIBRARY SUPPORT																	 *
*************************************************************************************/

/*GROUP(libcr_c.a libcr_eabihelpers.a)					*/	/* Redlib (None) 		*/
/*GROUP(libcr_nohost.a libcr_c.a libcr_eabihelpers.a)	*/	/* Redlib (Nohost) 		*/
/*GROUP(libcr_semihost.a libcr_c.a libcr_eabihelpers.a)	*/	/* Redlib (Semihost) 	*/
/*GROUP(libgcc.a libc.a libm.a)							*/	/* Newlib (None) 		*/
/*GROUP(libgcc.a libc.a libm.a libcr_newlib_nohost.a)	*/	/* Newlib (Nohost) 		*/
/*GROUP(libgcc.a libc.a libm.a libcr_newlib_semihost.a)	*/	/* Newlib (Semihost) 	*/

/*************************************************************************************
* MEMORY LAYOUT																		 *
*************************************************************************************/

/* Define the memory regions */
MEMORY
{
	FlashMemory		(rx)	: ORIGIN = 0x00000000, LENGTH = 0x00080000		/* 512k	*/
	LocalSRAM		(rwx)	: ORIGIN = 0x10000000, LENGTH = 0x00008000		/* 32k	*/
	AHBSRAM			(rwx)	: ORIGIN = 0x2007c000, LENGTH = 0x00008000		/* 32k	*/
}

/* Define a symbol for the top of each memory region */
__top_FlashMemory	= 0x00000000 + 0x00080000;
__top_LocalSRAM		= 0x10000000 + 0x00008000;
__top_AHBSRAM		= 0x2007c000 + 0x00008000;

/*************************************************************************************
* ENTRY POINT																		 *
*************************************************************************************/

ENTRY(Reset_Handler)

/*************************************************************************************
* OUTPUT SECTIONS																	 *
*************************************************************************************/

SECTIONS
{
	/*********************************************************************************
	* TEXT AND RODATA SECTION														 *
	*********************************************************************************/
	
	.text : ALIGN(4)
	{
		FILL(0xFF)
		
		/* 1. Interrupt vectors at address 0x00000000 */
		. = 0x00000000;
		KEEP(*(.interrupt_vectors))
		
		/* 2. Section table after the interrupt vectors */
		. = ALIGN(4);
		KEEP(*(.section_table))
	
		/* 3. Make it possible to use the space between the interrupt vectors and the CRP data */
		. = ALIGN(4);
		*(.after_vectors*)
		
		/* 4. Code Read Protect data */
		. = 0x000002FC;
		KEEP(*(.crp))
		
		/* 5. Code */
		*(.text*)
		
		/* 6. Readonly data */
		*(.rodata .rodata.*)
		
		. = ALIGN(4);
	} > FlashMemory
	
	/*********************************************************************************
	* DATA SECTION																	 *
	*********************************************************************************/
    
    .data_AHB : ALIGN(4)
	{
		FILL(0xFF)
		
		/* 1. Data */
		*(.data.AHB*)
		
		. = ALIGN(4);
	} > AHBSRAM AT>FlashMemory
	
	/* PROVIDE PLACEMENT INFORMATION */
	__data_AHB_Size = SIZEOF(.data_AHB);
	__data_AHB_LoadAddress = LOADADDR(.data_AHB);
    __data_AHB_StartAddress = ADDR(.data_AHB);
    __data_AHB_EndAddress = ADDR(.data_AHB) + SIZEOF(.data_AHB);
    
    .data : ALIGN(4)
	{
		FILL(0xFF)
		
		/* 1. Data */
		*(.data*)
		
		. = ALIGN(4);
	} > LocalSRAM AT>FlashMemory
	
	/* PROVIDE PLACEMENT INFORMATION */
	__data_Size = SIZEOF(.data);
	__data_LoadAddress = LOADADDR(.data);
    __data_StartAddress = ADDR(.data);
	__data_EndAddress = ADDR(.data) + SIZEOF(.data);
	
	/*********************************************************************************
	* BSS SECTION																	 *
	*********************************************************************************/
	
	.bss_AHB : ALIGN(4)
	{
		/* 1. Data */
		KEEP(*(.bss.bitband*))
		*(.bss.AHB*)
		
		. = ALIGN(4);
	} > AHBSRAM
	
	/* PROVIDE PLACEMENT INFORMATION */
	__bss_AHB_Size = SIZEOF(.bss_AHB);
    __bss_AHB_StartAddress = ADDR(.bss_AHB);
    __bss_AHB_EndAddress = ADDR(.bss_AHB) + SIZEOF(.bss_AHB);
	
	.bss : ALIGN(4)
	{
		/* 1. Data */
		*(.bss*)
		
		. = ALIGN(4);        
	} > LocalSRAM
	
	/* PROVIDE PLACEMENT INFORMATION */
	__bss_Size = SIZEOF(.bss);
	__bss_StartAddress = ADDR(.bss);
	__bss_EndAddress = ADDR(.bss) + SIZEOF(.bss);
	
	/*********************************************************************************
	* NOINIT SECTION																 *
	*********************************************************************************/
	
	.noinit_AHB (NOLOAD) : ALIGN(4)
	{
		/* 1. Data */
		KEEP(*(.noinit.bitband*))
		*(.noinit.AHB*)
		
		. = ALIGN(4);
	} > AHBSRAM
	
	.noinit (NOLOAD) : ALIGN(4)
	{
		/* 1. Data */
		*(.noinit*)
		
		. = ALIGN(4);
	} > LocalSRAM
}
