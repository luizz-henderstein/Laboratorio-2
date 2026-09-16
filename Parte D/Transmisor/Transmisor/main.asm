.include "m328pdef.inc"
.equ F_CPU = 16000000
.equ BAUD = 9600
.equ BPS = (F_CPU/16/BAUD)-1

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
    ldi r16, LOW(BPS)
    ldi r17, HIGH(BPS)
    rcall initUART

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
    subi r16, -0x30
    rcall putc
    rjmp nueva_lectura

leer_pulsadores:
    in r16, PINC
    com r16
    andi r16, 0b00000111
    ret

initUART:
    sts UBRR0L, r16
    sts UBRR0H, r17
    clr r16
    sts UCSR0A, r16
    ldi r16, (1<<TXEN0)
    sts UCSR0B, r16
    ldi r16, (1<<UCSZ01)|(1<<UCSZ00)
    sts UCSR0C, r16
    ret

putc:
    lds r17, UCSR0A
    sbrs r17, UDRE0
    rjmp putc
    sts UDR0, r16
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
