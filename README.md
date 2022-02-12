# atmega328p-oled-asm
This project contains AVR assembly code for reading a video off of an SD card and playing it on an OLED display.

More details about this project can be found on my blog.

[Driving an OLED display with ATmega328P using AVR assembly | BitBanged](https://bitbanged.com/posts/driving-an-oled-display-with-atmega328p-using-avr-assembly/)

## Dependencies
- [`avra`](https://github.com/Ro5bert/avra): The AVR assembler
- [`avrdude`](https://www.nongnu.org/avrdude): For flashing the ATmega328P
- [`make`](https://www.gnu.org/software/make): For build tasks like `make flash`
- [python](https://www.python.org): For preprocessing the video

## Usage
Here is a video of me explaining how to use this project:

<iframe width="560" height="315" src="https://www.youtube.com/embed/db0ZuH1yo3I" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
