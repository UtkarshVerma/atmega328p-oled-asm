; vim:ft=avra shiftwidth=2 tabstop=2
#define OLED_ADDRESS 0x3c

#define OLED_CMD_BYTE				(0<<6)
#define OLED_DATA_BYTE 			(1<<6)
#define OLED_SINGLE_BYTE 		(1<<7)
#define OLED_BYTE_STREAM	 	(0<<7)

; Fundamental commands (pg.28)
#define OLED_SET_CONTRAST           0x81    ; follow with 0x7F
#define OLED_DISPLAY_RAM            0xA4
#define OLED_DISPLAY_ALLON          0xA5
#define OLED_DISPLAY_NORMAL         0xA6
#define OLED_DISPLAY_INVERTED       0xA7
#define OLED_DISPLAY_OFF            0xAE
#define OLED_DISPLAY_ON             0xAF

; Addressing Command Table (pg.30)
#define OLED_SET_MEMORY_ADDR_MODE   0x20    ; follow with 0x00 = HORZ mode = Behave like a KS108 graphic LCD
#define OLED_SET_COLUMN_RANGE       0x21    ; can be used only in HORZ/VERT mode - follow with 0x00 and 0x7F = COL127
#define OLED_SET_PAGE_RANGE         0x22    ; can be used only in HORZ/VERT mode - follow with 0x00 and 0x07 = PAGE7

; Hardware Config (pg.31)
#define OLED_SET_DISPLAY_START_LINE 0x40
#define OLED_SET_SEGMENT_REMAP      0xA1    
#define OLED_SET_MUX_RATIO          0xA8    ; follow with 0x3F = 64 MUX
#define OLED_SET_COM_SCAN_MODE      0xC8    
#define OLED_SET_DISPLAY_OFFSET     0xD3    ; follow with 0x00
#define OLED_SET_COM_PIN_MAP        0xDA    ; follow with 0x12
#define OLED_NOP                    0xE3    ; NOP

; Timing and Driving Scheme (pg.32)
#define OLED_SET_DISPLAY_CLK_DIV    0xD5    ; follow with 0x80
#define OLED_SET_PRECHARGE          0xD9    ; follow with 0xF1
#define OLED_SET_VCOMH_DESELCT      0xDB    ; follow with 0x30

; Charge Pump (pg.62)
#define OLED_SET_CHARGE_PUMP        0x8D    ; follow with 0x14
