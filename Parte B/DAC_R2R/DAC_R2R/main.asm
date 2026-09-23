.include "m328pdef.inc"

.def temporal = r17

.cseg
.org 0x0000
    rjmp inicio

.org 0x0100

inicio:
    ldi temporal, HIGH(RAMEND)
    out SPH, temporal
    ldi temporal, LOW(RAMEND)
    out SPL, temporal
    ldi temporal, 0b00111111
    out DDRB, temporal
    ldi temporal, 0b00000011
    out DDRC, temporal
    clr temporal
    out PORTB, temporal
    out PORTC, temporal

principal:
    rjmp principal
