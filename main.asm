; vim:ft=avra:shiftwidth=2:tabstop=2:expandtab:
.nolist
.include "m328pdef.inc"
.include "oled.inc"
.include "sd.inc"

; Write given value on the I2C bus
.macro twiWrite
  push r16
  ldi r16, @0
  rcall twiWrite
  pop r16
.endmacro

.macro spiTransmit
  ldi r16, @0
  rcall spiTransmit
.endmacro

.macro spiTransfer
  spiTransmit @0
  rcall spiReceive
.endmacro

.macro storeAddress
  push r16
  ldi zh, high(ADDRESS)
  ldi zl, low(ADDRESS)

  ldi r16, byte4(@0)
  st z+, r16
  ldi r16, byte3(@0)
  st z+, r16
  ldi r16, byte2(@0)
  st z+, r16
  ldi r16, low(@0)
  st z+, r16

  pop r16
.endmacro

.macro sdCommand
  ldi r16, @0
  storeAddress @1
  ldi r17, @2
  rcall sdCmd
.endmacro

; Delay by milliseconds
.macro delay
  ldi r24, low(@0)
  ldi r25, high(@0)
  rcall delay
.endmacro

.equ DDR_SPI = DDRB
.equ PORT_SPI = PORTB
.equ SCK = PB5
.equ MISO = PB4
.equ MOSI = PB3
.equ SS = PB2

.equ FRAME_BUF = 0x0100
.equ RESP = FRAME_BUF + 1024
.equ ADDRESS = RESP + 5
.equ TOKEN = ADDRESS + 4
.list

main:
  rcall oledInit
  rcall sdInit
  storeAddress 0

loop:
  ldi yh, high(FRAME_BUF)
  ldi yl, low(FRAME_BUF)
  rcall sdReadFrame
  rcall updateAddress
  rcall oledWrite
  rjmp loop

; TODO: cmdAttempts, OCR checking
sdInit:
  rcall spiInit
  rcall sdPowerUpSeq
loop5:
  rcall sdGoIdle
  sts RESP, r16
  cpi r16, 0x01
  brne loop5

  rcall sdSendIfCond
  lds r17, RESP
  mov r16, r17
  cpi r17, 0x01
  brne exit6

  ; Check echo pattern
  lds r17, RESP+4
  cpi r17, 0xaa
  brne exit6

loop2:
  rcall sdSendApp
  sts RESP, r16
  cpi r16, 2
  brsh skip1

  rcall sdSendOpCond
  sts RESP, r16
skip1:
  delay 10
  cpi r16, SD_READY
  brne loop2

  rcall sdReadOCR
exit6:
  ret

; TODO: readAttempts, return value
; Read one frame from SD card and write it to `FRAME_BUF`
sdReadFrame:
  ldi r16, 0xff
  sts TOKEN, r16                 ; Set TOKEN to none

  ; Enable the card
  spiTransfer 0xff
  cbi PORT_SPI, SS
  spiTransfer 0xff

  ldi r16, CMD18
  ldi r17, CMD18_CRC
  rcall sdCmd

  rcall sdReadRes1
  cpi r16, 0xff
  breq exit2
  
  ; Max attempts
  ldi zl, low(SD_MAX_READ_ATTEMPTS)
  ldi zh, high(SD_MAX_READ_ATTEMPTS)
loop3:
  spiTransfer 0xff
  cpi r16, 0xff
  brne exit3
  sbiw z, 1
  brne loop3
exit3:
  push r16
  cpi r16, 0xfe
  brne exit4

  ldi r24, 2  ; Read 2 blocks
readBlocks:
  ldi xh, high(512)
  ldi xl, low(512)
readBlock:
  spiTransfer 0xff
  st y+, r16
  sbiw x, 1
  brne readBlock

discardCRC:
  spiTransfer 0xff
  cpi r16, 0xfe
  brne discardCRC

  dec r24
  brne readBlocks

  rcall sdStopTransmission
exit4:
  pop r16
  sts TOKEN, r16
exit2:
  ret

updateAddress:
  push yh
  push yl

  ; Increment address by two blocks
  lds zh, ADDRESS+2
  lds zl, ADDRESS+3
  adiw z, 2
  sts ADDRESS+2, zh
  sts ADDRESS+3, zl

  pop yl
  pop yh
  ret

; DONE
sdReadOCR:
  spiTransfer 0xff
  cbi PORT_SPI, SS
  spiTransfer 0xff

  sdCommand CMD58, CMD58_ARG, CMD58_CRC

  rcall sdReadRes7

  spiTransfer 0xff
  sbi PORT_SPI, SS
  spiTransfer 0xff
  ret

sdSendOpCond:
  spiTransfer 0xff
  cbi PORT_SPI, SS
  spiTransfer 0xff

  sdCommand ACMD41, ACMD41_ARG, ACMD41_CRC

  rcall sdReadRes1
  push r16

  spiTransfer 0xff
  sbi PORT_SPI, SS
  spiTransfer 0xff

  pop r16
  ret

sdSendApp:
  spiTransfer 0xff
  cbi PORT_SPI, SS
  spiTransfer 0xff

  sdCommand CMD55, CMD55_ARG, CMD55_CRC

  rcall sdReadRes1
  push r16

  spiTransfer 0xff
  sbi PORT_SPI, SS
  spiTransfer 0xff

  pop r16
  ret

sdStopTransmission:
  ; Assert SS
  spiTransfer 0xff
  cbi PORT_SPI, SS
  spiTransfer 0xff

  ldi r16, CMD12
  ldi r17, CMD12_CRC
  rcall sdCmd

  ; Skip a stuff byte
  spiTransfer 0xff
  rcall sdReadRes1

  ; Deselect SD card
  spiTransfer 0xff
  sbi PORT_SPI, SS
  spiTransfer 0xff
  ret

; DONE
sdSendIfCond:
  ; Assert SS
  spiTransfer 0xff
  cbi PORT_SPI, SS
  spiTransfer 0xff

  sdCommand CMD8, CMD8_ARG, CMD8_CRC
  rcall sdReadRes7

  ; Deselect SD card
  spiTransfer 0xff
  sbi PORT_SPI, SS
  spiTransfer 0xff
  ret

; DONE
sdReadRes7:
  ldi zh, high(RESP)
  ldi zl, low(RESP)

  rcall sdReadRes1
  st z+, r16

  cpi r16, 2
  brsh exit5

  spiTransfer 0xff
  st z+, r16
  spiTransfer 0xff
  st z+, r16
  spiTransfer 0xff
  st z+, r16
  spiTransfer 0xff
  st z+, r16
exit5:
  ret

; DONE
sdPowerUpSeq:
  sbi PORT_SPI, SS            ; Make sure that SD card is deselected
  delay 1                     ; Give it time to power on

  ; Send 80 clock cycles for synchronization
  ldi r17, 10
loop4:
  spiTransfer 0xff
  dec r17
  brne loop4
  
  sbi PORT_SPI, SS            ; Deselect SD card
  spiTransfer 0xff
  ret

sdGoIdle:
  ; Assert chip select
  spiTransfer 0xff
  cbi PORT_SPI, SS
  spiTransfer 0xff

  sdCommand CMD0, CMD0_ARG, CMD0_CRC
  rcall sdReadRes1
  push r16
  
  ; Deselect SD card
  spiTransfer 0xff
  sbi PORT_SPI, SS
  spiTransfer 0xff

  pop r16
  ret

sdReadRes1:
  ldi r22, 8
loop1:
  spiTransfer 0xff
  dec r22
  breq exit1
  cpi r16, 0xff
  breq loop1
exit1:
  ret

sdCmd:
  ori r16, 0x40
  rcall spiTransmit

  ldi zh, high(ADDRESS)
  ldi zl, low(ADDRESS)

  ld r16, z+
  rcall spiTransmit
  ld r16, z+
  rcall spiTransmit
  ld r16, z+
  rcall spiTransmit
  ld r16, z+
  rcall spiTransmit

  ; Send CRC
  mov r16, r17
  ori r16, 0x01
  rcall spiTransmit
  ret

oledInit:
  ; Initialize two-wire interface
  rcall twiInit

  ; Start transmission
  rcall twiStart
  twiWrite OLED_ADDRESS<<1    ; Transmit slave address in write mode (R/W# = 0)

  ; Indicate that multiple commands are going to be sent
  twiWrite (OLED_CMD_BYTE|OLED_BYTE_STREAM)

	twiWrite OLED_DISPLAY_OFF
	; Set mux ration tp select max number of rows - 64
	twiWrite OLED_SET_MUX_RATIO
	twiWrite 63

	; Set the display offset to 0
	twiWrite OLED_SET_DISPLAY_OFFSET
	twiWrite 0

	; Display start line to 0
	twiWrite OLED_SET_DISPLAY_START_LINE
	
	; Mirror the x-axis. In case you set it up such that the pins are north.
	twiWrite OLED_SET_SEGMENT_REMAP
		
	; Mirror the y-axis. In case you set it up such that the pins are north.
	twiWrite OLED_SET_COM_SCAN_MODE
		
	; Default - alternate COM pin map
	twiWrite OLED_SET_COM_PIN_MAP
	twiWrite 0x12
	
  ; set contrast
  twiWrite OLED_SET_CONTRAST
	twiWrite 0x7F
	
  ; Set display to enable rendering from GDDRAM (Graphic Display Data RAM)
	twiWrite OLED_DISPLAY_RAM

  ; Normal mode!
	twiWrite OLED_DISPLAY_NORMAL

  ; Default oscillator clock
	twiWrite OLED_SET_DISPLAY_CLK_DIV
	twiWrite 0x80

  ; Enable the charge pump
	twiWrite OLED_SET_CHARGE_PUMP
	twiWrite 0x14

  ; Set precharge cycles to high cap type
	twiWrite OLED_SET_PRECHARGE
	twiWrite 0x22

  ; Set the V_COMH deselect volatage to max
	twiWrite OLED_SET_VCOMH_DESELCT
	twiWrite 0x30

	; Horizonatal addressing mode - same as the KS108 GLCD
	twiWrite OLED_SET_MEMORY_ADDR_MODE
	twiWrite 0x00  

  ; Use the full column-range (0-127)
  twiWrite OLED_SET_COLUMN_RANGE
  twiWrite 0
  twiWrite 127

  ; Use the full page-range (0-7)
  twiWrite OLED_SET_PAGE_RANGE
  twiWrite 0
  twiWrite 7

	; Turn the Display ON
	twiWrite OLED_DISPLAY_ON

  rcall twiStop
  ret

; Write the the frame pointed stored in `FRAME_BUF`
oledWrite:
  ldi zh, high(FRAME_BUF)
  ldi zl, low(FRAME_BUF)

  rcall twiStart
  twiWrite OLED_ADDRESS<<1
  twiWrite (OLED_DATA_BYTE|OLED_BYTE_STREAM)

  ldi r17, 8
outer:
  ldi r18, 128
inner:
  ld r16, z+
  rcall twiWrite
  dec r18
  brne inner
  dec r17
  brne outer

  rcall twiStop
  ret

; Initialise TWI with SCL frequency = 100kHz
twiInit:
  ; Clear prescalar bits (TWSR[0:1])
  clr r23
  sts TWSR, r23

  ; Set TWBR = ((8MHz - 400kHz) - 16) / 2 = 2 for 400kHz SCL frequency
  ldi r23, 2
  sts TWBR, r23

  ; Enable the two wire interface
  ldi r23, 1<<TWEN
  sts TWCR, r23
  ret

; Transmit a START condition on the I2C bus
twiStart:
  ; Clear TWINT, become the master keeping TWI enabled
  ldi r23, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
  sts TWCR, r23

; Wait until transmission is done by checking TWINT
wait1:
  lds r23, TWCR
  sbrs r23, TWINT
  rjmp wait1
  ret

; Transmit a STOP condition to the bus
twiStop:
  ; Clear TWINT, write STOP in master mode keeping TWI enabled
  ldi r23, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
  sts TWCR, r23
  ret

; Send value stored in `r16` to the bus
twiWrite:
  sts TWDR, r16       ; Store value to data register
  
  ; Transmit the data
  ldi r23, (1<<TWINT)|(1<<TWEN)
  sts TWCR, r23

; Wait until transmission is done by checking TWINT
wait2:
  lds r23, TWCR
  sbrs r23, TWINT
  rjmp wait2

  ret

; Initialize MCU as an SPI master
spiInit:
  ; Set MOSI, SCK and SS as outputs
  ldi r23, (1<<MOSI)|(1<<SCK)|(1<<SS)
  out DDR_SPI, r23

  ; Pull SS HIGH as we're not sending anything yet
  sbi PORT_SPI, SS

  ; Enable SPI as master and set clock rate = F_CPU/16 (SPR0 = 1, SPR1 = SPI2X = 0)
  ldi r23, (1<<SPE)|(1<<MSTR)|(1<<SPR0)
  out SPCR, r23
  ret

; Transmit data stored in `r16` to the bus
spiTransmit:
  out SPDR, r16

; Wait until transmission is done
spiWait:
  in r23, SPSR
  sbrs r23, SPIF      ; Break if SPIF is set
  rjmp spiWait

  ret

; Read data on the bus and store it in `r16`
spiReceive:
  in r16, SPDR
  ret

; Introduce a delay of `[r25 r24]` ms for 8MHz clock
delay:                ; (8000 + 2) * r16 + 1 ~= [r25 r24] ms
  ldi r22, 19
delay1ms:             ; (419 + 2) * 19 + 1 = 8000 clock cycles = 1ms
  ldi r23, 209
l1:                   ; 2 * 209 + 1 = 419 clock cycles
  dec r23             ; 1 clock cycle
  brne l1             ; 1 clock cycle + 1 if branching

  dec r22
  brne delay1ms

  sbiw r24, 1         ; Decrement word [r25 r24] by 1
  brne delay
  ret
