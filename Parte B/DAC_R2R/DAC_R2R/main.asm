.include "m328pdef.inc"

.equ F_CPU = 16000000
.equ BAUD = 9600
.equ BPS = (F_CPU/16/BAUD)-1

.def muestra = r16
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

    ldi muestra, LOW(BPS)
    ldi temporal, HIGH(BPS)
    rcall iniciar_uart

    ldi temporal, (1<<COM2B1)|(1<<WGM21)|(1<<WGM20)
    sts TCCR2A, temporal
    ldi temporal, (1<<CS20)
    sts TCCR2B, temporal
    clr temporal
    sts OCR2B, temporal

    ldi ZH, HIGH(menu*2)
    ldi ZL, LOW(menu*2)
    rcall enviar_cadena

principal:
    rjmp principal

iniciar_uart:
    sts UBRR0L, muestra
    sts UBRR0H, temporal
    clr temporal
    sts UCSR0A, temporal
    ldi temporal, (1<<RXEN0)|(1<<TXEN0)
    sts UCSR0B, temporal
    ldi temporal, (1<<UCSZ01)|(1<<UCSZ00)
    sts UCSR0C, temporal
    ret

enviar_cadena:
    lpm muestra, Z+
    tst muestra
    breq fin_cadena
    rcall enviar_caracter
    rjmp enviar_cadena

fin_cadena:
    ret

enviar_caracter:
    lds temporal, UCSR0A
    sbrs temporal, UDRE0
    rjmp enviar_caracter
    sts UDR0, muestra
    ret

menu:
    .db 13,10,"DAC R-2R - Grupo 9",13,10,"1: Senal 1",13,10,"2: Senal 18",13,10,"+: frecuencia mayor",13,10,"-: frecuencia menor",13,10,"M: mostrar menu",13,10,0,0
