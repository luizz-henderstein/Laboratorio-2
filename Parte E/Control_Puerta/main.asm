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
    clr r21
    rcall demora_inicio
    rcall mensaje_cerrada
    sei

principal:
    tst r21
    breq revisar_estado
    clr r21
    rcall mensaje_obstaculo
    rcall mensaje_seguridad

revisar_estado:
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
    rcall mensaje_abriendo
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
    rcall mensaje_abierta
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
    rcall mensaje_cerrando
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
    rcall mensaje_cerrada
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
    rcall mensaje_abriendo
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
    rcall mensaje_cerrando
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
    ldi r21, 1

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

putc:
    lds r17, UCSR0A
    sbrs r17, UDRE0
    rjmp putc
    sts UDR0, r16
    ret

enviar_texto:
    lpm r16, Z+
    tst r16
    breq fin_texto
    rcall putc
    rjmp enviar_texto

fin_texto:
    ret

demora_inicio:
    ldi r24, 100

demora_100ms:
    ldi r25, 21

demora_1ms:
    ldi r26, 250

demora_ciclo:
    dec r26
    brne demora_ciclo
    dec r25
    brne demora_1ms
    dec r24
    brne demora_100ms
    ret

mensaje_abriendo:
    ldi ZH, HIGH(texto_abriendo*2)
    ldi ZL, LOW(texto_abriendo*2)
    rjmp enviar_texto

mensaje_abierta:
    ldi ZH, HIGH(texto_abierta*2)
    ldi ZL, LOW(texto_abierta*2)
    rjmp enviar_texto

mensaje_cerrando:
    ldi ZH, HIGH(texto_cerrando*2)
    ldi ZL, LOW(texto_cerrando*2)
    rjmp enviar_texto

mensaje_cerrada:
    ldi ZH, HIGH(texto_cerrada*2)
    ldi ZL, LOW(texto_cerrada*2)
    rjmp enviar_texto

mensaje_obstaculo:
    ldi ZH, HIGH(texto_obstaculo*2)
    ldi ZL, LOW(texto_obstaculo*2)
    rjmp enviar_texto

mensaje_seguridad:
    ldi ZH, HIGH(texto_seguridad*2)
    ldi ZL, LOW(texto_seguridad*2)
    rjmp enviar_texto

texto_abriendo:
    .db "Puerta abriendo.",13,10,0,0
texto_abierta:
    .db "Puerta abierta.",13,10,0
texto_cerrando:
    .db "Puerta cerrando.",13,10,0,0
texto_cerrada:
    .db "Puerta cerrada.",13,10,0
texto_obstaculo:
    .db "Obst",0xC3,0xA1,"culo detectado.",13,10,0
texto_seguridad:
    .db "Movimiento detenido por seguridad.",13,10,0,0
