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

.equ ESTADO_CERRADA = 0
.equ ESTADO_ABRIENDO = 1
.equ ESTADO_ABIERTA = 2
.equ ESTADO_CERRANDO = 3
.equ ESTADO_SEGURIDAD = 4

.cseg
.org 0x0000
    rjmp inicio

.org PCI2addr
    rjmp isr_obstaculo

.org 0x0100

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

    ldi r16, (1<<PCINT20)
    sts PCMSK2, r16
    ldi r16, (1<<PCIF2)
    out PCIFR, r16
    ldi r16, (1<<PCIE2)
    sts PCICR, r16

    ldi r20, ESTADO_CERRADA
    sei

principal:
    cpi r20, ESTADO_CERRADA
    breq puerta_cerrada
    cpi r20, ESTADO_ABRIENDO
    breq puerta_abriendo
    cpi r20, ESTADO_ABIERTA
    breq puerta_abierta
    cpi r20, ESTADO_CERRANDO
    breq puerta_cerrando
    rjmp puerta_seguridad

puerta_cerrada:
    sbis PINC, BOTON_ABRIR
    rjmp iniciar_apertura
    rjmp principal

puerta_abriendo:
    sbis PINC, FIN_ABIERTA
    rjmp finalizar_apertura
    rjmp principal

puerta_abierta:
    sbis PINC, BOTON_CERRAR
    rjmp iniciar_cierre
    rjmp principal

puerta_cerrando:
    sbis PINC, FIN_CERRADA
    rjmp finalizar_cierre
    rjmp principal

puerta_seguridad:
    sbis PIND, OBSTACULO
    rjmp principal
    sbis PINC, BOTON_ABRIR
    rjmp reanudar_apertura
    sbis PINC, BOTON_CERRAR
    rjmp reanudar_cierre
    rjmp principal

iniciar_apertura:
    sbis PIND, OBSTACULO
    rjmp principal
    cli
    cpi r20, ESTADO_CERRADA
    brne cancelar_apertura
    ldi r20, ESTADO_ABRIENDO
    cbi PORTD, MOTOR_BAJANDO
    sbi PORTD, MOTOR_SUBIENDO
    sbi PORTD, ALARMA
    sei
    rjmp principal

cancelar_apertura:
    sei
    rjmp principal

finalizar_apertura:
    cli
    cpi r20, ESTADO_ABRIENDO
    brne cancelar_fin_apertura
    rcall apagar_salidas
    ldi r20, ESTADO_ABIERTA
    sei
    rjmp principal

cancelar_fin_apertura:
    sei
    rjmp principal

iniciar_cierre:
    sbis PIND, OBSTACULO
    rjmp principal
    cli
    cpi r20, ESTADO_ABIERTA
    brne cancelar_cierre
    ldi r20, ESTADO_CERRANDO
    cbi PORTD, MOTOR_SUBIENDO
    sbi PORTD, MOTOR_BAJANDO
    sbi PORTD, ALARMA
    sei
    rjmp principal

cancelar_cierre:
    sei
    rjmp principal

finalizar_cierre:
    cli
    cpi r20, ESTADO_CERRANDO
    brne cancelar_fin_cierre
    rcall apagar_salidas
    ldi r20, ESTADO_CERRADA
    sei
    rjmp principal

cancelar_fin_cierre:
    sei
    rjmp principal

reanudar_apertura:
    cli
    cpi r20, ESTADO_SEGURIDAD
    brne cancelar_reanudacion_apertura
    sbis PIND, OBSTACULO
    rjmp cancelar_reanudacion_apertura
    ldi r20, ESTADO_ABRIENDO
    cbi PORTD, MOTOR_BAJANDO
    sbi PORTD, MOTOR_SUBIENDO
    sbi PORTD, ALARMA
    sei
    rjmp principal

cancelar_reanudacion_apertura:
    sei
    rjmp principal

reanudar_cierre:
    cli
    cpi r20, ESTADO_SEGURIDAD
    brne cancelar_reanudacion_cierre
    sbis PIND, OBSTACULO
    rjmp cancelar_reanudacion_cierre
    ldi r20, ESTADO_CERRANDO
    cbi PORTD, MOTOR_SUBIENDO
    sbi PORTD, MOTOR_BAJANDO
    sbi PORTD, ALARMA
    sei
    rjmp principal

cancelar_reanudacion_cierre:
    sei
    rjmp principal

apagar_salidas:
    cbi PORTD, MOTOR_SUBIENDO
    cbi PORTD, MOTOR_BAJANDO
    cbi PORTD, ALARMA
    ret

isr_obstaculo:
    push r16
    in r16, SREG
    push r16

    sbic PIND, OBSTACULO
    rjmp salir_interrupcion
    cpi r20, ESTADO_ABRIENDO
    breq detener_por_obstaculo
    cpi r20, ESTADO_CERRANDO
    brne salir_interrupcion

detener_por_obstaculo:
    cbi PORTD, MOTOR_SUBIENDO
    cbi PORTD, MOTOR_BAJANDO
    cbi PORTD, ALARMA
    ldi r20, ESTADO_SEGURIDAD

salir_interrupcion:
    pop r16
    out SREG, r16
    pop r16
    reti

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
