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
    ldi temporal, (1<<DDD3)
    out DDRD, temporal
    clr temporal
    out PORTB, temporal
    out PORTC, temporal

    ldi temporal, (1<<COM2B1)|(1<<WGM21)|(1<<WGM20)
    sts TCCR2A, temporal
    ldi temporal, (1<<CS20)
    sts TCCR2B, temporal
    clr temporal
    sts OCR2B, temporal

principal:
    rjmp principal
