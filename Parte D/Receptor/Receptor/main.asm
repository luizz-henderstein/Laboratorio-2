.include "m328pdef.inc"

.cseg
.org 0x0000
    rjmp inicio

inicio:
    ldi r16, HIGH(RAMEND)
    out SPH, r16
    ldi r16, LOW(RAMEND)
    out SPL, r16
    clr r16
    out PORTB, r16
    out PORTC, r16
    ldi r16, 0b00111111
    out DDRB, r16
    ldi r16, 0b00000011
    out DDRC, r16

principal:
    rjmp principal
