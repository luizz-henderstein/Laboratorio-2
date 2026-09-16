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
    out PORTB, r16
    out PORTC, r16
    ldi r16, 0b00111111
    out DDRB, r16
    ldi r16, 0b00000011
    out DDRC, r16
    ldi r16, LOW(BPS)
    ldi r17, HIGH(BPS)
    rcall initUART

principal:
    rcall getc
    rjmp principal

initUART:
    sts UBRR0L, r16
    sts UBRR0H, r17
    clr r16
    sts UCSR0A, r16
    ldi r16, (1<<RXEN0)
    sts UCSR0B, r16
    ldi r16, (1<<UCSZ01)|(1<<UCSZ00)
    sts UCSR0C, r16
    ret

getc:
    lds r17, UCSR0A
    sbrs r17, RXC0
    rjmp getc
    lds r16, UDR0
    ret
