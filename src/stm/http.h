/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _HTTP_H_
#define _HTTP_H_

// Includes
#include <stdint.h>
#include "cortex_m3.h"
#include "config.h"
#include "flash.h"
#include "tcp.h"

#ifdef _USE_HTTP_

// Type definitions for function pointers
typedef uint8_t * (* HTTP_ValueAnalyzer) (uint8_t * buffer);
typedef void (* HTTP_ValueProcessor) (void);
typedef void (* HTTP_TextInserter) (uint8_t * buffer);

// Type definitions
typedef struct {
	uint32_t N;
	char * * names;
	HTTP_ValueAnalyzer * values;
	HTTP_ValueProcessor * processors;
} HTTP_NameValue;

typedef struct {
	char * address;
	uint32_t size;
	HTTP_TextInserter * inserters;
} HTTP_Page;

typedef struct {
	char * url;
	HTTP_NameValue * namevalue;
	HTTP_Page * page;
} HTTP_URL;

// Definitions
#define HTTP_ANALYZE_ERROR		0
#define HTTP_ANALYZE_OK			1

// Function prototypes
HTTP_Page * HTTP_AnalyzeRequest (uint8_t * request, uint32_t length);
uint32_t HTTP_NameValueAnalyzer (uint8_t * buffer, HTTP_NameValue * namevalue);
void HTTP_SendPage (HTTP_Page * page);
uint32_t HTTP_UpdatePage (uint32_t size, HTTP_TextInserter * inserters);

#endif//_USE_HTTP_

#endif//_HTTP_H_
