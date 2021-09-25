; vim:ft=avra

  .device atmega328p

  .equ RAMEND = 0x8ff   ; End of user RAM
  .equ SREG = 0x3f      ; Status Register
  .equ SPL = 0x3d       ; Stack Pointer Low
  .equ SPH = 0x3e       ; Stack Pointer High
  .equ PORTB = 0x05     ; Port B
  .equ DDRB = 0x04      ; Data Direction Register Port B

  ; Reset Vector
  .org 0x0000
  jmp main

  ; Main Program Start
  .org 0x003a
main:
  ldi r16, 0            ; reset system status
  out SREG, r16         ; init stack pointer
  ldi r16, low(RAMEND)  ; 0xff
  out SPL, r16
  ldi r16, high(RAMEND) ; 0x08
  out SPH, r16

  ldi r16, 0x20         ; set port PB5 to output mode
  out DDRB, r16

  clr r17

mainloop:
  eor r17, r16          ; invert output bit
  out PORTB, r17        ; write to port
  call wait             ; wait some time
  jmp mainloop          ; loop forever

wait:
  push r16
  push r17
  push r18

  ldi r16, 0x20         ; loop 0x400000 times
  ldi r17, 0x00         ; ~12 million cycles
  ldi r18, 0x00         ; ~0.7s at 16Mhz
w0:
  dec r18
  brne w0
  dec r17
  brne w0
  dec r16
  brne w0

  pop r18
  pop r17
  pop r16
  ret
