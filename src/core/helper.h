/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _HELPER_H_
#define _HELPER_H_

#ifndef __ASSEMBLER__

// Structures
typedef struct
{
	uint32_t bit_number;
	uint32_t address_offset;
} NumberToBitReturnType;

// Global functions
extern NumberToBitReturnType NumberToBitInWord (uint32_t number);
extern NumberToBitReturnType NumberTo2BitsInWord (uint32_t number);
extern NumberToBitReturnType NumberTo4BitsInWord (uint32_t number);

#endif//__ASSEMBLER__

#endif//_HELPER_H_
