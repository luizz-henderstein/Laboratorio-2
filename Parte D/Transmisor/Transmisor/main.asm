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
    out DDRC, r16
    ldi r16, 0b00000111
    out PORTC, r16

principal:
    rcall leer_pulsadores
    rjmp principal

leer_pulsadores:
    in r16, PINC
    com r16
    andi r16, 0b00000111
    ret
