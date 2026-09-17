.include "m328pdef.inc"

.equ F_CPU = 16000000
.equ BAUD = 9600
.equ BPS = (F_CPU/8/BAUD)-1

.equ BOTON_ABRIR = PC0
.equ BOTON_CERRAR = PC1
.equ FIN_ABIERTA = PC2
.equ FIN_CERRADA = PC3
.equ OBSTACULO = PD4
.equ MOTOR_SUBIENDO = PD5
.equ MOTOR_BAJANDO = PD6
.equ ALARMA = PD7

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
    ldi r16, (1<<BOTON_ABRIR)|(1<<BOTON_CERRAR)|(1<<FIN_ABIERTA)|(1<<FIN_CERRADA)
    out PORTC, r16

    ldi r16, (1<<MOTOR_SUBIENDO)|(1<<MOTOR_BAJANDO)|(1<<ALARMA)
    out DDRD, r16
    ldi r16, (1<<OBSTACULO)
    out PORTD, r16

    ldi r16, LOW(BPS)
    ldi r17, HIGH(BPS)
    rcall initUART

principal:
    rjmp principal

initUART:
    sts UBRR0L, r16
    sts UBRR0H, r17
    ldi r16, (1<<U2X0)
    sts UCSR0A, r16
    ldi r16, (1<<TXEN0)
    sts UCSR0B, r16
    ldi r16, (1<<UCSZ01)|(1<<UCSZ00)
    sts UCSR0C, r16
    ret
