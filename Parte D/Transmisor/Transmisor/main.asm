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

nueva_lectura:
    rcall leer_pulsadores
    mov r18, r16
    ldi r19, 20

estabilizar:
    rcall demora_1ms
    rcall leer_pulsadores
    cp r16, r18
    brne nueva_lectura
    dec r19
    brne estabilizar
    rjmp nueva_lectura

leer_pulsadores:
    in r16, PINC
    com r16
    andi r16, 0b00000111
    ret

demora_1ms:
    ldi r20, 21

demora_externa:
    ldi r21, 250

demora_interna:
    dec r21
    brne demora_interna
    dec r20
    brne demora_externa
    ret
