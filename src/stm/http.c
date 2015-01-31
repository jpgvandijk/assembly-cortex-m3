/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

// Includes
#include "http.h"

#ifdef _USE_HTTP_

// Includes
#include "http_config.h"

HTTP_Page * HTTP_AnalyzeRequest (uint8_t * request, uint32_t length)
{
	uint32_t i, url;

	// First do a basic check: is it a get request with sufficient length?
	uint8_t * check = (uint8_t *) "GET ";
	if (length < (sizeof("GET / HTTP/1.0\r\n\r\n") - 1))
		return HTTP_ANALYZE_ERROR;
	for (i = 0; i < 4; i++)
		if (request[i] != check[i])
			return HTTP_ANALYZE_ERROR;

	// Too large URLs are also not supported
	// This enables to not explicitely check whether the request is sufficiently large
	if ((request + length) >= (ETH_Buffer + ETH_BUFFER_SIZE))
		return HTTP_ANALYZE_ERROR;
	request[length] = 0;

	// Compare with the supported URLs
	request = request + 4;
	for (url = 0; url < HTTP_SERVER_URLS; url++)
	{
		// Compare the strings
		i = 0;
		while (HTTP_Server[url].url[i] && (HTTP_Server[url].url[i] == request[i]))
			i++;

		// Check if they matched so far
		if (HTTP_Server[url].url[i] == 0)
		{
			// Check for a space, the end of the request URL
			if (request[i] == ' ')
			{
				// Request OK
				return HTTP_Server[url].page;
			}
			else
			{
				// Only valid if the character is a question mark and a series of names and values is allowed
				if ((request[i] == '?') && (HTTP_Server[url].namevalue != NULL))
				{
					// Let the name value analyzer decide whether the URL is valid
					if (HTTP_NameValueAnalyzer(request + i, HTTP_Server[url].namevalue) == HTTP_ANALYZE_ERROR)
					{
						return HTTP_ANALYZE_ERROR;
					}
					else
					{
						// Request OK
						return HTTP_Server[url].page;
					}
				}
			}
		}
	}

	// URL incorrect
	return HTTP_ANALYZE_ERROR;
}

uint32_t HTTP_NameValueAnalyzer (uint8_t * buffer, HTTP_NameValue * namevalue)
{
	// Mark which names/values have been found
	uint32_t n, i = 0, found = 0, value = 0;

	// Use the passed names, value extractors and value processors
	do
	{
		// Skip the '?' or '&'
		buffer++;

		// Check for each name
		for (n = 0; n < namevalue->N; n++)
		{
			// Skip if already found
			if (found & (1 << n))
				continue;

			// Compare the strings
			i = 0;
			while (namevalue->names[n][i] && (namevalue->names[n][i] == buffer[i]))
				i++;
			if (namevalue->names[n][i] != 0)
				continue;

			// Check for the equal sign following the name
			if (buffer[i] != '=')
				continue;

			// Remove from the checklist
			found |= (1 << n);
			break;
		}

		// Return if no matching name was found
		if (n == namevalue->N)
			return HTTP_ANALYZE_ERROR;

		// Check for the value, the field could be empty
		buffer += i + 1;
		if ((buffer[0] != '&') && (buffer[0] != ' ')) {
			buffer = namevalue->values[n](buffer);
			if (buffer == HTTP_ANALYZE_ERROR)
				return HTTP_ANALYZE_ERROR;
			value |= (1 << n);
		}

	} while (buffer[0] == '&');

	// Return if it is not the end of the name value string
	if (buffer[0] != ' ')
		return HTTP_ANALYZE_ERROR;

	// Process the values that were found
	for (n = 0; n < namevalue->N; n++)
		if (value & (1 << n))
			namevalue->processors[n]();

	// Return success
	return HTTP_ANALYZE_OK;
}

void HTTP_SendPage (HTTP_Page * page)
{
	// Check if a page should be send
	if (page == HTTP_ANALYZE_ERROR)
		page = &Page_Error;

	// Send the specified page
	uint8_t * data = (uint8_t *) page->address;
	uint32_t length = page->size;
	do
	{
		// Split the webpage into separate packets
		uint32_t size;
		if (length > 1460)
			size = 1460;
		else
			size = length;

		// Read the data for the packet
		FLASH_ReadBytes(data, ETH_Buffer + ETH_TCP_OPTIONS, size);

		// Update the data, possibly changing the packet size
		// if an update should happen at the end of the packet
		if (page->inserters != NULL)
			size = HTTP_UpdatePage(size, page->inserters);

		// Update the variables
		data += size;
		length -= size;

		// Send the packet
		ETH_SendTCPData(size, length?0:1);

	} while (length);
}

uint32_t HTTP_UpdatePage (uint32_t size, HTTP_TextInserter inserters[])
{
	// Setup the pointers
	uint8_t * start = ETH_Buffer + ETH_TCP_OPTIONS;
	uint8_t * end = start + size - 1;

	// Loop over the contents, find insertion fields: "\a\xnn    "
	while (start != end)
	{
		// Check for the alert character
		if (*start == '\a')
		{
			// Call the specified insert function, but only
			// if the update field is entirely in this packet
			if (size < 1460)
			{
				// The field is entirely in this packet
				inserters[start[1]](start);
			}
			else
			{
				// Call the specified insert function, but only
				// if the update field is entirely in this packet
				uint32_t i = 2;
				while ((start[i] == ' ') && ((start + i) != (end + 1)))
					i++;

				// Check for the end
				if ((start + i) == (end + 1))
				{
					// Return with reduced packet size
					return (start - ETH_Buffer + ETH_TCP_OPTIONS);
				}
				else
				{
					// The field is entirely in this packet
					inserters[start[1]](start);
				}
			}
		}
		start++;
	}

	// Return with the new size
	if (*start == '\a')
		return (size - 1);
	else
		return (size);
}

#endif//_USE_HTTP_
