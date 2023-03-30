/*
Основные функции для работы с TWI
*/

 .equ	DS1307_ADDRESS		=	104
 .equ	write				=	0
 .equ	read				=	1
 .equ	TWSR_MASK			=	0xFC
 .equ	TWI_NEED_ANSW		=	(1<<TWEA)
 .equ	TWI_NO_NEED_ANSW	=	(0<<TWEA)
// Общие статусные коды                     
 .equ	TWI_START			=	0x08  // START has been transmitted  
 .equ	TWI_REP_START		=	0x10  // Repeated START has been transmitted
 .equ	TWI_ARB_LOST		=	0x38  // Arbitration lost

// Статусные коды ведущего передатчика                     
 .equ	TWI_MTX_ADR_ACK     =	0x18  // SLA+W has been tramsmitted and ACK received
 .equ	TWI_MTX_ADR_NACK    =	0x20  // SLA+W has been tramsmitted and NACK received 
 .equ	TWI_MTX_DATA_ACK    =	0x28  // Data byte has been tramsmitted and ACK received
 .equ	TWI_MTX_DATA_NACK   =	0x30  // Data byte has been tramsmitted and NACK received 

// Статусные коды ведущего приемника 
 .equ	TWI_MRX_ADR_ACK     =	0x40  // SLA+R has been tramsmitted and ACK received
 .equ	TWI_MRX_ADR_NACK    =	0x48  // SLA+R has been tramsmitted and NACK received
 .equ	TWI_MRX_DATA_ACK    =	0x50  // Data byte has been received and ACK tramsmitted
 .equ	TWI_MRX_DATA_NACK   =	0x58  // Data byte has been received and NACK tramsmitted


 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
 //отправка стартового байта и разрешение прерывания
 Start:
 ;ожидание пока линия освободиться	
	in		templ,TWCR
	sbrc	templ,(1<<TWIE)
	rjmp	Start
 ;запуск обмена с помощью прерывания
	ldi		templ,(1<<TWEN)|(1<<TWIE)|(1<<TWINT)|(1<<TWSTA)
	out		TWCR,templ
 ret
 
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 //обработчик прерывания TWI   
 TWI_int:
	push	templ
	push	temph	
 ;считывание статусного регистра и его маскирование
	in		status,TWSR
	andi	status,TWSR_MASK
 ;если прерывание вызвано формированием старта, повторного старта, успешной передачи
 ;пакета или байта данных вызывается функция в которой происходит передача след. байта или формирование стоп
	cpi		status,TWI_START
	breq	tranceive
	cpi		status,TWI_REP_START
	breq	tranceive
	cpi		status,TWI_MTX_ADR_ACK
	breq	tranceive
	cpi		status,TWI_MTX_DATA_ACK
	brne	status_check_1
 tranceive:
	call	Send_byte	
	rjmp	exit_twi_int 
 ;при успешном принятии байта данных с подтверждением в зависимости от номера принятого байта 
 ;запись осуществляется в соответствующий регистр и далее выполнение функции, которая будет исполняться
 ;также при успешной передаче пакета с адресом датчика
 status_check_1:
	cpi		status,TWI_MRX_DATA_ACK
	brne	receive
	call	Read_byte
	rjmp	exit_twi_int
 receive:
	cpi		status,TWI_MRX_ADR_ACK
	brne	status_check_2
	dec		byte_address
	ldi		templ,(1<<TWEN)|(1<<TWIE)|(1<<TWINT)|(1<<TWEA)
	out		TWCR,templ
	rjmp	exit_twi_int 
 status_check_2:
 ;если принят байт без подтверждения - считывается байт и формируется стоп
	cpi		status,TWI_MRX_DATA_NACK
	brne	status_check_3
	call	Read_byte
	rjmp	exit_twi_int 
 status_check_3:
 ;следующие операции выполняются при возникновении ошибок
 ;потеря приоритета
	cpi		status,TWI_ARB_LOST
	brne	status_check_4
	ldi		templ,(1<<TWEN)|(1<<TWIE)|(1<<TWINT)|(1<<TWSTA)
	out		TWCR,templ
	rjmp	exit_twi_int
 status_check_4:	
 ;был передан пакет SLA+W и не получено подтверждение
 ;был передан пакет SLA+R и не получено подтверждение    
 ;был передан байт данных и не получено подтверждение
 ;ошибка на шине из-за некоректных состояний СТАРТ или СТОП
	ldi		templ,(1<<TWEN)|(0<<TWIE)|(0<<TWINT)|(0<<TWEA)|(0<<TWSTA)|(0<<TWSTO)|(0<<TWWC)	;запрет прерывания
	out		TWCR,templ
 exit_twi_int:	
	pop		temph
	pop		templ
 reti
 
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 //отправка байта в зависимости от номера посылаемого байта указаного в регистре byte_address
 Send_byte:
	tst		twi_packet_size					;определить последний байт в посылке
	breq	last_byte
	ldi		YL,LOW(TWI_BUFFER_OUT)			;загрузить байт из СОЗУ, адрес байта - в регистре byte_address
	ldi		YH,HIGH(TWI_BUFFER_OUT)
	clr		templ
	add		YL,byte_address
	adc		YH,templ
	ld		templ,Y
	out		TWDR,templ										;загрузка полученного байта в регистр данных TWI
	ldi		templ,(1<<TWEN)|(1<<TWIE)|(1<<TWINT)			;отправка байта
	out		TWCR,templ
	inc		byte_address									;инкрементировать адрес для загрузки след. байта
	dec		twi_packet_size							
	rjmp	exit_send
 //если последний байт отправлен - сформировать стоп
 last_byte:
	ldi		templ,(1<<TWEN)|(1<<TWINT)|(1<<TWSTO)|(0<<TWIE)
	out		TWCR,templ
 exit_send:
 ret
 
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 //чтение байта и запись считаного байта в СОЗУ в соответствии с его номером в посылке,
 //который указан в регистре byte_address 
 Read_byte:
	tst		twi_packet_size
	brne	not_last_byte_in
	in		temph,TWDR
	ldi		templ,(1<<TWEN)|(1<<TWINT)|(1<<TWSTO)|(0<<TWIE)
	out		TWCR,templ
	rjmp	exit_read
 not_last_byte_in:
	cpi		twi_packet_size,1
	brne	not_pre_last_byte_in
	in		temph,TWDR
	ldi		templ,(1<<TWEN)|(1<<TWIE)|(1<<TWINT)|(0<<TWEA)
	out		TWCR,templ
	rjmp	exit_read
 not_pre_last_byte_in:
	in		temph,TWDR
	ldi		templ,(1<<TWEN)|(1<<TWIE)|(1<<TWINT)|(1<<TWEA)
	out		TWCR,templ	
 exit_read:
	ldi		YL,LOW(TWI_BUFFER_IN)			;загрузить байт в СОЗУ, адрес байта СОЗУ - в регистре byte_address
	ldi		YH,HIGH(TWI_BUFFER_IN)
	clr		templ
	add		YL,byte_address
	adc		YH,templ
	st		Y,temph	
	dec		twi_packet_size
	inc		byte_address
 ret
 
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 //чтение пакета данных из памяти датчика и запись их в буфер СОЗУ.
 //запись начинается с нулевого адреса, количество считываемых байт - 7.
 //адрес первого байта в СОЗУ по адресу, заданного меткой TWI_BUFFER_IN
 //перед чтением указатель адреса памяти устр-ва устанавливается в 0,
 //для этого необходимо отправить 2 байта - адрес устр-ва и 0 

 Read_packet:
	clr		templ
	out		PORT_ANODE,templ
	//установка указателя на 0
	ldi		twi_packet_size,2						
	clr		byte_address
	ldi		YL,LOW(TWI_BUFFER_OUT)					;получить адрес в СОЗУ и записать туда адрес устройства и 0
	ldi		YH,HIGH(TWI_BUFFER_OUT)	
	ldi		templ,(DS1307_ADDRESS<<1)|write			;адрес устройства(байт для записи)						
	st		Y+,templ
	clr		templ						
	st		Y,templ
	call	Start
	call	Wait_TWI_finish
	//чтение данных
	ldi		twi_packet_size,8						;7 байтов считываемых данных и 1 байт для записи
	clr		byte_address							;чтение данных с нулевого адреса
	ldi		templ,(DS1307_ADDRESS<<1)|read			;адрес устройства(байт для записи)
	ldi		YL,LOW(TWI_BUFFER_OUT)					;получить адрес в СОЗУ и записать туда адрес устройства
	ldi		YH,HIGH(TWI_BUFFER_OUT)
	st		Y,templ
	call	Start
	call	Wait_TWI_finish
 ret

 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 //ожидание окончания работы TWI
 Wait_TWI_finish:
	in		templ,TWCR
	sbrc	templ,TWIE
	rjmp	Wait_TWI_finish
 ret

 .dseg

 TWI_BUFFER_OUT:	.byte	16

 TWI_BUFFER_IN:		.byte	16

 .cseg
