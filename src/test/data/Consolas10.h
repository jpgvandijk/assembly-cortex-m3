/************************************************************************************
*
* Author: J.P.G. van Dijk
*
************************************************************************************/

#ifndef _CONSOLAS10_H_
#define _CONSOLAS10_H_

static uint8_t Consolas10[] __attribute__ ((section (".ext"))) = {

	// Width, height, first char, char count
	0x06,
	0x0A,
	0x20,
	0x60,

	// Char widths
	

	// Font data
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 32
	0x00, 0x82, 0x08, 0x20, 0x80, 0x08, 0x00, 0x00, // 33
	0x00, 0xA2, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, // 34
	0x00, 0xC3, 0x3E, 0x33, 0xE6, 0x18, 0x00, 0x00, // 35
	0x00, 0x43, 0x94, 0x70, 0x62, 0x9E, 0x20, 0x00, // 36
	0x03, 0x9A, 0xBC, 0x20, 0xF5, 0x67, 0x00, 0x00, // 37
	0x01, 0xC5, 0x14, 0x63, 0xE9, 0x9F, 0x00, 0x00, // 38
	0x00, 0x82, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 39
	0x00, 0x42, 0x10, 0x41, 0x04, 0x10, 0x20, 0x40, // 40
	0x01, 0x02, 0x04, 0x10, 0x41, 0x04, 0x21, 0x00, // 41
	0x00, 0x47, 0xDF, 0x10, 0x00, 0x00, 0x00, 0x00, // 42
	0x00, 0x00, 0x04, 0x11, 0xF1, 0x04, 0x00, 0x00, // 43
	0x00, 0x00, 0x00, 0x00, 0x03, 0x0C, 0x31, 0x80, // 44
	0x00, 0x00, 0x00, 0x01, 0xC0, 0x00, 0x00, 0x00, // 45
	0x00, 0x00, 0x00, 0x00, 0x03, 0x0C, 0x00, 0x00, // 46
	0x00, 0x21, 0x04, 0x10, 0x82, 0x10, 0x40, 0x00, // 47
	0x00, 0x07, 0x22, 0xBB, 0xA8, 0x9C, 0x00, 0x00, // 48
	0x00, 0x03, 0x14, 0x10, 0x41, 0x1E, 0x00, 0x00, // 49
	0x00, 0x03, 0x92, 0x08, 0x42, 0x1E, 0x00, 0x00, // 50
	0x00, 0x07, 0x82, 0x30, 0x20, 0x9C, 0x00, 0x00, // 51
	0x00, 0x03, 0x0C, 0x52, 0x4F, 0x84, 0x00, 0x00, // 52
	0x00, 0x07, 0x90, 0x70, 0x20, 0x9C, 0x00, 0x00, // 53
	0x00, 0x03, 0x98, 0x79, 0x14, 0x4E, 0x00, 0x00, // 54
	0x00, 0x07, 0x82, 0x10, 0x42, 0x08, 0x00, 0x00, // 55
	0x00, 0x07, 0x92, 0x31, 0x24, 0x9C, 0x00, 0x00, // 56
	0x00, 0x07, 0x22, 0x89, 0xE1, 0xB8, 0x00, 0x00, // 57
	0x00, 0x00, 0x08, 0x20, 0x02, 0x08, 0x00, 0x00, // 58
	0x00, 0x00, 0x08, 0x20, 0x03, 0x0C, 0x31, 0x80, // 59
	0x00, 0x00, 0x02, 0x31, 0x03, 0x02, 0x00, 0x00, // 60
	0x00, 0x00, 0x00, 0x78, 0x07, 0x80, 0x00, 0x00, // 61
	0x00, 0x00, 0x10, 0x30, 0x23, 0x10, 0x00, 0x00, // 62
	0x01, 0x81, 0x04, 0x61, 0x00, 0x10, 0x00, 0x00, // 63
	0x00, 0xE4, 0x71, 0xB6, 0xDB, 0xA0, 0xC1, 0xC0, // 64
	0x00, 0x02, 0x14, 0x52, 0x2F, 0xA2, 0x00, 0x00, // 65
	0x00, 0x07, 0x92, 0x71, 0x24, 0x9C, 0x00, 0x00, // 66
	0x00, 0x07, 0xB0, 0x82, 0x0C, 0x1E, 0x00, 0x00, // 67
	0x00, 0x07, 0x12, 0x49, 0x24, 0x9C, 0x00, 0x00, // 68
	0x00, 0x07, 0x90, 0x79, 0x04, 0x1E, 0x00, 0x00, // 69
	0x00, 0x07, 0x90, 0x79, 0x04, 0x10, 0x00, 0x00, // 70
	0x00, 0x07, 0xB0, 0x9A, 0x2C, 0x9E, 0x00, 0x00, // 71
	0x00, 0x04, 0x92, 0x79, 0x24, 0x92, 0x00, 0x00, // 72
	0x00, 0x07, 0x08, 0x20, 0x82, 0x1C, 0x00, 0x00, // 73
	0x00, 0x07, 0x82, 0x08, 0x20, 0x9C, 0x00, 0x00, // 74
	0x00, 0x04, 0x94, 0x61, 0x85, 0x12, 0x00, 0x00, // 75
	0x00, 0x04, 0x10, 0x41, 0x04, 0x1E, 0x00, 0x00, // 76
	0x00, 0x04, 0x95, 0xB6, 0x18, 0x61, 0x00, 0x00, // 77
	0x00, 0x04, 0x9A, 0x69, 0x65, 0x92, 0x00, 0x00, // 78
	0x00, 0x07, 0x22, 0x8A, 0x28, 0x9C, 0x00, 0x00, // 79
	0x00, 0x07, 0x12, 0x49, 0xC4, 0x10, 0x00, 0x00, // 80
	0x00, 0x07, 0x22, 0x8A, 0x28, 0x9C, 0x20, 0x60, // 81
	0x00, 0x07, 0x12, 0x49, 0xC5, 0x92, 0x00, 0x00, // 82
	0x00, 0x03, 0x90, 0x60, 0x60, 0x9C, 0x00, 0x00, // 83
	0x00, 0x0F, 0x88, 0x20, 0x82, 0x08, 0x00, 0x00, // 84
	0x00, 0x04, 0x51, 0x45, 0x14, 0x4E, 0x00, 0x00, // 85
	0x00, 0x04, 0x51, 0x44, 0xA2, 0x84, 0x00, 0x00, // 86
	0x00, 0x04, 0x51, 0x55, 0xD4, 0xD1, 0x00, 0x00, // 87
	0x00, 0x08, 0x94, 0x20, 0xC4, 0xA3, 0x00, 0x00, // 88
	0x00, 0x04, 0x4A, 0x28, 0x41, 0x04, 0x00, 0x00, // 89
	0x00, 0x07, 0x84, 0x10, 0x82, 0x1E, 0x00, 0x00, // 90
	0x00, 0xE2, 0x08, 0x20, 0x82, 0x08, 0x20, 0xE0, // 91
	0x01, 0x04, 0x08, 0x20, 0x41, 0x04, 0x08, 0x00, // 92
	0x01, 0xC1, 0x04, 0x10, 0x41, 0x04, 0x11, 0xC0, // 93
	0x00, 0x02, 0x14, 0x50, 0x00, 0x00, 0x00, 0x00, // 94
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xF0, // 95
	0x60, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 96
	0x00, 0x00, 0x1E, 0x09, 0xE4, 0x9E, 0x00, 0x00, // 97
	0x01, 0x04, 0x1E, 0x49, 0x24, 0x9C, 0x00, 0x00, // 98
	0x00, 0x00, 0x0E, 0x41, 0x04, 0x0E, 0x00, 0x00, // 99
	0x00, 0x20, 0x8E, 0x49, 0x24, 0x8E, 0x00, 0x00, // 100
	0x00, 0x00, 0x0C, 0x49, 0xE4, 0x0E, 0x00, 0x00, // 101
	0x00, 0x72, 0x3E, 0x20, 0x82, 0x08, 0x00, 0x00, // 102
	0x00, 0x00, 0x1F, 0x8B, 0xC8, 0x3E, 0x8B, 0xC0, // 103
	0x01, 0x04, 0x1E, 0x49, 0x24, 0x92, 0x00, 0x00, // 104
	0x00, 0x40, 0x1C, 0x10, 0x41, 0x1E, 0x00, 0x00, // 105
	0x00, 0x40, 0x1C, 0x10, 0x41, 0x04, 0x11, 0x80, // 106
	0x01, 0x04, 0x12, 0x51, 0x85, 0x12, 0x00, 0x00, // 107
	0x01, 0xC1, 0x04, 0x10, 0x41, 0x1E, 0x00, 0x00, // 108
	0x00, 0x00, 0x1F, 0x55, 0x55, 0x55, 0x00, 0x00, // 109
	0x00, 0x00, 0x1E, 0x49, 0x24, 0x92, 0x00, 0x00, // 110
	0x00, 0x00, 0x1C, 0x8A, 0x28, 0x9C, 0x00, 0x00, // 111
	0x00, 0x00, 0x1E, 0x49, 0x24, 0x9C, 0x41, 0x00, // 112
	0x00, 0x00, 0x0E, 0x49, 0x24, 0x8E, 0x08, 0x20, // 113
	0x00, 0x00, 0x1E, 0x49, 0x04, 0x10, 0x00, 0x00, // 114
	0x00, 0x00, 0x1E, 0x40, 0xC0, 0x9E, 0x00, 0x00, // 115
	0x01, 0x04, 0x3C, 0x41, 0x04, 0x0C, 0x00, 0x00, // 116
	0x00, 0x00, 0x12, 0x49, 0x24, 0x9E, 0x00, 0x00, // 117
	0x00, 0x00, 0x0A, 0x28, 0xA2, 0x84, 0x00, 0x00, // 118
	0x00, 0x00, 0x21, 0xAA, 0xED, 0x92, 0x00, 0x00, // 119
	0x00, 0x00, 0x22, 0x50, 0xC4, 0xA3, 0x00, 0x00, // 120
	0x00, 0x00, 0x0A, 0x28, 0xA3, 0x04, 0x11, 0x80, // 121
	0x00, 0x00, 0x1E, 0x10, 0x42, 0x1E, 0x00, 0x00, // 122
	0x00, 0xC2, 0x08, 0x21, 0x02, 0x08, 0x20, 0xC0, // 123
	0x20, 0x82, 0x08, 0x20, 0x82, 0x08, 0x20, 0x80, // 124
	0x01, 0x82, 0x08, 0x20, 0x42, 0x08, 0x21, 0x80, // 125
	0x00, 0x00, 0x00, 0xEA, 0xE0, 0x00, 0x00, 0x00, // 126
	0x00, 0x0F, 0xA2, 0xEA, 0xA8, 0xBE, 0x00, 0x00 // 127
	
};

#endif//_CONSOLAS10_H_
