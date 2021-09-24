DEVICE = atmega328p
PORT = /dev/ttyUSB*
PROGRAMMER = -c arduino -P $(PORT) -b 38400 -p $(DEVICE)
FUSES = -U lfuse:w:0xf2:m

all: main.hex

main.hex: main.asm
	avra main.asm

flash: all
	avrdude $(PROGRAMMER) -U flash:w:main.hex:i

fuses:
	avrdude $(PROGRAMMER) $(FUSES)

bootloader:
	avrdude -c stk500v1 -P $(PORT) -b 19200 -p $(DEVICE) $(FUSES) -U flash:w:bootloader.hex:i -U lock:w:0x0f:m

.PHONY: clean
clean:
	rm main.hex main.eep.hex main.obj
