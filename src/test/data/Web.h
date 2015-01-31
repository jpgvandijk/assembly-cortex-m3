/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _WEB_H_
#define _WEB_H_

// Includes
#include "flash.h"

// Webrequests
#define WEB_REQUEST_ADDRESS			(request - FLASH_BASE_ADDRESS)
#define WEB_REQUEST_SIZE			(sizeof(request) - 1)
static char request[] IN_EXTERNAL_FLASH =

	"GET /notification.php?id=0 HTTP/1.1\r\n"
	"Host: 192.168.1.55\r\n"
	"User-Agent: EtherShield/1.6\r\n"
	"Accept: text/html\r\n"
	"Connection: close\r\n\r\n";

// Webpages
#define PAGE_ERROR_ADDRESS			(PAGE_ERROR - FLASH_BASE_ADDRESS)
#define PAGE_ERROR_SIZE				(sizeof(PAGE_ERROR) - 1)
static char PAGE_ERROR[] IN_EXTERNAL_FLASH =

	"HTTP/1.0 401 Unauthorized\r\n"
	"Content-Type: text/html\r\n\r\n"
	"<h1>401 Unauthorized</h1>";

#define PAGE_LOGIN_ADDRESS			(PAGE_LOGIN - FLASH_BASE_ADDRESS)
#define PAGE_LOGIN_SIZE				(sizeof(PAGE_LOGIN) - 1)
static char PAGE_LOGIN[] IN_EXTERNAL_FLASH =

	"HTTP/1.0 200 OK\r\n"
	"Content-Type: text/html\r\n\r\n"
	"<p>Usage: http://hc.timleferink.nl:8011/password</p>";

#define PAGE_DATA_ADDRESS			(PAGE_DATA - FLASH_BASE_ADDRESS)
#define PAGE_DATA_SIZE				(sizeof(PAGE_DATA) - 1)
static char PAGE_DATA[] IN_EXTERNAL_FLASH =

	"HTTP/1.0 200 OK\r\n"
	"Content-Type: text/html\r\n\r\n"
	"\a\x00                                                ";

#define PAGE_DOOR_ADDRESS			(PAGE_DOOR - FLASH_BASE_ADDRESS)
#define PAGE_DOOR_SIZE				(sizeof(PAGE_DOOR) - 1)
static char PAGE_DOOR[] IN_EXTERNAL_FLASH =

	"HTTP/1.0 200 OK\r\n"
	"Content-Type: text/html\r\n\r\n"
	"<h1>De deur wordt geopend</h1>";

#define PAGE_MAIN_ADDRESS			(PAGE_MAIN - FLASH_BASE_ADDRESS)
#define PAGE_MAIN_SIZE				(sizeof(PAGE_MAIN) - 1)
static char PAGE_MAIN[] IN_EXTERNAL_FLASH =

	"HTTP/1.0 200 OK\r\n"
	"Content-Type: text/html\r\n\r\n"
	"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">"
	"<html>"
		"<head>"
			"<meta http-equiv=\"Content-Type\" content=\"text/html;charset=ISO-8859-1\">"
			"<meta name=\"viewport\" content=\"width=505\">"
			"<title>Home Automation</title>"
		"</head>"
		"<body>"
			"<table border=\"1\" width=\"480\"><tr><td height=\"470\" valign=\"top\" bgcolor=\"#EBEBEB\"><center>"
				"<h1>Home Automation</h1>"
				"<h3>Temperature Control</h3>"
				"<form action=\"/Tim78654\" method=\"get\">"
					"<table style=\"border: 1px dotted gray;\">"
						"<tr><td width=\"200\">Outside Temperature:</td><td width=\"110\">\a\x00    &deg;C</td></tr>"
						"<tr><td>Room Temperature:</td><td>\a\x01    &deg;C</td></tr>"
						"<tr><td>Set Temperature:</td><td>\a\x02    &deg;C</td></tr>"
						"<tr><td><input name=\"T\"></td><td><input type=\"submit\" value=\"Set temperature\"></td></tr>"
						"<tr><td>Valve:</td><td>\a\x03 </td></tr>"
						"<tr><td>Floorpump:</td><td>\a\x04 </td></tr>"
					"</table>"
				"</form>"
				"<h3>Light Control</h3>"
				"<form action=\"/Tim78654\" method=\"get\">"
					"<table style=\"border: 1px dotted gray;\">"
						"<tr><td>Entrance:</td><td><a href=\"/Tim78654?action=\a\x05\">\a\x06 </a></td></tr>"
						"<tr><td>Kitchen:</td><td><a href=\"/Tim78654?action=\a\x07\">\a\x08 </a></td></tr>"
						"<tr><td width=\"200\">Dimmer:</td><td width=\"110\">\a\x09</td></tr>"
						"<tr><td><input name=\"d\"></td><td><input type=\"submit\" value=\"Set dimmer\" style=\"width: 110px\"></td></tr>"
					"</table>"
				"</form>"
				"<h3>Other Controls</h3>"
				"<table style=\"border: 1px dotted gray;\">"
					"<tr><td width=\"200\">Door:</td><td colspan=\"2\"><a href=\"/Tim78654?action=OD\">Open</a></td></tr>"
					"<tr><td width=\"200\">Building door:</td><td colspan=\"2\"><a href=\"/Tim78654?action=OB\">Open</a></td></tr>"
					"<tr><td>Relay A:</td><td width=\"40\"><a href=\"/Tim78654?action=A1\">On</a></td><td width=\"70\"><a href=\"/Tim78654?action=A0\">Off</a></td></tr>"
					"<tr><td>Relay B:</td><td><a href=\"/Tim78654?action=B1\">On</a></td><td><a href=\"/Tim78654?action=B0\">Off</a></td></tr>"
					"<tr><td>Relay C:</td><td><a href=\"/Tim78654?action=C1\">On</a></td><td><a href=\"/Tim78654?action=C0\">Off</a></td></tr>"
					"<tr><td>Relay D:</td><td><a href=\"/Tim78654?action=D1\">On</a></td><td><a href=\"/Tim78654?action=D0\">Off</a></td></tr>"
				"</table>"
				"<br>"
			"</center></td></tr></table>"
		"</body>"
	"</html>";

#endif//_WEB_H_
